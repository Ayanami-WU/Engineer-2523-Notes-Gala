# GitLab Runner 配置指南

## 问题说明

当你推送代码到 GitLab 后，CI/CD Pipeline 显示：

```
This job is stuck because the project doesn't have any runners online assigned to it.
```

这是因为 GitLab CI/CD 需要 **GitLab Runner** 来执行 `.gitlab-ci.yml` 中定义的任务（构建和部署）。

## 解决方案

### 方案一：启用 ZJU GitLab 共享 Runner（推荐，最简单）

#### 步骤

1. **访问项目设置**
   - 打开你的 GitLab 项目：https://git.zju.edu.cn/3250103435/engineering-2523-notes
   - 点击左侧菜单 **Settings** → **CI/CD**

2. **查看 Runners 配置**
   - 在 CI/CD 设置页面，找到 **Runners** 部分
   - 点击 **Expand** 展开

3. **检查共享 Runner**
   - 查看 **Shared runners** 部分
   - 如果看到类似 "shared-runner-1" 或其他 Runner 列表
   - 点击 **Enable shared runners for this project** 按钮

4. **验证**
   - 启用后，回到项目首页
   - 点击左侧 **CI/CD** → **Pipelines**
   - 你的 Pipeline 应该会自动开始运行

#### 可能的情况

- ✅ **有共享 Runner**：启用后即可使用，无需其他配置
- ❌ **没有共享 Runner**：使用方案二或方案三

---

### 方案二：在香港服务器上安装 GitLab Runner

如果 ZJU GitLab 没有提供共享 Runner，你需要在自己的服务器上安装。

#### 前提条件

- 香港服务器已安装 Docker
- 服务器可以访问 git.zju.edu.cn
- 具有 sudo 权限

#### 步骤

##### 1. 将安装脚本上传到服务器

在本地执行：

```bash
# 将脚本上传到香港服务器
scp setup-gitlab-runner.sh your-user@your-hk-server-ip:~/
```

##### 2. 在服务器上运行安装脚本

SSH 登录到香港服务器，然后：

```bash
# 赋予执行权限
chmod +x setup-gitlab-runner.sh

# 运行安装脚本
sudo bash setup-gitlab-runner.sh
```

安装过程会：
- 添加 GitLab Runner 官方软件源
- 安装 GitLab Runner
- 启动并启用 Runner 服务

##### 3. 获取注册令牌

在 GitLab 项目中：

1. 进入 **Settings** → **CI/CD** → **Runners**
2. 点击 **New project runner** 按钮
3. 按照页面提示：
   - **Tags**: 输入 `mkdocs,deploy`（可选）
   - **Runner description**: `mkdocs-notes-runner`
   - 点击 **Create runner**
4. **复制显示的注册令牌**（格式如 `glrt-xxxxxxxxxxxx`）

##### 4. 注册 Runner

在香港服务器上执行：

```bash
sudo gitlab-runner register
```

按提示输入：

```
GitLab instance URL:
https://git.zju.edu.cn

Registration token:
[粘贴你从 GitLab 复制的令牌]

Description:
mkdocs-notes-runner

Tags (comma separated):
mkdocs,deploy

Executor:
docker

Default Docker image:
alpine:latest
```

##### 5. 验证 Runner 状态

```bash
# 查看 Runner 列表
sudo gitlab-runner list

# 查看 Runner 服务状态
sudo systemctl status gitlab-runner

# 在 GitLab 网页中查看
# Settings → CI/CD → Runners → Available specific runners
# 应该能看到你刚注册的 Runner（绿色圆点表示在线）
```

##### 6. 触发 Pipeline

Runner 注册成功后：

```bash
# 在本地项目中创建一个小改动来触发 Pipeline
git commit --allow-empty -m "test: trigger pipeline with new runner"
git push origin main
```

然后在 GitLab 的 **CI/CD → Pipelines** 查看运行状态。

#### 故障排查

##### Runner 显示离线

```bash
# 重启 Runner 服务
sudo systemctl restart gitlab-runner

# 查看日志
sudo journalctl -u gitlab-runner -f
```

##### Docker 权限问题

```bash
# 将 gitlab-runner 用户添加到 docker 组
sudo usermod -aG docker gitlab-runner

# 重启 Runner
sudo systemctl restart gitlab-runner
```

##### 网络连接问题

```bash
# 在服务器上测试连接
ping git.zju.edu.cn

# 测试 HTTPS 访问
curl -I https://git.zju.edu.cn
```

---

### 方案三：手动部署（不使用 CI/CD）

如果无法配置 Runner，你可以选择手动部署到服务器。

#### 本地构建

```bash
# 在本地构建网站
docker run --rm -v $(pwd):/docs \
  squidfunk/mkdocs-material:9.7.0 \
  sh -c "pip install -r requirements.txt && mkdocs build"
```

#### 部署到服务器

```bash
# 使用 rsync 同步到服务器
rsync -avz --delete site/ your-user@your-hk-server-ip:~/mkdocs-notes/site/
```

#### 使用 Docker Compose 运行

在服务器上：

```bash
cd ~/mkdocs-notes
docker-compose up -d
```

访问 `http://your-server-ip:8111` 查看网站。

#### 创建部署脚本

为方便手动部署，可以创建脚本：

```bash
#!/bin/bash
# deploy-manual.sh - 手动部署脚本

set -e

echo "构建网站..."
docker run --rm -v $(pwd):/docs \
  squidfunk/mkdocs-material:9.7.0 \
  sh -c "pip install -r requirements.txt && mkdocs build"

echo "部署到服务器..."
rsync -avz --delete site/ your-user@your-server-ip:~/mkdocs-notes/site/

echo "部署完成！"
echo "访问: http://your-server-ip:8111"
```

使用：

```bash
chmod +x deploy-manual.sh
./deploy-manual.sh
```

---

## 推荐方案总结

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **方案一：共享 Runner** | 无需配置，立即可用 | 依赖 ZJU 提供 | ⭐⭐⭐⭐⭐ |
| **方案二：自建 Runner** | 完全控制，自动部署 | 需要服务器资源 | ⭐⭐⭐⭐ |
| **方案三：手动部署** | 简单直接，无依赖 | 每次手动操作 | ⭐⭐⭐ |

**建议流程：**

1. 首先尝试**方案一**（启用共享 Runner）
2. 如果没有共享 Runner，使用**方案二**（自建 Runner）
3. 如果服务器资源有限或配置困难，使用**方案三**（手动部署）

---

## CI/CD 变量配置

无论使用哪种方案（如果使用 CI/CD），都需要在 GitLab 中配置以下变量：

1. 进入 **Settings** → **CI/CD** → **Variables**
2. 点击 **Add variable**，逐个添加：

| Key | Value | Protected | Masked |
|-----|-------|-----------|--------|
| `SSH_PRIVATE_KEY` | [服务器部署用的私钥内容] | ✅ | ✅ |
| `SERVER_HOST` | 你的香港服务器 IP | ❌ | ❌ |
| `SERVER_USER` | SSH 用户名 | ❌ | ❌ |
| `DEPLOY_PATH` | `~/mkdocs-notes/site` | ❌ | ❌ |

### 生成部署用 SSH 密钥

在香港服务器上：

```bash
# 生成专用于 CI/CD 部署的密钥
ssh-keygen -t rsa -b 4096 -C "gitlab-ci-deploy" -f ~/.ssh/gitlab-ci

# 将公钥添加到授权列表
cat ~/.ssh/gitlab-ci.pub >> ~/.ssh/authorized_keys

# 复制私钥内容（用于 GitLab CI/CD 变量）
cat ~/.ssh/gitlab-ci
```

将私钥内容复制到 GitLab 的 `SSH_PRIVATE_KEY` 变量中。

---

## 常见问题

### Q1: Runner 运行后 Pipeline 仍然卡住？

**A:** 检查以下几点：
1. Runner 是否在线（GitLab Settings → CI/CD → Runners 查看绿色圆点）
2. Runner 的 tags 是否匹配（如果 `.gitlab-ci.yml` 中指定了 tags）
3. 查看 Runner 日志：`sudo journalctl -u gitlab-runner -f`

### Q2: 构建成功但部署失败？

**A:** 检查：
1. CI/CD 变量是否正确配置
2. SSH 密钥是否有效
3. 服务器网络是否可达
4. 部署路径是否存在且有写权限

### Q3: 如何查看 Pipeline 详细日志？

**A:**
1. 进入 **CI/CD** → **Pipelines**
2. 点击 Pipeline 状态图标
3. 点击具体的 job（build 或 deploy）
4. 查看详细输出日志

### Q4: 多个项目共用一个 Runner？

**A:** 可以。在注册 Runner 时不要指定 tags，或者使用通用的 tags。同一个 Runner 可以服务多个项目。

### Q5: Runner 占用服务器资源太多？

**A:**
1. 限制并发任务数：编辑 `/etc/gitlab-runner/config.toml`，设置 `concurrent = 1`
2. 使用 Docker executor 隔离环境
3. 考虑使用专门的构建服务器

---

## 参考资料

- [GitLab Runner 官方文档](https://docs.gitlab.com/runner/)
- [GitLab CI/CD 快速入门](https://docs.gitlab.com/ee/ci/quick_start/)
- [Docker Executor 配置](https://docs.gitlab.com/runner/executors/docker.html)

---

**祝部署顺利！🚀**

如有问题，请检查 GitLab Pipeline 日志或 Runner 服务日志以获取详细错误信息。
