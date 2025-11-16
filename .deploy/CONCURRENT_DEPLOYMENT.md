# GitHub Actions 并发控制说明

## 问题背景

当快速连续push多个commit时，会触发多个GitHub Actions同时运行，导致：

### ❌ 不添加并发控制的后果

```
Time  Action                    Server Status
------|------------------------|---------------------------
0:00  Push commit A
0:01  → Action A starts        Building...
0:05  Push commit B
0:06  → Action B starts        Building... (并行)  ⚠️
0:08  Push commit C
0:09  → Action C starts        Building... (并行)  ⚠️
0:15  Action A deploys         Container restart
0:16  Action B deploys         Container restart  ⚠️ 冲突！
0:18  Action C deploys         Container restart  ⚠️ 冲突！
```

**问题**：
1. **容器冲突** - 多个Action同时操作同一容器
2. **资源浪费** - 构建中间版本（A和B）没有意义
3. **部署失败** - `docker stop/rm` 命令可能失败
4. **网站不稳定** - 容器频繁重启

---

## ✅ 解决方案：并发控制

在 `.github/workflows/deploy.yml` 中添加：

```yaml
concurrency:
  group: production-deployment
  cancel-in-progress: true
```

### 工作原理

```
Time  Action                    Server Status
------|------------------------|---------------------------
0:00  Push commit A
0:01  → Action A starts        Building...
0:05  Push commit B
0:06  → Action B starts
      → Action A canceled!     Building stopped  ✅
      Action B building...     Building...
0:08  Push commit C
0:09  → Action C starts
      → Action B canceled!     Building stopped  ✅
      Action C building...     Building...
0:18  Action C deploys         Container restart (一次)  ✅
```

### 配置说明

| 参数 | 值 | 说明 |
|------|-----|------|
| `group` | `production-deployment` | 并发组名称（自定义） |
| `cancel-in-progress` | `true` | 新任务会取消正在运行的旧任务 |

**效果**：
- ✅ 同一时间只运行一个部署任务
- ✅ 新的push会自动取消旧的部署
- ✅ 始终部署最新的代码
- ✅ 避免资源浪费

---

## 📊 行为对比

### 场景1：连续3次push

#### 不使用并发控制
```
Commit A → Action A (运行)
Commit B → Action B (运行)  ← 并行
Commit C → Action C (运行)  ← 并行

结果：
- 3个Action同时运行
- 服务器上3个docker build进程
- 可能导致容器冲突
- 浪费CI/CD资源
```

#### 使用并发控制 ✅
```
Commit A → Action A (运行)
Commit B → Action B (运行) → 自动取消Action A
Commit C → Action C (运行) → 自动取消Action B

结果：
- 只有Action C完成
- 服务器只运行一次构建
- 直接部署最新版本
- 节省资源和时间
```

---

## 🎯 实际效果

### 示例：快速修复3个bug

```bash
# 连续push 3次
git commit -m "Fix bug 1" && git push
git commit -m "Fix bug 2" && git push
git commit -m "Fix bug 3" && git push
```

**不使用并发控制**：
```
Action 1: 构建bug1版本 (5分钟) → 部署
Action 2: 构建bug2版本 (5分钟) → 部署  ⚠️ bug1的修复被覆盖
Action 3: 构建bug3版本 (5分钟) → 部署  ⚠️ bug2的修复被覆盖

总耗时：15分钟
部署次数：3次
网站不稳定时间：长
```

**使用并发控制** ✅：
```
Action 1: 开始构建... → 被取消
Action 2: 开始构建... → 被取消
Action 3: 构建bug3版本 (5分钟) → 部署  ✅ 包含所有3个修复

总耗时：5分钟
部署次数：1次
网站不稳定时间：短
```

---

## 🔍 如何查看部署状态

### GitHub Actions 页面

访问：`https://github.com/[用户名]/[仓库名]/actions`

**状态标识**：
- 🟡 **黄色圆圈** - 正在运行
- ❌ **红色X** - 被取消或失败
- ✅ **绿色勾** - 成功完成
- ⚪ **灰色圆圈** - 等待中

**取消标识**：
```
⚠️ This workflow run was cancelled
```

### 实际示例

```
✅ Deploy to Server #45 (3e4ae23) - Success
   Deployed: Add security options comparison document

❌ Deploy to Server #44 (0464087) - Cancelled
   Reason: Superseded by newer deployment

❌ Deploy to Server #43 (0f97b1b) - Cancelled
   Reason: Superseded by newer deployment
```

---

## ⚙️ 高级配置

### 选项1：排队而不是取消

如果你希望所有部署都执行（按顺序排队）：

```yaml
concurrency:
  group: production-deployment
  cancel-in-progress: false  # 改为 false
```

**效果**：
- Action A 运行完成
- Action B 等待A完成后运行
- Action C 等待B完成后运行

**缺点**：
- ❌ 浪费时间（部署中间版本）
- ❌ 网站频繁重启

**不推荐用于生产部署**

---

### 选项2：分支级别的并发控制

如果有多个分支（如dev、staging、production）：

```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: true
```

**效果**：
- `main` 分支的部署不会影响 `dev` 分支
- 每个分支独立管理并发

---

## 📝 最佳实践

### ✅ 推荐做法

1. **生产环境**：使用 `cancel-in-progress: true`
   - 总是部署最新代码
   - 避免资源浪费

2. **合并多个小改动**：
   ```bash
   # 不推荐
   git commit -m "Fix typo 1" && git push
   git commit -m "Fix typo 2" && git push
   git commit -m "Fix typo 3" && git push

   # 推荐
   git commit -m "Fix typos"  # 包含所有修改
   git push  # 只触发一次部署
   ```

3. **查看部署状态**：
   - push后访问 GitHub Actions 页面
   - 确认只有最新的Action在运行

### ❌ 避免的做法

1. 不要在部署期间频繁push
2. 不要手动取消正在运行的Action（会自动取消）
3. 不要同时运行多个手动部署

---

## 🛠️ 故障排查

### 问题1：Action被意外取消

**现象**：你push了commit A，但它被自动取消了

**原因**：在A运行期间，又push了commit B

**解决**：
- 这是正常行为
- B包含了A的所有更改
- 最终部署的是最新代码

---

### 问题2：想要部署特定的旧commit

**解决方案**：
1. 使用 `git revert` 回退到该commit
2. 或者创建新分支部署：
   ```bash
   git checkout -b hotfix <commit-hash>
   git push origin hotfix
   ```

---

## 📚 参考资料

- [GitHub Actions - Concurrency](https://docs.github.com/en/actions/using-jobs/using-concurrency)
- [Workflow syntax - concurrency](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency)

---

## 总结

添加并发控制后：
- ✅ 避免部署冲突
- ✅ 节省CI/CD资源
- ✅ 减少网站重启次数
- ✅ 始终部署最新代码
- ✅ 提升部署可靠性

**关键配置**：
```yaml
concurrency:
  group: production-deployment
  cancel-in-progress: true
```

这是生产环境部署的**必备配置**！
