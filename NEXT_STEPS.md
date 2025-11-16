# 🚀 接下来的部署步骤

> 代码已成功推送到 GitLab！现在按照以下步骤完成自动化部署配置。

---

## 📍 当前状态

✅ **已完成**:
- [x] 项目代码已推送到 GitLab
- [x] GitLab CI/CD 配置文件已创建 (`.gitlab-ci.yml`)
- [x] Docker 配置文件已优化
- [x] 部署脚本已准备
- [x] 端口配置为 8111

🔄 **待完成**:
- [ ] 初始化远程服务器
- [ ] 配置 GitLab CI/CD 变量
- [ ] 触发首次部署

---

## 第一步: 初始化远程服务器 (10 分钟)

### 1.1 SSH 登录到服务器

```bash
ssh your-username@your-server-ip
```

> 将 `your-username` 和 `your-server-ip` 替换为实际值

### 1.2 下载并运行初始化脚本

```bash
# 从 GitLab 下载初始化脚本
wget https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/raw/main/server-init.sh

# 添加执行权限
chmod +x server-init.sh

# 运行脚本（会自动安装 Docker 和配置环境）
./server-init.sh
```

脚本会自动完成：
- ✓ 检测操作系统
- ✓ 安装 Docker 和 Docker Compose
- ✓ 配置用户权限
- ✓ 开放 8111 端口
- ✓ 创建部署目录 `~/mkdocs-deploy`

### 1.3 重新登录使权限生效

```bash
# 退出当前 SSH 会话
exit

# 重新登录
ssh your-username@your-server-ip

# 验证 Docker 安装
docker --version
docker compose version
```

应该看到类似输出：
```
Docker version 24.x.x
Docker Compose version v2.x.x
```

---

## 第二步: 配置 GitLab CI/CD 变量 (5 分钟)

### 2.1 生成 SSH 密钥对（本地机器）

打开**本地终端**（不是服务器），运行：

```bash
# 生成专用于 GitLab CI 的 SSH 密钥
ssh-keygen -t ed25519 -C "gitlab-ci-deployment" -f ~/.ssh/gitlab_ci_deploy

# 查看私钥（稍后用于 GitLab）
cat ~/.ssh/gitlab_ci_deploy

# 查看公钥（稍后用于服务器）
cat ~/.ssh/gitlab_ci_deploy.pub
```

### 2.2 添加公钥到服务器

**方法 1: 使用 ssh-copy-id (推荐)**

```bash
ssh-copy-id -i ~/.ssh/gitlab_ci_deploy.pub your-username@your-server-ip
```

**方法 2: 手动添加**

```bash
# SSH 登录到服务器
ssh your-username@your-server-ip

# 添加公钥
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "这里粘贴公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

### 2.3 在 GitLab 中配置 CI/CD 变量

1. 打开项目: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note

2. 进入: **Settings (设置)** → **CI/CD** → **Variables (变量)**

3. 点击 **Add variable (添加变量)**，依次添加以下 4 个变量：

#### 变量 1: SSH_PRIVATE_KEY

```
Key (键): SSH_PRIVATE_KEY
Value (值): (粘贴 ~/.ssh/gitlab_ci_deploy 的完整内容)
Type (类型): File
Protect variable (保护变量): ✓ 勾选
Mask variable (掩码变量): ✓ 勾选
```

> **重要**: 确保包含私钥的开头和结尾：
> ```
> -----BEGIN OPENSSH PRIVATE KEY-----
> ... (私钥内容) ...
> -----END OPENSSH PRIVATE KEY-----
> ```

#### 变量 2: SERVER_HOST

```
Key: SERVER_HOST
Value: your-server-ip  (例如: 192.168.1.100 或 server.example.com)
Type: Variable
Protect variable: ✓ 勾选
Mask variable: ✗ 不勾选
```

#### 变量 3: SERVER_USER

```
Key: SERVER_USER
Value: your-username  (服务器的 SSH 用户名)
Type: Variable
Protect variable: ✓ 勾选
Mask variable: ✗ 不勾选
```

#### 变量 4: DEPLOY_PATH

```
Key: DEPLOY_PATH
Value: /home/your-username/mkdocs-deploy
Type: Variable
Protect variable: ✓ 勾选
Mask variable: ✗ 不勾选
```

> **注意**: 将 `your-username` 替换为实际的服务器用户名

### 2.4 验证 SSH 连接

在本地测试 SSH 连接是否正常：

```bash
ssh -i ~/.ssh/gitlab_ci_deploy your-username@your-server-ip "echo 'SSH connection successful!'"
```

应该输出: `SSH connection successful!`

---

## 第三步: 触发部署 (5 分钟)

### 3.1 查看 CI/CD Pipeline

1. 打开项目: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note

2. 进入: **CI/CD** → **Pipelines**

3. 应该看到一个自动触发的 Pipeline（由刚才的 git push 触发）

如果没有看到 Pipeline，或者需要手动触发：

**选项 A: 通过界面触发**
- 点击 **Run pipeline**
- 选择分支 `main`
- 点击 **Run pipeline** 按钮

**选项 B: 通过代码推送触发**
```bash
# 进行一个小修改
echo "" >> README.md
git add README.md
git commit -m "Trigger CI/CD pipeline"
git push origin main
```

### 3.2 监控部署过程

在 Pipelines 页面，点击最新的 Pipeline，查看两个阶段：

**Stage 1: build_docker** (预计 3-5 分钟)
- 拉取代码
- 构建 Docker 镜像
- 安装 Python 依赖
- 验证插件
- 构建 MkDocs 站点
- 保存镜像为 tar 文件

**Stage 2: deploy_to_server** (预计 1-2 分钟)
- SSH 连接到服务器
- 传输 Docker 镜像
- 停止旧容器
- 启动新容器
- 清理旧镜像

### 3.3 查看部署日志

点击 `deploy_to_server` job，查看日志输出，应该看到：

```
Deploying to your-username@your-server-ip:/home/your-username/mkdocs-deploy
SSH connection successful
Loading Docker image...
Loaded image: mkdocs-notes:latest
Stopping old container...
Starting new container...
✓ 容器运行中
========================================
部署成功！
访问地址: http://your-server-ip:8111
========================================
Deployment completed!
```

---

## 第四步: 验证部署 (2 分钟)

### 4.1 检查容器状态

SSH 到服务器：

```bash
ssh your-username@your-server-ip

# 查看运行中的容器
docker ps

# 应该看到类似输出：
# CONTAINER ID   IMAGE                 STATUS         PORTS
# abc123def456   mkdocs-notes:latest  Up 2 minutes   0.0.0.0:8111->80/tcp
```

### 4.2 查看容器日志

```bash
# 查看日志
docker logs mkdocs-notes

# 实时查看日志
docker logs -f mkdocs-notes
```

### 4.3 访问网站

打开浏览器，访问：

```
http://your-server-ip:8111
```

应该看到你的 MkDocs 文档网站！

### 4.4 测试自动部署

修改文档内容：

```bash
# 在本地修改任意文档
echo "## 测试自动部署" >> docs/index.md

# 提交并推送
git add docs/index.md
git commit -m "Test auto deployment"
git push origin main
```

等待 GitLab CI/CD 完成（约 3-5 分钟），刷新网站查看更新。

---

## 🎉 完成！

恭喜！你已经成功配置了 GitLab CI/CD 自动部署。

### 现在你可以：

✅ **自动部署**: 每次推送到 `main` 分支，自动触发部署

✅ **访问网站**: http://your-server-ip:8111

✅ **查看日志**: GitLab → CI/CD → Pipelines

✅ **管理容器**: SSH 到服务器使用 Docker 命令

---

## 📋 常用命令参考

### 服务器端

```bash
# SSH 登录
ssh your-username@your-server-ip

# 查看容器状态
docker ps

# 查看日志
docker logs -f mkdocs-notes

# 重启容器
cd ~/mkdocs-deploy
docker-compose restart

# 停止容器
docker-compose down

# 启动容器
docker-compose up -d

# 手动重新部署
./deploy-docker.sh

# 清理旧镜像
docker image prune -f
```

### 本地开发

```bash
# 本地预览
mkdocs serve

# 本地测试构建
docker build -t test-mkdocs .
docker run -d -p 8111:80 test-mkdocs

# 推送更新
git add .
git commit -m "Update content"
git push origin main
```

---

## 🐛 遇到问题？

### CI/CD Pipeline 失败

1. **检查变量配置**
   - GitLab → Settings → CI/CD → Variables
   - 确保 4 个变量都已正确配置

2. **查看详细日志**
   - GitLab → CI/CD → Pipelines → 点击失败的 job
   - 查看具体错误信息

3. **常见错误**
   - `Permission denied (publickey)`: SSH 密钥配置错误
   - `Docker daemon not running`: 服务器 Docker 未启动
   - `Port 8111 already in use`: 端口被占用

### 容器无法启动

```bash
# SSH 到服务器
ssh your-username@your-server-ip

# 查看所有容器（包括停止的）
docker ps -a

# 查看容器日志
docker logs mkdocs-notes

# 检查端口占用
sudo netstat -tlnp | grep 8111

# 手动重新部署
cd ~/mkdocs-deploy
./deploy-docker.sh
```

### 网站无法访问

1. **检查容器是否运行**
   ```bash
   docker ps | grep mkdocs-notes
   ```

2. **检查防火墙**
   ```bash
   # Ubuntu/Debian
   sudo ufw status
   sudo ufw allow 8111/tcp

   # CentOS/Rocky
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --permanent --add-port=8111/tcp
   sudo firewall-cmd --reload
   ```

3. **测试本地访问**
   ```bash
   curl http://localhost:8111
   ```

---

## 📚 相关文档

- **完整部署指南**: [GITLAB_CI_DEPLOYMENT_GUIDE.md](GITLAB_CI_DEPLOYMENT_GUIDE.md)
- **快速参考**: [QUICK_START.md](QUICK_START.md)
- **1Panel 部署**: [1PANEL_DEPLOYMENT.md](1PANEL_DEPLOYMENT.md)
- **故障排除**: [CI_CD_TROUBLESHOOTING_CN.md](CI_CD_TROUBLESHOOTING_CN.md)

---

## 📞 需要帮助？

如果遇到问题：

1. ✓ 检查本文档的故障排除部分
2. ✓ 查看 GitLab CI/CD 日志
3. ✓ 查看容器日志: `docker logs mkdocs-notes`
4. ✓ 运行验证脚本: `python verify-plugins.py`
5. ✓ 查看完整部署指南: `GITLAB_CI_DEPLOYMENT_GUIDE.md`

---

**最后更新**: 2025-11-16
**项目地址**: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note
