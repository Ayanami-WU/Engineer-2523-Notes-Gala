#!/bin/bash
#########################################################################
# 服务器端 Git 拉取 + Docker 构建 + 部署脚本
# 直接在服务器上执行，避免 GitLab Runner 限制
#########################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
# 自动检测仓库 URL（支持 GitLab 和 GitHub）
if [ -n "$REPO_URL" ]; then
    # 如果环境变量已设置，使用环境变量的值
    REPO_URL="$REPO_URL"
else
    # 默认使用 GitHub（可以通过环境变量覆盖）
    REPO_URL="${REPO_URL:-https://github.com/Ayanami-WU/Engineer-2523-Notes-Gala.git}"
fi

DEPLOY_DIR="${HOME}/mkdocs-deploy"
PROJECT_DIR="${DEPLOY_DIR}/source"
CONTAINER_NAME="mkdocs-notes"
IMAGE_NAME="mkdocs-notes"
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查 Docker
check_docker() {
    log_step "检查 Docker 环境..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装！请先运行 server-init.sh"
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        log_error "Docker daemon 未运行！"
        exit 1
    fi

    log_info "Docker 版本: $(docker --version)"
}

# 检查 Git
check_git() {
    log_step "检查 Git..."

    if ! command -v git &> /dev/null; then
        log_warn "Git 未安装，正在安装..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        else
            log_error "无法自动安装 Git，请手动安装"
            exit 1
        fi
    fi

    log_info "Git 版本: $(git --version)"
}

# 创建部署目录
create_directories() {
    log_step "创建部署目录..."
    mkdir -p "$DEPLOY_DIR"
    mkdir -p "$PROJECT_DIR"
    log_info "部署目录: $DEPLOY_DIR"
}

# 克隆或更新代码
sync_code() {
    log_step "同步代码..."

    if [ -d "$PROJECT_DIR/.git" ]; then
        log_info "更新现有仓库..."
        cd "$PROJECT_DIR"

        # 保存当前分支
        CURRENT_BRANCH=$(git branch --show-current)

        # 拉取最新代码（优化：只拉取需要的分支）
        git fetch origin --depth 1
        git reset --hard origin/main || git reset --hard origin/master

        log_info "代码已更新到最新版本"
    else
        log_info "克隆仓库（使用浅克隆加速）..."
        rm -rf "$PROJECT_DIR"

        # 使用浅克隆（--depth 1）和单分支（--single-branch）加速
        # 配置 git 使用更大的缓冲区提高速度
        git clone \
            --depth 1 \
            --single-branch \
            --branch main \
            "$REPO_URL" \
            "$PROJECT_DIR" 2>&1 || \
        git clone \
            --depth 1 \
            --single-branch \
            --branch master \
            "$REPO_URL" \
            "$PROJECT_DIR"

        cd "$PROJECT_DIR"
        log_info "仓库克隆完成"
    fi

    # 显示当前提交
    log_info "当前提交: $(git log -1 --oneline)"
}

# 停止旧容器
stop_old_container() {
    log_step "停止旧容器..."

    cd "$PROJECT_DIR"

    # 如果使用 docker-compose，先尝试清理
    if [ -f "docker-compose.yml" ]; then
        log_info "使用 docker-compose 停止容器..."
        if docker compose version &> /dev/null; then
            docker compose down 2>/dev/null || true
        else
            docker-compose down 2>/dev/null || true
        fi
    fi

    # 强制清理所有同名容器（兜底策略）
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "强制清理同名容器..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
        log_info "旧容器已强制删除"
    else
        log_info "未找到旧容器"
    fi
}

# 构建 Docker 镜像
build_docker_image() {
    log_step "构建 Docker 镜像..."

    cd "$PROJECT_DIR"

    # 删除旧镜像（可选）
    if docker images | grep -q "^$IMAGE_NAME "; then
        log_info "删除旧镜像..."
        docker rmi "$IMAGE_NAME:latest" 2>/dev/null || true
    fi

    # 构建新镜像（强制重新构建，不使用缓存）
    log_info "开始构建（使用 --no-cache 强制重新构建，这可能需要几分钟）..."

    if docker build --no-cache -t "$IMAGE_NAME:latest" . 2>&1 | tee /tmp/docker-build.log; then
        log_info "✓ Docker 镜像构建成功"
    else
        log_error "✗ Docker 镜像构建失败"
        echo ""
        log_error "=== 构建日志（最后 50 行）==="
        tail -50 /tmp/docker-build.log
        echo ""
        log_error "完整日志位于: /tmp/docker-build.log"
        exit 1
    fi
}

# 启动新容器
start_container() {
    log_step "启动新容器..."

    cd "$PROJECT_DIR"

    if [ -f "docker-compose.yml" ]; then
        # 使用 docker-compose（强制重新构建和重新创建）
        if docker compose version &> /dev/null; then
            docker compose up -d --build --force-recreate
        else
            docker-compose up -d --build --force-recreate
        fi
        log_info "容器已通过 docker-compose 启动（强制重新构建）"
    else
        # 直接使用 docker run
        docker run -d \
            --name "$CONTAINER_NAME" \
            --restart unless-stopped \
            -p "$HOST_PORT:80" \
            "$IMAGE_NAME:latest"
        log_info "容器已通过 docker run 启动"
    fi
}

# 检查容器状态
check_container_status() {
    log_step "检查容器状态..."

    sleep 3

    if docker ps | grep -q "$CONTAINER_NAME"; then
        log_info "✓ 容器运行中"
        echo ""
        docker ps | grep "$CONTAINER_NAME"
        echo ""

        # 获取服务器 IP
        SERVER_IP=$(hostname -I | awk '{print $1}')

        log_info "=========================================="
        log_info "部署成功！"
        log_info ""
        log_info "访问地址:"
        log_info "  - http://localhost:$HOST_PORT"
        log_info "  - http://$SERVER_IP:$HOST_PORT"
        log_info "=========================================="
    else
        log_error "✗ 容器未运行"
        log_error "查看日志: docker logs $CONTAINER_NAME"

        # 显示最近的容器日志
        if docker ps -a | grep -q "$CONTAINER_NAME"; then
            echo ""
            log_error "=== 容器日志 ==="
            docker logs "$CONTAINER_NAME" 2>&1 | tail -20
        fi

        exit 1
    fi
}

# 清理
cleanup() {
    log_step "清理未使用的 Docker 资源..."

    # 删除未使用的镜像
    docker image prune -f

    # 删除构建缓存（可选）
    # docker builder prune -f

    log_info "清理完成"
}

# 显示日志
show_logs() {
    log_step "显示容器日志..."
    echo ""
    log_info "=== 最近 20 行日志 ==="
    docker logs --tail 20 "$CONTAINER_NAME"
    echo ""
    log_info "查看实时日志: docker logs -f $CONTAINER_NAME"
}

# 主函数
main() {
    echo "=========================================="
    echo "MkDocs 服务器端构建部署脚本"
    echo "=========================================="
    echo ""

    check_docker
    check_git
    create_directories
    sync_code
    stop_old_container
    build_docker_image
    start_container
    check_container_status
    cleanup
    show_logs

    echo ""
    log_info "=========================================="
    log_info "部署完成！"
    log_info "=========================================="
}

# 错误处理
trap 'log_error "脚本执行失败！查看上面的错误信息。"' ERR

# 执行主函数
main "$@"
