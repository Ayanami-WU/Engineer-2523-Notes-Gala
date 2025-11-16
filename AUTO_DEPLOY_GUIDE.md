# 🤖 GitLab CI 自动化部署指南

> **最佳方案**：GitLab CI 触发 + 服务器端构建
>
> 结合两种方案的优势：自动化部署 + 避免 Runner 限制

---

## 💡 方案原理

### 工作流程

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│   开发者    │─push→ │   GitLab     │─SSH──→│  远程服务器 │
│  git push   │       │   CI/CD      │       │             │
└─────────────┘       └──────────────┘       └─────────────┘
                             ↓                       ↓
                      只需配置 SSH            在服务器上构建
                      轻量级任务              完整资源可用
```

### 执行步骤

1. **本地**: 推送代码到 GitLab (`git push`)
2. **GitLab CI**: 检测到 push，启动 Pipeline
3. **SSH 连接**: GitLab Runner 通过 SSH 连接到服务器
4. **服务器执行**:
   - 拉取最新代码 (git clone/pull)
   - 构建 Docker 镜像
   - 部署容器
5. **完成**: 网站自动更新

### 优势对比

| 特性 | 本方案 | 纯 GitLab CI | 纯手动部署 |
|------|--------|-------------|----------|
| 自动化 | ✅ 完全自动 | ✅ 完全自动 | ❌ 需手动 |
| 构建资源 | ✅ 服务器资源 | ❌ Runner 限制 | ✅ 服务器资源 |
| 易调试 | ✅ 容易 | ❌ 困难 | ✅ 容易 |
| 配置复杂度 | ⭐⭐ 简单 | ⭐⭐⭐⭐ 复杂 | ⭐ 最简单 |

---

## 🚀 快速开始（3 步配置）

### 前置要求

- ✅ 服务器可通过 SSH 访问
- ✅ 服务器已安装 Docker（运行 `server-init.sh`）
- ✅ GitLab 项目访问权限

---

### 步骤 1: 初始化服务器（5 分钟）

如果还没初始化，SSH 登录到服务器：

```bash
ssh your-username@your-server-ip

# 下载并运行初始化脚本
wget https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/raw/main/server-init.sh
chmod +x server-init.sh
./server-init.sh

# 重新登录使权限生效
exit
ssh your-username@your-server-ip

# 验证 Docker 安装
docker --version
```

---

### 步骤 2: 配置 GitLab CI/CD 变量（3 分钟）

#### 2.1 生成 SSH 密钥（本地机器）

```bash
# 生成专用于 GitLab CI 的 SSH 密钥
ssh-keygen -t ed25519 -C "gitlab-ci-auto-deploy" -f ~/.ssh/gitlab_ci_key

# 不设置密码，直接按回车
```

#### 2.2 添加公钥到服务器

```bash
# 方法 1: 使用 ssh-copy-id（推荐）
ssh-copy-id -i ~/.ssh/gitlab_ci_key.pub your-username@your-server-ip

# 方法 2: 手动添加
cat ~/.ssh/gitlab_ci_key.pub
# 复制输出，然后在服务器上：
# echo "粘贴的公钥内容" >> ~/.ssh/authorized_keys
```

#### 2.3 测试 SSH 连接

```bash
# 测试密钥是否工作
ssh -i ~/.ssh/gitlab_ci_key your-username@your-server-ip "echo 'SSH works!'"

# 应该输出: SSH works!
```

#### 2.4 在 GitLab 中配置变量

**访问**: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/settings/ci_cd

点击 **Variables** → **Expand** → **Add variable**

添加以下 **3 个变量**：

##### 变量 1: SSH_PRIVATE_KEY 🔑

```
Key: SSH_PRIVATE_KEY
Value: (粘贴私钥完整内容)
Type: File
Protected: ✓ 勾选
Masked: ✓ 勾选
```

**获取私钥内容**:
```bash
cat ~/.ssh/gitlab_ci_key
```

**复制完整内容**，包括：
```
-----BEGIN OPENSSH PRIVATE KEY-----
... (所有内容) ...
-----END OPENSSH PRIVATE KEY-----
```

##### 变量 2: SERVER_HOST 🌐

```
Key: SERVER_HOST
Value: your-server-ip  (例如: 192.168.1.100)
Type: Variable
Protected: ✓ 勾选
Masked: ✗ 不勾选
```

##### 变量 3: SERVER_USER 👤

```
Key: SERVER_USER
Value: your-username  (服务器的 SSH 用户名)
Type: Variable
Protected: ✓ 勾选
Masked: ✗ 不勾选
```

**不需要 DEPLOY_PATH** - 脚本使用默认路径 `~/mkdocs-deploy`

---

### 步骤 3: 触发自动部署（自动）

配置完成后，推送代码即可自动部署：

```bash
# 方法 1: 推送现有代码
git push origin main

# 方法 2: 做一个小修改触发
echo "" >> README.md
git add README.md
git commit -m "Trigger auto deployment"
git push origin main
```

**查看 Pipeline**: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/pipelines

---

## 📊 Pipeline 执行过程

### 完整流程演示

访问 Pipelines 页面后，点击最新的 Pipeline，你会看到：

#### 阶段: deploy_to_server

**预期执行时间**: 5-10 分钟（首次）/ 3-5 分钟（后续）

**执行步骤**:

```
1. Preparing environment (1 秒)
   → 拉取 alpine 镜像
   → 设置环境变量

2. Installing SSH client (5 秒)
   → apk add openssh-client bash

3. Setting up SSH keys (2 秒)
   → 配置 SSH 密钥
   → 添加服务器到 known_hosts

4. Testing SSH connection (3 秒)
   → 验证 SSH 连接
   → 输出: "SSH connection successful!"

5. Executing deployment on server (5-10 分钟)
   → 进入部署目录
   → 检查/下载部署脚本
   → 克隆/更新代码
   → 构建 Docker 镜像  ← 最耗时
   → 停止旧容器
   → 启动新容器
   → 清理资源

6. Job succeeded (1 秒)
   → 输出访问地址
   → Pipeline 完成 ✅
```

### 成功的标志

✅ **Pipeline 成功**:
```
✓ 部署成功完成
访问地址: http://your-server-ip:8111
Job succeeded
```

✅ **网站可访问**: `http://your-server-ip:8111`

---

## 📝 日志解读

### 正常的部署日志

<details>
<summary>点击展开完整日志示例</summary>

```
Running with gitlab-runner 16.x.x
  on runner-xxx

Preparing the "docker" executor
  Using Docker executor with image alpine:latest ...
  Pulling docker image alpine:latest ...

Preparing environment
  Running on runner-xxx...

Getting source from Git repository
  Fetching changes...
  Initialized empty Git repository
  Created fresh repository.

Installing SSH client
  + apk add --no-cache openssh-client bash
  OK: 9 MiB in 23 packages

Setting up SSH keys
  + mkdir -p ~/.ssh
  + chmod 700 ~/.ssh
  + echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
  + chmod 600 ~/.ssh/id_rsa
  + ssh-keyscan -H 192.168.1.100 >> ~/.ssh/known_hosts
  # 192.168.1.100:22 SSH-2.0-OpenSSH_8.x

Testing SSH connection
  + ssh -o StrictHostKeyChecking=no user@192.168.1.100 "echo 'SSH connection successful!'"
  SSH connection successful!

==========================================
GitLab CI - 服务器端自动化部署
Commit: abc123de
Branch: main
Author: Your Name
Message: Trigger auto deployment
==========================================

→ 进入部署目录...
✓ 部署脚本已存在

==========================================
开始执行服务器端构建和部署...
==========================================

[INFO] 检查 Docker 环境...
[INFO] Docker 版本: Docker version 24.x.x

[INFO] 检查 Git...
[INFO] Git 版本: git version 2.x.x

[STEP] 同步代码...
[INFO] 更新现有仓库...
[INFO] 代码已更新到最新版本
[INFO] 当前提交: abc123de Trigger auto deployment

[STEP] 停止旧容器...
[INFO] 旧容器已停止并删除

[STEP] 构建 Docker 镜像...
[INFO] 开始构建（这可能需要几分钟）...

Step 1/8 : FROM squidfunk/mkdocs-material:9.7.0 AS builder
 ---> abc123def456
Step 2/8 : WORKDIR /docs
 ---> Using cache
 ---> def456abc789
Step 3/8 : COPY requirements.txt .
 ---> Using cache
 ---> 789abc123def
Step 4/8 : RUN pip install --no-cache-dir -r requirements.txt
 ---> Running in abc123...
Collecting mkdocs-glightbox
  Downloading mkdocs_glightbox-0.4.0...
...
Successfully installed mkdocs-glightbox-0.4.0 ...
 ---> abc789def123
Step 5/8 : COPY . .
 ---> 123def456abc
Step 6/8 : RUN mkdocs build --verbose
 ---> Running in def789abc456
INFO - Building documentation...
INFO - Cleaning site directory
INFO - Documentation built in 2.34 seconds
 ---> 456abc789def
Step 7/8 : FROM nginx:alpine
 ---> 789def123abc
Step 8/8 : COPY --from=builder /docs/site /usr/share/nginx/html
 ---> def123456789
Successfully built def123456789
Successfully tagged mkdocs-notes:latest

[INFO] ✓ Docker 镜像构建成功

[STEP] 启动新容器...
[INFO] 容器已通过 docker-compose 启动

[STEP] 检查容器状态...
[INFO] ✓ 容器运行中

abc123def456   mkdocs-notes:latest   Up 2 seconds   0.0.0.0:8111->80/tcp   mkdocs-notes

[INFO] ==========================================
[INFO] 部署成功！
[INFO]
[INFO] 访问地址:
[INFO]   - http://localhost:8111
[INFO]   - http://192.168.1.100:8111
[INFO] ==========================================

==========================================
GitLab CI 部署任务完成！
==========================================

✓ 部署成功完成
访问地址: http://192.168.1.100:8111

Job succeeded
```

</details>

---

## 🔧 故障排除

### 问题 1: SSH 连接失败

**症状**:
```
Permission denied (publickey)
或
ssh: connect to host xxx port 22: Connection refused
```

**解决方法**:

1. **检查变量配置**:
   - GitLab → Settings → CI/CD → Variables
   - 确保 `SSH_PRIVATE_KEY`、`SERVER_HOST`、`SERVER_USER` 都已配置

2. **验证私钥格式**:
   ```bash
   # 私钥必须包含完整内容
   cat ~/.ssh/gitlab_ci_key
   # 应该以 -----BEGIN OPENSSH PRIVATE KEY----- 开头
   ```

3. **检查公钥是否添加到服务器**:
   ```bash
   ssh your-username@your-server-ip "cat ~/.ssh/authorized_keys"
   # 应该看到你的公钥
   ```

4. **手动测试 SSH**:
   ```bash
   ssh -i ~/.ssh/gitlab_ci_key your-username@your-server-ip "echo OK"
   ```

### 问题 2: 服务器端构建失败

**症状**:
```
ERROR: failed to solve: process ... did not complete successfully
```

**解决方法**:

1. **SSH 到服务器查看详细日志**:
   ```bash
   ssh your-username@your-server-ip
   cat /tmp/docker-build.log
   ```

2. **手动运行部署脚本**:
   ```bash
   cd ~/mkdocs-deploy
   ./build-and-deploy-server.sh
   ```

3. **检查常见问题**:
   - Docker 是否运行: `docker ps`
   - Git 是否安装: `git --version`
   - 磁盘空间: `df -h`
   - 内存: `free -h`

### 问题 3: Pipeline 卡住不动

**症状**:
Pipeline 显示 "pending" 或长时间无响应

**解决方法**:

1. **检查 Runner 状态**:
   - GitLab → Settings → CI/CD → Runners
   - 确保有可用的 Runner

2. **取消并重新运行**:
   - Pipelines → 点击 Pipeline
   - 点击 "Cancel"
   - 点击 "Retry"

3. **检查 tags**:
   如果配置了 `tags: docker`，但没有对应的 Runner，需要注释掉

### 问题 4: 变量未定义

**症状**:
```
$SERVER_HOST: unbound variable
```

**解决方法**:

确保在 GitLab 中配置了所有 3 个变量：
- `SSH_PRIVATE_KEY`
- `SERVER_HOST`
- `SERVER_USER`

并且变量的 **Protected** 选项要勾选（因为 main 是保护分支）

### 问题 5: 容器无法启动

**解决方法**:

SSH 到服务器查看：

```bash
# 查看容器状态
docker ps -a | grep mkdocs

# 查看容器日志
docker logs mkdocs-notes

# 检查端口占用
sudo netstat -tlnp | grep 8111

# 手动重启
cd ~/mkdocs-deploy
docker-compose restart
```

---

## 🎯 使用场景

### 场景 1: 日常更新文档

```bash
# 1. 编辑文档
vim docs/your-page.md

# 2. 提交更改
git add docs/your-page.md
git commit -m "Update documentation"

# 3. 推送（自动触发部署）
git push origin main

# 4. 等待 3-5 分钟，网站自动更新
```

### 场景 2: 修复 bug

```bash
# 1. 创建修复分支
git checkout -b fix/typo

# 2. 修复问题
vim docs/some-file.md
git add docs/some-file.md
git commit -m "Fix typo in documentation"

# 3. 合并到 main（触发部署）
git checkout main
git merge fix/typo
git push origin main
```

### 场景 3: 回滚到之前版本

```bash
# 1. 查看提交历史
git log --oneline

# 2. 回滚到指定提交
git revert <commit-hash>

# 3. 推送（自动部署旧版本）
git push origin main
```

---

## 📊 性能和成本

### 执行时间

| 操作 | 首次 | 后续 |
|------|------|------|
| SSH 连接 | 5 秒 | 3 秒 |
| Git 克隆/拉取 | 30 秒 | 5 秒 |
| Docker 构建 | 5-8 分钟 | 2-3 分钟（缓存） |
| 容器启动 | 10 秒 | 5 秒 |
| **总计** | **6-10 分钟** | **3-5 分钟** |

### GitLab CI 分钟数消耗

- 每次部署消耗: **1-2 分钟**（仅 SSH 连接和触发）
- GitLab Free 限额: **400 分钟/月**
- 可部署次数: **~200 次/月**

💡 **节省方案**: 构建在服务器上进行，不消耗 Runner 资源！

---

## 📚 扩展配置

### 添加构建通知

在 GitLab 中配置通知：

**Settings → Integrations**

可以添加：
- Slack 通知
- Email 通知
- Webhook 通知

### 添加多环境部署

修改 `.gitlab-ci.yml` 支持多环境：

```yaml
# 开发环境
deploy_dev:
  stage: deploy
  variables:
    SERVER_HOST: $DEV_SERVER_HOST
  only:
    - develop

# 生产环境
deploy_prod:
  stage: deploy
  variables:
    SERVER_HOST: $PROD_SERVER_HOST
  only:
    - main
  when: manual  # 需要手动确认
```

### 添加部署前检查

```yaml
validate:
  stage: test
  script:
    - echo "Running validation..."
    # 添加你的检查脚本
  only:
    - main
```

---

## ✅ 检查清单

完成以下步骤确保配置正确：

### 服务器端

- [ ] Docker 已安装并运行
- [ ] Git 已安装
- [ ] SSH 公钥已添加到 `~/.ssh/authorized_keys`
- [ ] 端口 8111 已开放
- [ ] 防火墙允许 SSH (22) 和 HTTP (8111)

### GitLab 端

- [ ] CI/CD 变量已配置（3 个）
- [ ] `SSH_PRIVATE_KEY` 格式正确
- [ ] `SERVER_HOST` 和 `SERVER_USER` 正确
- [ ] 变量的 Protected 选项已勾选

### 本地测试

- [ ] SSH 密钥可以连接到服务器
- [ ] 代码已推送到 GitLab
- [ ] Pipeline 触发成功

### 验证部署

- [ ] Pipeline 显示绿色 ✅
- [ ] 网站可以访问 `http://server-ip:8111`
- [ ] 容器正在运行 `docker ps`

---

## 🎉 成功！

如果一切正常，你现在拥有：

- ✅ **自动化部署**: 推送代码即可自动更新网站
- ✅ **稳定构建**: 在服务器上构建，资源充足
- ✅ **易于调试**: SSH 登录即可查看详细日志
- ✅ **完整日志**: GitLab 和服务器双重日志记录

**下次更新文档**，只需：

```bash
git add .
git commit -m "Update docs"
git push origin main
```

等待 3-5 分钟，网站自动更新！🚀

---

## 📖 相关文档

- **服务器初始化**: [server-init.sh](server-init.sh)
- **部署脚本**: [build-and-deploy-server.sh](build-and-deploy-server.sh)
- **服务器端部署**: [SERVER_DEPLOYMENT.md](SERVER_DEPLOYMENT.md)
- **项目状态**: [STATUS.md](STATUS.md)

---

**最后更新**: 2025-11-16
**版本**: 1.0.0
