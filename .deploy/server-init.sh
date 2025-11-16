#!/bin/bash
#########################################################################
# 服务器初始化脚本
# 在全新的远程服务器上运行，安装 Docker 和必要的工具
#########################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检测操作系统
detect_os() {
    log_step "检测操作系统..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        log_info "操作系统: $OS $VER"
    else
        log_error "无法检测操作系统"
        exit 1
    fi
}

# 更新系统
update_system() {
    log_step "更新系统包..."
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get upgrade -y
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum update -y
            ;;
        *)
            log_warn "未识别的系统，跳过更新"
            ;;
    esac
}

# 安装基础工具
install_basic_tools() {
    log_step "安装基础工具..."
    case $OS in
        ubuntu|debian)
            sudo apt-get install -y \
                curl \
                wget \
                git \
                vim \
                ca-certificates \
                gnupg \
                lsb-release
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum install -y \
                curl \
                wget \
                git \
                vim \
                ca-certificates
            ;;
    esac
}

# 安装 Docker
install_docker() {
    log_step "检查 Docker 安装状态..."

    if command -v docker &> /dev/null; then
        log_warn "Docker 已安装，版本: $(docker --version)"
        read -p "是否重新安装 Docker? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    log_step "安装 Docker..."

    case $OS in
        ubuntu|debian)
            # 卸载旧版本
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

            # 安装依赖
            sudo apt-get update
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release

            # 添加 Docker 官方 GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

            # 设置仓库
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # 安装 Docker Engine
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        centos|rhel|rocky|almalinux)
            # 卸载旧版本
            sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest \
                docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true

            # 安装依赖
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

            # 安装 Docker Engine
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
    esac

    # 启动 Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    log_info "Docker 安装完成: $(docker --version)"
}

# 配置 Docker 用户权限
configure_docker_user() {
    log_step "配置 Docker 用户权限..."

    # 将当前用户添加到 docker 组
    sudo usermod -aG docker $USER

    log_warn "需要重新登录才能使用 Docker 而无需 sudo"
    log_warn "或者运行: newgrp docker"
}

# 安装 Docker Compose (如果需要)
install_docker_compose_standalone() {
    log_step "检查 Docker Compose..."

    if docker compose version &> /dev/null; then
        log_info "Docker Compose (插件版本) 已安装"
        return
    fi

    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose (独立版本) 已安装: $(docker-compose --version)"
        return
    fi

    log_step "安装 Docker Compose..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    log_info "Docker Compose 安装完成: $(docker-compose --version)"
}

# 配置防火墙
configure_firewall() {
    log_step "配置防火墙（开放 8111 端口）..."

    # UFW (Ubuntu/Debian)
    if command -v ufw &> /dev/null; then
        sudo ufw allow 8111/tcp
        sudo ufw status
    # firewalld (CentOS/RHEL)
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=8111/tcp
        sudo firewall-cmd --reload
        sudo firewall-cmd --list-ports
    else
        log_warn "未找到防火墙工具，请手动开放 8111 端口"
    fi
}

# 创建部署目录
create_deploy_directory() {
    log_step "创建部署目录..."

    DEPLOY_DIR="${HOME}/mkdocs-deploy"
    mkdir -p $DEPLOY_DIR

    log_info "部署目录: $DEPLOY_DIR"
    echo "export DEPLOY_PATH=$DEPLOY_DIR" >> ~/.bashrc
}

# 测试 Docker 安装
test_docker() {
    log_step "测试 Docker 安装..."

    # 临时使用 newgrp 运行 docker 命令
    if docker run --rm hello-world &> /dev/null; then
        log_info "✓ Docker 测试成功"
    else
        log_warn "Docker 测试失败，可能需要重新登录"
    fi
}

# 显示后续步骤
show_next_steps() {
    echo ""
    echo "=========================================="
    log_info "服务器初始化完成！"
    echo "=========================================="
    echo ""
    echo "后续步骤:"
    echo ""
    echo "1. 退出当前 SSH 会话并重新登录（使 Docker 权限生效）"
    echo "   或运行: newgrp docker"
    echo ""
    echo "2. 在 GitLab 中配置 CI/CD 变量:"
    echo "   - SSH_PRIVATE_KEY: SSH 私钥"
    echo "   - SERVER_HOST: 服务器 IP 或域名"
    echo "   - SERVER_USER: SSH 用户名"
    echo "   - DEPLOY_PATH: $DEPLOY_DIR"
    echo ""
    echo "3. 推送代码到 GitLab，触发 CI/CD 流水线"
    echo ""
    echo "4. 部署完成后访问: http://$(hostname -I | awk '{print $1}'):8111"
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "MkDocs 服务器初始化脚本"
    echo "=========================================="
    echo ""

    detect_os
    update_system
    install_basic_tools
    install_docker
    configure_docker_user
    install_docker_compose_standalone
    configure_firewall
    create_deploy_directory
    test_docker
    show_next_steps
}

# 执行主函数
main
