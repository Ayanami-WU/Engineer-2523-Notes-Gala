# ✅ 部署检查清单

快速检查部署所需的所有步骤。

---

## 📋 部署前检查

### 本地环境
- [ ] Git 已安装
- [ ] 代码已推送到 GitLab: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note
- [ ] 所有文件已提交（无未跟踪文件）

### 远程服务器
- [ ] 服务器可通过 SSH 访问
- [ ] 服务器已重置（全新环境）
- [ ] 端口 8111 可用
- [ ] 至少 2GB 内存
- [ ] 至少 10GB 可用磁盘

---

## 🚀 第一步: 服务器初始化

```bash
# SSH 登录
ssh your-username@your-server-ip

# 下载初始化脚本
wget https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/raw/main/server-init.sh

# 运行脚本
chmod +x server-init.sh
./server-init.sh

# 重新登录
exit
ssh your-username@your-server-ip
```

### 验证服务器初始化
- [ ] Docker 已安装: `docker --version`
- [ ] Docker Compose 已安装: `docker compose version`
- [ ] Docker 可以无 sudo 运行: `docker ps`
- [ ] 端口 8111 已开放
- [ ] 部署目录已创建: `ls ~/mkdocs-deploy`

---

## 🔐 第二步: GitLab CI/CD 配置

### 生成 SSH 密钥（本地）

```bash
ssh-keygen -t ed25519 -C "gitlab-ci" -f ~/.ssh/gitlab_ci_deploy
```

- [ ] 私钥已生成: `~/.ssh/gitlab_ci_deploy`
- [ ] 公钥已生成: `~/.ssh/gitlab_ci_deploy.pub`

### 添加公钥到服务器

```bash
ssh-copy-id -i ~/.ssh/gitlab_ci_deploy.pub your-username@your-server-ip
```

- [ ] 公钥已添加到服务器
- [ ] SSH 连接测试成功: `ssh -i ~/.ssh/gitlab_ci_deploy your-username@your-server-ip "echo OK"`

### 配置 GitLab 变量

进入: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/settings/ci_cd

**Settings → CI/CD → Variables → Add variable**

- [ ] `SSH_PRIVATE_KEY` (Type: File, Protected: ✓, Masked: ✓)
- [ ] `SERVER_HOST` (Type: Variable, Protected: ✓)
- [ ] `SERVER_USER` (Type: Variable, Protected: ✓)
- [ ] `DEPLOY_PATH` (Type: Variable, Protected: ✓)

---

## 🚢 第三步: 触发部署

### 方式 1: 自动触发（推荐）

代码已推送，Pipeline 应该自动运行。

查看: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/pipelines

### 方式 2: 手动触发

```bash
echo "" >> README.md
git add README.md
git commit -m "Trigger deployment"
git push origin main
```

### 监控部署

- [ ] Pipeline 已触发
- [ ] Stage 1 (build_docker) 成功 ✓
- [ ] Stage 2 (deploy_to_server) 成功 ✓
- [ ] 部署日志显示 "Deployment completed!"

---

## ✅ 第四步: 验证部署

### 服务器检查

```bash
ssh your-username@your-server-ip

# 容器状态
docker ps | grep mkdocs-notes

# 容器日志
docker logs mkdocs-notes
```

- [ ] 容器正在运行
- [ ] 端口映射正确: `0.0.0.0:8111->80/tcp`
- [ ] 日志无错误

### 网站访问

```
http://your-server-ip:8111
```

- [ ] 网站可以访问
- [ ] 页面正常显示
- [ ] 图片和样式正确加载

### 自动部署测试

```bash
# 本地修改
echo "## 测试" >> docs/index.md
git add docs/index.md
git commit -m "Test auto deploy"
git push origin main
```

- [ ] Pipeline 自动触发
- [ ] 部署成功
- [ ] 网站更新显示

---

## 🎯 全部完成检查

- [ ] ✓ 服务器初始化完成
- [ ] ✓ Docker 环境正常
- [ ] ✓ GitLab CI/CD 变量配置完成
- [ ] ✓ SSH 密钥配置正确
- [ ] ✓ 首次部署成功
- [ ] ✓ 网站可以访问
- [ ] ✓ 自动部署功能正常

---

## 🔧 故障排除快速参考

### Pipeline 失败

```bash
# 检查变量配置
GitLab → Settings → CI/CD → Variables

# 查看详细日志
GitLab → CI/CD → Pipelines → 点击失败的 job
```

### 容器问题

```bash
# SSH 到服务器
ssh your-username@your-server-ip

# 查看容器
docker ps -a | grep mkdocs

# 查看日志
docker logs mkdocs-notes

# 重新部署
cd ~/mkdocs-deploy
./deploy-docker.sh
```

### 网站无法访问

```bash
# 检查容器
docker ps | grep mkdocs-notes

# 检查端口
docker port mkdocs-notes

# 检查防火墙
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-ports  # CentOS

# 测试本地
curl http://localhost:8111
```

---

## 📱 快速命令

### 查看部署状态
```bash
ssh your-username@your-server-ip "docker ps"
```

### 查看日志
```bash
ssh your-username@your-server-ip "docker logs -f mkdocs-notes"
```

### 重启服务
```bash
ssh your-username@your-server-ip "cd ~/mkdocs-deploy && docker-compose restart"
```

### 完全重新部署
```bash
ssh your-username@your-server-ip "cd ~/mkdocs-deploy && ./deploy-docker.sh"
```

---

## 📚 相关文档

- **详细步骤**: [NEXT_STEPS.md](NEXT_STEPS.md)
- **快速开始**: [QUICK_START.md](QUICK_START.md)
- **完整指南**: [GITLAB_CI_DEPLOYMENT_GUIDE.md](GITLAB_CI_DEPLOYMENT_GUIDE.md)

---

**项目地址**: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note
**完成所有步骤预计时间**: 20-30 分钟
