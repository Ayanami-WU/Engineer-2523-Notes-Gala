# 浙大 GitLab CI/CD 自动部署指南

本指南将帮助你配置从浙大 GitLab (git.zju.edu.cn) 到香港服务器的自动部署，使用 SSH 密钥链认证。

## 概述

当你通过 SSH 推送代码到浙大 GitLab 的 `master` 或 `main` 分支时：
1. 浙大 GitLab CI 自动构建你的 MkDocs 网站
2. 构建的网站通过 SSH 密钥链自动部署到香港服务器
3. 服务器在 8111 端口提供网站访问

## 前置要求

- 浙大 GitLab (git.zju.edu.cn) 账号
- 已配置 SSH 密钥用于 git push 到浙大 GitLab
- 有 SSH 访问权限的香港服务器
- 服务器上已安装 Docker

---

## 详细配置步骤

### 步骤 1：配置浙大 GitLab 的 SSH 访问

如果你还没有为浙大 GitLab 配置 SSH 密钥：

1. **生成 SSH 密钥对**（在本地机器上）：
```bash
ssh-keygen -t rsa -b 4096 -C "你的浙大邮箱@zju.edu.cn"
# 保存到默认位置： ~/.ssh/id_rsa
```

2. **添加公钥到浙大 GitLab**：
```bash
# 显示你的公钥
cat ~/.ssh/id_rsa.pub
```

前往浙大 GitLab：**设置 → SSH 密钥**，添加公钥。

3. **测试 SSH 连接**：
```bash
ssh -T git@git.zju.edu.cn
```

如果看到欢迎信息，说明配置成功！

### 步骤 2：准备香港服务器

#### 方案 A：使用 Docker（推荐）

1. **安装 Docker 和 Docker Compose**：
```bash
# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo apt install docker-compose -y

# 将用户添加到 docker 组
sudo usermod -aG docker $USER
# 注销并重新登录以使组权限生效
```

2. **创建部署目录**：
```bash
mkdir -p ~/mkdocs-notes
cd ~/mkdocs-notes
```

3. **配置防火墙允许 8111 端口**：
```bash
sudo ufw allow 8111/tcp
sudo ufw status
```

#### 方案 B：使用 Nginx（静态文件）

1. **安装 nginx 和 rsync**：
```bash
sudo apt update
sudo apt install nginx rsync -y
```

2. **创建部署目录**：
```bash
sudo mkdir -p /var/www/mkdocs-notes
sudo chown $USER:$USER /var/www/mkdocs-notes
```

3. **配置 nginx**（`/etc/nginx/sites-available/mkdocs-notes`）：
```nginx
server {
    listen 8111;
    server_name 你的服务器IP;  # 或域名

    root /var/www/mkdocs-notes;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # 启用 gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript
               application/x-javascript application/xml+rss
               application/javascript application/json;
}
```

4. **启用网站配置**：
```bash
sudo ln -s /etc/nginx/sites-available/mkdocs-notes /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

5. **配置防火墙**：
```bash
sudo ufw allow 8111/tcp
sudo ufw status
```

### 步骤 3：配置 SSH 密钥链认证

**在香港服务器上操作**：

1. **为 GitLab CI 生成专用 SSH 密钥**：
```bash
# 为 GitLab CI/CD 生成新的密钥对
ssh-keygen -t rsa -b 4096 -C "gitlab-ci-deploy" -f ~/.ssh/gitlab-ci
```

2. **将公钥添加到 authorized_keys**：
```bash
cat ~/.ssh/gitlab-ci.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

3. **显示私钥**（你需要将其添加到 GitLab）：
```bash
cat ~/.ssh/gitlab-ci
```

**重要**：复制完整的私钥内容，包括 `-----BEGIN/END RSA PRIVATE KEY-----` 行。

4. **测试 SSH 连接**（从本地机器）：
```bash
ssh -i ~/.ssh/gitlab-ci $USER@你的服务器IP
```

### 步骤 4：配置浙大 GitLab CI/CD 变量

前往你的浙大 GitLab 项目：**设置 → CI/CD → 变量**

添加以下变量（全部标记为**受保护**和**已屏蔽**）：

| 变量名 | 类型 | 值 | 示例 | 说明 |
|--------|------|-----|------|------|
| `SSH_PRIVATE_KEY` | 文件 | 私钥内容 | `-----BEGIN RSA...` | 步骤 3 中的私钥 |
| `SERVER_HOST` | 变量 | 服务器 IP 或域名 | `123.45.67.89` | 香港服务器地址 |
| `SERVER_USER` | 变量 | SSH 用户名 | `ubuntu` 或 `你的用户名` | 服务器 SSH 用户 |
| `DEPLOY_PATH` | 变量 | 部署路径 | `/var/www/mkdocs-notes` (nginx) 或 `~/mkdocs-notes` (docker) | 部署目标目录 |

**如何添加变量**：
1. 前往 git.zju.edu.cn 你的项目
2. 导航到**设置 → CI/CD → 变量 → 展开**
3. 点击**添加变量**
4. 对于 `SSH_PRIVATE_KEY`：
   - 键：`SSH_PRIVATE_KEY`
   - 值：粘贴完整私钥
   - 类型：变量（或文件）
   - ✓ 保护变量
   - ✓ 屏蔽变量
5. 对其他变量重复此步骤

### 步骤 5：初始化 Git 仓库并推送到浙大 GitLab

1. **在浙大 GitLab 创建新项目**：
   - 前往 git.zju.edu.cn
   - 点击"新建项目"
   - 命名（例如："course-notes"）
   - 根据需要设置可见性

2. **初始化并推送**（在本地项目目录）：
```bash
# 初始化 git 仓库
git init

# 添加所有文件
git add .

# 创建初始提交
git commit -m "初始提交，配置 CI/CD"

# 添加浙大 GitLab 远程仓库（使用 SSH URL）
git remote add origin git@git.zju.edu.cn:你的用户名/course-notes.git

# 推送到浙大 GitLab
git push -u origin master
```

**注意**：确保使用 SSH URL（`git@git.zju.edu.cn:...`）而不是 HTTPS！

### 步骤 6：监控部署

1. 前往你的浙大 GitLab 项目
2. 导航到 **CI/CD → 流水线**
3. 观察流水线运行：
   - **构建阶段**：安装依赖并构建 MkDocs 网站
   - **部署阶段**：使用 SSH 密钥链部署到香港服务器
4. 如有错误，查看日志

### 步骤 7：访问网站

**Docker 部署：**
```
http://你的服务器IP:8111
```

**Nginx 部署：**
```
http://你的服务器IP:8111
```

---

## 日常使用工作流

初始配置完成后，更新笔记非常简单：

```bash
# 1. 编辑笔记
vim docs/calculus/chapter1.md

# 2. 添加并提交更改
git add .
git commit -m "添加微积分第一章笔记"

# 3. 通过 SSH 推送到浙大 GitLab
git push

# 4. GitLab CI 自动构建并部署！🚀
```

检查部署：
- 访问：http://你的服务器IP:8111
- 或监控流水线：git.zju.edu.cn → 你的项目 → CI/CD → 流水线

---

## 部署方式

### 方式 1：静态文件 + Nginx（当前）

默认的 `.gitlab-ci.yml` 使用此方式：
- ✅ 简单快速
- ✅ 资源占用低
- ✅ 直接文件服务

**工作原理**：
1. GitLab CI 构建静态 HTML 文件
2. 使用 `rsync` 通过 SSH 密钥链同步文件到服务器
3. Nginx 在 8111 端口提供文件服务

### 方式 2：Docker 部署（备选）

切换到 Docker 部署：

```bash
# 切换 CI/CD 配置
mv .gitlab-ci.yml .gitlab-ci-static.yml
mv .gitlab-ci-docker.yml .gitlab-ci.yml
git add . && git commit -m "切换到 Docker 部署" && git push
```

Docker 方式需要额外的变量：

| 变量 | 值 | 说明 |
|------|-----|------|
| `CI_REGISTRY` | `registry.git.zju.edu.cn` | 浙大 GitLab 容器注册表 |
| `CI_REGISTRY_USER` | 你的浙大 GitLab 用户名 | 用于 Docker 注册表登录 |
| `CI_REGISTRY_PASSWORD` | 你的访问令牌 | 在设置 → 访问令牌创建 |

**工作原理**：
1. GitLab CI 构建包含网站的 Docker 镜像
2. 推送镜像到浙大 GitLab 容器注册表
3. 通过 SSH 密钥链登录服务器
4. 拉取新镜像并在 8111 端口重启容器

---

## 测试和故障排查

### 从本地测试 SSH 连接

```bash
# 使用 GitLab CI 密钥测试
ssh -i ~/.ssh/gitlab-ci $SERVER_USER@$SERVER_HOST

# 或使用默认密钥
ssh $SERVER_USER@$SERVER_HOST
```

### 测试部署

**Nginx 方式**：
```bash
# 检查文件是否已部署
ssh $SERVER_USER@$SERVER_HOST "ls -la /var/www/mkdocs-notes"

# 测试 nginx 配置
ssh $SERVER_USER@$SERVER_HOST "sudo nginx -t"

# 检查 8111 端口是否监听
ssh $SERVER_USER@$SERVER_HOST "sudo netstat -tulpn | grep 8111"
```

**Docker 方式**：
```bash
# 检查容器是否运行
ssh $SERVER_USER@$SERVER_HOST "docker ps"

# 检查容器日志
ssh $SERVER_USER@$SERVER_HOST "docker logs mkdocs-notes"

# 测试 8111 端口是否可访问
curl http://你的服务器IP:8111
```

### 常见问题

#### 1. 流水线在 SSH 步骤失败

**错误**：`Permission denied (publickey)`

**解决方案**：
- 验证 `SSH_PRIVATE_KEY` 包含 BEGIN/END 行
- 检查公钥是否在服务器的 `~/.ssh/authorized_keys` 中
- 确保 `SERVER_HOST` 和 `SERVER_USER` 正确
- 手动测试 SSH 连接

#### 2. rsync 失败

**错误**：`rsync: command not found`

**解决方案**：
```bash
# 在服务器上安装 rsync
ssh $SERVER_USER@$SERVER_HOST "sudo apt install rsync -y"
```

#### 3. DEPLOY_PATH 权限被拒绝

**错误**：写入部署目录时 `Permission denied`

**解决方案**：
```bash
# 修复所有权
ssh $SERVER_USER@$SERVER_HOST "sudo chown -R $USER:$USER $DEPLOY_PATH"
```

#### 4. 8111 端口无法访问

**错误**：无法访问 http://你的服务器IP:8111

**解决方案**：
```bash
# 检查防火墙
ssh $SERVER_USER@$SERVER_HOST "sudo ufw status"

# 允许 8111 端口
ssh $SERVER_USER@$SERVER_HOST "sudo ufw allow 8111/tcp"

# 对于 nginx，检查是否运行
ssh $SERVER_USER@$SERVER_HOST "sudo systemctl status nginx"

# 对于 Docker，检查容器状态
ssh $SERVER_USER@$SERVER_HOST "docker ps"
```

#### 5. 网站加载不正确

**错误**：网站加载但显示异常

**解决方案**：
- 检查浏览器控制台错误
- 验证 `mkdocs.yml` 中的 `site_url` 与实际 URL 匹配
- 清除浏览器缓存

#### 6. 浙大 GitLab SSH 连接问题

**错误**：推送到 git.zju.edu.cn 时 `Permission denied`

**解决方案**：
```bash
# 测试到浙大 GitLab 的 SSH 连接
ssh -T git@git.zju.edu.cn

# 将 SSH 密钥添加到 ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# 验证 SSH 配置（~/.ssh/config）
Host git.zju.edu.cn
    HostName git.zju.edu.cn
    User git
    IdentityFile ~/.ssh/id_rsa
```

### 查看日志

**GitLab CI 日志**：
- 前往浙大 GitLab → 你的项目 → CI/CD → 流水线 → 点击流水线 → 查看作业日志

**服务器日志**：
```bash
# Nginx 错误日志
ssh $SERVER_USER@$SERVER_HOST "sudo tail -f /var/log/nginx/error.log"

# Docker 容器日志
ssh $SERVER_USER@$SERVER_HOST "docker logs -f mkdocs-notes"

# 系统日志
ssh $SERVER_USER@$SERVER_HOST "sudo journalctl -xe"
```

---

## 安全最佳实践

1. **使用专用 SSH 密钥**：
   - ✓ GitLab CI 部署使用单独的密钥
   - ✓ 个人访问使用不同的密钥
   - ✓ 个人密钥使用强密码短语

2. **保护服务器安全**：
   ```bash
   # 保持系统更新
   sudo apt update && sudo apt upgrade -y

   # 配置防火墙
   sudo ufw enable
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 8111/tcp  # 你的 Web 服务

   # 禁用密码认证（仅使用 SSH 密钥）
   sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

3. **保护 GitLab CI/CD 变量**：
   - ✓ 始终将敏感变量标记为"已屏蔽"
   - ✓ 将变量标记为"受保护"以限制到受保护分支
   - ✓ 定期轮换 SSH 密钥

4. **使用 HTTPS（如果使用域名）**：
   ```bash
   # 安装 Certbot
   sudo apt install certbot python3-certbot-nginx -y

   # 获取证书（需要域名指向你的服务器）
   sudo certbot --nginx -d 你的域名.com

   # 自动续期已配置
   sudo certbot renew --dry-run
   ```

5. **限制 SSH 访问**：
   ```bash
   # 编辑 SSH 配置
   sudo vim /etc/ssh/sshd_config

   # 添加这些行：
   AllowUsers 你的用户名
   PermitRootLogin no
   MaxAuthTries 3

   # 重启 SSH
   sudo systemctl restart sshd
   ```

---

## 高级配置

### 部署后自动重启服务

编辑 `.gitlab-ci.yml`：

```yaml
  script:
    - rsync -avz --delete site/ $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH
    # 部署后重载 nginx
    - ssh $SERVER_USER@$SERVER_HOST "sudo systemctl reload nginx"
```

**Docker 方式**：
```yaml
  script:
    - rsync -avz --delete site/ $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH
    # 重新构建并重启容器
    - ssh $SERVER_USER@$SERVER_HOST "cd $DEPLOY_PATH && docker-compose up -d --build"
```

### 多环境部署

可以设置测试和生产环境：

```yaml
deploy_staging:
  stage: deploy
  # ... 部署配置 ...
  environment:
    name: staging
    url: http://staging-server:8111
  only:
    - develop

deploy_production:
  stage: deploy
  # ... 部署配置 ...
  environment:
    name: production
    url: http://production-server:8111
  only:
    - master
```

---

## 文件结构

```
.
├── .gitlab-ci.yml              # CI/CD 配置（nginx + rsync）
├── .gitlab-ci-docker.yml       # 备选配置（Docker 部署）
├── Dockerfile                  # 生产 Docker 镜像
├── docker-compose.yml          # Docker Compose 配置（8111 端口）
├── deploy.sh                   # 服务器端辅助脚本
├── DEPLOYMENT.md               # 英文部署指南
├── DEPLOYMENT_CN.md            # 本文件（中文）
├── README.md                   # 中文 README
├── mkdocs.yml                  # MkDocs 配置
├── requirements.txt            # Python 依赖
├── .gitignore                  # Git 忽略模式
├── .ignored-commits            # Git 修订插件用
├── docs/                       # Markdown 笔记
│   ├── index.md
│   ├── calculus/
│   ├── linear-algebra/
│   ├── c-programming/
│   ├── engineering-graphics/
│   └── college-english/
├── overrides/                  # 自定义主题覆盖
├── hooks/                      # MkDocs 钩子
└── site/                       # 构建输出（自动生成）
```

---

## 快速参考

### 浙大 GitLab URLs

- Web 界面：https://git.zju.edu.cn
- SSH 克隆：`git@git.zju.edu.cn:用户名/仓库名.git`
- 容器注册表：`registry.git.zju.edu.cn`

### 常用命令

```bash
# 本地构建
docker run --rm -v $(pwd):/docs squidfunk/mkdocs-material:9.7.0 build

# 本地测试
docker run --rm -v $(pwd):/docs -p 8000:8000 \
  squidfunk/mkdocs-material:9.7.0 serve -a 0.0.0.0:8000

# 推送到浙大 GitLab
git add . && git commit -m "更新笔记" && git push

# 检查服务器上的部署
ssh $SERVER_USER@$SERVER_HOST "ls -lh $DEPLOY_PATH"

# 查看网站
curl http://你的服务器IP:8111
```

---

## 需要帮助？

- 浙大 GitLab 文档：查看 git.zju.edu.cn 帮助
- GitLab CI/CD：https://docs.gitlab.com/ee/ci/
- MkDocs Material：https://squidfunk.github.io/mkdocs-material/
- 流水线日志：git.zju.edu.cn → 你的项目 → CI/CD → 流水线

---

**祝记笔记愉快！📚✨**
