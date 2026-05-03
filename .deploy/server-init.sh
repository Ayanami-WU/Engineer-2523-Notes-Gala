#!/bin/bash
#########################################################################
# Caddy static site bootstrap for this project.
# Run once on the remote server before GitHub Actions deploys releases.
#########################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SITE_HOST="${SITE_HOST:-:8111}"
DEPLOY_PATH="${DEPLOY_PATH:-/srv/mkdocs-site}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CADDY_TEMPLATE="${CADDY_TEMPLATE:-$REPO_DIR/Caddyfile}"
TMP_CADDYFILE="$(mktemp)"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

detect_os() {
    log_step "Detecting operating system..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$ID"
        VER="${VERSION_ID:-unknown}"
        log_info "Detected: $OS $VER"
    else
        echo "Unable to detect operating system."
        exit 1
    fi
}

install_basic_tools() {
    log_step "Installing required tools..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y curl ca-certificates debian-keyring debian-archive-keyring apt-transport-https gnupg
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y curl ca-certificates
            else
                sudo yum install -y curl ca-certificates
            fi
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

install_caddy() {
    log_step "Installing Caddy..."
    if command -v caddy >/dev/null 2>&1; then
        log_info "Caddy already installed: $(caddy version)"
        return
    fi

    case "$OS" in
        ubuntu|debian)
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
                sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
                sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
            sudo apt-get update
            sudo apt-get install -y caddy
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y 'dnf-command(copr)'
                sudo dnf copr enable -y @caddy/caddy
                sudo dnf install -y caddy
            else
                sudo yum install -y yum-plugin-copr
                sudo yum copr enable -y @caddy/caddy
                sudo yum install -y caddy
            fi
            ;;
    esac

    log_info "Installed Caddy: $(caddy version)"
}

prepare_directories() {
    log_step "Preparing deployment directories..."
    sudo mkdir -p "$DEPLOY_PATH/releases" "$DEPLOY_PATH/incoming"
    sudo chown -R "$USER":caddy "$DEPLOY_PATH"
    sudo find "$DEPLOY_PATH" -type d -exec chmod 2755 {} +
    log_info "Deployment path: $DEPLOY_PATH"
}

install_caddyfile() {
    log_step "Installing Caddy configuration..."
    if [ -f "$CADDY_TEMPLATE" ]; then
        sed \
            -e "s|__SITE_HOST__|$SITE_HOST|g" \
            -e "s|__SITE_ROOT__|$DEPLOY_PATH/current|g" \
            "$CADDY_TEMPLATE" > "$TMP_CADDYFILE"
    else
        log_warn "Caddy template not found at $CADDY_TEMPLATE, using built-in template."
        cat > "$TMP_CADDYFILE" <<EOF
$SITE_HOST {
    root * $DEPLOY_PATH/current

    encode gzip zstd

    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        -X-Powered-By
    }

    @static {
        path *.jpg *.jpeg *.png *.gif *.ico *.css *.js *.svg *.woff *.woff2 *.ttf *.eot
    }
    header @static Cache-Control "public, max-age=2592000, immutable"

    @pdf {
        path *.pdf
    }
    header @pdf Content-Disposition "inline"
    header @pdf X-Content-Type-Options "nosniff"

    @course_dirs {
        path_regexp course_dirs ^/(calculus|linear-algebra|c-programming|engineering-graphics|college-english|ode|physics|mechanical-drawing|ai-fundamentals|politics)/.+/$
    }

    handle @course_dirs {
        file_server browse
    }

    handle {
        file_server
    }
}
EOF
    fi

    sudo cp "$TMP_CADDYFILE" /etc/caddy/Caddyfile
    sudo caddy validate --config /etc/caddy/Caddyfile
}

configure_service() {
    log_step "Enabling Caddy service..."
    sudo systemctl enable caddy
    sudo systemctl restart caddy
    sudo systemctl --no-pager --full status caddy
}

configure_firewall() {
    ports=""
    if [[ "$SITE_HOST" == *:* ]]; then
        port="${SITE_HOST##*:}"
        ports="$port"
    else
        ports="80 443"
    fi

    log_step "Opening firewall ports: $ports"
    if command -v ufw >/dev/null 2>&1; then
        for port in $ports; do
            sudo ufw allow "$port"/tcp
        done
    elif command -v firewall-cmd >/dev/null 2>&1; then
        for port in $ports; do
            sudo firewall-cmd --permanent --add-port="$port"/tcp
        done
        sudo firewall-cmd --reload
    else
        log_warn "No supported firewall tool detected. Open ports manually: $ports"
    fi
}

show_next_steps() {
    echo ""
    echo "=========================================="
    log_info "Server bootstrap complete."
    echo "=========================================="
    echo ""
    echo "GitHub Actions secrets required:"
    echo "  SERVER_HOST"
    echo "  SERVER_USER"
    echo "  SSH_PRIVATE_KEY"
    echo ""
    echo "Optional runtime environment:"
    echo "  DEPLOY_PATH=$DEPLOY_PATH"
    echo "  SITE_HOST=$SITE_HOST"
    echo ""
    echo "Caddy is serving from: $DEPLOY_PATH/current"
}

cleanup() {
    rm -f "$TMP_CADDYFILE"
}

trap cleanup EXIT

main() {
    detect_os
    install_basic_tools
    install_caddy
    prepare_directories
    install_caddyfile
    configure_service
    configure_firewall
    show_next_steps
}

main "$@"
