# 🚀 GitHub Actions 自动化部署指南

> **完美方案**：GitHub Actions + 服务器端构建
>
> 适用于公网服务器，解决内网 GitLab 无法访问的问题

---

## 💡 为什么选择 GitHub？

### 问题分析

❌ **GitLab 在内网的问题**:
- 外部服务器无法访问内网 GitLab
- 无法克隆代码
- 无法下载部署脚本

✅ **GitHub 的优势**:
- 公网访问，全球可达
- GitHub Actions 免费额度充足
- 配置简单，功能强大
- 与 GitLab CI 类似的工作流

---

## 🎯 方案架构

```
开发者推送代码到 GitHub
        ↓
GitHub Actions 检测到 push
        ↓
SSH 连接到外部服务器
        ↓
服务器从 GitHub 克隆代码
        ↓
Docker 构建 + 部署
        ↓
网站自动更新 ✅
```

### 核心优势

- ✅ **完全自动化**: 推送即部署
- ✅ **公网访问**: 服务器可访问 GitHub
- ✅ **无资源限制**: 构建在服务器上
- ✅ **易于调试**: GitHub Actions 日志清晰
- ✅ **免费使用**: 2000 分钟/月（免费版）

---

## 📋 快速开始（4 步）

### 前置要求

- ✅ GitHub 账号
- ✅ 外部服务器（可访问公网）
- ✅ 服务器已安装 Docker

---

### 步骤 1: 创建 GitHub 仓库（2 分钟）

#### 1.1 在 GitHub 上创建新仓库

访问: https://github.com/new

填写信息：
```
Repository name: e-2523-note  (或其他名称)
Description: My course notes built with MkDocs Material
Public 或 Private: 选择 Public（推荐）
不要初始化 README/gitignore/license
```

点击 **Create repository**

#### 1.2 记录仓库信息

创建后，GitHub 会显示仓库 URL，例如：
```
https://github.com/YOUR_USERNAME/e-2523-note.git
```

记下你的：
- **GitHub 用户名**: `YOUR_USERNAME`
- **仓库名称**: `e-2523-note`

---

### 步骤 2: 推送代码到 GitHub（3 分钟）

在本地项目目录：

```bash
# 进入项目目录
cd ~/tonycrane-note

# 添加 GitHub 远程仓库
git remote add github https://github.com/YOUR_USERNAME/e-2523-note.git

# 查看远程仓库
git remote -v

# 推送到 GitHub
git push github main

# 或者如果你的主分支是 master:
# git push github master
```

**提示**: 推送时可能需要 GitHub 认证：
- 使用 Personal Access Token（推荐）
- 或配置 SSH 密钥

---

### 步骤 3: 初始化服务器（5 分钟）

SSH 登录到你的**外部服务器**：

```bash
ssh your-username@your-server-ip

# 下载并运行初始化脚本
wget https://raw.githubusercontent.com/YOUR_USERNAME/e-2523-note/main/server-init.sh
chmod +x server-init.sh
./server-init.sh

# 重新登录
exit
ssh your-username@your-server-ip

# 验证 Docker
docker --version
docker ps
```

---

### 步骤 4: 配置 GitHub Secrets（5 分钟）

#### 4.1 生成 SSH 密钥（本地机器）

```bash
# 生成密钥
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions_key
# 按两次回车（不设密码）

# 添加公钥到服务器
ssh-copy-id -i ~/.ssh/github_actions_key.pub your-username@your-server-ip

# 测试连接
ssh -i ~/.ssh/github_actions_key your-username@your-server-ip "echo OK"

# 查看私钥（稍后用于 GitHub）
cat ~/.ssh/github_actions_key
```

#### 4.2 在 GitHub 中配置 Secrets

访问你的 GitHub 仓库：

```
https://github.com/YOUR_USERNAME/e-2523-note/settings/secrets/actions
```

点击 **New repository secret**，添加以下 **3 个 Secrets**:

##### Secret 1: SSH_PRIVATE_KEY 🔑

```
Name: SSH_PRIVATE_KEY
Value: (粘贴 ~/.ssh/github_actions_key 的完整内容)
```

**完整内容**包括：
```
-----BEGIN OPENSSH PRIVATE KEY-----
... (所有行) ...
-----END OPENSSH PRIVATE KEY-----
```

点击 **Add secret**

##### Secret 2: SERVER_HOST 🌐

```
Name: SERVER_HOST
Value: your-server-ip  (例如: 45.76.123.45)
```

点击 **Add secret**

##### Secret 3: SERVER_USER 👤

```
Name: SERVER_USER
Value: your-username  (服务器的 SSH 用户名)
```

点击 **Add secret**

#### 4.3 验证 Secrets

在 Secrets 页面，你应该看到 3 个 Secrets：
- ✅ `SSH_PRIVATE_KEY`
- ✅ `SERVER_HOST`
- ✅ `SERVER_USER`

---

### 🎉 完成！触发自动部署

现在推送代码即可自动部署：

```bash
# 做一个小修改
echo "# GitHub Actions Test" >> README.md
git add README.md
git commit -m "Test GitHub Actions deployment"
git push github main
```

---

## 📊 查看 GitHub Actions 执行

### 访问 Actions 页面

```
https://github.com/YOUR_USERNAME/e-2523-note/actions
```

你会看到：
- **Workflow 名称**: Deploy to Server
- **触发者**: 你的用户名
- **分支**: main
- **状态**: 🟡 In progress / 🟢 Success / 🔴 Failed

### 查看详细日志

点击 Workflow run → 点击 `Deploy to Remote Server` job

你会看到每个步骤的执行日志：

```
✓ Checkout code
✓ Display deployment info
✓ Setup SSH
✓ Test SSH connection
⏳ Deploy to server (5-10 分钟)
  → 进入部署目录
  → 下载部署脚本
  → 克隆代码
  → 构建 Docker 镜像
  → 启动容器
  → 清理资源
✓ Deployment complete
```

---

## 🎯 完整执行流程

### 时间线

| 步骤 | 耗时 | 说明 |
|------|------|------|
| 1. 代码推送 | 1 秒 | `git push` |
| 2. GitHub 检测 | 5 秒 | 触发 workflow |
| 3. Setup SSH | 10 秒 | 配置 SSH 连接 |
| 4. 测试连接 | 3 秒 | 验证 SSH |
| 5. 服务器部署 | 5-10 分钟 | 主要耗时 |
| 6. 完成 | 1 秒 | 显示结果 |
| **总计** | **6-11 分钟** | 首次较慢 |

### 后续更新

后续推送会更快（3-5 分钟），因为：
- ✅ Docker 层缓存
- ✅ Git 只拉取增量
- ✅ 依赖包已安装

---

## 🔧 GitHub Actions 配置详解

### Workflow 文件位置

```
.github/workflows/deploy.yml
```

### 触发条件

```yaml
on:
  push:
    branches:
      - main
      - master
  workflow_dispatch:  # 允许手动触发
```

### 手动触发部署

访问: `https://github.com/YOUR_USERNAME/e-2523-note/actions`

选择 **Deploy to Server** → 点击 **Run workflow** → 选择分支 → **Run workflow**

### 查看所有运行记录

所有部署历史都可以在 Actions 页面查看。

---

## 🐛 故障排除

### 问题 1: SSH 连接失败

**症状**:
```
Permission denied (publickey)
```

**解决**:

1. **检查 Secrets**:
   - GitHub → Settings → Secrets
   - 确保 `SSH_PRIVATE_KEY` 包含完整私钥

2. **验证公钥已添加到服务器**:
   ```bash
   ssh your-username@your-server-ip "cat ~/.ssh/authorized_keys"
   ```

3. **本地测试 SSH**:
   ```bash
   ssh -i ~/.ssh/github_actions_key your-username@your-server-ip "echo OK"
   ```

### 问题 2: 服务器无法克隆代码

**症状**:
```
fatal: unable to access 'https://github.com/...': Could not resolve host
```

**解决**:

1. **检查服务器网络**:
   ```bash
   ssh your-username@your-server-ip "ping github.com -c 3"
   ```

2. **测试 GitHub 访问**:
   ```bash
   ssh your-username@your-server-ip "curl -I https://github.com"
   ```

3. **如果是防火墙问题**:
   - 联系服务器管理员开放出站 HTTPS (443)

### 问题 3: Docker 构建失败

**解决**:

SSH 到服务器查看详细日志：

```bash
ssh your-username@your-server-ip
cd ~/mkdocs-deploy
cat /tmp/docker-build.log
```

常见原因：
- 内存不足
- 磁盘空间不足
- 插件安装失败

### 问题 4: GitHub Actions 超时

**症状**:
```
Error: The operation was canceled.
```

**原因**: 默认超时 6 小时，但可能网络慢导致超时

**解决**:

在 workflow 中增加超时时间：

```yaml
jobs:
  deploy:
    timeout-minutes: 60  # 增加到 60 分钟
```

### 问题 5: Secrets 未定义

**症状**:
```
SSH_PRIVATE_KEY: not found
```

**解决**:

确保 Secrets 名称完全一致：
- `SSH_PRIVATE_KEY` (不是 `SSH_KEY` 或其他)
- `SERVER_HOST`
- `SERVER_USER`

---

## 📝 日常使用

### 更新文档

```bash
# 1. 编辑文档
vim docs/your-page.md

# 2. 提交
git add docs/your-page.md
git commit -m "Update documentation"

# 3. 推送（自动触发部署）
git push github main

# 4. 等待 3-5 分钟
# 访问 GitHub Actions 查看进度
```

### 查看部署状态

**方法 1: GitHub 网页**
```
https://github.com/YOUR_USERNAME/e-2523-note/actions
```

**方法 2: GitHub CLI**
```bash
# 安装 GitHub CLI
brew install gh  # macOS
# 或访问 https://cli.github.com

# 登录
gh auth login

# 查看最新的 workflow 运行
gh run list --limit 5

# 查看特定运行的日志
gh run view <run-id> --log
```

**方法 3: SSH 到服务器**
```bash
ssh your-username@your-server-ip "docker ps | grep mkdocs-notes"
```

---

## 🔄 从 GitLab 迁移

### 保留两个远程仓库

你可以同时保留 GitLab（内网开发）和 GitHub（公网部署）:

```bash
# 查看当前远程仓库
git remote -v

# 应该看到:
# origin    git@git.koala-studio.org.cn:Koala-Inno-WMX/e-2523-note.git
# github    https://github.com/YOUR_USERNAME/e-2523-note.git

# 推送到两个仓库
git push origin main   # GitLab (内网)
git push github main   # GitHub (公网部署)
```

### 同时推送到两个仓库

创建别名：

```bash
# 添加到 ~/.gitconfig 或 ~/.zshrc
git config --global alias.pushall '!git push origin main && git push github main'

# 使用
git pushall
```

或创建脚本：

```bash
# ~/push-both.sh
#!/bin/bash
git push origin main
git push github main

chmod +x ~/push-both.sh
```

---

## 📊 GitHub vs GitLab 对比

| 特性 | GitHub Actions | GitLab CI |
|------|---------------|-----------|
| 配置位置 | `.github/workflows/` | `.gitlab-ci.yml` |
| 密钥存储 | Secrets | Variables |
| 免费额度 | 2000 分钟/月 | 400 分钟/月 |
| 公网访问 | ✅ 全球可达 | ❌ 内网受限 |
| 配置复杂度 | ⭐⭐⭐ | ⭐⭐⭐ |
| 日志查看 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 手动触发 | ✅ workflow_dispatch | ✅ 支持 |

---

## ✅ 成功检查清单

### 配置阶段

- [ ] GitHub 仓库已创建
- [ ] 代码已推送到 GitHub
- [ ] 服务器已初始化（Docker 已安装）
- [ ] SSH 密钥已生成
- [ ] 公钥已添加到服务器
- [ ] 3 个 Secrets 已配置

### 部署阶段

- [ ] GitHub Actions workflow 已触发
- [ ] SSH 连接测试成功
- [ ] 服务器端脚本执行成功
- [ ] Docker 镜像构建成功
- [ ] 容器启动成功

### 验证阶段

- [ ] Actions 显示绿色 ✓
- [ ] 网站可访问 `http://server-ip:8111`
- [ ] 容器正在运行 `docker ps`

---

## 🎉 部署成功

如果一切顺利，你现在拥有：

✅ **GitHub 公网仓库**: 可全球访问
✅ **自动化部署**: 推送即部署
✅ **服务器构建**: 无资源限制
✅ **详细日志**: GitHub Actions 清晰展示
✅ **稳定可靠**: 3-5 分钟自动完成

---

## 📚 相关文档

| 文档 | 用途 |
|------|------|
| [server-init.sh](server-init.sh) | 服务器初始化脚本 |
| [build-and-deploy-server.sh](build-and-deploy-server.sh) | 部署脚本 |
| [SERVER_DEPLOYMENT.md](SERVER_DEPLOYMENT.md) | 手动部署指南 |

---

## 📞 需要帮助？

1. **查看 GitHub Actions 日志**: 最详细的错误信息
2. **SSH 到服务器**: 查看服务器端日志
3. **检查 Secrets**: 确保配置正确
4. **参考故障排除**: 本文档的故障排除部分

---

## 🚀 下一步

**立即开始部署：**

1. ✅ 创建 GitHub 仓库
2. ✅ 推送代码
3. ✅ 初始化服务器
4. ✅ 配置 Secrets
5. ✅ 推送触发部署
6. ✅ 访问网站！

---

**GitHub 仓库**: https://github.com/YOUR_USERNAME/e-2523-note
**Actions 页面**: https://github.com/YOUR_USERNAME/e-2523-note/actions
**网站访问**: http://your-server-ip:8111

**最后更新**: 2025-11-16
