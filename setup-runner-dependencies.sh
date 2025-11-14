#!/bin/bash
# 在 GitLab Runner 机器上安装依赖
# 适用于 Shell Executor
# 支持 Ubuntu/Debian 系统

set -e

echo "=========================================="
echo "GitLab Runner 依赖安装脚本"
echo "=========================================="
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo -e "${RED}无法检测操作系统${NC}"
    exit 1
fi

echo "检测到操作系统: $OS $VER"
echo ""

# 检测包管理器
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    UPDATE_CMD="apt-get update"
    INSTALL_CMD="apt-get install -y"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    UPDATE_CMD="yum check-update || true"
    INSTALL_CMD="yum install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="dnf check-update || true"
    INSTALL_CMD="dnf install -y"
else
    echo -e "${RED}不支持的包管理器${NC}"
    exit 1
fi

echo "使用包管理器: $PKG_MANAGER"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}提示: 某些操作可能需要 sudo 权限${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

echo -e "${GREEN}步骤 1/5: 更新包索引${NC}"
$SUDO $UPDATE_CMD

echo ""
echo -e "${GREEN}步骤 2/5: 安装 Python 3${NC}"
if command -v python3 &> /dev/null; then
    echo "Python 3 已安装: $(python3 --version)"
else
    $SUDO $INSTALL_CMD python3 python3-pip python3-venv
fi

echo ""
echo -e "${GREEN}步骤 3/5: 安装 pip${NC}"
if command -v pip3 &> /dev/null || python3 -m pip --version &> /dev/null; then
    echo "pip 已安装: $(python3 -m pip --version)"
else
    $SUDO $INSTALL_CMD python3-pip
fi

echo ""
echo -e "${GREEN}步骤 4/5: 安装 rsync 和 SSH 工具${NC}"
$SUDO $INSTALL_CMD rsync openssh-client

echo ""
echo -e "${GREEN}步骤 5/5: 安装 MkDocs 和依赖${NC}"

# 选择安装方式
if [ "$EUID" -eq 0 ]; then
    # Root 用户，全局安装
    pip3 install mkdocs mkdocs-material
else
    # 普通用户，用户级安装
    python3 -m pip install --user mkdocs mkdocs-material

    # 添加用户 bin 目录到 PATH（针对 gitlab-runner 用户）
    if [ -d "$HOME/.local/bin" ]; then
        if ! echo $PATH | grep -q "$HOME/.local/bin"; then
            echo ""
            echo -e "${YELLOW}注意: 需要将 ~/.local/bin 添加到 PATH${NC}"
            echo "运行以下命令（或添加到 ~/.bashrc）："
            echo "export PATH=\$PATH:\$HOME/.local/bin"
        fi
    fi
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✓ 安装完成！"
echo "==========================================${NC}"
echo ""

# 验证安装
echo -e "${GREEN}验证安装:${NC}"
echo ""

echo -n "Python 3: "
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓ $(python3 --version)${NC}"
else
    echo -e "${RED}✗ 未找到${NC}"
fi

echo -n "pip: "
if python3 -m pip --version &> /dev/null; then
    echo -e "${GREEN}✓ $(python3 -m pip --version)${NC}"
else
    echo -e "${RED}✗ 未找到${NC}"
fi

echo -n "mkdocs: "
export PATH=$PATH:$HOME/.local/bin
if command -v mkdocs &> /dev/null; then
    echo -e "${GREEN}✓ $(mkdocs --version)${NC}"
else
    echo -e "${RED}✗ 未找到（可能需要添加 ~/.local/bin 到 PATH）${NC}"
fi

echo -n "rsync: "
if command -v rsync &> /dev/null; then
    echo -e "${GREEN}✓ $(rsync --version | head -1)${NC}"
else
    echo -e "${RED}✗ 未找到${NC}"
fi

echo -n "ssh: "
if command -v ssh &> /dev/null; then
    echo -e "${GREEN}✓ $(ssh -V 2>&1)${NC}"
else
    echo -e "${RED}✗ 未找到${NC}"
fi

echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "1. 确保 GitLab Runner 正在运行"
echo "2. 如果使用非 root 用户运行 Runner，确保 PATH 包含 ~/.local/bin"
echo "3. 推送代码到 GitLab 触发 Pipeline"
echo ""
