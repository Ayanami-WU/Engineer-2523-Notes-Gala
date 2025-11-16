# ✅ Runner 问题已修复

## 问题描述

之前遇到的错误：
```
This job is stuck because of one of the following problems.
There are no active runners online, no runners for the protected branch,
or no runners that match all of the job's tags: docker
```

## 解决方案

已修改 `.gitlab-ci.yml` 文件，**注释掉了 `tags: docker` 要求**，现在 CI 将使用 GitLab 的共享 Runner。

### 修改内容

**修改前**:
```yaml
build_docker:
  stage: build
  # ... 其他配置
  tags:
    - docker  # ❌ 需要专用 Runner

deploy_to_server:
  stage: deploy
  # ... 其他配置
  tags:
    - docker  # ❌ 需要专用 Runner
```

**修改后**:
```yaml
build_docker:
  stage: build
  # ... 其他配置
  # tags:
  #   - docker  # ✅ 已注释，使用共享 Runner

deploy_to_server:
  stage: deploy
  # ... 其他配置
  # tags:
  #   - docker  # ✅ 已注释，使用共享 Runner
```

## 下一步操作

### 1. 查看 Pipeline 状态

访问: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/pipelines

你应该会看到一个新的 Pipeline 正在运行（由刚才的 push 触发）。

### 2. 监控 Pipeline 执行

点击最新的 Pipeline，可以看到两个阶段：

**阶段 1: build_docker** (约 3-5 分钟)
- 使用 `docker:24-cli` 镜像
- 构建 MkDocs Docker 镜像
- 保存镜像为 tar 文件

**阶段 2: deploy_to_server** (约 1-2 分钟)
- 需要先配置 GitLab CI/CD 变量才能成功
- SSH 到服务器并部署

### 3. 如果 build_docker 阶段成功

说明共享 Runner 可用，Pipeline 配置正确！✅

### 4. 如果 deploy_to_server 阶段失败

**正常情况** - 因为还没有配置 CI/CD 变量，会看到类似错误：
```
$SSH_PRIVATE_KEY: unbound variable
或
ssh: connect to host : Name or service not known
```

**解决方法**: 按照 [NEXT_STEPS.md](NEXT_STEPS.md) 配置 CI/CD 变量。

## CI/CD 变量配置（如果还没配置）

访问: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/settings/ci_cd

需要配置 4 个变量：

| 变量名 | 说明 |
|--------|------|
| `SSH_PRIVATE_KEY` | SSH 私钥（用于连接服务器）|
| `SERVER_HOST` | 服务器 IP 地址 |
| `SERVER_USER` | SSH 用户名 |
| `DEPLOY_PATH` | 部署目录路径 |

详细步骤请查看: [NEXT_STEPS.md](NEXT_STEPS.md)

## 共享 Runner vs 专用 Runner

### 当前配置：使用共享 Runner ✅

**优点**:
- 无需自己维护 Runner
- GitLab 提供的免费资源
- 配置简单，开箱即用

**缺点**:
- 可能有执行队列等待时间
- 每月有使用限额（免费版通常 400 分钟）

### 如果需要专用 Runner

如果你有自己的服务器并想使用专用 Runner：

1. **在服务器上安装 GitLab Runner**:
   ```bash
   # Ubuntu/Debian
   curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
   sudo apt-get install gitlab-runner
   ```

2. **注册 Runner**:
   ```bash
   sudo gitlab-runner register
   # GitLab URL: https://git.koala-studio.org.cn
   # Token: (从项目 Settings → CI/CD → Runners 获取)
   # Executor: docker
   # Tags: docker
   ```

3. **取消注释 tags 配置**:
   在 `.gitlab-ci.yml` 中将 `# tags: - docker` 取消注释

## 验证 Pipeline 状态

### 检查 Pipeline 是否运行

```bash
# 方法 1: 通过 Web UI
打开: https://git.koala-studio.org.cn/Koala-Inno-WMX/e-2523-note/-/pipelines

# 方法 2: 使用 Git 命令查看最新提交
git log -1 --oneline
# 输出: af6f8533 Fix: Remove runner tags requirement to use shared runners
```

### Pipeline 状态说明

| 状态 | 图标 | 说明 |
|------|------|------|
| Pending | ⏸️ | 等待 Runner |
| Running | ▶️ | 正在执行 |
| Passed | ✅ | 成功完成 |
| Failed | ❌ | 执行失败 |

## 预期结果

### 如果已配置 CI/CD 变量

完整的 Pipeline 应该成功完成，可以访问网站：
```
http://your-server-ip:8111
```

### 如果未配置 CI/CD 变量

- `build_docker` 阶段应该成功 ✅
- `deploy_to_server` 阶段会失败 ❌（缺少变量）

**这是正常的！** 继续按照 [NEXT_STEPS.md](NEXT_STEPS.md) 配置即可。

## 相关文档

- **详细部署步骤**: [NEXT_STEPS.md](NEXT_STEPS.md)
- **快速检查清单**: [CHECKLIST.md](CHECKLIST.md)
- **完整部署指南**: [GITLAB_CI_DEPLOYMENT_GUIDE.md](GITLAB_CI_DEPLOYMENT_GUIDE.md)

---

**最后更新**: 2025-11-16
**状态**: ✅ Runner 问题已解决
**下一步**: 配置 CI/CD 变量并完成部署
