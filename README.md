# 我的课程笔记本

这是一个基于 [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) 构建的课程笔记网站，使用 [TonyCrane/note](https://github.com/TonyCrane/note) 模板。

## 📚 课程列表

本笔记本包含以下课程：

- **微积分** - 微积分基础知识和应用
- **线性代数** - 矩阵、向量空间、线性变换等
- **C程序设计** - C语言编程基础和实践
- **工程图学** - 工程制图原理和技术标准
- **大学英语** - 英语综合能力提升

## 🚀 快速开始

### 本地预览

使用 Docker 在本地运行开发服务器：

```bash
# 安装依赖并启动开发服务器
docker run --rm -it \
  -v $(pwd):/docs \
  -p 8000:8000 \
  squidfunk/mkdocs-material:9.7.0 \
  sh -c "pip install -r requirements.txt && mkdocs serve -a 0.0.0.0:8000"
```

然后访问 `http://localhost:8000` 查看网站。

### 构建静态网站

```bash
# 构建静态 HTML 文件到 site/ 目录
docker run --rm -v $(pwd):/docs \
  squidfunk/mkdocs-material:9.7.0 \
  sh -c "pip install -r requirements.txt && mkdocs build"
```

## 📝 编写笔记

### 目录结构

```
docs/
├── index.md                    # 首页
├── calculus/                   # 微积分
│   └── index.md
├── linear-algebra/             # 线性代数
│   └── index.md
├── c-programming/              # C程序设计
│   └── index.md
├── engineering-graphics/       # 工程图学
│   └── index.md
└── college-english/            # 大学英语
    └── index.md
```

### 添加新笔记

1. 在对应课程目录下创建 Markdown 文件：

```bash
# 例如：添加微积分第一章
vim docs/calculus/chapter1.md
```

2. 在 `mkdocs.yml` 的 `nav` 部分添加导航链接：

```yaml
nav:
  - 首页: index.md
  - 微积分:
      - calculus/index.md
      - 第一章: calculus/chapter1.md  # 新增
  # ...其他课程
```

3. 提交并推送到 GitLab：

```bash
git add .
git commit -m "添加微积分第一章笔记"
git push
```

推送后，GitLab CI/CD 会自动构建并部署到服务器！

### Markdown 语法

支持丰富的 Markdown 扩展语法：

#### 1. 数学公式

行内公式：`$E = mc^2$` → $E = mc^2$

块级公式：
```markdown
$$
\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
$$
```

#### 2. 代码高亮

```python
def hello_world():
    print("Hello, World!")
```

#### 3. 提示框

```markdown
!!! note "提示"
    这是一个提示框

!!! warning "警告"
    这是一个警告框

!!! tip "技巧"
    这是一个技巧框
```

#### 4. 任务列表

```markdown
- [x] 已完成的任务
- [ ] 待完成的任务
```

#### 5. 表格

```markdown
| 标题1 | 标题2 | 标题3 |
|-------|-------|-------|
| 内容1 | 内容2 | 内容3 |
```

更多语法请参考 [MkDocs Material 文档](https://squidfunk.github.io/mkdocs-material/reference/)。

## 🔧 配置说明

### 基本配置

编辑 `mkdocs.yml` 文件修改网站配置：

```yaml
# 网站信息
site_name: 我的课程笔记本
site_url: https://your-domain.com/
site_description: 我的大学课程学习笔记

# 主题配置
theme:
  name: material
  language: zh  # 中文界面

# 插件
plugins:
  - search          # 搜索功能
  - glightbox       # 图片灯箱
  # ...其他插件
```

### 自定义样式

自定义 CSS 文件位于 `docs/css/` 目录：

- `docs/css/custom.css` - 自定义样式
- `docs/css/tasklist.css` - 任务列表样式
- `docs/css/card.css` - 卡片样式

### 图片资源

将图片放在 `docs/assets/images/` 目录下：

```
docs/assets/images/
├── calculus/           # 微积分相关图片
├── linear-algebra/     # 线性代数相关图片
└── ...
```

在 Markdown 中引用：

```markdown
![图片描述](../assets/images/calculus/example.png)
```

## 🚢 部署

### 方式一：自动部署（推荐）

本项目已配置 GitLab CI/CD，推送到浙大 GitLab 后自动部署到香港服务器。

**详细步骤请参阅：** 📖 [部署指南（中文）](DEPLOYMENT_CN.md)

**快速概览：**

1. **服务器准备**
   ```bash
   # 生成 SSH 密钥用于 CI/CD
   ssh-keygen -t rsa -b 4096 -C "gitlab-ci-deploy" -f ~/.ssh/gitlab-ci
   cat ~/.ssh/gitlab-ci.pub >> ~/.ssh/authorized_keys
   ```

2. **GitLab 配置**
   - 在 git.zju.edu.cn 创建项目
   - 添加 CI/CD 变量（Settings → CI/CD → Variables）：
     - `SSH_PRIVATE_KEY`: 私钥内容
     - `SERVER_HOST`: 服务器地址
     - `SERVER_USER`: SSH 用户名
     - `DEPLOY_PATH`: 部署路径

3. **推送代码**
   ```bash
   git remote add origin git@git.zju.edu.cn:your-username/notes.git
   git push -u origin master
   ```

4. **访问网站**
   ```
   http://your-server-ip:8111
   ```

### 方式二：手动部署

#### 使用 Docker

```bash
# 在服务器上
cd ~/mkdocs-notes
docker-compose up -d
```

网站将在 `http://your-server-ip:8111` 运行。

#### 使用 Nginx

```bash
# 构建网站
mkdocs build

# 复制到 Nginx 目录
sudo cp -r site/* /var/www/mkdocs-notes/

# 重载 Nginx
sudo systemctl reload nginx
```

## 📂 项目结构

```
.
├── README.md                   # 本文件（中文）
├── DEPLOYMENT.md               # 部署指南（英文）
├── DEPLOYMENT_CN.md            # 部署指南（中文）
├── mkdocs.yml                  # MkDocs 配置文件
├── requirements.txt            # Python 依赖
├── .gitlab-ci.yml              # GitLab CI/CD 配置
├── .gitlab-ci-docker.yml       # Docker 部署配置
├── Dockerfile                  # Docker 镜像配置
├── docker-compose.yml          # Docker Compose 配置
├── nginx.conf.example          # Nginx 配置示例
├── deploy.sh                   # 部署脚本
├── .gitignore                  # Git 忽略文件
├── .ignored-commits            # Git 忽略的提交
├── docs/                       # 文档源文件
│   ├── index.md               # 首页
│   ├── calculus/              # 微积分
│   ├── linear-algebra/        # 线性代数
│   ├── c-programming/         # C程序设计
│   ├── engineering-graphics/  # 工程图学
│   ├── college-english/       # 大学英语
│   ├── assets/                # 静态资源
│   │   └── images/           # 图片
│   ├── css/                   # 自定义样式
│   └── js/                    # 自定义脚本
├── overrides/                  # 主题覆盖
├── hooks/                      # MkDocs 钩子
└── site/                       # 构建输出（自动生成）
```

## 🔍 常见问题

### 1. 本地预览时提示插件缺失

确保安装了所有依赖：

```bash
pip install -r requirements.txt
```

### 2. 数学公式不显示

检查 `mkdocs.yml` 中是否启用了 `pymdownx.arithmatex` 扩展：

```yaml
markdown_extensions:
  - pymdownx.arithmatex:
      generic: true
```

### 3. 图片无法显示

- 检查图片路径是否正确（相对路径）
- 确保图片文件存在于 `docs/assets/images/` 目录
- 检查文件名大小写

### 4. 推送后网站未更新

- 检查 GitLab CI/CD Pipeline 状态
- 查看 Pipeline 日志排查错误
- 确认 CI/CD 变量配置正确

### 5. 网站样式显示异常

清除浏览器缓存或使用无痕模式访问。

## 🛠️ 开发技巧

### 实时预览

开发时启用实时预览，保存文件后自动刷新：

```bash
docker run --rm -it \
  -v $(pwd):/docs \
  -p 8000:8000 \
  squidfunk/mkdocs-material:9.7.0 \
  sh -c "pip install -r requirements.txt && mkdocs serve -a 0.0.0.0:8000"
```

### 检查链接

检查文档中的断链：

```bash
mkdocs build --strict
```

### 搜索功能

内置的搜索功能支持中文分词，会自动索引所有文档内容。

## 📖 参考资料

- [MkDocs 文档](https://www.mkdocs.org/)
- [Material for MkDocs 文档](https://squidfunk.github.io/mkdocs-material/)
- [Markdown 语法指南](https://markdown.com.cn/)
- [GitLab CI/CD 文档](https://docs.gitlab.com/ee/ci/)
- [TonyCrane/note 模板](https://github.com/TonyCrane/note)

## 📜 许可证

本项目内容遵循 [CC-BY-4.0](LICENSE) 许可证。

模板来自 [TonyCrane/note](https://github.com/TonyCrane/note)，遵循其原始许可证。

## 🤝 贡献

欢迎提出建议和改进！

## 📧 联系方式

如有问题，请通过以下方式联系：

- 提交 Issue 到 GitLab 仓库
- 邮件：your-email@example.com

---

**祝学习愉快！📚✨**
