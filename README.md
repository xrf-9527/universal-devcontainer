# Universal Dev Container — **Bypass Mode Default**

> 这一版默认启用 **bypassPermissions**（绕过权限确认）。仅在**可信仓库**和**隔离环境**使用（本模板自带默认拒绝出网的白名单防火墙）。

## 先决条件

- VS Code ≥ 1.105，扩展 `ms-vscode-remote.remote-containers` ≥ 0.427
- Docker Desktop（或兼容 Docker 引擎）已启动，支持 `host.docker.internal`
- Git 可用（用于脚本拉取仓库）
- 如处于受限网络/走代理，请先阅读 `docs/PROXY_SETUP.md`

## 快速开始

推荐方式（自动挂载任意项目目录）：
```bash
# 选择登录方式（console 推荐）
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# 在要作为项目的目录里运行，或指定路径/仓库
scripts/open-here.sh                     # 用当前目录作为项目
# 或
scripts/open-project.sh /abs/path/to/project
# 或
scripts/open-project.sh https://github.com/owner/repo.git

# VS Code 打开后执行：Dev Containers: Reopen in Container / Rebuild Container
```

脚本会生成本地覆盖文件 `.devcontainer/devcontainer.local.json`，把所选项目目录挂载到容器内 `/workspaces/<项目名>`，无需手动设置环境变量。

切换项目或恢复默认挂载：
```bash
# 切换：再次运行 open-here.sh / open-project.sh 覆盖本地配置

# 恢复默认挂载（删除本地覆盖），然后在 VS Code 中 Rebuild Container
scripts/clear-override.sh
```

进入容器后：
```bash
claude /help
/permissions   # 查看当前模式（应该显示 bypassPermissions）
```

### 验证清单
- `python3 --version`（预期 Ubuntu 24.04 为 3.12.x）
- `node -v`（LTS）/ `npm -v`
- `gh --version`
- `env | grep -i proxy`、`nc -vz host.docker.internal 1082`（如配置了代理）

## 环境变量配置

### 必需变量
| 变量 | 说明 | 示例 |
|------|------|------|
| `CLAUDE_LOGIN_METHOD` | 登录方式：`console`/`claudeai`/`apiKey` | `console` |
| `ANTHROPIC_API_KEY` | Anthropic API Key（用 apiKey 方式时） | `sk-ant-xxx...` |

注：如不使用上述脚本，也可以通过环境变量手动指定项目挂载（不推荐，易错）：
```bash
export PROJECT_DIR=/abs/path/to/project
export PROJECT_NAME=$(basename "$PROJECT_DIR")
code /abs/path/to/universal-devcontainer
```

### 可选变量
| 变量 | 说明 | 示例 |
|------|------|------|
| `CLAUDE_ORG_UUID` | 强制使用指定组织 UUID | `org-xxx...` |
| `EXTRA_ALLOW_DOMAINS` | 防火墙额外白名单域名（空格分隔） | `"mycompany.com api.internal.net"` |
| `ALLOW_SSH_ANY` | 允许任意 SSH 连接（默认 `0`，仅允许 GitHub） | `1` |
| `ENABLE_CLAUDE_SANDBOX` | 启用 Claude Code 沙箱模式 | `1` |
| `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` | API Key Helper 缓存时间（毫秒） | `300000` |
| `HOST_PROXY_URL` | 宿主机 HTTP/HTTPS 代理地址 | `http://host.docker.internal:7890` |
| `ALL_PROXY` | 宿主机 SOCKS 代理地址（可选） | `socks5h://host.docker.internal:1080` |
| `NO_PROXY` | 不走代理的地址列表（可选） | `localhost,127.0.0.1,.local` |

#### EXTRA_ALLOW_DOMAINS 使用示例
```bash
# 允许访问公司内部域名
export EXTRA_ALLOW_DOMAINS="gitlab.mycompany.com registry.internal.net"

# 防火墙将会额外放行这些域名的 HTTPS (443) 连接
```

## 模式切换（脚本与 JSON 两种）

- 用脚本：
  ```bash
  scripts/switch-mode.sh bypass      # 开启绕过（默认）
  scripts/switch-mode.sh safe        # 更安全（acceptEdits + 禁用绕过）
  scripts/switch-mode.sh custom ask  # 自定义模式字符串
  ```
- 手动 JSON：见 `MODE-SWITCH.md`。

## 防火墙白名单

容器启动时会应用默认拒绝的出站防火墙，仅允许以下域名的 HTTPS (443) 连接：

**默认白名单**：
- `registry.npmjs.org` / `npmjs.org` — npm 包管理
- `github.com` / `api.github.com` / `objects.githubusercontent.com` — GitHub 访问
- `claude.ai` / `api.anthropic.com` / `console.anthropic.com` — Claude Code 服务
- DNS 服务器（从 `/etc/resolv.conf` 读取）— UDP/TCP 53 端口
- GitHub SSH（22 端口，除非设置 `ALLOW_SSH_ANY=1`）

**扩展白名单**：使用 `EXTRA_ALLOW_DOMAINS` 环境变量添加额外域名。

**VPN/代理支持**：容器支持通过宿主机代理访问网络。详见 [VPN/代理配置指南](docs/PROXY_SETUP.md)。

网络/代理注意事项（摘要）：
- 在 macOS/Windows 下通过 `host.docker.internal` 访问宿主代理端口（示例：`HTTP_PROXY=http://host.docker.internal:1082`）
- 设置 `NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local`
- 受限网络下建议只走代理；如需更严格策略，可按需调整 `.devcontainer/init-firewall.sh`

## 内置功能

### 预装插件
- `commit-commands` — 提交辅助命令
- `pr-review-toolkit` — PR 审查工具
- `security-guidance` — 安全指导

### 自定义命令和技能
- `/review-pr <PR编号>` — 分析 GitHub PR 并生成审查要点
- `reviewing-prs` skill — 专注于代码审查的 AI 技能

### 端口转发
默认转发以下端口到主机：`3000`, `5173`, `8000`, `9003`

### 预装工具
- **开发工具**：Node.js (LTS), Python（系统版本，Ubuntu 24.04 为 3.12），GitHub CLI
- **系统工具**：git, curl, jq, iptables, dnsutils, netcat

说明：使用系统 Python 可避免在受限网络下源码编译与 GPG 校验失败。如果必须固定到 3.11 等非系统版本，可在 `devcontainer.json` 中修改 Feature 配置，并确保为该 Feature 提供专用代理（或预配置 dirmngr）。

## 目录结构
- `.devcontainer/` — 容器定义
  - `Dockerfile` — 基础镜像和系统包
  - `devcontainer.json` — VS Code Dev Container 配置
  - `devcontainer.local.json` — 本地覆盖（由脚本生成，绑定项目目录；已加入 .gitignore）
  - `bootstrap-claude.sh` — Claude Code 安装和配置（postCreate）
  - `init-firewall.sh` — 防火墙初始化（postStart）
  - `setup-proxy.sh` — 代理配置脚本（可选执行）
- `scripts/` — 辅助脚本
  - `open-here.sh` — 在当前目录打开 Dev Container（生成本地覆盖并挂载）
  - `open-project.sh <路径|Git URL>` — 打开指定项目（生成本地覆盖并挂载）
  - `clear-override.sh` — 清理本地覆盖，恢复默认挂载
  - `switch-mode.sh` — 权限模式切换
- `.claude/` — Claude Code 配置
  - `settings.local.json` — 项目级权限配置
- `docs/` — 文档目录
  - `PROXY_SETUP.md` — VPN/代理配置指南
- `README.md` / `MODE-SWITCH.md` — 主要文档

## 安全提醒
- **绕过模式**不会有人类确认，请**只在可信项目**使用
- 防火墙默认拒绝所有出站连接，仅白名单域名可访问
- 敏感文件受保护：`.env*`, `secrets/**`, `id_rsa`, `id_ed25519`
- 容器需要 `--cap-add=NET_ADMIN` 权限来管理 iptables 防火墙

如需切换到更安全的模式（非绕过），请参见 `MODE-SWITCH.md` 或运行 `scripts/switch-mode.sh safe`。

## 许可证
MIT License — 详见 `LICENSE` 文件
