# Security Hardening & Alerts

## CVE Alerts

### CVE-2024-43581 — Remote Code Execution (October 2024)

High-severity RCE vulnerability in Microsoft OpenSSH for Windows. Affected multiple
Windows builds. **Action**: ensure cumulative updates are applied.

### Late 2024 ACL Regression

Cumulative updates in late 2024 caused `sshd` service failures due to ACL changes on
`C:\ProgramData\ssh` and its `logs` subdirectory. After updates, verify:

```powershell
Get-Service sshd
Get-WinEvent -LogName Application | Where-Object { $_.Message -like "*sshd*" }
```

If `sshd` fails to start, check and repair ACLs on `C:\ProgramData\ssh`.

## Layered Security Checklist

| Layer | Action |
|-------|--------|
| Firewall | Restrict inbound TCP/22 to authorized source IPs only |
| Auth | Key-only (`PasswordAuthentication no`), Ed25519 with passphrase |
| ACLs | `C:\ProgramData\ssh` — SYSTEM + Administrators only |
| User whitelist | `AllowUsers` in `sshd_config` |
| Monitoring | Enable SSH logging, alert on anomalous sessions |
| VPN | Use VPN/Zerotier — never expose SSH directly to internet |
| Patching | Apply cumulative updates promptly, test before production |

## Verify Key File Permissions

```powershell
# Standard user authorized_keys must be readable only by owner
icacls.exe $env:USERPROFILE\.ssh\authorized_keys

# Admin keys — must be Administrators + SYSTEM only
icacls.exe $env:ProgramData\ssh\administrators_authorized_keys
```
