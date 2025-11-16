# 1Panel 部署指南

## 问题诊断

如果遇到 `The "glightbox" plugin is not installed` 等插件缺失错误，说明容器中没有安装所需的 MkDocs 插件。

## 解决方案

### 方法 1: 使用项目自带的 Dockerfile（推荐）

1. **在 1Panel 中创建应用时，确保选择 "使用 Dockerfile 构建"**

2. **Dockerfile 配置**:
   - 路径: 使用项目根目录的 `Dockerfile`
   - 构建上下文: `.`（当前目录）

3. **环境变量**（可选）:
   ```
   FULL=false  # 禁用某些性能密集型插件
   ```

4. **端口映射**:
   ```
   容器端口: 80
   主机端口: 8111 (或其他可用端口)
   ```

### 方法 2: 使用 Docker Compose（推荐）

直接使用项目中的 `docker-compose.yml` 文件：

```bash
# 在项目目录下运行
docker-compose up -d --build
```

### 方法 3: 手动验证和安装

如果你已经有一个运行中但缺少插件的容器：

1. **进入容器**:
   ```bash
   docker exec -it <container_name> sh
   ```

2. **运行验证脚本**:
   ```bash
   python verify-plugins.py
   ```

3. **如果缺少插件，手动安装**:
   ```bash
   pip install -r requirements.txt
   ```

4. **重新构建站点**:
   ```bash
   mkdocs build
   ```

## 完整的 1Panel 配置示例

### 应用设置

```yaml
应用名称: mkdocs-notes
镜像构建方式: Dockerfile
Dockerfile 路径: ./Dockerfile
端口映射:
  - 主机: 8111
  - 容器: 80
重启策略: unless-stopped
```

### 构建配置

确保 1Panel 能够访问以下文件：
- `Dockerfile` - 容器构建配置
- `requirements.txt` - Python 依赖列表
- `mkdocs.yml` - MkDocs 配置文件
- `docs/` - 文档源文件
- `overrides/` - 主题覆盖文件
- `hooks/` - 自定义钩子

## 验证安装

### 本地验证（构建前）

在构建 Docker 镜像前，可以在本地验证插件：

```bash
# 安装依赖
pip install -r requirements.txt

# 运行验证脚本
python verify-plugins.py

# 本地测试构建
mkdocs build
```

### 容器验证（构建后）

```bash
# 查看容器日志
docker logs <container_name>

# 进入容器检查
docker exec -it <container_name> sh

# 在容器内验证
python verify-plugins.py
```

## 常见问题

### Q1: 为什么会缺少插件？

**原因**:
- 使用了基础的 `squidfunk/mkdocs-material` 镜像，没有安装额外插件
- 1Panel 默认可能不会使用项目的 Dockerfile

**解决**:
- 确保在 1Panel 中选择"使用 Dockerfile 构建"
- 或手动进入容器安装 `pip install -r requirements.txt`

### Q2: 构建失败怎么办？

**检查步骤**:
1. 查看构建日志，定位错误
2. 确保 `requirements.txt` 中的所有包都可用
3. 检查网络连接（pip 下载可能需要代理）
4. 尝试在本地先构建测试

### Q3: 某些功能不工作？

**可能原因**:
- 某些插件需要 Git 仓库（如 git-revision-date-localized）
- 某些插件默认被禁用（通过 `!ENV [FULL, false]`）

**解决**:
- 确保项目在 Git 仓库中
- 设置环境变量 `FULL=true` 启用所有功能

## 推荐的 1Panel 配置流程

1. **上传项目文件到服务器**
2. **在 1Panel 中创建新应用**
   - 选择 "从 Dockerfile 构建"
   - 选择项目目录
3. **配置端口映射**: 80 -> 8111
4. **构建并启动**
5. **验证**: 访问 `http://your-server:8111`

## 性能优化建议

对于生产环境：

1. **禁用开发功能**:
   ```bash
   FULL=false  # 禁用 RSS、Git 日期等性能密集型功能
   ```

2. **使用多阶段构建**（已在 Dockerfile 中实现）:
   - Stage 1: 使用 MkDocs 构建静态文件
   - Stage 2: 使用 Nginx 轻量级镜像提供服务

3. **CDN 资源**:
   - 项目已配置使用 CDN (tonycrane.cc)
   - KaTeX, 字体等资源从 CDN 加载

## 技术支持

如遇到问题：
1. 运行 `verify-plugins.py` 检查插件状态
2. 查看容器日志 `docker logs <container>`
3. 检查 `mkdocs.yml` 配置是否正确
4. 确认所有文件都正确复制到容器中
