# 快速开始指南 - GitLab CI/CD 部署

> 快速参考 - 完整文档请查看 [GITLAB_CI_DEPLOYMENT_GUIDE.md](GITLAB_CI_DEPLOYMENT_GUIDE.md)

## 📋 3 步完成部署

### 步骤 1: 服务器初始化 (5 分钟)

```bash
# SSH 登录到服务器
ssh user@your-server-ip

# 下载并运行初始化脚本
wget https://your-gitlab-url/raw/main/server-init.sh
chmod +x server-init.sh
./server-init.sh

# 重新登录
exit
ssh user@your-server-ip
```

### 步骤 2: GitLab 配置 (3 分钟)

#### 2.1 生成 SSH 密钥

```bash
# 在本地机器上
ssh-keygen -t ed25519 -C "gitlab-ci" -f ~/.ssh/gitlab_deploy_key

# 添加公钥到服务器
ssh-copy-id -i ~/.ssh/gitlab_deploy_key.pub user@your-server-ip
```

#### 2.2 配置 GitLab CI/CD 变量

进入项目: **Settings → CI/CD → Variables → Add variable**

| 键名 | 值 | 保护 | 掩码 |
|------|-----|------|------|
| `SSH_PRIVATE_KEY` | `~/.ssh/gitlab_deploy_key` 内容 | ✓ | ✓ |
| `SERVER_HOST` | `your-server-ip` | ✓ | - |
| `SERVER_USER` | `username` | ✓ | - |
| `DEPLOY_PATH` | `/home/username/mkdocs-deploy` | ✓ | - |

### 步骤 3: 部署 (1 分钟)

```bash
# 推送代码
git add .
git commit -m "Setup CI/CD"
git push origin main
```

✅ **完成！** 访问 `http://your-server-ip:8111`

---

## 🔍 检查清单

### 服务器准备

- [ ] 服务器可通过 SSH 访问
- [ ] Docker 已安装: `docker --version`
- [ ] Docker Compose 已安装: `docker compose version`
- [ ] 端口 8111 已开放
- [ ] 部署目录已创建: `~/mkdocs-deploy`

### GitLab 配置

- [ ] SSH 密钥对已生成
- [ ] 公钥已添加到服务器 `~/.ssh/authorized_keys`
- [ ] GitLab CI/CD 变量已配置（4 个）
- [ ] GitLab Runner 可用（或使用共享 Runner）

### 项目文件

- [ ] `.gitlab-ci.yml` 存在
- [ ] `Dockerfile` 存在
- [ ] `docker-compose.yml` 存在
- [ ] `deploy-docker.sh` 存在并可执行
- [ ] `requirements.txt` 包含所有插件

---

## 🚀 常用命令

### 服务器端

```bash
# 查看容器状态
docker ps

# 查看日志
docker logs -f mkdocs-notes

# 重启容器
cd ~/mkdocs-deploy
docker-compose restart

# 手动部署
./deploy-docker.sh

# 清理旧镜像
docker image prune -f
```

### 本地开发

```bash
# 本地预览
mkdocs serve

# 本地构建测试
docker build -t test-mkdocs .
docker run -d -p 8111:80 --name test-mkdocs test-mkdocs

# 清理测试容器
docker stop test-mkdocs && docker rm test-mkdocs
```

---

## 🐛 快速故障排除

### CI/CD 失败

```bash
# 检查 GitLab CI 日志
# GitLab → CI/CD → Pipelines → 点击失败的 job

# 常见原因：
# 1. SSH_PRIVATE_KEY 格式错误
# 2. 服务器 SSH 连接失败
# 3. Docker 构建失败（插件缺失）
```

### 容器无法启动

```bash
# SSH 到服务器
ssh user@server-ip

# 查看容器状态
docker ps -a | grep mkdocs-notes

# 查看日志
docker logs mkdocs-notes

# 常见原因：
# 1. 端口 8111 被占用：netstat -tlnp | grep 8111
# 2. 镜像构建失败：docker images | grep mkdocs-notes
# 3. docker-compose.yml 配置错误
```

### 网站无法访问

```bash
# 检查容器是否运行
docker ps | grep mkdocs-notes

# 检查端口映射
docker port mkdocs-notes

# 测试本地访问
curl http://localhost:8111

# 检查防火墙
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-ports  # CentOS
```

---

## 📝 配置参考

### docker-compose.yml

```yaml
version: '3.8'
services:
  mkdocs-notes:
    build: .
    container_name: mkdocs-notes
    ports:
      - "8111:80"  # 宿主机端口:容器端口
    restart: unless-stopped
```

### .gitlab-ci.yml 关键配置

```yaml
variables:
  HOST_PORT: 8111        # 修改此处更改端口
  CONTAINER_PORT: 80
  IMAGE_NAME: mkdocs-notes
  CONTAINER_NAME: mkdocs-notes

tags:
  - docker  # 如果使用共享 Runner，删除此行
```

---

## 🔗 相关链接

- **完整部署指南**: [GITLAB_CI_DEPLOYMENT_GUIDE.md](GITLAB_CI_DEPLOYMENT_GUIDE.md)
- **1Panel 部署**: [1PANEL_DEPLOYMENT.md](1PANEL_DEPLOYMENT.md)
- **CI/CD 故障排除**: [CI_CD_TROUBLESHOOTING_CN.md](CI_CD_TROUBLESHOOTING_CN.md)
- **GitLab Runner 设置**: [GITLAB_RUNNER_SETUP_CN.md](GITLAB_RUNNER_SETUP_CN.md)

---

## ⏱️ 预计时间

| 步骤 | 时间 |
|------|------|
| 服务器初始化 | 5-10 分钟 |
| GitLab 配置 | 3-5 分钟 |
| 首次部署（CI/CD） | 5-8 分钟 |
| 后续更新部署 | 3-5 分钟 |

**总计**: 约 15-20 分钟完成首次部署

---

**提示**:
- 首次部署需下载 Docker 镜像，时间较长
- 后续更新只需推送代码即可自动部署
- 建议先在测试环境验证配置
