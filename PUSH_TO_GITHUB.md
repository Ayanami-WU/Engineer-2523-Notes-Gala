# 📤 推送代码到 GitHub

> 仓库: https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala (Public)

---

## ⚡ 快速推送（选择一种方法）

### 方法 1: 使用 Personal Access Token（推荐 - 最简单）

#### 步骤 1: 创建 Token

1. 访问: https://github.com/settings/tokens
2. 点击 **Generate new token** → **Generate new token (classic)**
3. 填写:
   ```
   Note: MkDocs Deploy
   Expiration: No expiration (或选择期限)
   Select scopes:
     ✅ repo (勾选所有 repo 权限)
   ```
4. 点击 **Generate token**
5. **立即复制 token**（只显示一次！格式类似: `ghp_xxxxxxxxxxxx`）

#### 步骤 2: 推送代码

```bash
# 推送
git push github main

# 输入:
Username: Ayanami-WU
Password: [粘贴你的 token]
```

**重要**: 密码处粘贴的是 token，不是 GitHub 密码！

---

### 方法 2: 使用 SSH（推荐 - 长期使用）

#### 步骤 1: 生成 SSH 密钥

```bash
# 检查是否已有密钥
ls ~/.ssh/id_*.pub

# 如果没有，生成新密钥
ssh-keygen -t ed25519 -C "your_email@example.com"
# 按三次回车（使用默认设置）
```

#### 步骤 2: 添加公钥到 GitHub

```bash
# 查看公钥
cat ~/.ssh/id_ed25519.pub

# 复制输出的内容（以 ssh-ed25519 开头）
```

访问: https://github.com/settings/keys

1. 点击 **New SSH key**
2. 填写:
   ```
   Title: MacBook (或其他名称)
   Key type: Authentication Key
   Key: [粘贴公钥]
   ```
3. 点击 **Add SSH key**

#### 步骤 3: 改用 SSH URL 并推送

```bash
# 改用 SSH URL
git remote set-url github git@github.com:Ayanami-WU/Engineer-2523-Notes-Gala.git

# 测试 SSH 连接
ssh -T git@github.com
# 应该看到: Hi Ayanami-WU! You've successfully authenticated...

# 推送代码
git push github main
```

---

## ✅ 推送成功后

推送成功后，你会看到：

```
Enumerating objects: XX, done.
Counting objects: 100% (XX/XX), done.
...
To https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala.git
   xxxxxxx..yyyyyyy  main -> main
```

然后访问仓库确认：

```
https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala
```

应该能看到所有文件！

---

## 📋 下一步

推送成功后，继续配置部署：

1. ✅ 代码已推送到 GitHub
2. ⏭️ 配置 GitHub Secrets (3 个)
3. ⏭️ 初始化服务器
4. ⏭️ 触发自动部署

**详细步骤**: [DEPLOY_NOW.md](DEPLOY_NOW.md)

---

## 🐛 故障排除

### 问题: Token 推送失败

```
remote: Support for password authentication was removed
```

**原因**: 必须使用 Personal Access Token，不能用密码

**解决**: 按照"方法 1"创建并使用 token

### 问题: SSH 推送失败

```
Permission denied (publickey)
```

**原因**: SSH 公钥未添加到 GitHub

**解决**:
1. 确认公钥已添加: https://github.com/settings/keys
2. 测试连接: `ssh -T git@github.com`

---

## 🎯 推荐方案

- **首次使用**: 方法 1 (Personal Access Token) - 快速简单
- **长期使用**: 方法 2 (SSH) - 无需每次输入密码

---

**选择一个方法开始推送吧！** 🚀
