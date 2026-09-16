# Windows SSH 认证维护

先核对 Windows 构建号、OpenSSH 来源/版本和当前微软说明，不沿用旧文档中的漏洞编号与受影响范围作为现时结论。具体漏洞诊断以厂商公告和本机更新状态为依据。

服务不可用时通过已有管理通道读取：

```powershell
Get-Service sshd
Get-WinEvent -LogName Application | Where-Object { $_.Message -like '*sshd*' }
icacls.exe $env:ProgramData\ssh\administrators_authorized_keys
```

日志位置取决于服务配置。检查配置语法、服务账户和相关文件 ACL；不能仅凭更新时间认定是 ACL 回归。

按实际任务维护防火墙来源限制、账户许可、密钥权限和日志。修改 `sshd_config` 前保留当前配置和可恢复访问方式，验证新认证可用后再关闭旧方式。不要把禁用密码、换钥、重启服务或整目录权限重置当作普通远程命令的必做步骤。

管理员公钥文件与普通用户公钥文件权限不同，按[微软密钥管理说明](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)逐文件处理。私钥保留受保护副本，不能因加载进 agent 就删除唯一副本。
