# 字体测试页面

<style>
.font-test {
  border: 2px solid #ccc;
  padding: 20px;
  margin: 20px 0;
  border-radius: 8px;
}

.jetbrains {
  font-family: "JetBrains Mono" !important;
}

.lxgw {
  font-family: "LXGW WenKai Screen" !important;
}

.combined {
  font-family: "JetBrains Mono", "LXGW WenKai Screen" !important;
}
</style>

## 字体加载诊断

### 测试1: JetBrains Mono

<div class="font-test jetbrains">
ABCDEFGhijklmn 1234567890
这是中文测试 The Quick Brown Fox
</div>

### 测试2: LXGW WenKai Screen

<div class="font-test lxgw">
ABCDEFGhijklmn 1234567890
这是中文测试 The Quick Brown Fox
鹅翔万里的笔记本
</div>

### 测试3: 组合字体 (当前配置)

<div class="font-test combined">
ABCDEFGhijklmn 1234567890
这是中文测试 The Quick Brown Fox
鹅翔万里的笔记本
程序设计与算法基础
</div>

### 测试4: 默认样式

<div class="font-test">
ABCDEFGhijklmn 1234567890
这是中文测试 The Quick Brown Fox
鹅翔万里的笔记本
程序设计与算法基础
</div>

## 调试信息

打开浏览器开发者工具 (F12)，查看：

1. **Network 标签页** - 检查以下资源是否成功加载 (状态200):
   - `https://cdn.tonycrane.cc/jbmono/jetbrainsmono.css`
   - `https://cdn.tonycrane.cc/lxgw/lxgwscreen.css`
   - 各个 `.woff2` 字体文件

2. **Console 标签页** - 是否有字体加载错误

3. **Elements 标签页** - 选中文字，在 Computed 面板查看实际使用的 `font-family`

## CSS 变量检查

<script>
document.addEventListener('DOMContentLoaded', function() {
  const root = document.documentElement;
  const textFont = getComputedStyle(root).getPropertyValue('--md-text-font');
  const codeFont = getComputedStyle(root).getPropertyValue('--md-code-font');

  console.log('Text Font:', textFont);
  console.log('Code Font:', codeFont);

  const info = document.getElementById('css-vars-info');
  if (info) {
    info.innerHTML = `
      <li>--md-text-font: <code>${textFont}</code></li>
      <li>--md-code-font: <code>${codeFont}</code></li>
    `;
  }
});
</script>

<ul id="css-vars-info">
  <li>加载中...</li>
</ul>
