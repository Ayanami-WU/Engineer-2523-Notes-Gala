# CI/CD 故障排除指南

## 问题：Job failed with "No such command 'sh'"

### 问题原因

这个错误表明你的 GitLab Runner 使用的是 **Shell Executor**，而原来的 `.gitlab-ci.yml` 配置需要 **Docker Executor**。

原配置使用了 Docker 镜像（`image: squidfunk/mkdocs-material:9.7.0`），但 Shell Executor 不支持 Docker 镜像，直接在 Runner 机器的 shell 环境中执行命令。

### 已实施的解决方案

✅ **我已经更新了配置文件，现在兼容 Shell Executor！**

**主要改动：**

1. **移除了 Docker 镜像依赖**
   - 删除了 `image: $DOCKER_IMAGE` 和 `image: alpine:latest`
   - 现在可以在任何 Linux 环境运行

2. **添加了环境检测**
   - 自动检测 `python3` 或 `python` 命令
   - 检查 `rsync` 是否可用
   - 提供清晰的错误提示

3. **优化了包安装**
   - 使用 `pip install --user` 避免权限问题
   - 自动添加 `~/.local/bin` 到 PATH

---

## ⚠️ Runner 机器需要的依赖

你的 GitLab Runner 机器需要安装以下工具：

### 必需工具

- ✅ **Python 3** (python3 或 python)
- ✅ **pip** (Python 包管理器)
- ✅ **rsync** (文件同步工具)
- ✅ **openssh-client** (SSH 客户端)
- ✅ **git** (通常已随 Runner 安装)

---

## 🛠️ 安装依赖

### 方法一：使用自动安装脚本（推荐）

我已经创建了一个自动安装脚本 `setup-runner-dependencies.sh`。

**在 Runner 机器上执行：**

```bash
# 1. 下载脚本
curl -O https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/raw/main/setup-runner-dependencies.sh

# 或者如果项目已克隆
cd /path/to/e-2523-note
chmod +x setup-runner-dependencies.sh

# 2. 运行脚本（可能需要 sudo）
sudo bash setup-runner-dependencies.sh

# 3. 验证安装
python3 --version
pip3 --version
mkdocs --version
rsync --version
```

### 方法二：手动安装

#### Ubuntu/Debian 系统

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv rsync openssh-client

# 安装 MkDocs（全局安装，需要 sudo）
sudo pip3 install mkdocs mkdocs-material

# 或者用户级安装（推荐，无需 sudo）
pip3 install --user mkdocs mkdocs-material
export PATH=$PATH:$HOME/.local/bin
```

#### CentOS/RHEL 系统

```bash
sudo yum install -y python3 python3-pip rsync openssh-clients

# 安装 MkDocs
sudo pip3 install mkdocs mkdocs-material

# 或者用户级安装
pip3 install --user mkdocs mkdocs-material
export PATH=$PATH:$HOME/.local/bin
```

#### macOS 系统

```bash
# 安装 Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装依赖
brew install python3 rsync openssh

# 安装 MkDocs
pip3 install mkdocs mkdocs-material
```

---

## 🔍 检查 Runner 配置

查看你的 GitLab Runner 使用的 Executor 类型：

```bash
# 在 Runner 机器上
sudo gitlab-runner verify

# 查看配置文件
sudo cat /etc/gitlab-runner/config.toml
```

配置文件示例：

```toml
concurrent = 1
check_interval = 0

[[runners]]
  name = "my-shell-runner"
  url = "https://git.koala-studio.org.cn/"
  token = "xxxxxxxxxxxx"
  executor = "shell"  # 这里显示 executor 类型
```

---

## 📋 验证 Pipeline 是否成功

### 1. 查看 Pipeline 状态

访问：`https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/pipelines`

### 2. 查看 Job 日志

点击具体的 job（build 或 deploy_to_server），查看详细日志。

### 3. 常见错误及解决方案

#### 错误：`python3: command not found`

**解决：** 在 Runner 机器上安装 Python 3

```bash
sudo apt-get install python3 python3-pip
```

#### 错误：`mkdocs: command not found`

**解决：** 安装 MkDocs 并确保在 PATH 中

```bash
pip3 install --user mkdocs mkdocs-material
export PATH=$PATH:$HOME/.local/bin

# 永久添加到 PATH（针对 gitlab-runner 用户）
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
```

#### 错误：`rsync: command not found`

**解决：** 安装 rsync

```bash
sudo apt-get install rsync
```

#### 错误：`Permission denied (publickey)` in deploy stage

**解决：** 配置 CI/CD 变量

在 GitLab 项目中：**Settings → CI/CD → Variables**，添加：

| 变量名 | 值 |
|--------|-----|
| `SSH_PRIVATE_KEY` | 服务器部署用的私钥内容 |
| `SERVER_HOST` | 服务器 IP 地址 |
| `SERVER_USER` | SSH 用户名 |
| `DEPLOY_PATH` | 部署路径（如 `~/mkdocs-notes/site`） |

---

## 🚀 触发新的 Pipeline

安装依赖后，推送新的提交触发 Pipeline：

```bash
# 在本地项目目录
git commit --allow-empty -m "test: 测试 CI/CD 配置"
git push origin main
```

然后查看 Pipeline 状态：`https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/pipelines`

---

## 🔄 如果你想使用 Docker Executor

如果你更喜欢使用 Docker Executor（更干净、隔离性更好），可以：

### 1. 重新注册 Runner 为 Docker Executor

```bash
sudo gitlab-runner register

# 按提示输入：
# GitLab instance URL: https://git.koala-studio.org.cn
# Registration token: [从 Settings → CI/CD → Runners 获取]
# Description: mkdocs-docker-runner
# Tags: docker,mkdocs
# Executor: docker
# Default Docker image: alpine:latest
```

### 2. 在 Runner 机器上安装 Docker

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# 添加 gitlab-runner 用户到 docker 组
sudo usermod -aG docker gitlab-runner
sudo systemctl restart gitlab-runner
```

### 3. 恢复使用 Docker 版本的 CI 配置

项目中有一个备份文件 `.gitlab-ci-docker.yml`，可以参考或直接使用。

---

## 📊 对比：Shell vs Docker Executor

| 特性 | Shell Executor | Docker Executor |
|------|----------------|-----------------|
| **隔离性** | ❌ 低（直接在 Runner 机器执行） | ✅ 高（每个 job 独立容器） |
| **环境一致性** | ❌ 依赖 Runner 机器环境 | ✅ 高（使用 Docker 镜像） |
| **依赖管理** | ❌ 需要手动安装 | ✅ 包含在镜像中 |
| **性能** | ✅ 快（无容器启动时间） | ❌ 较慢（需启动容器） |
| **配置复杂度** | ✅ 简单 | ❌ 需要 Docker 支持 |
| **适用场景** | 简单项目、资源受限 | 复杂项目、多环境 |

---

## 🆘 仍然遇到问题？

### 收集诊断信息

在 Runner 机器上运行：

```bash
# 检查 Python
python3 --version
pip3 --version

# 检查 MkDocs
mkdocs --version
python3 -m mkdocs --version

# 检查 PATH
echo $PATH

# 检查 gitlab-runner 用户环境
sudo -u gitlab-runner bash -c 'echo $PATH'
sudo -u gitlab-runner bash -c 'python3 --version'
sudo -u gitlab-runner bash -c 'mkdocs --version'

# 检查 Runner 服务状态
sudo systemctl status gitlab-runner

# 查看 Runner 日志
sudo journalctl -u gitlab-runner -f
```

### 调试 CI/CD

在 `.gitlab-ci.yml` 的 `before_script` 添加调试命令：

```yaml
before_script:
  - echo "=== 环境信息 ==="
  - pwd
  - whoami
  - echo $PATH
  - python3 --version || echo "python3 not found"
  - pip3 --version || echo "pip3 not found"
  - mkdocs --version || echo "mkdocs not found"
```

---

## 📖 相关文档

- [GitLab Runner 配置指南](GITLAB_RUNNER_SETUP_CN.md)
- [部署指南](DEPLOYMENT_CN.md)
- [README](README.md)

---

**祝调试顺利！🎯**

如果问题仍未解决，请查看 GitLab Pipeline 的详细日志，并检查上述诊断信息。
