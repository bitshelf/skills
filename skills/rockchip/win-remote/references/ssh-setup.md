# SSH Key Setup for Windows

[Microsoft: OpenSSH key management](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)
[OpenSSH overview](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh-overview)

## Generate Key Pair (Linux)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/win_remote -N "" -C "win-remote"
```

Ed25519 is recommended by Microsoft (modern, compact, strong). Avoid DSA; RSA 4096
is acceptable where policy requires it.

## Deploy Public Key to Windows

### Standard user

```bash
ssh ${WIN_USER}@${WIN_HOST} "powershell -Command \"
    New-Item -Force -ItemType Directory -Path \\\"\$env:USERPROFILE\\.ssh\\\";
    Add-Content -Force -Path \\\"\$env:USERPROFILE\\.ssh\\authorized_keys\\\" \
        -Value '$(cat ~/.ssh/win_remote.pub)'
\""
```

### Administrative user

Admin keys go to `C:\ProgramData\ssh\administrators_authorized_keys` (**not** `~\.ssh\authorized_keys`),
with strict ACL:

```bash
ssh ${WIN_USER}@${WIN_HOST} "powershell -Command \"
    Add-Content -Force -Path \\\"\$env:ProgramData\\ssh\\administrators_authorized_keys\\\" \
        -Value '$(cat ~/.ssh/win_remote.pub)';
    icacls.exe \\\"\$env:ProgramData\\ssh\\administrators_authorized_keys\\\" \
        /inheritance:r /grant \\\"*S-1-5-32-544:F\\\" /grant \\\"SYSTEM:F\\\"
\""
```

The SID `*S-1-5-32-544` is the Administrators group (works on any language).

## ssh-agent (Recommended)

Store keys in `ssh-agent` instead of on disk:

```bash
# Linux
eval $(ssh-agent -s)
ssh-add ~/.ssh/win_remote

# Windows (PowerShell as Admin)
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

After adding to agent, **delete the private key from disk** — it cannot be retrieved from the agent.

## SSH Config (~/.ssh/config)

```
Host win-target
    HostName <ip-or-hostname>
    User <username>
    IdentityFile ~/.ssh/win_remote
    StrictHostKeyChecking accept-new
    ConnectTimeout 10
    PasswordAuthentication no
```

## sshd_config Hardening

On the Windows machine, edit `C:\ProgramData\ssh\sshd_config`:

```ini
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
PermitEmptyPasswords no
AllowUsers <admin-user>
```

Restart: `Restart-Service sshd` (PowerShell as Admin).

## Important Limitations

- **Microsoft Entra ID (Azure AD) accounts do NOT support key-based auth** — only local
  and Active Directory domain accounts.
- `AuthorizedKeysCommand` and `AuthorizedKeysCommandUser` are **not supported** on Windows.
- Remote sessions via key auth have **no associated user credentials** — outbound auth as
  that user is not possible by design.

See [security.md](security.md) for CVE alerts and ACL hardening.
