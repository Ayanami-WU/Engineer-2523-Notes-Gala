# ⚡ GitHub 快速部署（4 步完成）

> 解决内网 GitLab 无法访问的问题

---

## 🎯 步骤 1: 创建 GitHub 仓库

访问: https://github.com/new

```
Repository name: e-2523-note
Description: My course notes
Visibility: Public
```

创建后记下仓库 URL

---

## 📤 步骤 2: 推送代码到 GitHub

```bash
cd ~/tonycrane-note

# 添加 GitHub 远程仓库
git remote add github https://github.com/YOUR_USERNAME/e-2523-note.git

# 推送代码
git push github main
```

---

## 🔐 步骤 3: 配置 GitHub Secrets

### 3.1 生成 SSH 密钥

```bash
# 生成密钥
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions_key

# 添加到服务器
ssh-copy-id -i ~/.ssh/github_actions_key.pub your-username@your-server-ip

# 查看私钥（复制用于 GitHub）
cat ~/.ssh/github_actions_key
```

### 3.2 在 GitHub 添加 Secrets

访问: `https://github.com/YOUR_USERNAME/e-2523-note/settings/secrets/actions`

添加 3 个 Secrets:

| Name | Value |
|------|-------|
| `SSH_PRIVATE_KEY` | 私钥完整内容 |
| `SERVER_HOST` | 服务器 IP |
| `SERVER_USER` | SSH 用户名 |

---

## 🚀 步骤 4: 初始化服务器 + 触发部署

### 4.1 服务器初始化

```bash
ssh your-username@your-server-ip
wget https://raw.githubusercontent.com/YOUR_USERNAME/e-2523-note/main/server-init.sh
chmod +x server-init.sh
./server-init.sh
```

### 4.2 触发部署

```bash
# 做一个修改
echo "test" >> README.md
git add README.md
git commit -m "Test GitHub Actions"
git push github main
```

---

## ✅ 查看部署

访问: `https://github.com/YOUR_USERNAME/e-2523-note/actions`

等待 5-10 分钟 → 访问 `http://your-server-ip:8111`

---

## 📖 详细文档

完整指南: [GITHUB_DEPLOY_GUIDE.md](GITHUB_DEPLOY_GUIDE.md)

---

**就这么简单！**
