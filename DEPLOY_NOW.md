# 🚀 立即部署指南

> 仓库已配置: https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala

---

## ✅ 已完成

- ✅ GitHub 远程仓库已添加
- ✅ 部署脚本已更新
- ✅ GitHub Actions 工作流已配置

---

## 📤 步骤 1: 推送代码到 GitHub

### 选项 A: 使用 HTTPS (推荐 - 简单)

```bash
# 改用 HTTPS URL
git remote set-url github https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala.git

# 推送代码
git push github main
```

推送时会要求输入 GitHub 凭据：
- **Username**: `Ayanami-WU`
- **Password**: 使用 **Personal Access Token** (不是密码)

#### 创建 Personal Access Token:

1. 访问: https://github.com/settings/tokens
2. 点击 **Generate new token** → **Generate new token (classic)**
3. 设置:
   - Note: `MkDocs Deployment`
   - Expiration: `No expiration` (或选择时间)
   - 勾选: ✅ **repo** (全部权限)
4. 点击 **Generate token**
5. **复制 token** (只显示一次！)
6. 推送时用 token 作为密码

### 选项 B: 使用 SSH (推荐 - 长期使用)

#### 1. 生成 SSH 密钥（如果还没有）

```bash
# 检查是否已有密钥
ls ~/.ssh/id_*.pub

# 如果没有，生成新密钥
ssh-keygen -t ed25519 -C "your_email@example.com"
# 按三次回车（使用默认位置，不设密码）

# 查看公钥
cat ~/.ssh/id_ed25519.pub
```

#### 2. 添加公钥到 GitHub

1. 复制上面命令输出的公钥（以 `ssh-ed25519` 开头）
2. 访问: https://github.com/settings/keys
3. 点击 **New SSH key**
4. 填写:
   - Title: `MacBook` (或其他名称)
   - Key: 粘贴公钥
5. 点击 **Add SSH key**

#### 3. 测试并推送

```bash
# 测试 SSH 连接
ssh -T git@github.com
# 应该看到: Hi Ayanami-WU! You've successfully authenticated...

# 推送代码
git push github main
```

---

## 🔐 步骤 2: 配置 GitHub Secrets (3 个)

### 2.1 生成部署用的 SSH 密钥

```bash
# 生成专用于 GitHub Actions 的密钥
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy
# 按两次回车（不设密码）

# 添加公钥到服务器
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub your-username@your-server-ip

# 测试连接
ssh -i ~/.ssh/github_actions_deploy your-username@your-server-ip "echo 'SSH OK!'"

# 查看私钥（稍后用于 GitHub Secrets）
cat ~/.ssh/github_actions_deploy
```

### 2.2 在 GitHub 添加 Secrets

访问: https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala/settings/secrets/actions

点击 **New repository secret**，添加以下 3 个 Secrets:

#### Secret 1: SSH_PRIVATE_KEY

```
Name: SSH_PRIVATE_KEY

Value: (粘贴 ~/.ssh/github_actions_deploy 的完整内容)

包括:
-----BEGIN OPENSSH PRIVATE KEY-----
... (所有行) ...
-----END OPENSSH PRIVATE KEY-----
```

点击 **Add secret**

#### Secret 2: SERVER_HOST

```
Name: SERVER_HOST

Value: your-server-ip  (例如: 45.76.123.45)
```

点击 **Add secret**

#### Secret 3: SERVER_USER

```
Name: SERVER_USER

Value: your-username  (服务器的 SSH 用户名，例如: ubuntu, root)
```

点击 **Add secret**

### 2.3 验证 Secrets

在 Secrets 页面应该看到：
- ✅ `SSH_PRIVATE_KEY`
- ✅ `SERVER_HOST`
- ✅ `SERVER_USER`

---

## 🖥️ 步骤 3: 初始化服务器（如果还没做）

SSH 登录到服务器：

```bash
ssh your-username@your-server-ip
```

下载并运行初始化脚本：

```bash
# 下载初始化脚本
wget https://raw.githubusercontent.com/Ayanami-WU/Engineer-2523-Notes-Gala/main/server-init.sh

# 添加执行权限
chmod +x server-init.sh

# 运行初始化
./server-init.sh

# 重新登录使权限生效
exit
ssh your-username@your-server-ip

# 验证 Docker
docker --version
docker ps
```

---

## 🚀 步骤 4: 触发部署

代码已经推送，Secrets 已配置，服务器已初始化。

现在做一个小修改触发部署：

```bash
# 创建一个测试文件
echo "# GitHub Actions Deployment Test" >> TEST.md

# 提交
git add TEST.md
git commit -m "Test GitHub Actions deployment"

# 推送到 GitHub（触发自动部署）
git push github main
```

---

## 📊 查看部署进度

### 访问 GitHub Actions

```
https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala/actions
```

你会看到：
- **Workflow**: Deploy to Server
- **Status**: 🟡 In progress / 🟢 Success / 🔴 Failed
- **Triggered by**: push

### 点击查看详细日志

每个步骤都有实时日志：

```
✓ Checkout code
✓ Display deployment info
✓ Setup SSH
✓ Test SSH connection
⏳ Deploy to server (5-10 分钟)
  → 下载部署脚本
  → 克隆代码从 GitHub
  → 构建 Docker 镜像
  → 启动容器
✓ Deployment complete
```

---

## ✅ 验证部署成功

### 1. GitHub Actions 显示绿色 ✓

Actions 页面应该显示绿色勾号 ✅

### 2. 访问网站

打开浏览器：

```
http://your-server-ip:8111
```

应该能看到你的文档网站！

### 3. 检查服务器

SSH 到服务器：

```bash
ssh your-username@your-server-ip

# 查看容器
docker ps | grep mkdocs-notes

# 查看日志
docker logs mkdocs-notes
```

---

## 🎯 快速命令参考

### 推送代码（HTTPS）

```bash
git add .
git commit -m "Update docs"
git push github main
```

### 推送代码（SSH）

```bash
git add .
git commit -m "Update docs"
git push github main
```

### 查看远程仓库

```bash
git remote -v
```

### 查看 Actions 状态

访问: https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala/actions

### 查看服务器容器

```bash
ssh your-username@your-server-ip "docker ps | grep mkdocs"
```

---

## 🐛 故障排除

### 问题 1: 推送失败 (HTTPS)

```
fatal: could not read Username
```

**解决**: 使用 Personal Access Token 作为密码

### 问题 2: 推送失败 (SSH)

```
Permission denied (publickey)
```

**解决**:
1. 添加 SSH 公钥到 GitHub
2. https://github.com/settings/keys

### 问题 3: Actions 失败

查看 Actions 日志，常见原因：
- Secrets 未配置
- SSH 连接失败
- 服务器 Docker 未运行

### 问题 4: 网站无法访问

检查：
1. GitHub Actions 是否成功
2. 服务器容器是否运行
3. 防火墙是否开放 8111 端口

---

## 📖 相关文档

- **详细指南**: [GITHUB_DEPLOY_GUIDE.md](GITHUB_DEPLOY_GUIDE.md)
- **快速参考**: [QUICK_GITHUB_SETUP.md](QUICK_GITHUB_SETUP.md)

---

## 🎉 完成后

每次更新文档只需：

```bash
vim docs/your-page.md
git add docs/your-page.md
git commit -m "Update documentation"
git push github main
```

等待 3-5 分钟，网站自动更新！

---

**GitHub 仓库**: https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala
**Actions 页面**: https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala/actions
**网站地址**: http://your-server-ip:8111

**现在开始按照步骤操作吧！** 🚀
