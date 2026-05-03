# 工试2523の笔记本

> 📚 浙江大学工科试验班 2523 课程笔记与资料整理

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
- **微积分（甲）** - 拆分为甲 I / 甲 II 两套资料入口
  - 甲 I：旧版笔记、习题课讲义、历年卷、真题
  - 甲 II：本学期期中期末、小测整理

- **线性代数** - 矩阵、向量空间、线性变换
  - 复习大纲、公式手册、真题、考试宝典

### 💻 计算机类
- **C程序设计** - C语言编程基础与实践
  - Hydrofoil笔记、上机题目(165+)、历年卷、考试宝典

### 📏 工程类
- **工程图学** - 工程制图原理与技术标准
  - Draba_Chen笔记、背诵资料、期中期末真题、考试宝典

- **机械制图** - 机械图样阅读与习题资料
  - 图纸资料、习题答案、图片打包资源

### 🗣️ 语言类
- **大学英语** - 英语综合能力提升
  - 默写器、单词表

### 🔬 理学与通识
- **常微分方程** - 微分方程基础与历年卷
  - 多份课程笔记、英文 ODE 历年卷

- **大学物理（甲）I** - 力学、热学与电磁学基础
  - 讲义、期中真题、期末真题

- **人工智能基础（A）** - 人工智能入门课程资料
  - 讲义、课件分卷 ZIP

- **形势与政策I** - 课程笔记与复习资料
  - 笔记、时事资料、考前背诵

---

## 📂 项目结构

```
.
├── docs/                      # 文档源文件目录
│   ├── index.md              # 网站首页
│   ├── calculus/             # 微积分（甲）
│   │   ├── index.md         # 课程切换入口
│   │   ├── i.md             # 微积分（甲）I
│   │   ├── ii.md            # 微积分（甲）II
│   │   └── *.pdf            # PDF 资料
│   ├── linear-algebra/       # 线性代数
│   ├── c-programming/        # C程序设计
│   ├── engineering-graphics/ # 工程图学
│   ├── college-english/      # 大学英语
│   ├── ode/                  # 常微分方程
│   ├── physics/              # 大学物理
│   ├── mechanical-drawing/   # 机械制图
│   ├── ai-fundamentals/      # 人工智能基础
│   ├── politics/             # 形势与政策
│   ├── assets/              # 静态资源
│   │   ├── images/          # 图片素材
│   │   └── files/           # 文件资料
│   ├── css/                 # 自定义样式
│   └── js/                  # 自定义脚本
├── .deploy/                  # 部署相关配置
│   ├── Caddyfile            # Caddy 静态站模板
│   └── server-init.sh       # 服务器初始化脚本
├── overrides/               # 主题自定义覆盖
├── hooks/                   # MkDocs 钩子脚本
├── mkdocs.yml              # MkDocs 配置文件
├── requirements.txt        # Python 依赖
├── Dockerfile              # 本地容器化预览配置
├── docker-compose.yml      # 本地容器化预览配置
└── .github/                # GitHub Actions 工作流
    └── workflows/
        ├── ci.yml          # 严格构建与校验
        └── deploy.yml      # 静态站部署
```

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
| **Docker** | 本地预览 |
| **GitHub Actions** | CI/CD 自动化部署 |
| **Caddy** | 生产静态文件托管 |

---

## 📖 更多信息

### 部署说明
本项目使用 GitHub Actions 进行 CI/CD：
- `ci.yml` 负责严格构建与大文件校验
- `deploy.yml` 负责构建 `site/` 并上传到服务器

生产环境由 Caddy 直接托管静态产物，服务器端不再执行 `git pull` 或 Docker 构建。

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
