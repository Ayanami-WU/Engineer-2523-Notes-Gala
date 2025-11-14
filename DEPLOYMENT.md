# ZJU GitLab CI/CD Deployment Guide

This guide will help you set up automatic deployment from ZJU GitLab (git.zju.edu.cn) to your Hong Kong server using SSH keychain authentication.

## Overview

When you push to ZJU GitLab `master` or `main` branch via SSH:
1. ZJU GitLab CI builds your MkDocs site
2. The built site is automatically deployed to your HK server via SSH keychain
3. Your server serves the site on port 8111

## Prerequisites

- Access to ZJU GitLab (git.zju.edu.cn)
- SSH key configured for git push to ZJU GitLab
- Hong Kong server with SSH access
- Docker installed on your HK server

---

## Setup Instructions

### Step 1: Configure Git for ZJU GitLab with SSH

If you haven't set up SSH keys for ZJU GitLab yet:

1. **Generate SSH key pair** (on your local machine):
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@zju.edu.cn"
# Save to default location: ~/.ssh/id_rsa
```

2. **Add public key to ZJU GitLab**:
```bash
# Display your public key
cat ~/.ssh/id_rsa.pub
```

Go to ZJU GitLab: **Settings → SSH Keys** and add the public key.

3. **Test SSH connection**:
```bash
ssh -T git@git.zju.edu.cn
```

### Step 2: Prepare Your HK Server

#### Option A: Using Docker (Recommended)

1. **Install Docker and Docker Compose**:
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose -y

# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

2. **Create deployment directory**:
```bash
mkdir -p ~/mkdocs-notes
cd ~/mkdocs-notes
```

3. **Configure firewall to allow port 8111**:
```bash
sudo ufw allow 8111/tcp
sudo ufw status
```

#### Option B: Using Nginx (Static Files)

1. **Install nginx and rsync**:
```bash
sudo apt update
sudo apt install nginx rsync -y
```

2. **Create deployment directory**:
```bash
sudo mkdir -p /var/www/mkdocs-notes
sudo chown $USER:$USER /var/www/mkdocs-notes
```

3. **Configure nginx** (`/etc/nginx/sites-available/mkdocs-notes`):
```nginx
server {
    listen 8111;
    server_name your-server-ip;  # or your-domain.com

    root /var/www/mkdocs-notes;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript
               application/x-javascript application/xml+rss
               application/javascript application/json;
}
```

4. **Enable the site**:
```bash
sudo ln -s /etc/nginx/sites-available/mkdocs-notes /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

5. **Configure firewall**:
```bash
sudo ufw allow 8111/tcp
sudo ufw status
```

### Step 3: Set Up SSH Keychain Authentication

**On your HK server**:

1. **Generate dedicated SSH key for GitLab CI**:
```bash
# Generate a new key pair specifically for GitLab CI/CD
ssh-keygen -t rsa -b 4096 -C "gitlab-ci-deploy" -f ~/.ssh/gitlab-ci
```

2. **Add the public key to authorized_keys**:
```bash
cat ~/.ssh/gitlab-ci.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

3. **Display the private key** (you'll need this for GitLab):
```bash
cat ~/.ssh/gitlab-ci
```

**Important**: Copy the entire private key including the `-----BEGIN/END RSA PRIVATE KEY-----` lines.

4. **Test SSH connection** (from your local machine):
```bash
ssh -i ~/.ssh/gitlab-ci $USER@your-server-ip
```

### Step 4: Configure ZJU GitLab CI/CD Variables

Go to your ZJU GitLab project: **Settings → CI/CD → Variables**

Add the following variables (mark all as **Protected** and **Masked**):

| Variable | Type | Value | Example | Description |
|----------|------|-------|---------|-------------|
| `SSH_PRIVATE_KEY` | File | Private key content | `-----BEGIN RSA...` | The private key from Step 3 |
| `SERVER_HOST` | Variable | Server IP or domain | `123.45.67.89` | Your HK server address |
| `SERVER_USER` | Variable | SSH username | `ubuntu` or `your-username` | SSH user on your server |
| `DEPLOY_PATH` | Variable | Deployment path | `/var/www/mkdocs-notes` (nginx) or `~/mkdocs-notes` (docker) | Where to deploy |

**How to add variables**:
1. Go to your project on git.zju.edu.cn
2. Navigate to **Settings → CI/CD → Variables → Expand**
3. Click **Add variable**
4. For `SSH_PRIVATE_KEY`:
   - Key: `SSH_PRIVATE_KEY`
   - Value: Paste the entire private key
   - Type: Variable (or File)
   - ✓ Protect variable
   - ✓ Mask variable
5. Repeat for other variables

### Step 5: Initialize Git Repository and Push to ZJU GitLab

1. **Create a new project on ZJU GitLab**:
   - Go to git.zju.edu.cn
   - Click "New project"
   - Name it (e.g., "course-notes")
   - Set visibility as needed

2. **Initialize and push** (in your local project directory):
```bash
# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit with CI/CD setup"

# Add ZJU GitLab remote (use SSH URL)
git remote add origin git@git.zju.edu.cn:your-username/course-notes.git

# Push to ZJU GitLab
git push -u origin master
```

**Note**: Make sure to use the SSH URL (`git@git.zju.edu.cn:...`) not HTTPS!

### Step 6: Monitor Deployment

1. Go to your ZJU GitLab project
2. Navigate to **CI/CD → Pipelines**
3. Watch your pipeline run:
   - **Build stage**: Installs dependencies and builds the MkDocs site
   - **Deploy stage**: Uses SSH keychain to deploy to your HK server
4. Check the logs if there are any errors

### Step 7: Access Your Site

**For Docker deployment**:
```
http://your-server-ip:8111
```

**For Nginx deployment**:
```
http://your-server-ip:8111
```

---

## Daily Workflow

After initial setup, updating your notes is simple:

```bash
# 1. Edit your notes
vim docs/calculus/chapter1.md

# 2. Add and commit changes
git add .
git commit -m "Add calculus chapter 1 notes"

# 3. Push to ZJU GitLab via SSH
git push

# 4. GitLab CI automatically builds and deploys! 🚀
```

Check the deployment:
- Visit: http://your-server-ip:8111
- Or monitor pipeline: git.zju.edu.cn → Your Project → CI/CD → Pipelines

---

## Deployment Methods

### Method 1: Static Files + Nginx (Current)

The default `.gitlab-ci.yml` uses this method:
- ✅ Simple and fast
- ✅ Low resource usage
- ✅ Direct file serving

**How it works**:
1. GitLab CI builds static HTML files
2. Uses `rsync` to sync files to server via SSH keychain
3. Nginx serves files on port 8111

### Method 2: Docker Deployment (Alternative)

To use Docker deployment:

```bash
# Switch CI/CD configuration
mv .gitlab-ci.yml .gitlab-ci-static.yml
mv .gitlab-ci-docker.yml .gitlab-ci.yml
git add . && git commit -m "Switch to Docker deployment" && git push
```

Additional variables needed for Docker method:

| Variable | Value | Description |
|----------|-------|-------------|
| `CI_REGISTRY` | `registry.git.zju.edu.cn` | ZJU GitLab container registry |
| `CI_REGISTRY_USER` | Your ZJU GitLab username | For Docker registry login |
| `CI_REGISTRY_PASSWORD` | Your access token | Create at Settings → Access Tokens |

**How it works**:
1. GitLab CI builds Docker image with the site
2. Pushes image to ZJU GitLab Container Registry
3. SSH into server via keychain
4. Pulls new image and restarts container on port 8111

---

## Testing and Troubleshooting

### Test SSH Connection from Local

```bash
# Test with the GitLab CI key
ssh -i ~/.ssh/gitlab-ci $SERVER_USER@$SERVER_HOST

# Or if using your default key
ssh $SERVER_USER@$SERVER_HOST
```

### Test Deployment

**For Nginx**:
```bash
# Check if files are deployed
ssh $SERVER_USER@$SERVER_HOST "ls -la /var/www/mkdocs-notes"

# Test nginx config
ssh $SERVER_USER@$SERVER_HOST "sudo nginx -t"

# Check if port 8111 is listening
ssh $SERVER_USER@$SERVER_HOST "sudo netstat -tulpn | grep 8111"
```

**For Docker**:
```bash
# Check if container is running
ssh $SERVER_USER@$SERVER_HOST "docker ps"

# Check container logs
ssh $SERVER_USER@$SERVER_HOST "docker logs mkdocs-notes"

# Test if port 8111 is accessible
curl http://your-server-ip:8111
```

### Common Issues

#### 1. Pipeline fails at SSH step

**Error**: `Permission denied (publickey)`

**Solution**:
- Verify `SSH_PRIVATE_KEY` includes BEGIN/END lines
- Check that public key is in `~/.ssh/authorized_keys` on server
- Ensure `SERVER_HOST` and `SERVER_USER` are correct
- Test SSH connection manually

#### 2. rsync fails

**Error**: `rsync: command not found`

**Solution**:
```bash
# Install rsync on server
ssh $SERVER_USER@$SERVER_HOST "sudo apt install rsync -y"
```

#### 3. Permission denied on DEPLOY_PATH

**Error**: `Permission denied` when writing to deployment directory

**Solution**:
```bash
# Fix ownership
ssh $SERVER_USER@$SERVER_HOST "sudo chown -R $USER:$USER $DEPLOY_PATH"
```

#### 4. Port 8111 not accessible

**Error**: Cannot access http://your-server-ip:8111

**Solution**:
```bash
# Check firewall
ssh $SERVER_USER@$SERVER_HOST "sudo ufw status"

# Allow port 8111
ssh $SERVER_USER@$SERVER_HOST "sudo ufw allow 8111/tcp"

# For nginx, check if it's running
ssh $SERVER_USER@$SERVER_HOST "sudo systemctl status nginx"

# For Docker, check container status
ssh $SERVER_USER@$SERVER_HOST "docker ps"
```

#### 5. Site not loading correctly

**Error**: Site loads but looks broken

**Solution**:
- Check browser console for errors
- Verify `site_url` in `mkdocs.yml` matches your actual URL
- Clear browser cache

#### 6. ZJU GitLab SSH connection issues

**Error**: `Permission denied` when pushing to git.zju.edu.cn

**Solution**:
```bash
# Test SSH connection to ZJU GitLab
ssh -T git@git.zju.edu.cn

# Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Verify SSH config (~/.ssh/config)
Host git.zju.edu.cn
    HostName git.zju.edu.cn
    User git
    IdentityFile ~/.ssh/id_rsa
```

### View Logs

**GitLab CI logs**:
- Go to ZJU GitLab → Your Project → CI/CD → Pipelines → Click on pipeline → View job logs

**Server logs**:
```bash
# Nginx error logs
ssh $SERVER_USER@$SERVER_HOST "sudo tail -f /var/log/nginx/error.log"

# Docker container logs
ssh $SERVER_USER@$SERVER_HOST "docker logs -f mkdocs-notes"

# System logs
ssh $SERVER_USER@$SERVER_HOST "sudo journalctl -xe"
```

---

## Security Best Practices

1. **Use dedicated SSH keys**:
   - ✓ Separate key for GitLab CI deployment
   - ✓ Different key for personal access
   - ✓ Use strong passphrases for personal keys

2. **Secure your server**:
   ```bash
   # Keep system updated
   sudo apt update && sudo apt upgrade -y

   # Configure firewall
   sudo ufw enable
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 8111/tcp  # Your web service

   # Disable password authentication (SSH keys only)
   sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

3. **Protect GitLab CI/CD variables**:
   - ✓ Always mark sensitive variables as "Masked"
   - ✓ Mark variables as "Protected" to limit to protected branches
   - ✓ Regularly rotate SSH keys

4. **Use HTTPS (if using a domain)**:
   ```bash
   # Install Certbot
   sudo apt install certbot python3-certbot-nginx -y

   # Get certificate (requires domain pointing to your server)
   sudo certbot --nginx -d your-domain.com

   # Auto-renewal is configured automatically
   sudo certbot renew --dry-run
   ```

5. **Limit SSH access**:
   ```bash
   # Edit SSH config
   sudo vim /etc/ssh/sshd_config

   # Add these lines:
   AllowUsers your-username
   PermitRootLogin no
   MaxAuthTries 3

   # Restart SSH
   sudo systemctl restart sshd
   ```

---

## Advanced Configuration

### Auto-restart services after deployment

Edit `.gitlab-ci.yml`:

```yaml
  script:
    - rsync -avz --delete site/ $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH
    # Reload nginx after deployment
    - ssh $SERVER_USER@$SERVER_HOST "sudo systemctl reload nginx"
```

**For Docker**:
```yaml
  script:
    - rsync -avz --delete site/ $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH
    # Rebuild and restart container
    - ssh $SERVER_USER@$SERVER_HOST "cd $DEPLOY_PATH && docker-compose up -d --build"
```

### Multiple environments

You can set up staging and production:

```yaml
deploy_staging:
  stage: deploy
  # ... deployment config ...
  environment:
    name: staging
    url: http://staging-server:8111
  only:
    - develop

deploy_production:
  stage: deploy
  # ... deployment config ...
  environment:
    name: production
    url: http://production-server:8111
  only:
    - master
```

---

## File Structure

```
.
├── .gitlab-ci.yml              # CI/CD config (nginx + rsync)
├── .gitlab-ci-docker.yml       # Alternative (Docker deployment)
├── Dockerfile                  # Production Docker image
├── docker-compose.yml          # Docker Compose (port 8111)
├── deploy.sh                   # Server-side helper script
├── DEPLOYMENT.md               # This file
├── mkdocs.yml                  # MkDocs configuration
├── requirements.txt            # Python dependencies
├── .gitignore                  # Git ignore patterns
├── .ignored-commits            # For git revision plugin
├── docs/                       # Your markdown notes
│   ├── index.md
│   ├── calculus/
│   ├── linear-algebra/
│   ├── c-programming/
│   ├── engineering-graphics/
│   └── college-english/
├── overrides/                  # Custom theme overrides
├── hooks/                      # MkDocs hooks
└── site/                       # Built site (auto-generated)
```

---

## Quick Reference

### ZJU GitLab URLs

- Web interface: https://git.zju.edu.cn
- SSH clone: `git@git.zju.edu.cn:username/repo.git`
- Container registry: `registry.git.zju.edu.cn`

### Common Commands

```bash
# Build locally
docker run --rm -v $(pwd):/docs squidfunk/mkdocs-material:9.7.0 build

# Test locally
docker run --rm -v $(pwd):/docs -p 8000:8000 \
  squidfunk/mkdocs-material:9.7.0 serve -a 0.0.0.0:8000

# Push to ZJU GitLab
git add . && git commit -m "Update notes" && git push

# Check deployment on server
ssh $SERVER_USER@$SERVER_HOST "ls -lh $DEPLOY_PATH"

# View site
curl http://your-server-ip:8111
```

---

## Need Help?

- ZJU GitLab documentation: Check git.zju.edu.cn help
- GitLab CI/CD: https://docs.gitlab.com/ee/ci/
- MkDocs Material: https://squidfunk.github.io/mkdocs-material/
- Pipeline logs: git.zju.edu.cn → Your Project → CI/CD → Pipelines

---

**Happy note-taking! 📚**
