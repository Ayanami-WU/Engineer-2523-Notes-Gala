# 工试2523の笔记本

> 📚 浙江大学工程试验班 2523 课程笔记与资料整理

这是一个基于 [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) 构建的在线笔记网站，整理并分享大学课程的学习笔记、考试资料和学习心得。

## ✨ 项目特色

- 📖 **系统整理** - 按课程分类整理笔记和资料
- 🎨 **优雅界面** - 基于 Material Design 的现代化 UI
- 🔍 **快速搜索** - 支持中文分词的全文搜索
- 📱 **响应式设计** - 完美适配电脑、平板和手机
- 🌓 **暗色模式** - 支持浅色/暗色主题切换
- 📥 **资料下载** - 提供 PDF、代码等学习资料下载

---

## 📚 课程目录

### 📐 数学类
- **微积分** - 函数、极限、导数、积分等基础知识
  - 檠荛的微积分笔记、习题集、历年卷、真题

- **线性代数** - 矩阵、向量空间、线性变换
  - 复习大纲、公式手册、真题、考试宝典

### 💻 计算机类
- **C程序设计** - C语言编程基础与实践
  - Hydrofoil笔记、上机题目(165+)、历年卷、考试宝典

### 📏 工程类
- **工程图学** - 工程制图原理与技术标准
  - Draba_Chen笔记、背诵资料、期中期末真题、考试宝典

### 🗣️ 语言类
- **大学英语** - 英语综合能力提升
  - 默写器、单词表

---

## 📂 项目结构

```
.
├── docs/                      # 文档源文件目录
│   ├── index.md              # 网站首页
│   ├── calculus/             # 微积分
│   │   ├── index.md         # 课程主页（含资料列表）
│   │   ├── *.pdf            # PDF 资料
│   │   └── 真题/            # 真题文件夹
│   ├── linear-algebra/       # 线性代数
│   ├── c-programming/        # C程序设计
│   ├── engineering-graphics/ # 工程图学
│   ├── college-english/      # 大学英语
│   ├── assets/              # 静态资源
│   │   ├── images/          # 图片素材
│   │   └── files/           # 文件资料
│   ├── css/                 # 自定义样式
│   └── js/                  # 自定义脚本
├── .deploy/                  # 部署相关文档和脚本
│   ├── DEPLOY_NOW.md        # 部署指南
│   └── *.sh                 # 部署脚本
├── overrides/               # 主题自定义覆盖
├── hooks/                   # MkDocs 钩子脚本
├── mkdocs.yml              # MkDocs 配置文件
├── requirements.txt        # Python 依赖
├── Dockerfile              # Docker 镜像配置
├── docker-compose.yml      # Docker Compose 配置
└── .github/                # GitHub Actions 工作流
    └── workflows/
        └── deploy.yml      # 自动部署配置
```

---

## 🚀 快速开始

### 在线访问

访问已部署的网站：`http://your-server-ip:8111`

### 本地预览

使用 Docker 快速启动本地预览：

```bash
docker run --rm -it \
  -v $(pwd):/docs \
  -p 8000:8000 \
  squidfunk/mkdocs-material:9.7.0 \
  sh -c "pip install -r requirements.txt && mkdocs serve -a 0.0.0.0:8000"
```

然后访问 `http://localhost:8000`

---

## 📝 如何使用

### 浏览笔记
1. 访问网站首页
2. 从导航栏选择感兴趣的课程
3. 在课程页面查看笔记目录和资料列表

### 下载资料
每门课程的主页（`index.md`）都提供了资料列表，点击下载图标即可获取 PDF、文档等资料。

### 搜索内容
使用页面顶部的搜索框，支持中文关键词搜索。

---

## 🛠️ 技术栈

| 技术 | 用途 |
|------|------|
| **MkDocs** | 静态网站生成器 |
| **Material for MkDocs** | Material Design 主题 |
| **Python-Markdown** | Markdown 解析与扩展 |
| **KaTeX** | 数学公式渲染 |
| **Docker** | 容器化部署 |
| **GitHub Actions** | CI/CD 自动化部署 |
| **Nginx** | Web 服务器 |

---

## 📖 更多信息

### 部署说明
详细的部署文档请查看 [.deploy/](.deploy/) 目录：
- `.deploy/DEPLOY_NOW.md` - 完整部署指南
- `.deploy/QUICK_GITHUB_SETUP.md` - 快速设置指南

### 模板来源
本项目基于 [TonyCrane/note](https://github.com/TonyCrane/note) 模板构建，在此表示感谢！

### 参考文档
- [MkDocs 官方文档](https://www.mkdocs.org/)
- [Material for MkDocs 文档](https://squidfunk.github.io/mkdocs-material/)
- [Markdown 语法指南](https://markdown.com.cn/)

---

## 📜 许可证

本项目采用以下许可：
- **笔记内容**: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- **代码部分**: [MIT License](LICENSE)
- **原始模板**: 遵循 [TonyCrane/note](https://github.com/TonyCrane/note) 许可

---

## 🤝 贡献

欢迎提出建议和改进！如有问题请提交 Issue 或 Pull Request。

---

## 📧 联系方式

- **GitHub**: [@Ayanami-WU](https://github.com/Ayanami-WU)
- **邮箱**: wumingxuan@zju.edu.cn

---

<div align="center">

**📚 祝学习愉快！✨**

Made with ❤️ by 工试2523

</div>
