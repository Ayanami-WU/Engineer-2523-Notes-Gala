#!/bin/bash
#########################################################################
# Docker 部署脚本 - 在服务器上运行
# 用于部署 MkDocs Material 项目
#########################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
CONTAINER_NAME="mkdocs-notes"
IMAGE_NAME="mkdocs-notes:latest"
HOST_PORT=8111

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 是否安装
check_docker() {
    log_info "检查 Docker 安装..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装！请先安装 Docker。"
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        log_error "Docker daemon 未运行！请启动 Docker 服务。"
        exit 1
    fi

    log_info "Docker 版本: $(docker --version)"
}

# 检查 docker-compose 是否安装
check_docker_compose() {
    log_info "检查 Docker Compose 安装..."
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        log_info "使用 Docker Compose V2"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
        log_info "使用 Docker Compose V1"
    else
        log_error "Docker Compose 未安装！"
        exit 1
    fi
}

# 加载 Docker 镜像
load_image() {
    if [ -f "mkdocs-image.tar" ]; then
        log_info "加载 Docker 镜像..."
        docker load -i mkdocs-image.tar
        log_info "镜像加载完成"
    else
        log_warn "未找到 mkdocs-image.tar，跳过镜像加载"
    fi
}

# 停止旧容器
stop_old_container() {
    log_info "停止旧容器..."
    if [ -f "docker-compose.yml" ]; then
        $COMPOSE_CMD down 2>/dev/null || true
    else
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
    fi
}

# 启动新容器
start_container() {
    log_info "启动新容器..."
    if [ -f "docker-compose.yml" ]; then
        $COMPOSE_CMD up -d
    else
        docker run -d \
            --name $CONTAINER_NAME \
            --restart unless-stopped \
            -p $HOST_PORT:80 \
            $IMAGE_NAME
    fi
}

# 检查容器状态
check_status() {
    log_info "检查容器状态..."
    sleep 2

    if docker ps | grep -q $CONTAINER_NAME; then
        log_info "✓ 容器运行中"
        docker ps | grep $CONTAINER_NAME

        # 获取服务器 IP
        SERVER_IP=$(hostname -I | awk '{print $1}')
        log_info ""
        log_info "=========================================="
        log_info "部署成功！"
        log_info "访问地址: http://${SERVER_IP}:${HOST_PORT}"
        log_info "=========================================="
    else
        log_error "✗ 容器未运行"
        log_error "查看日志: docker logs $CONTAINER_NAME"
        exit 1
    fi
}

# 清理旧镜像
cleanup() {
    log_info "清理未使用的镜像..."
    docker image prune -f
}

# 主函数
main() {
    echo "=========================================="
    echo "MkDocs Docker 部署脚本"
    echo "=========================================="

    check_docker
    check_docker_compose
    load_image
    stop_old_container
    start_container
    check_status
    cleanup

    log_info "部署完成！"
}

# 执行主函数
main
