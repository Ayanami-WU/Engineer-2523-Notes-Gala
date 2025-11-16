# 🚀 服务器端直接部署指南

> 推荐方案：直接在服务器上 Git 拉取 + Docker 构建 + 部署

这种方式避免了 GitLab Runner 的限制，更容易调试，适合首次部署。

---

## 为什么选择服务器端构建？

### ✅ 优点

- **无 Runner 限制**: 不受 GitLab Runner 资源限制
- **易于调试**: 可以直接查看完整的构建日志
- **更快速**: 在服务器本地构建，无需传输大型镜像
- **更灵活**: 可以随时手动触发部署

### ⚠️ 缺点

- 需要手动触发（或设置 cron）
- 需要在服务器上配置 Git 访问

---

## 📋 快速开始（3 步完成）

### 第 1 步: 初始化服务器

SSH 登录到服务器：

```bash
ssh your-username@your-server-ip
```

下载并运行初始化脚本：

```bash
# 下载初始化脚本
wget https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/raw/main/server-init.sh

# 运行初始化
chmod +x server-init.sh
./server-init.sh

# 重新登录使权限生效
exit
ssh your-username@your-server-ip
```

### 第 2 步: 下载部署脚本

```bash
# 创建部署目录
mkdir -p ~/mkdocs-deploy
cd ~/mkdocs-deploy

# 下载部署脚本
wget https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/raw/main/build-and-deploy-server.sh

# 添加执行权限
chmod +x build-and-deploy-server.sh
```

### 第 3 步: 运行部署

```bash
# 执行部署脚本
./build-and-deploy-server.sh
```

脚本会自动完成：
- ✅ 克隆/更新代码
- ✅ 构建 Docker 镜像
- ✅ 停止旧容器
- ✅ 启动新容器
- ✅ 验证部署状态

---

## 📝 部署脚本功能详解

### `build-and-deploy-server.sh` 做什么？

#### 1. 检查环境
```
✓ 检查 Docker 是否安装
✓ 检查 Git 是否安装
✓ 创建必要的目录
```

#### 2. 同步代码
```
如果首次运行:
  → 克隆仓库到 ~/mkdocs-deploy/source

如果已存在:
  → 拉取最新代码 (git pull)
  → 重置到最新版本
```

#### 3. 构建镜像
```
→ 停止并删除旧容器
→ 使用 Dockerfile 构建新镜像
→ 显示构建过程
```

#### 4. 部署容器
```
→ 启动新容器
→ 端口映射: 8111 → 80
→ 自动重启策略: unless-stopped
```

#### 5. 验证和清理
```
→ 检查容器状态
→ 显示访问地址
→ 清理旧镜像
→ 显示最近日志
```

---

## 🔧 常用操作

### 首次部署

```bash
ssh your-username@your-server-ip
cd ~/mkdocs-deploy
./build-and-deploy-server.sh
```

**预计时间**: 5-10 分钟（包括下载和构建）

### 更新部署

```bash
ssh your-username@your-server-ip
cd ~/mkdocs-deploy
./build-and-deploy-server.sh
```

**预计时间**: 3-5 分钟

### 查看容器状态

```bash
# 查看运行中的容器
docker ps

# 查看容器日志
docker logs mkdocs-notes

# 实时查看日志
docker logs -f mkdocs-notes
```

### 重启容器

```bash
docker restart mkdocs-notes
```

### 停止容器

```bash
docker stop mkdocs-notes
docker rm mkdocs-notes
```

### 完全重新部署

```bash
# 删除所有相关资源
docker stop mkdocs-notes
docker rm mkdocs-notes
docker rmi mkdocs-notes:latest
rm -rf ~/mkdocs-deploy/source

# 重新运行部署脚本
cd ~/mkdocs-deploy
./build-and-deploy-server.sh
```

---

## 🐛 故障排除

### 问题 1: Git 克隆失败

**错误**:
```
fatal: unable to access 'https://git.koala-studio.org.cn/...': Could not resolve host
```

**解决方法**:

**选项 A**: 检查网络连接
```bash
ping git.koala-studio.org.cn
```

**选项 B**: 使用 SSH 克隆（如果配置了 SSH 密钥）

编辑脚本 `build-and-deploy-server.sh`，修改：
```bash
# 修改前
REPO_URL="https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note.git"

# 修改后
REPO_URL="git@git.koala-studio.org.cn:Koala-Inno-WMX/e-2523-note.git"
```

**选项 C**: 手动克隆
```bash
cd ~/mkdocs-deploy
git clone https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note.git source
```

### 问题 2: Docker 构建失败

**错误**:
```
ERROR: failed to solve: process ... did not complete successfully
```

**解决方法**:

1. **查看完整构建日志**:
```bash
cat /tmp/docker-build.log
```

2. **手动调试构建**:
```bash
cd ~/mkdocs-deploy/source

# 尝试手动构建
docker build -t test-mkdocs .

# 如果失败，查看具体错误
```

3. **常见原因**:
   - ✗ 插件安装失败 → 检查 requirements.txt
   - ✗ mkdocs.yml 配置错误 → 检查配置文件
   - ✗ 文档语法错误 → 检查 docs/ 目录

4. **临时禁用问题插件**:

编辑 `mkdocs.yml`，注释掉导致问题的插件：
```yaml
plugins:
  - search
  # - glightbox  # 临时禁用
  # - rss        # 临时禁用
```

### 问题 3: 容器启动后立即退出

**检查**:
```bash
# 查看容器状态
docker ps -a | grep mkdocs

# 查看退出原因
docker logs mkdocs-notes
```

**可能原因**:
- Nginx 配置错误
- 端口冲突
- 文件权限问题

### 问题 4: 端口 8111 被占用

**错误**:
```
bind: address already in use
```

**解决方法**:

**选项 A**: 停止占用端口的进程
```bash
# 查找占用端口的进程
sudo netstat -tlnp | grep 8111
# 或
sudo lsof -i :8111

# 停止进程
sudo kill -9 <PID>
```

**选项 B**: 修改端口

编辑 `docker-compose.yml`:
```yaml
ports:
  - "8112:80"  # 改为 8112 或其他端口
```

或编辑脚本中的 `HOST_PORT` 变量。

### 问题 5: 网站无法访问

**检查清单**:

1. **容器是否运行**:
```bash
docker ps | grep mkdocs-notes
```

2. **端口是否正确映射**:
```bash
docker port mkdocs-notes
# 应显示: 80/tcp -> 0.0.0.0:8111
```

3. **防火墙是否开放**:
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 8111/tcp

# CentOS/Rocky
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --add-port=8111/tcp
sudo firewall-cmd --reload
```

4. **本地测试**:
```bash
curl http://localhost:8111
# 应返回 HTML 内容
```

5. **Nginx 日志**:
```bash
docker exec -it mkdocs-notes cat /var/log/nginx/error.log
```

---

## 🔄 自动化部署（可选）

### 方法 1: 使用 Cron 定时更新

每天凌晨 2 点自动更新：

```bash
# 编辑 crontab
crontab -e

# 添加以下行
0 2 * * * cd ~/mkdocs-deploy && ./build-and-deploy-server.sh >> ~/mkdocs-deploy/deploy.log 2>&1
```

### 方法 2: 使用 Git Hooks

在代码推送后自动部署：

1. **在 GitLab 项目中设置 Webhook**:
   - Settings → Webhooks
   - URL: `http://your-server-ip:9000/hooks/deploy`
   - 触发器: Push events

2. **在服务器上设置 Webhook 接收器**:

使用 `webhook` 工具或自定义脚本监听并触发部署。

### 方法 3: 使用简化的 GitLab CI

创建一个简单的 CI，只负责 SSH 到服务器触发脚本：

```yaml
# .gitlab-ci-simple.yml
deploy:
  stage: deploy
  image: alpine:latest
  script:
    - apk add --no-cache openssh-client
    - mkdir -p ~/.ssh
    - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_HOST \
        "cd ~/mkdocs-deploy && ./build-and-deploy-server.sh"
  only:
    - main
```

---

## 📊 部署日志

### 查看部署脚本日志

```bash
# 查看最近的部署日志（如果使用 cron）
tail -50 ~/mkdocs-deploy/deploy.log

# 实时查看部署过程
tail -f ~/mkdocs-deploy/deploy.log
```

### 查看容器日志

```bash
# 最近 50 行
docker logs --tail 50 mkdocs-notes

# 实时日志
docker logs -f mkdocs-notes

# 带时间戳
docker logs -t mkdocs-notes
```

### 查看 Nginx 访问日志

```bash
docker exec -it mkdocs-notes cat /var/log/nginx/access.log
```

---

## 🎯 完整操作流程示例

### 场景: 首次在服务器上部署

```bash
# 1. SSH 登录
ssh user@server-ip

# 2. 运行初始化脚本（如果未运行）
wget https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/raw/main/server-init.sh
chmod +x server-init.sh
./server-init.sh

# 3. 重新登录
exit
ssh user@server-ip

# 4. 下载部署脚本
mkdir -p ~/mkdocs-deploy
cd ~/mkdocs-deploy
wget https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/raw/main/build-and-deploy-server.sh
chmod +x build-and-deploy-server.sh

# 5. 首次部署
./build-and-deploy-server.sh

# 6. 等待构建完成（5-10 分钟）

# 7. 访问网站
# http://server-ip:8111
```

### 场景: 代码更新后重新部署

```bash
# 1. SSH 登录
ssh user@server-ip

# 2. 进入部署目录
cd ~/mkdocs-deploy

# 3. 运行部署脚本（会自动拉取最新代码）
./build-and-deploy-server.sh

# 4. 等待完成（3-5 分钟）
```

### 场景: 调试构建问题

```bash
# 1. SSH 登录
ssh user@server-ip

# 2. 进入项目目录
cd ~/mkdocs-deploy/source

# 3. 查看当前代码版本
git log -1 --oneline

# 4. 手动构建查看详细错误
docker build -t test-mkdocs .

# 5. 如果构建成功，手动运行
docker run -d -p 8111:80 --name test-mkdocs test-mkdocs

# 6. 查看日志
docker logs test-mkdocs

# 7. 清理测试容器
docker stop test-mkdocs
docker rm test-mkdocs
docker rmi test-mkdocs
```

---

## 📚 相关文档

- **服务器初始化**: [server-init.sh](server-init.sh)
- **项目状态**: [STATUS.md](STATUS.md)
- **快速开始**: [QUICK_START.md](QUICK_START.md)
- **完整 CI/CD 指南**: [GITLAB_CI_DEPLOYMENT_GUIDE.md](GITLAB_CI_DEPLOYMENT_GUIDE.md)

---

## ✅ 优势总结

| 方案 | 优点 | 缺点 |
|------|------|------|
| **服务器端构建** | ✅ 无 Runner 限制<br>✅ 易于调试<br>✅ 构建快速 | ⚠️ 需手动触发<br>⚠️ 需服务器访问 Git |
| **GitLab CI 构建** | ✅ 完全自动化<br>✅ Git 驱动 | ⚠️ Runner 限制<br>⚠️ 调试困难 |

**推荐**: 首次部署使用**服务器端构建**，稳定后可选择性配置 GitLab CI。

---

**下一步**: 在服务器上运行 `./build-and-deploy-server.sh` 开始部署！
