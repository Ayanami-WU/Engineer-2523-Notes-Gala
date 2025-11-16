# Docker 构建缓存优化策略

## 问题背景

之前使用 `docker build --no-cache` 强制重新构建所有层，导致：
- ❌ 每次都重新下载和安装 Python 依赖（~2-3分钟）
- ❌ 可能触发 PyPI 速率限制
- ❌ GitHub Actions 部署时间过长

## 优化方案

### 智能层缓存策略

通过在 Dockerfile 中使用 `ARG CACHEBUST`，实现：
- ✅ **缓存 Python 依赖层**：只在 `requirements.txt` 变化时重装
- ✅ **强制更新文档层**：每次都获取最新的文档内容
- ✅ **大幅提速**：构建时间从 5-8分钟降至 1-2分钟

### Dockerfile 结构

```dockerfile
# 1. 复制 requirements.txt
COPY requirements.txt .

# 2. 安装依赖（会被缓存）
RUN pip install -r requirements.txt

# 3. 缓存破坏点
ARG CACHEBUST=1

# 4. 复制文档（每次都重新执行）
COPY . .

# 5. 构建站点
RUN mkdocs build
```

### 工作原理

1. **第1-2步**：Docker 会缓存这些层，除非 `requirements.txt` 文件内容变化
2. **第3步**：`CACHEBUST` 参数每次构建时都不同（使用时间戳），使后续所有层失效
3. **第4-5步**：强制重新执行，确保获取最新文档内容

### 构建命令

```bash
# 传递时间戳作为 CACHEBUST 参数
docker build --build-arg CACHEBUST=$(date +%s) -t mkdocs-notes:latest .
```

## 性能对比

| 策略 | 构建时间 | 依赖缓存 | 文档更新 |
|------|---------|---------|---------|
| `--no-cache` | 5-8分钟 | ❌ 每次重装 | ✅ 强制更新 |
| 智能缓存 | 1-2分钟 | ✅ 智能缓存 | ✅ 强制更新 |

## 何时完全重建

如果需要完全重建（例如更新了 `requirements.txt`），Docker 会自动检测到文件变化并重装依赖。

也可以手动强制完全重建：
```bash
docker build --no-cache -t mkdocs-notes:latest .
```

## 参考资料

- [Docker BuildKit Cache Mounts](https://docs.docker.com/build/cache/)
- [Multi-stage Build Best Practices](https://docs.docker.com/build/building/multi-stage/)
