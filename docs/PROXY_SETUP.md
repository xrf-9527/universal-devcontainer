# Dev Container VPN/代理配置指南

## 概述

本指南介绍如何配置 Dev Container 使用宿主机的 VPN 或代理服务。这对于需要通过公司 VPN 或代理访问网络资源的场景非常有用。

## 方案说明

我们采用 **方案 A（推荐，跨平台）**：将宿主机代理作为 HTTP(S)/SOCKS 代理透传给容器。

### 工作原理

1. 宿主机运行代理客户端（如 Clash、V2Ray、Surge 等）
2. 通过 `host.docker.internal` 别名让容器访问宿主机
3. 容器内的应用通过代理环境变量连接到宿主机代理
4. 防火墙自动放行代理端口，允许容器访问代理服务

### 平台支持

- **macOS / Windows (Docker Desktop)**: `host.docker.internal` 默认可用
- **Linux (Docker Engine ≥ 20.10)**: 需要通过 `--add-host=host.docker.internal:host-gateway` 映射

## 快速开始

### 步骤 1: 在宿主机配置代理环境变量

在宿主机（**非容器内**）的终端或 shell 配置文件中设置以下环境变量：

```bash
# HTTP/HTTPS 代理（常见端口：7890、8080、8888）
export HOST_PROXY_URL=http://host.docker.internal:7890

# SOCKS 代理（可选，常见端口：1080）
export ALL_PROXY=socks5h://host.docker.internal:1080

# NO_PROXY：不走代理的地址（可选）
export NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local
```

**注意**：
- 端口号（如 `7890`）应替换为你的代理软件实际监听的端口
- 常见代理软件端口：
  - Clash: HTTP 7890, SOCKS 7891
  - V2Ray: HTTP/SOCKS 1080
  - Surge: HTTP 6152, SOCKS 6153
  - Shadowsocks: SOCKS 1080

**推荐做法**：将这些环境变量添加到你的 shell 配置文件中（如 `~/.zshrc` 或 `~/.bashrc`），这样每次启动终端都会自动设置：

```bash
# 添加到 ~/.zshrc 或 ~/.bashrc
echo 'export HOST_PROXY_URL=http://host.docker.internal:7890' >> ~/.zshrc
echo 'export ALL_PROXY=socks5h://host.docker.internal:1080' >> ~/.zshrc
echo 'export NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local' >> ~/.zshrc

# 重新加载配置
source ~/.zshrc
```

### 步骤 2: 启动 Dev Container

环境变量配置好后，直接在 VS Code 中重新构建并启动 Dev Container：

1. 打开 VS Code 命令面板（Cmd/Ctrl + Shift + P）
2. 执行命令：`Dev Containers: Rebuild Container`

容器启动后，代理配置会自动生效。

### 步骤 3: （可选）配置包管理器代理

如果你希望 apt、npm、pip、git 等工具也使用代理，在容器内执行：

```bash
bash .devcontainer/setup-proxy.sh
```

这个脚本会自动配置以下工具的代理设置：
- APT (Debian/Ubuntu 包管理器)
- npm / yarn
- pip (Python 包管理器)
- git
- wget

### 步骤 4: 验证代理配置

在容器内执行以下命令验证代理是否工作：

```bash
# 1. 检查环境变量
env | grep -i proxy

# 2. 测试代理端口连接
nc -vz host.docker.internal 7890

# 3. 测试实际网络访问（如果你的代理允许访问 Google）
curl -I https://www.google.com

# 4. 查看防火墙规则（应该看到代理端口被允许）
sudo iptables -S OUTPUT | grep -i proxy
```

## 配置详解

### devcontainer.json 配置

```json
{
  "runArgs": [
    "--cap-add=NET_ADMIN",
    "--add-host=host.docker.internal:host-gateway"
  ],
  "remoteEnv": {
    "HTTP_PROXY": "${localEnv:HOST_PROXY_URL}",
    "HTTPS_PROXY": "${localEnv:HOST_PROXY_URL}",
    "ALL_PROXY": "${localEnv:ALL_PROXY}",
    "NO_PROXY": "${localEnv:NO_PROXY}"
  },
  "containerEnv": {
    "HTTP_PROXY": "${localEnv:HOST_PROXY_URL}",
    "HTTPS_PROXY": "${localEnv:HOST_PROXY_URL}",
    "ALL_PROXY": "${localEnv:ALL_PROXY}",
    "NO_PROXY": "${localEnv:NO_PROXY}"
  }
}
```

**配置说明**：
- `--add-host=host.docker.internal:host-gateway`: 让 Linux 系统也能使用 `host.docker.internal`
- `${localEnv:HOST_PROXY_URL}`: 从宿主机环境变量读取代理 URL
- `remoteEnv`: 为 VS Code 及其子进程（终端、任务等）设置环境变量
- `containerEnv`: 为整个容器进程环境设置环境变量

### 防火墙自动放行

`init-firewall.sh` 会自动解析代理环境变量，并将代理主机和端口加入白名单：

```bash
allow_proxy_from_env() {
  # 从 HTTP(S)_PROXY 或 ALL_PROXY 提取代理地址
  PROXY_RAW="${HTTP_PROXY:-${HTTPS_PROXY:-${ALL_PROXY:-}}}"
  # 解析主机和端口
  # 将代理 IP 和端口加入 iptables 白名单
}
```

这样即使防火墙默认拒绝出站连接，容器也能访问代理服务。

## 常见问题

### Q1: 我的代理软件应该如何配置？

**关键设置**：
1. **允许来自局域网的连接**：大多数代理软件默认只监听 `127.0.0.1`，需要改为监听 `0.0.0.0` 或允许局域网连接
2. **记住端口号**：记下 HTTP 和 SOCKS 代理的端口号，用于设置环境变量

**常见代理软件配置**：

- **Clash**: 在配置文件中设置 `allow-lan: true`
- **V2Ray**: 在 Inbounds 中设置监听地址为 `0.0.0.0`
- **Surge**: 在 "代理设置" 中勾选 "允许来自局域网的连接"

### Q2: 容器无法连接到代理怎么办？

**诊断步骤**：

```bash
# 1. 检查宿主机环境变量是否正确设置
echo $HOST_PROXY_URL

# 2. 在容器内检查环境变量是否传入
env | grep -i proxy

# 3. 测试 host.docker.internal 是否可达
ping -c 3 host.docker.internal

# 4. 测试代理端口是否开放
nc -vz host.docker.internal 7890

# 5. 检查防火墙规则
sudo iptables -S OUTPUT
```

**常见原因**：
- 宿主机代理软件未运行或端口配置错误
- 代理软件未开启 "允许局域网连接"
- 端口号设置错误
- Linux 系统未正确映射 `host.docker.internal`

### Q3: apt 不支持 SOCKS 代理怎么办？

APT 只支持 HTTP/HTTPS 代理。如果你的 VPN 只提供 SOCKS 代理，有两个解决方案：

1. **推荐**：配置代理软件同时开启 HTTP 和 SOCKS 端口
2. 使用 `proxychains` 或 `redsocks` 进行协议转换

### Q4: 某些域名不应该走代理怎么办？

使用 `NO_PROXY` 环境变量：

```bash
export NO_PROXY=localhost,127.0.0.1,.example.com,.internal
```

- 支持通配符域名（如 `.example.com` 匹配所有子域名）
- 多个条目用逗号分隔
- 不要添加协议前缀

### Q5: 如何临时禁用代理？

**方法 1**：在宿主机取消设置环境变量后重建容器

```bash
unset HOST_PROXY_URL
unset ALL_PROXY
# 然后在 VS Code 中执行 "Rebuild Container"
```

**方法 2**：在容器内临时取消环境变量

```bash
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
```

注意：方法 2 只对当前 shell 会话有效。

## 进阶配置

### 使用环境文件管理代理配置

可以创建一个 `.env.proxy` 文件管理代理配置：

```bash
# .env.proxy
HOST_PROXY_URL=http://host.docker.internal:7890
ALL_PROXY=socks5h://host.docker.internal:1080
NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local
```

然后在 shell 配置中：

```bash
# ~/.zshrc
if [ -f ~/.env.proxy ]; then
  export $(grep -v '^#' ~/.env.proxy | xargs)
fi
```

### 为不同项目配置不同代理

使用 VS Code 的工作区设置：

```json
// .vscode/settings.json
{
  "terminal.integrated.env.linux": {
    "HTTP_PROXY": "http://host.docker.internal:7890",
    "HTTPS_PROXY": "http://host.docker.internal:7890"
  }
}
```

## 参考资料

- [Docker 官方文档 - Networking](https://docs.docker.com/network/)
- [VS Code Dev Containers - Environment Variables](https://code.visualstudio.com/remote/advancedcontainers/environment-variables)
- [Docker host.docker.internal 说明](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)

## 故障排除日志

如果遇到问题，请收集以下信息：

```bash
# 宿主机信息
docker --version
docker info | grep -i os

# 环境变量
env | grep -i proxy

# 容器内测试
docker exec -it <container-name> bash -c 'env | grep -i proxy'
docker exec -it <container-name> bash -c 'nc -vz host.docker.internal 7890'

# 防火墙规则
docker exec -it <container-name> bash -c 'sudo iptables -S OUTPUT'
```
