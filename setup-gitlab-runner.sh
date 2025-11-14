#!/bin/bash
# GitLab Runner 安装脚本（在香港服务器上运行）
# 适用于 Ubuntu/Debian 系统

set -e

echo "=========================================="
echo "GitLab Runner 安装脚本"
echo "=========================================="
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 请使用 root 权限运行此脚本${NC}"
    echo "使用: sudo bash setup-gitlab-runner.sh"
    exit 1
fi

echo -e "${GREEN}步骤 1/5: 添加 GitLab Runner 官方仓库${NC}"
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash

echo ""
echo -e "${GREEN}步骤 2/5: 安装 GitLab Runner${NC}"
apt-get update
apt-get install -y gitlab-runner

echo ""
echo -e "${GREEN}步骤 3/5: 验证安装${NC}"
gitlab-runner --version

echo ""
echo -e "${GREEN}步骤 4/5: 启动 GitLab Runner 服务${NC}"
systemctl start gitlab-runner
systemctl enable gitlab-runner
systemctl status gitlab-runner --no-pager

echo ""
echo -e "${YELLOW}=========================================="
echo "安装完成！"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}下一步：注册 Runner${NC}"
echo ""
echo "1. 在 GitLab 项目中获取注册令牌："
echo "   Settings → CI/CD → Runners → Expand → New project runner"
echo ""
echo "2. 运行注册命令："
echo -e "${GREEN}   sudo gitlab-runner register${NC}"
echo ""
echo "3. 按提示输入信息："
echo "   - GitLab instance URL: https://git.zju.edu.cn"
echo "   - Registration token: [从 GitLab 页面复制]"
echo "   - Description: mkdocs-notes-runner"
echo "   - Tags: mkdocs,deploy"
echo "   - Executor: docker"
echo "   - Default Docker image: alpine:latest"
echo ""
echo -e "${YELLOW}注意事项：${NC}"
echo "1. 确保服务器可以访问 git.zju.edu.cn"
echo "2. 如果使用 Docker executor，确保已安装 Docker"
echo "3. Runner 注册后会立即可用"
echo ""
