# Windows SSH 密钥配置

依据当前 Windows/OpenSSH 版本核对[微软密钥管理文档](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)和[OpenSSH 概述](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh-overview)。

## 生成和部署公钥

Linux 上生成独立密钥，交互设置口令，保留现有密钥：

```bash
ssh-keygen -t ed25519 -f ~/.ssh/win_remote -C win-remote
```

按组织策略及主机支持选择算法。只将 `.pub` 公钥传到 Windows，不传私钥。普通用户通常使用其 `.ssh/authorized_keys`。管理员账户在默认匹配规则下使用 `%ProgramData%/ssh/administrators_authorized_keys`；先查看实际 `sshd_config`，不要把默认布局当不可配置规则。

管理员密钥文件仅允许 SYSTEM 和 Administrators 访问；检查现有 ACL 后按微软文档修正，非英语系统可用组 SID `S-1-5-32-544`。普通用户文件按对应账户权限要求配置。不盲目递归替换整个 SSH 目录 ACL。

## 使用 ssh-agent

Linux 示例：

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/win_remote
```

Linux agent 将密钥保存在进程内，进程退出后需重新加载，因此不能因 `ssh-add` 成功就删除唯一私钥。保留受保护的私钥及可恢复备份。Windows agent 的存储行为应按对应实现文档理解，同样先建立可恢复方案。

Windows 在需要且授权时可于管理员 PowerShell 配置：

```powershell
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

## 客户端配置

```sshconfig
Host win-target
    HostName <ip-or-hostname>
    User <username>
    IdentityFile ~/.ssh/win_remote
    StrictHostKeyChecking ask
    ConnectTimeout 10
    PasswordAuthentication no
```

首次连接核对主机指纹；保留已有项目的认证策略。更改服务认证前验证密钥登录和可用恢复通道，避免锁死远程访问。

微软当前文档列出 Entra ID 账户及部分 OpenSSH 指令的支持限制；遇到问题时按当前版本核对，不仅凭本笔记断言。服务重启与认证修改应在任务范围内，维护参考 [security.md](security.md)。
