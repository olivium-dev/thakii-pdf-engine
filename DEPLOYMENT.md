# Deployment Guide for Thakii PDF Engine

This guide covers deploying the Thakii PDF Engine to the `thakii-02.fds-1.com` server using both GitHub Actions and manual deployment.

## Prerequisites

### Local Requirements
- `cloudflared` CLI tool installed
- SSH access to the target server
- Git repository with proper access

### Server Requirements
- Ubuntu 24.04 LTS (or compatible)
- Python 3.12+
- SSH access via Cloudflare Access
- Sudo privileges for service management

## GitHub Actions Deployment

### Setup Required Secrets

Add the following secrets to your GitHub repository:

1. **SSH_PRIVATE_KEY**: Private SSH key for server access
2. **CLOUDFLARE_SERVICE_TOKEN**: Cloudflare Access service token

```bash
# Generate SSH key pair (if needed)
ssh-keygen -t rsa -b 4096 -C "github-actions@thakii.com"

# Add public key to server
ssh-copy-id -o ProxyCommand="cloudflared access ssh --hostname %h" ec2-user@thakii-02.fds-1.com
```

### Workflow Triggers

The deployment workflow triggers on:
- Push to `main` or `master` branch
- Pull requests to `main` or `master` branch (tests only)
- Manual workflow dispatch

### Deployment Process

1. **Test Phase**:
   - Sets up Python environment
   - Installs dependencies
   - Runs unit tests
   - Tests basic functionality

2. **Deploy Phase**:
   - Establishes SSH connection via Cloudflare Access
   - Creates deployment directory
   - Backs up current deployment
   - Deploys new application files
   - Sets up Python virtual environment
   - Installs system dependencies
   - Creates systemd service
   - Verifies deployment

3. **Notification Phase**:
   - Reports deployment status
   - Provides deployment details

## Manual Deployment

### Using the Deployment Script

```bash
# Deploy to production
./deploy.sh

# Check application health
./deploy.sh health

# Rollback to previous deployment
./deploy.sh rollback
```

### Manual Step-by-Step Deployment

1. **Test SSH Connection**:
```bash
ssh -o ProxyCommand="cloudflared access ssh --hostname %h" ec2-user@thakii-02.fds-1.com
```

2. **Run Local Tests**:
```bash
python3 -m unittest tests.test_time_utils tests.test_subtitle_srt_parser tests.test_subtitle_webvtt_parser -v
```

3. **Create Deployment Package**:
```bash
tar -czf thakii-pdf-engine.tar.gz \
  --exclude='.git' \
  --exclude='venv' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  .
```

4. **Deploy to Server**:
```bash
# Copy files
scp -o ProxyCommand="cloudflared access ssh --hostname %h" \
    thakii-pdf-engine.tar.gz \
    ec2-user@thakii-02.fds-1.com:/tmp/

# Extract and setup
ssh -o ProxyCommand="cloudflared access ssh --hostname %h" \
    ec2-user@thakii-02.fds-1.com \
    "mkdir -p /home/ec2-user/thakii-pdf-engine &&
     cd /home/ec2-user/thakii-pdf-engine &&
     tar -xzf /tmp/thakii-pdf-engine.tar.gz &&
     python3 -m venv venv &&
     source venv/bin/activate &&
     pip install opencv-python fpdf2 webvtt-py srt numpy pillow"
```

## Service Management

### Systemd Service

The application is deployed as a systemd service:

```bash
# Check service status
sudo systemctl status thakii-pdf-engine

# Start service
sudo systemctl start thakii-pdf-engine

# Stop service
sudo systemctl stop thakii-pdf-engine

# Restart service
sudo systemctl restart thakii-pdf-engine

# View logs
sudo journalctl -u thakii-pdf-engine -f
```

### Service Configuration

Location: `/etc/systemd/system/thakii-pdf-engine.service`

```ini
[Unit]
Description=Thakii PDF Engine Service
After=network.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/thakii-pdf-engine
Environment=PATH=/home/ec2-user/thakii-pdf-engine/venv/bin
ExecStart=/home/ec2-user/thakii-pdf-engine/venv/bin/python -m src.main
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=thakii-pdf-engine

[Install]
WantedBy=multi-user.target
```

## Directory Structure on Server

```
/home/ec2-user/thakii-pdf-engine/
├── src/                          # Application source code
├── thakii_pdf_engine/           # Package structure
├── tests/                       # Test files
├── fonts/                       # Font files
├── venv/                        # Python virtual environment
├── deployment_info.txt          # Deployment metadata
├── README.md                    # Project documentation
└── requirements.txt             # Python dependencies
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   - Verify cloudflared is installed and configured
   - Check Cloudflare Access permissions
   - Ensure SSH key is properly configured

2. **Python Dependencies Failed**:
   - Check Python version compatibility
   - Verify system dependencies are installed
   - Check virtual environment activation

3. **Service Won't Start**:
   - Check service logs: `sudo journalctl -u thakii-pdf-engine -f`
   - Verify file permissions
   - Check Python path and dependencies

### Health Checks

```bash
# Test application import
cd /home/ec2-user/thakii-pdf-engine
source venv/bin/activate
python -c "from src.main import CommandLineArgRunner; print('OK')"

# Test basic functionality
python -m src.main --help

# Check system resources
df -h
free -h
ps aux | grep python
```

### Rollback Procedure

1. **Automatic Rollback** (using script):
```bash
./deploy.sh rollback
```

2. **Manual Rollback**:
```bash
# Find backup directory
ls -la /home/ec2-user/thakii-pdf-engine.backup.*

# Stop service
sudo systemctl stop thakii-pdf-engine

# Restore backup
sudo mv /home/ec2-user/thakii-pdf-engine.backup.YYYYMMDD_HHMMSS /home/ec2-user/thakii-pdf-engine

# Start service
sudo systemctl start thakii-pdf-engine
```

## Monitoring and Maintenance

### Log Monitoring

```bash
# Real-time logs
sudo journalctl -u thakii-pdf-engine -f

# Recent logs
sudo journalctl -u thakii-pdf-engine --since "1 hour ago"

# Error logs only
sudo journalctl -u thakii-pdf-engine -p err
```

### Performance Monitoring

```bash
# System resources
htop
iotop
nethogs

# Application-specific
ps aux | grep thakii-pdf-engine
lsof -p $(pgrep -f thakii-pdf-engine)
```

### Backup Strategy

- Automatic backups created before each deployment
- Backups stored in `/home/ec2-user/thakii-pdf-engine.backup.TIMESTAMP`
- Recommended to keep last 5 backups
- Manual backup: `cp -r /home/ec2-user/thakii-pdf-engine /home/ec2-user/thakii-pdf-engine.backup.$(date +%Y%m%d_%H%M%S)`

## Security Considerations

1. **SSH Access**: Uses Cloudflare Access for secure SSH tunneling
2. **Service User**: Runs as `ec2-user` (non-root)
3. **File Permissions**: Proper file ownership and permissions
4. **Network**: No direct internet exposure (behind Cloudflare)
5. **Updates**: Regular system and dependency updates recommended

## Support

For deployment issues:
1. Check this documentation
2. Review GitHub Actions logs
3. Check server logs: `sudo journalctl -u thakii-pdf-engine -f`
4. Verify SSH connectivity and permissions
5. Test local functionality before deployment
