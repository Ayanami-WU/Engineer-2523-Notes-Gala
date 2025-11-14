#!/bin/bash
# 手动部署脚本 - 用于不使用 GitLab CI/CD 时的手动部署
# Manual deployment script for deploying without GitLab CI/CD

set -e

# 配置区域 - 请修改为你的服务器信息
# Configuration - modify with your server details
SERVER_USER="your-username"          # SSH 用户名
SERVER_HOST="your-server-ip"         # 服务器 IP 地址
DEPLOY_PATH="~/mkdocs-notes/site"    # 部署路径

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "MkDocs 手动部署脚本"
echo "Manual Deployment Script"
echo "==========================================${NC}"
echo ""

# 检查配置
if [ "$SERVER_USER" = "your-username" ] || [ "$SERVER_HOST" = "your-server-ip" ]; then
    echo -e "${RED}错误: 请先修改脚本中的服务器配置！${NC}"
    echo -e "${YELLOW}编辑文件: deploy-manual.sh${NC}"
    echo "修改以下变量:"
    echo "  - SERVER_USER: 你的 SSH 用户名"
    echo "  - SERVER_HOST: 你的服务器 IP"
    echo "  - DEPLOY_PATH: 服务器上的部署路径"
    exit 1
fi

echo -e "${GREEN}步骤 1/3: 构建网站${NC}"
echo "使用 Docker 构建 MkDocs 网站..."
echo ""

docker run --rm -v $(pwd):/docs \
  squidfunk/mkdocs-material:9.7.0 \
  sh -c "pip install -q -r requirements.txt && mkdocs build"

if [ $? -ne 0 ]; then
    echo -e "${RED}构建失败！请检查错误信息。${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ 构建成功！${NC}"
echo ""

echo -e "${GREEN}步骤 2/3: 测试服务器连接${NC}"
echo "测试 SSH 连接到 $SERVER_USER@$SERVER_HOST ..."
echo ""

ssh -o ConnectTimeout=5 -o BatchMode=yes $SERVER_USER@$SERVER_HOST exit 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}无法连接到服务器！${NC}"
    echo "请检查:"
    echo "  1. 服务器 IP 地址是否正确"
    echo "  2. SSH 密钥是否已配置"
    echo "  3. 服务器是否在线"
    exit 1
fi

echo -e "${GREEN}✓ 服务器连接正常${NC}"
echo ""

echo -e "${GREEN}步骤 3/3: 部署到服务器${NC}"
echo "使用 rsync 同步文件到 $SERVER_HOST:$DEPLOY_PATH ..."
echo ""

rsync -avz --delete site/ $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH

if [ $? -ne 0 ]; then
    echo -e "${RED}部署失败！请检查错误信息。${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✓ 部署成功！"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}访问你的网站:${NC}"
echo "  http://$SERVER_HOST:8111"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo "  - 如果网站未更新,请清除浏览器缓存"
echo "  - 确保 Docker Compose 正在运行: docker-compose up -d"
echo ""
