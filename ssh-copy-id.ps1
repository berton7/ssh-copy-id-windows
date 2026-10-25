<#
.SYNOPSIS
Installs a local SSH public key in a remote account's authorized_keys file.

.EXAMPLE
.\ssh-copy-id.ps1 user@server

.EXAMPLE
.\ssh-copy-id.ps1 -IdentityFile "$HOME\.ssh\id_ed25519.pub" -Port 2222 user@server
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target,

    [string]$IdentityFile,

    [ValidateRange(1, 65535)]
    [int]$Port = 22
)

$sshCommand = Get-Command ssh.exe -ErrorAction SilentlyContinue
if (-not $sshCommand) {
    throw 'OpenSSH Client was not found. Install the Windows OpenSSH Client feature and try again.'
}

if ([string]::IsNullOrWhiteSpace($IdentityFile)) {
    $defaultKeys = @(
        (Join-Path $HOME '.ssh\id_ed25519.pub'),
        (Join-Path $HOME '.ssh\id_rsa.pub')
    )
    $IdentityFile = $defaultKeys | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $IdentityFile) {
        throw 'No default public key was found. Generate one with ssh-keygen or specify -IdentityFile.'
    }
}

$resolvedIdentityFile = Resolve-Path -LiteralPath $IdentityFile -ErrorAction Stop
$publicKey = [System.IO.File]::ReadAllText($resolvedIdentityFile.Path).Trim()
if ([string]::IsNullOrWhiteSpace($publicKey) -or $publicKey -match '[\r\n]') {
    throw "The public key file must contain exactly one non-empty key line: $IdentityFile"
}

if ($Target.StartsWith('-')) {
    throw 'Target must be a user@host or SSH config host, not an SSH option.'
}

$keyBytes = [System.Text.Encoding]::UTF8.GetBytes($publicKey)
$encodedKey = [Convert]::ToBase64String($keyBytes)
$remoteScript = @(
    'set -e'
    'umask 077'
    'mkdir -p "$HOME/.ssh"'
    'touch "$HOME/.ssh/authorized_keys"'
    'chmod 700 "$HOME/.ssh"'
    'chmod 600 "$HOME/.ssh/authorized_keys"'
    ('key=$(printf ''%s'' ''{0}'' | base64 -d)' -f $encodedKey)
    'if grep -qxF -- "$key" "$HOME/.ssh/authorized_keys"; then'
    '    printf ''Public key is already installed.\n'''
    'else'
    '    printf ''%s\n'' "$key" >> "$HOME/.ssh/authorized_keys"'
    '    printf ''Public key installed.\n'''
    'fi'
) -join "`n"
$encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($remoteScript))
$remoteCommand = "printf %s $encodedScript | base64 -d | sh"

$sshArgs = @()
if ($Port -ne 22) {
    $sshArgs += @('-p', "$Port")
}

& $sshCommand.Source @sshArgs $Target $remoteCommand
if ($LASTEXITCODE -ne 0) {
    throw "ssh-copy-id failed with exit code $LASTEXITCODE."
}
