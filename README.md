# ssh-copy-id for Windows

A PowerShell equivalent of Linux `ssh-copy-id` for installing a local SSH public key on a remote account.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- The Windows OpenSSH Client (`ssh.exe`)
- A remote SSH server with `sh`, `mkdir`, `touch`, `chmod`, `grep`, and `base64`

## Usage

Open PowerShell in this folder and run:

```powershell
.\ssh-copy-id.ps1 user@server
```

By default, the script uses the first public key it finds in this order:

1. `$HOME\.ssh\id_ed25519.pub`
2. `$HOME\.ssh\id_rsa.pub`

Specify another public key or a non-default SSH port with:

```powershell
.\ssh-copy-id.ps1 -IdentityFile "$HOME\.ssh\work_key.pub" -Port 2222 user@server
```

The script prompts for SSH authentication as needed, creates the remote `.ssh` directory and `authorized_keys` file, applies standard permissions, and avoids adding a key that is already installed. It transfers the key as a single line and safely transports its remote setup command.

## Generate a key

If you do not have a key pair yet, create one with:

```powershell
ssh-keygen -t ed25519
```

Run the script from PowerShell. If script execution is restricted by policy, you can invoke it for this process with:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\ssh-copy-id.ps1 user@server
```
