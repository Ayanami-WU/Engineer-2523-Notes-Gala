# GitLab CI/CD 自动部署指南

> 使用 GitLab CI/CD 自动构建 Docker 镜像并部署到远程服务器

## 📋 目录

1. [架构概述](#架构概述)
2. [前置要求](#前置要求)
3. [服务器初始化](#服务器初始化)
4. [GitLab 配置](#gitlab-配置)
5. [部署流程](#部署流程)
6. [验证和测试](#验证和测试)
7. [故障排除](#故障排除)

---

## 🏗️ 架构概述

### 部署流程图

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   开发者    │─push→│   GitLab     │─SSH──→│  远程服务器 │
│  本地修改   │      │   CI/CD      │      │   Docker    │
└─────────────┘      └──────────────┘      └─────────────┘
                            │
                            ├─ Stage 1: Build
                            │  └─ 构建 Docker 镜像
                            │  └─ 保存为 tar 文件
                            │
                            └─ Stage 2: Deploy
                               └─ SSH 传输到服务器
                               └─ 加载镜像并启动容器
```

### 技术栈

- **源码管理**: GitLab
- **CI/CD**: GitLab CI/CD
- **容器化**: Docker + Docker Compose
- **部署方式**: SSH + rsync
- **Web 服务**: Nginx (Alpine)
- **端口**: 8111 (宿主机) → 80 (容器)

---

## ✅ 前置要求

### 本地环境

- [x] Git 已安装
- [x] 项目已推送到 GitLab

### 远程服务器

- [x] Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / Rocky Linux 8+
- [x] SSH 访问权限
- [x] 端口 8111 可用（80 端口被占用）
- [x] 至少 2GB 内存
- [x] 至少 10GB 可用磁盘空间

### GitLab

- [x] GitLab 项目权限
- [x] 可以配置 CI/CD 变量
- [x] 可以注册 GitLab Runner（或使用共享 Runner）

---

## 🚀 服务器初始化

### 方法 1: 使用自动化脚本（推荐）

#### 步骤 1: 下载初始化脚本到服务器

```bash
# SSH 登录到服务器
ssh user@your-server-ip

# 下载脚本
wget https://raw.githubusercontent.com/your-username/tonycrane-note/main/server-init.sh
# 或者使用项目中的脚本
```

#### 步骤 2: 运行初始化脚本

```bash
chmod +x server-init.sh
./server-init.sh
```

脚本会自动完成：
- ✓ 检测操作系统
- ✓ 更新系统包
- ✓ 安装基础工具（curl, wget, git, vim）
- ✓ 安装 Docker Engine
- ✓ 安装 Docker Compose
- ✓ 配置用户权限
- ✓ 开放 8111 端口
- ✓ 创建部署目录

#### 步骤 3: 重新登录使权限生效

```bash
# 退出当前会话
exit

# 重新 SSH 登录
ssh user@your-server-ip

# 或者在当前会话中执行
newgrp docker
```

#### 步骤 4: 验证安装

```bash
# 检查 Docker
docker --version
docker ps

# 检查 Docker Compose
docker compose version
# 或
docker-compose --version
```

### 方法 2: 手动安装

<details>
<summary>点击展开手动安装步骤</summary>

#### Ubuntu/Debian

```bash
# 更新系统
sudo apt-get update && sudo apt-get upgrade -y

# 安装依赖
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 添加 Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到 docker 组
sudo usermod -aG docker $USER
```

#### CentOS/Rocky Linux

```bash
# 安装依赖
sudo yum install -y yum-utils

# 添加 Docker 仓库
sudo yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# 安装 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到 docker 组
sudo usermod -aG docker $USER
```

#### 配置防火墙

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 8111/tcp

# firewalld (CentOS/Rocky)
sudo firewall-cmd --permanent --add-port=8111/tcp
sudo firewall-cmd --reload
```

#### 创建部署目录

```bash
mkdir -p ~/mkdocs-deploy
echo 'export DEPLOY_PATH=~/mkdocs-deploy' >> ~/.bashrc
source ~/.bashrc
```

</details>

---

## 🔐 GitLab 配置

### 1. 生成 SSH 密钥对（如果还没有）

在**本地机器**上运行：

```bash
# 生成 SSH 密钥对
ssh-keygen -t ed25519 -C "gitlab-ci-deployment" -f ~/.ssh/gitlab_deploy_key

# 查看私钥（稍后配置到 GitLab）
cat ~/.ssh/gitlab_deploy_key

# 查看公钥（稍后添加到服务器）
cat ~/.ssh/gitlab_deploy_key.pub
```

### 2. 将公钥添加到服务器

```bash
# 方法 1: 使用 ssh-copy-id
ssh-copy-id -i ~/.ssh/gitlab_deploy_key.pub user@your-server-ip

# 方法 2: 手动添加
ssh user@your-server-ip
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 3. 配置 GitLab CI/CD 变量

进入 GitLab 项目页面：

**Settings** → **CI/CD** → **Variables** → **Add variable**

添加以下变量：

| 键名 | 值 | 类型 | 保护 | 掩码 | 说明 |
|------|-----|------|------|------|------|
| `SSH_PRIVATE_KEY` | （私钥内容） | File | ✓ | ✓ | SSH 私钥 |
| `SERVER_HOST` | `your-server-ip` | Variable | ✓ | - | 服务器 IP/域名 |
| `SERVER_USER` | `username` | Variable | ✓ | - | SSH 用户名 |
| `DEPLOY_PATH` | `/home/username/mkdocs-deploy` | Variable | ✓ | - | 部署路径 |

#### 获取 SSH 私钥内容

```bash
# 查看私钥
cat ~/.ssh/gitlab_deploy_key

# 复制完整内容，包括：
# -----BEGIN OPENSSH PRIVATE KEY-----
# ...（私钥内容）...
# -----END OPENSSH PRIVATE KEY-----
```

### 4. 注册 GitLab Runner（可选）

如果使用自己的 Runner：

<details>
<summary>点击展开 Runner 安装步骤</summary>

#### 在服务器上安装 Runner

```bash
# Ubuntu/Debian
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner

# CentOS/Rocky
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
sudo yum install gitlab-runner
```

#### 注册 Runner

```bash
sudo gitlab-runner register

# 按提示输入：
# GitLab URL: https://gitlab.com
# Registration token: （从项目 Settings → CI/CD → Runners 获取）
# Description: my-docker-runner
# Tags: docker
# Executor: docker
# Default Docker image: alpine:latest
```

#### 配置 Runner

编辑 `/etc/gitlab-runner/config.toml`：

```toml
[[runners]]
  name = "my-docker-runner"
  url = "https://gitlab.com"
  token = "YOUR_TOKEN"
  executor = "docker"
  [runners.docker]
    privileged = true  # 允许 Docker-in-Docker
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
```

重启 Runner：

```bash
sudo gitlab-runner restart
```

</details>

---

## 🚢 部署流程

### 完整部署步骤

#### 步骤 1: 确认配置文件

确保项目根目录包含以下文件：

```
tonycrane-note/
├── .gitlab-ci.yml          # GitLab CI 配置
├── Dockerfile              # Docker 镜像构建
├── docker-compose.yml      # Docker Compose 配置
├── deploy-docker.sh        # 部署脚本
├── requirements.txt        # Python 依赖
├── mkdocs.yml             # MkDocs 配置
└── docs/                  # 文档内容
```

#### 步骤 2: 推送代码到 GitLab

```bash
# 提交更改
git add .
git commit -m "Configure GitLab CI/CD deployment"

# 推送到主分支
git push origin main  # 或 master
```

#### 步骤 3: 监控 CI/CD 流水线

1. 打开 GitLab 项目页面
2. 进入 **CI/CD** → **Pipelines**
3. 查看最新的流水线

流水线包含两个阶段：

**Stage 1: Build** (约 3-5 分钟)
- ✓ 拉取代码
- ✓ 构建 Docker 镜像
- ✓ 安装 Python 依赖
- ✓ 构建 MkDocs 静态站点
- ✓ 保存镜像为 tar 文件

**Stage 2: Deploy** (约 1-2 分钟)
- ✓ SSH 连接到服务器
- ✓ 传输 Docker 镜像
- ✓ 停止旧容器
- ✓ 启动新容器
- ✓ 清理旧镜像

#### 步骤 4: 查看部署日志

点击流水线中的 **deploy_to_server** job，查看部署日志：

```
Deploying to user@server-ip:/home/user/mkdocs-deploy
Loading Docker image...
Loaded image: mkdocs-notes:latest
Stopping old container...
Starting new container...
Container mkdocs-notes started
Deployment completed!
Service running at: http://server-ip:8111
```

#### 步骤 5: 访问网站

打开浏览器访问：

```
http://your-server-ip:8111
```

---

## ✅ 验证和测试

### 1. 检查容器状态

SSH 登录到服务器：

```bash
ssh user@your-server-ip

# 查看运行中的容器
docker ps

# 应该看到类似输出：
# CONTAINER ID   IMAGE                  STATUS         PORTS
# abc123def456   mkdocs-notes:latest   Up 2 minutes   0.0.0.0:8111->80/tcp
```

### 2. 查看容器日志

```bash
# 查看容器日志
docker logs mkdocs-notes

# 实时查看日志
docker logs -f mkdocs-notes
```

### 3. 测试网站访问

```bash
# 在服务器上测试
curl http://localhost:8111

# 应该返回 HTML 内容
```

### 4. 检查插件安装

```bash
# 进入容器
docker exec -it mkdocs-notes sh

# 运行验证脚本（如果包含在镜像中）
# python verify-plugins.py

# 退出容器
exit
```

### 5. 测试自动部署

修改文档内容并推送：

```bash
# 修改任意文档
echo "## 测试更新" >> docs/index.md

# 提交并推送
git add docs/index.md
git commit -m "Test auto deployment"
git push origin main
```

等待 CI/CD 完成后，刷新网站查看更新。

---

## 🔧 故障排除

### 常见问题

#### 1. **SSH 连接失败**

**错误信息**:
```
Permission denied (publickey)
```

**解决方法**:
- 检查 `SSH_PRIVATE_KEY` 是否正确配置
- 确认服务器已添加对应的公钥
- 测试 SSH 连接：
  ```bash
  ssh -i ~/.ssh/gitlab_deploy_key user@server-ip
  ```

#### 2. **Docker 构建失败**

**错误信息**:
```
ERROR: The "glightbox" plugin is not installed
```

**解决方法**:
- 检查 `requirements.txt` 是否包含所有插件
- 查看 Dockerfile 中的安装步骤
- 在本地测试构建：
  ```bash
  docker build -t test-mkdocs .
  ```

#### 3. **端口已被占用**

**错误信息**:
```
Error starting userland proxy: listen tcp4 0.0.0.0:8111: bind: address already in use
```

**解决方法**:
- 检查端口占用：
  ```bash
  sudo netstat -tlnp | grep 8111
  ```
- 停止占用端口的进程或修改 `docker-compose.yml` 使用其他端口

#### 4. **容器启动后立即退出**

**解决方法**:
```bash
# 查看容器日志
docker logs mkdocs-notes

# 查看最近退出的容器
docker ps -a

# 手动启动容器调试
docker run -it --rm mkdocs-notes:latest sh
```

#### 5. **网站无法访问**

**检查清单**:
- [ ] 容器是否正在运行：`docker ps | grep mkdocs-notes`
- [ ] 端口是否正确映射：检查 `docker-compose.yml`
- [ ] 防火墙是否开放 8111 端口
- [ ] 服务器安全组是否允许 8111 端口

#### 6. **GitLab Runner 标签不匹配**

**错误信息**:
```
This job is stuck because the project doesn't have any runners online with any of these tags assigned to it: docker
```

**解决方法**:

**选项 1**: 移除 tags 要求（使用共享 Runner）

编辑 `.gitlab-ci.yml`，删除或注释所有 `tags: - docker` 行

**选项 2**: 注册专用 Runner 并添加 `docker` 标签

```bash
sudo gitlab-runner register
# Tags: docker
```

### 日志位置

| 日志类型 | 位置 |
|---------|------|
| GitLab CI 日志 | GitLab UI → Pipelines → Jobs |
| Docker 容器日志 | `docker logs mkdocs-notes` |
| Nginx 日志 | 容器内 `/var/log/nginx/` |
| 系统日志 | `/var/log/syslog` (Ubuntu) |

### 调试技巧

#### 1. 本地模拟 CI 构建

```bash
# 在项目目录下
docker build -t mkdocs-test .
docker run -d -p 8111:80 --name mkdocs-test mkdocs-test:latest

# 访问测试
curl http://localhost:8111

# 清理
docker stop mkdocs-test
docker rm mkdocs-test
```

#### 2. 手动部署测试

```bash
# SSH 到服务器
ssh user@server-ip

# 进入部署目录
cd ~/mkdocs-deploy

# 手动运行部署脚本
./deploy-docker.sh
```

#### 3. 验证 GitLab CI 配置

```bash
# 使用 GitLab CI Lint 工具
# 访问：https://gitlab.com/your-username/your-project/-/ci/lint
```

---

## 📚 附录

### A. 项目文件说明

| 文件 | 用途 |
|------|------|
| `.gitlab-ci.yml` | GitLab CI/CD 流水线配置 |
| `Dockerfile` | Docker 镜像构建配置 |
| `docker-compose.yml` | Docker Compose 服务配置 |
| `deploy-docker.sh` | 服务器端部署脚本 |
| `server-init.sh` | 服务器初始化脚本 |
| `requirements.txt` | Python 依赖列表 |
| `mkdocs.yml` | MkDocs 配置文件 |
| `verify-plugins.py` | 插件验证脚本 |

### B. 环境变量参考

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `SSH_PRIVATE_KEY` | SSH 私钥 | `-----BEGIN OPENSSH...` |
| `SERVER_HOST` | 服务器地址 | `192.168.1.100` |
| `SERVER_USER` | SSH 用户名 | `deploy` |
| `DEPLOY_PATH` | 部署目录 | `/home/deploy/mkdocs` |
| `CI_COMMIT_SHORT_SHA` | Git 提交哈希 | `abc123de` |
| `CI_REGISTRY_IMAGE` | 镜像仓库地址 | （可选） |

### C. 有用的命令

```bash
# 重启容器
docker-compose restart

# 查看容器资源使用
docker stats mkdocs-notes

# 更新镜像并重新部署
docker-compose pull
docker-compose up -d

# 清理所有未使用的 Docker 资源
docker system prune -a

# 查看部署历史
cd ~/mkdocs-deploy
ls -lt mkdocs-image.tar*
```

### D. 性能优化建议

1. **启用 Docker 构建缓存**
   - GitLab CI 配置中使用 `cache` 关键字

2. **使用轻量级基础镜像**
   - 已使用 `nginx:alpine` 作为最终镜像

3. **禁用不必要的插件**
   - 在 `mkdocs.yml` 中设置 `enabled: !ENV [FULL, false]`

4. **配置 CDN**
   - 静态资源（CSS, JS）使用 CDN 加速

---

## 📞 支持

如遇到问题：

1. 查看本文档的 [故障排除](#故障排除) 部分
2. 检查 GitLab CI 日志和容器日志
3. 运行 `verify-plugins.py` 验证插件
4. 提交 Issue 到项目仓库

---

**最后更新**: 2025-11-16
**版本**: 1.0.0
