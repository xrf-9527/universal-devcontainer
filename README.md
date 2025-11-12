# Universal Dev Container — Claude Code 开发环境

> 可复用的 Dev Container 配置，集成 Claude Code、防火墙和代理支持。
> 默认启用 **bypassPermissions**（绕过权限确认）— 仅用于**可信仓库**和**隔离环境**。

## 这是什么？

这是一个预配置的开发容器环境，包含：
- ✅ **Claude Code** — AI 编程助手（已配置登录和权限）
- ✅ **开发工具** — Node.js (LTS)、Python 3.12、GitHub CLI
- ✅ **网络安全** — 基于白名单的出站防火墙
- ✅ **代理支持** — VPN/企业代理透传
- ✅ **可复用** — 一份配置，用于所有项目

## 先决条件

- VS Code ≥ 1.105 + Dev Containers 扩展 ≥ 0.427
- Docker Desktop 已启动
- （可选）`npm i -g @devcontainers/cli` — 用于脚本辅助

**受限网络/代理环境**：先阅读 [代理配置指南](docs/PROXY_SETUP.md)

---

## 快速开始 🚀

**核心概念**：这个仓库提供一个可复用的 Dev Container 配置，通过 `workspaceMount` 动态挂载你的项目。

### 方法 1：使用脚本（最简单）⭐

```bash
# 设置 Claude 登录方式（首次使用需要）
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# 为任意项目打开容器
/path/to/universal-devcontainer/scripts/open-project.sh /path/to/your/project

# 或在当前目录
cd /path/to/your/project
/path/to/universal-devcontainer/scripts/open-project.sh .

# 或直接从 Git 仓库克隆并开发
/path/to/universal-devcontainer/scripts/open-project.sh https://github.com/owner/repo.git
```

**工作原理**：
1. 脚本设置 `PROJECT_PATH` 环境变量指向你的项目
2. 打开 universal-devcontainer 目录（不是你的项目目录）
3. VS Code 提示 "Reopen in Container"
4. 容器启动后，你的项目被挂载到 `/workspace`

### 方法 2：手动设置环境变量

如果不想用脚本，可以手动操作：

```bash
# 1. 设置环境变量
export PROJECT_PATH=/path/to/your/project
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# 2. 用 VS Code 打开 universal-devcontainer 目录
code /path/to/universal-devcontainer

# 3. 在 VS Code 中：Dev Containers: Reopen in Container
```

### 方法 3：开发容器本身

如果你想在这个容器里开发 universal-devcontainer 本身，请同样提供 `PROJECT_PATH`（或使用脚本）：

```bash
# 方式 1：用脚本（推荐）
/path/to/universal-devcontainer/scripts/open-project.sh /path/to/universal-devcontainer

# 方式 2：手动设置环境变量
export PROJECT_PATH=/path/to/universal-devcontainer
code /path/to/universal-devcontainer
# 在 VS Code 中：Dev Containers: Reopen in Container
```

说明：为确保兼容性与可预期行为，本配置采用“方案A”，仅在设置了 `PROJECT_PATH` 时进行挂载。

容器内路径约定：
- 你的外部项目：`/workspace`
- 本仓库（工具与脚本）：`/universal`

---

## 验证安装

容器启动后，打开终端验证：

```bash
# 检查 Claude Code
claude /help
/permissions          # 应显示 bypassPermissions

# 检查开发工具
node -v               # LTS 版本
python3 --version     # 3.12.x (Ubuntu 24.04)
gh --version          # GitHub CLI

# 检查代理（如已配置）
env | grep -i proxy
nc -vz host.docker.internal 1082  # 测试宿主代理连通性
```

---

## 环境变量配置

### 必需变量（登录 Claude）

| 变量 | 说明 | 示例 |
|------|------|------|
| `CLAUDE_LOGIN_METHOD` | 登录方式：`console`/`claudeai`/`apiKey` | `console` |
| `ANTHROPIC_API_KEY` | API Key（用 `apiKey` 方式时） | `sk-ant-xxx...` |

在宿主机设置（容器会自动读取）：

```bash
# 方式 1：环境变量
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# 方式 2：VS Code settings.json
// ~/.config/Code/User/settings.json
{
  "dev.containers.defaultEnv": {
    "CLAUDE_LOGIN_METHOD": "console",
    "ANTHROPIC_API_KEY": "sk-ant-..."
  }
}
```

### 可选变量

| 变量 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `CLAUDE_ORG_UUID` | 强制使用指定组织 | - | `org-xxx...` |
| `HOST_PROXY_URL` | 宿主机 HTTP/HTTPS 代理 | - | `http://host.docker.internal:7890` |
| `ALL_PROXY` | 宿主机 SOCKS 代理 | - | `socks5h://host.docker.internal:1080` |
| `NO_PROXY` | 不走代理的地址 | - | `localhost,127.0.0.1,.local` |
| `EXTRA_ALLOW_DOMAINS` | 防火墙额外白名单 | - | `"gitlab.com myapi.com"` |
| `ALLOW_SSH_ANY` | 允许任意 SSH 连接 | `0` | `1` |
| `STRICT_PROXY_ONLY` | 仅允许代理访问 | `0` | `1` |
| `ENABLE_CLAUDE_SANDBOX` | Claude 沙箱模式 | - | `1` |

**代理配置详细说明**：见 [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)

---

## 模式切换

默认使用 **bypass 模式**（无人工确认）。如需更安全的模式，请手动编辑 `~/.claude/settings.json`：

```jsonc
{
  "permissions": {
    // 更安全：需要确认编辑
    "defaultMode": "acceptEdits",
    // 可选：彻底禁用绕过模式（企业更严策略）
    "disableBypassPermissionsMode": "disable"
  }
}
```

---

## 防火墙白名单

容器默认**拒绝所有出站连接**，仅允许以下域名的 HTTPS (443) 连接：

**基础白名单**：
- `registry.npmjs.org` / `npmjs.org` — npm 包管理
- `github.com` / `api.github.com` / `objects.githubusercontent.com` — GitHub
- `claude.ai` / `api.anthropic.com` / `console.anthropic.com` — Claude Code
- DNS 服务器（UDP/TCP 53）
- GitHub SSH（22 端口，除非 `ALLOW_SSH_ANY=1`）

**扩展白名单**：

```bash
export EXTRA_ALLOW_DOMAINS="gitlab.mycompany.com registry.internal.net"
```

防火墙会额外放行这些域名。

**严格代理模式**（`STRICT_PROXY_ONLY=1`）：
- 仅放行 DNS 和代理端口
- 所有外网访问必须走代理
- 适用于高安全要求的受限网络

---

## 内置功能

### 预装插件
- `commit-commands` — 提交辅助
- `pr-review-toolkit` — PR 审查
- `security-guidance` — 安全指导

**插件故障排查**：如果 `/doctor` 显示插件 "not found in marketplace"：

```bash
# 重新运行 bootstrap 脚本
bash .devcontainer/bootstrap-claude.sh

# 验证
claude /plugins marketplaces        # 应显示 claude-code-plugins
claude /plugins search commit-commands
```

### 自定义命令和技能
- `/review-pr <PR编号>` — 分析 GitHub PR
- `reviewing-prs` skill — 代码审查 AI 技能

### 端口转发
默认转发：`3000`, `5173`, `8000`, `9003`

### 预装工具
- **开发工具**：Node.js (LTS), Python 3.12, GitHub CLI
- **系统工具**：git, curl, jq, iptables, dnsutils, netcat

---

## 目录结构

```
universal-devcontainer/
├── .devcontainer/
│   ├── devcontainer.json       # 主配置（通过 mounts 绑定 /workspace 与 /universal）
│   ├── Dockerfile              # 基础镜像
│   ├── bootstrap-claude.sh     # Claude Code 安装
│   ├── init-firewall.sh        # 防火墙规则
│   └── setup-proxy.sh          # 代理配置
├── scripts/
│   └── open-project.sh         # 挂载外部项目到容器（设置 PROJECT_PATH）
├── .claude/
│   └── settings.local.json     # 项目级权限配置
└── docs/
    └── PROXY_SETUP.md          # 代理配置详细指南
```

---

## 故障排查

### 快速排错卡片：打开项目（Workspace does not exist）
- 推荐启动方式：`scripts/open-project.sh /path/to/your/project`（为每个项目开启独立 VS Code 进程，确保继承 `PROJECT_PATH`）。
- 手动方式：从终端执行 `export PROJECT_PATH=/path/to/your/project && code /path/to/universal-devcontainer`（不要从 Dock 启动 VS Code）。
- 变更后重建：VS Code → “Dev Containers: Rebuild Without Cache”。
- macOS 路径共享：Docker Desktop → Settings → Resources → File Sharing 包含项目父目录（如 `/Users`）。
- 快速自检：
  - 宿主机：`echo $PROJECT_PATH`、`test -d "$PROJECT_PATH" && echo OK || echo MISSING`
  - 容器内：查看启动横幅（MOTD）或 `grep ' /workspace ' /proc/mounts` 校验挂载；脚本路径在 `/universal/.devcontainer/...`。

### 问题：容器无法访问外网

**检查项**：
1. 防火墙是否阻止了你需要的域名？→ 添加到 `EXTRA_ALLOW_DOMAINS`
2. 是否在受限网络？→ 配置 `HOST_PROXY_URL`，见 [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)
3. Docker 文件共享权限（macOS）：Docker Desktop → Resources → File Sharing 包含 `/Users`

### 问题：Claude Code 插件找不到

```bash
# 检查市场配置
claude /plugins marketplaces

# 重新 bootstrap
bash .devcontainer/bootstrap-claude.sh

# 检查网络
curl -I https://api.github.com
```

### 问题：路径权限错误（macOS/Linux）

```bash
# 确保父目录可遍历
chmod o+rx /Users/<username>
chmod o+rx /Users/<username>/developer
chmod o+rx /Users/<username>/developer/<project>
```

### 问题：extends 找不到配置文件

**现象**：提示 "missing image information"

**解决**：
- **方法 1**：使用 `github:owner/repo` 而非 `file:相对路径`
- **方法 2**：检查相对路径是否正确（从项目根目录到配置文件的路径）
- **方法 3**：使用方法 1（VS Code UI 流程），无需 extends

### 问题：授权页面一直转圈（OAuth 本地回调 localhost）

**现象**：打开 `https://claude.ai/oauth/authorize?...redirect_uri=http://localhost:<随机端口>/callback` 点击 Authorize 后页面一直加载。

**根因**：回调服务在容器内监听 `127.0.0.1:<随机端口>`，而浏览器在宿主机访问 `localhost:<随机端口>`。未进行端口转发时，宿主机的本地回环无法到达容器，回调请求失败。

**解决**：
- 已内置：`devcontainer.json` 启用动态端口自动转发（`portsAttributes.otherPortsAttributes` + `remote.autoForwardPorts=true`）。出现回调端口监听时，VS Code 会自动将容器端口转发到宿主机相同端口；通常无需手动操作。
- 如仍失败：
  - 观察授权 URL 中的端口号（如 `63497`），在 VS Code 左侧 “PORTS” 面板手动 Forward 该端口。
  - 或在容器内执行登录时，用 `ss -lntp | grep <端口>` 确认监听后再转发。
  - 规避法：设置 `CLAUDE_LOGIN_METHOD=console` 并提供 `ANTHROPIC_API_KEY`，改走控制台/API Key 登录，绕开浏览器本地回调。

---

## 安全提醒 ⚠️

- **绕过模式**不会有人工确认，请**只在可信项目**使用
- 防火墙默认拒绝所有出站连接，仅白名单域名可访问
- 敏感文件受保护：`.env*`, `secrets/**`, `id_rsa`, `id_ed25519`
- 容器需要 `--cap-add=NET_ADMIN` 权限来管理防火墙

如需更安全的模式：按上面的示例手动配置。

---

## 常见使用场景

### 场景 1：快速试用（临时项目）
→ 使用**方法 1**（UI 流程），无需创建任何文件

### 场景 2：团队协作项目
→ 使用**方法 2**（项目配置），提交 `.devcontainer/devcontainer.json` 到代码库

### 场景 3：多个个人项目
→ 使用**方法 3**（脚本辅助），快速为每个项目生成配置

### 场景 4：企业受限网络
→ 先配置代理（见 [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)），然后使用任一方法

---

## 更新日志

### v2.0.0（简化版本）— 2025-01

**重大变更**（提升易用性）：
- ✅ 使用 **workspaceMount** 动态挂载项目（不再依赖 extends）
- ✅ 简化脚本逻辑（从 71 行减少到 65 行）
- ✅ 删除所有不稳定的 extends 相关代码
- ✅ 一个容器服务所有项目

---

## 参考资料

- [VS Code Dev Containers 官方文档](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container 规范](https://containers.dev/)
- [Claude Code 文档](https://code.claude.com/docs)

## 许可证

MIT License — 详见 `LICENSE` 文件
### 问题：启动时提示 “Workspace does not exist”

**原因**：宿主 VS Code 进程未继承 `PROJECT_PATH`，或 Docker Desktop 未共享该路径，导致 `/workspace` 挂载失败。

**解决**：
- 推荐使用脚本启动：`scripts/open-project.sh <你的项目路径>`（脚本会以独立 VS Code 实例启动，继承环境变量）。
- 或在 VS Code 用户设置中配置：
  ```jsonc
  {
    "dev.containers.defaultEnv": { "PROJECT_PATH": "/path/to/your/project" }
  }
  ```
- macOS: Docker Desktop → Settings → Resources → File Sharing，确保包含 `/Users` 或你的项目父目录。
- 仍失败时，先验证：`echo $PROJECT_PATH && test -d "$PROJECT_PATH" && echo OK || echo MISSING`。
