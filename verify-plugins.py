#!/usr/bin/env python3
"""
MkDocs Plugins Verification Script
检查所有必需的 MkDocs 插件是否正确安装
"""

import sys
import importlib.util

# 定义所有必需的插件
REQUIRED_PLUGINS = [
    ('mkdocs', 'MkDocs Core'),
    ('material', 'Material Theme'),
    ('mkdocs_glightbox', 'GLightbox Plugin'),
    ('mkdocs_rss_plugin', 'RSS Plugin'),
    ('mkdocs_git_revision_date_localized_plugin', 'Git Revision Date Plugin'),
    ('mkdocs_changelog_plugin', 'Changelog Plugin'),
    ('mkdocs_heti_plugin', 'Heti Plugin'),
    ('mkdocs_statistics_plugin', 'Statistics Plugin'),
]

# 可选但推荐的依赖
OPTIONAL_DEPENDENCIES = [
    ('yaml', 'PyYAML'),
    ('jinja2', 'Jinja2'),
    ('markdown', 'Markdown'),
    ('pygments', 'Pygments'),
    ('pymdownx', 'PyMdown Extensions'),
    ('bs4', 'BeautifulSoup4'),
    ('lxml', 'lxml'),
]

def check_module(module_name, display_name):
    """检查模块是否可以导入"""
    try:
        spec = importlib.util.find_spec(module_name)
        if spec is not None:
            module = importlib.import_module(module_name)
            version = getattr(module, '__version__', 'unknown')
            print(f"✓ {display_name:40} (version: {version})")
            return True
        else:
            print(f"✗ {display_name:40} NOT FOUND")
            return False
    except Exception as e:
        print(f"✗ {display_name:40} ERROR: {str(e)}")
        return False

def main():
    print("=" * 70)
    print("MkDocs 插件验证检查")
    print("=" * 70)

    print("\n检查必需的插件:")
    print("-" * 70)

    all_required_ok = True
    for module_name, display_name in REQUIRED_PLUGINS:
        if not check_module(module_name, display_name):
            all_required_ok = False

    print("\n检查可选依赖:")
    print("-" * 70)

    optional_ok_count = 0
    for module_name, display_name in OPTIONAL_DEPENDENCIES:
        if check_module(module_name, display_name):
            optional_ok_count += 1

    print("\n" + "=" * 70)
    print("检查结果:")
    print("=" * 70)

    if all_required_ok:
        print("✓ 所有必需的插件都已正确安装!")
    else:
        print("✗ 某些必需的插件缺失，请运行以下命令安装:")
        print("  pip install -r requirements.txt")

    print(f"\n可选依赖: {optional_ok_count}/{len(OPTIONAL_DEPENDENCIES)} 已安装")

    if not all_required_ok:
        sys.exit(1)

    print("\n尝试加载 MkDocs 配置...")
    try:
        import mkdocs.config
        import mkdocs.plugins
        print("✓ MkDocs 配置模块加载成功!")
    except Exception as e:
        print(f"✗ MkDocs 配置模块加载失败: {e}")
        sys.exit(1)

    print("\n" + "=" * 70)
    print("所有检查通过! 可以运行 mkdocs build/serve")
    print("=" * 70)

if __name__ == '__main__':
    main()
