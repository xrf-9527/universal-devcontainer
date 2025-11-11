# Universal Dev Container (v2-bypass) — **Bypass Mode Default**

> 这一版默认启用 **bypassPermissions**（绕过权限确认）。仅在**可信仓库**和**隔离环境**使用（本模板自带默认拒绝出网的白名单防火墙）。

## 快速开始

```bash
# 选择登录方式（console 推荐）
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# 指定你的项目
export PROJECT_DIR=/abs/path/to/project
export PROJECT_NAME=$(basename "$PROJECT_DIR")

# 打开此仓库并 Reopen in Container
code /abs/path/to/universal-devcontainer-v2-bypass
```

进入容器后：
```bash
claude /help
/permissions   # 查看当前模式（应该显示 bypassPermissions）
```

## 环境变量配置

### 必需变量
| 变量 | 说明 | 示例 |
|------|------|------|
| `PROJECT_DIR` | 要挂载的项目目录（绝对路径） | `/Users/me/my-project` |
| `PROJECT_NAME` | 项目名称（通常是目录名） | `my-project` |
| `CLAUDE_LOGIN_METHOD` | 登录方式：`console`/`claudeai`/`apiKey` | `console` |
| `ANTHROPIC_API_KEY` | Anthropic API Key（用 apiKey 方式时） | `sk-ant-xxx...` |

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
- **开发工具**：Node.js (LTS), Python 3.11, GitHub CLI
- **系统工具**：git, curl, jq, iptables, dnsutils, netcat

## 目录结构
- `.devcontainer/` — 容器定义
  - `Dockerfile` — 基础镜像和系统包
  - `devcontainer.json` — VS Code Dev Container 配置
  - `bootstrap-claude.sh` — Claude Code 安装和配置（postCreate）
  - `init-firewall.sh` — 防火墙初始化（postStart）
  - `setup-proxy.sh` — 代理配置脚本（可选执行）
- `scripts/` — 辅助脚本
  - `open-here.sh` — 在当前目录打开 Dev Container
  - `open-project.sh <路径|Git URL>` — 打开指定项目
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

## 许可证
MIT License — 详见 `LICENSE` 文件

