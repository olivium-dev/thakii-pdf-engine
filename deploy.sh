#!/bin/bash

# Thakii PDF Engine Deployment Script
# Usage: ./deploy.sh [environment]

set -e

# Configuration
SERVER="thakii-02.fds-1.com"
USER="ec2-user"
DEPLOY_PATH="/home/ec2-user/thakii-pdf-engine"
SERVICE_NAME="thakii-pdf-engine"
ENVIRONMENT="${1:-production}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# SSH command wrapper
ssh_exec() {
    ssh -o ProxyCommand="cloudflared access ssh --hostname %h" \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=30 \
        ${USER}@${SERVER} "$1"
}

scp_copy() {
    scp -o ProxyCommand="cloudflared access ssh --hostname %h" \
        -o StrictHostKeyChecking=no \
        "$1" ${USER}@${SERVER}:"$2"
}

# Main deployment function
deploy() {
    log_info "Starting deployment to ${SERVER} (${ENVIRONMENT})"
    
    # Test SSH connectivity
    log_info "Testing SSH connectivity..."
    if ssh_exec "echo 'SSH connection successful'"; then
        log_success "SSH connection established"
    else
        log_error "Failed to establish SSH connection"
        exit 1
    fi
    
    # Run local tests
    log_info "Running local tests..."
    if python3 -m unittest tests.test_time_utils tests.test_subtitle_srt_parser tests.test_subtitle_webvtt_parser -v; then
        log_success "Local tests passed"
    else
        log_error "Local tests failed"
        exit 1
    fi
    
    # Create deployment package
    log_info "Creating deployment package..."
    tar -czf thakii-pdf-engine.tar.gz \
        --exclude='.git' \
        --exclude='venv' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.pytest_cache' \
        --exclude='test_*.mp4' \
        --exclude='*.pdf' \
        --exclude='simple_test.mp4' \
        .
    log_success "Deployment package created"
    
    # Create deployment directory
    log_info "Creating deployment directory on server..."
    ssh_exec "mkdir -p ${DEPLOY_PATH}"
    
    # Stop existing service
    log_info "Stopping existing service..."
    ssh_exec "sudo systemctl stop ${SERVICE_NAME} || echo 'Service not running'"
    
    # Backup current deployment
    log_info "Backing up current deployment..."
    ssh_exec "if [ -d ${DEPLOY_PATH} ]; then 
                sudo cp -r ${DEPLOY_PATH} ${DEPLOY_PATH}.backup.\$(date +%Y%m%d_%H%M%S) || true
              fi"
    
    # Copy files to server
    log_info "Copying files to server..."
    scp_copy "thakii-pdf-engine.tar.gz" "/tmp/"
    
    # Extract files on server
    log_info "Extracting files on server..."
    ssh_exec "cd ${DEPLOY_PATH} && 
              tar -xzf /tmp/thakii-pdf-engine.tar.gz --strip-components=0 &&
              rm /tmp/thakii-pdf-engine.tar.gz"
    
    # Setup Python environment
    log_info "Setting up Python environment..."
    ssh_exec "cd ${DEPLOY_PATH} &&
              python3 -m venv venv &&
              source venv/bin/activate &&
              pip install --upgrade pip &&
              pip install opencv-python fpdf2 webvtt-py srt numpy pillow"
    
    # Install system dependencies
    log_info "Installing system dependencies..."
    ssh_exec "sudo apt-get update -qq &&
              sudo apt-get install -y python3-opencv libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1 || true"
    
    # Test deployment
    log_info "Testing deployment..."
    ssh_exec "cd ${DEPLOY_PATH} &&
              source venv/bin/activate &&
              python -c 'from src.main import CommandLineArgRunner; print(\"Application imported successfully\")'"
    
    # Create systemd service
    log_info "Creating systemd service..."
    ssh_exec "sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << 'EOF'
[Unit]
Description=Thakii PDF Engine Service
After=network.target

[Service]
Type=simple
User=${USER}
Group=${USER}
WorkingDirectory=${DEPLOY_PATH}
Environment=PATH=${DEPLOY_PATH}/venv/bin
Environment=HEALTH_PORT=8080
Environment=HEALTH_HOST=0.0.0.0
ExecStart=${DEPLOY_PATH}/venv/bin/python -m src.health_server
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

[Install]
WantedBy=multi-user.target
EOF"
    
    # Enable service
    log_info "Enabling service..."
    ssh_exec "sudo systemctl daemon-reload &&
              sudo systemctl enable ${SERVICE_NAME}"
    
    # Create deployment info
    log_info "Creating deployment info..."
    ssh_exec "cd ${DEPLOY_PATH} &&
              echo 'Deployment Info:' > deployment_info.txt &&
              echo 'Date: \$(date)' >> deployment_info.txt &&
              echo 'Environment: ${ENVIRONMENT}' >> deployment_info.txt &&
              echo 'Deployed by: \$(whoami)' >> deployment_info.txt &&
              cat deployment_info.txt"
    
    # Final verification
    log_info "Final verification..."
    ssh_exec "cd ${DEPLOY_PATH} &&
              source venv/bin/activate &&
              python -m src.main --help"
    
    # Cleanup
    rm -f thakii-pdf-engine.tar.gz
    
    log_success "Deployment completed successfully!"
    log_info "You can now start the service with: sudo systemctl start ${SERVICE_NAME}"
    log_info "Check service status with: sudo systemctl status ${SERVICE_NAME}"
    log_info "View logs with: sudo journalctl -u ${SERVICE_NAME} -f"
}

# Health check function
health_check() {
    log_info "Performing health check on ${SERVER}..."
    
    # Test basic import
    ssh_exec "cd ${DEPLOY_PATH} &&
              source venv/bin/activate &&
              python -c 'from src.main import CommandLineArgRunner; print(\"✅ Application is healthy\")'"
    
    # Test service status
    ssh_exec "sudo systemctl status ${SERVICE_NAME} --no-pager || echo 'Service not running'"
    
    # Test health endpoint if service is running
    if ssh_exec "sudo systemctl is-active ${SERVICE_NAME} >/dev/null 2>&1"; then
        log_info "Testing health endpoint..."
        sleep 5  # Wait for server to start
        
        if ssh_exec "curl -f -s http://localhost:8080/health >/dev/null 2>&1"; then
            log_success "✅ Health endpoint is responding"
            log_info "🌐 Health endpoint: http://localhost:8080/health"
            log_info "📋 Service info: http://localhost:8080/"
            
            # Show health response
            log_info "Health response:"
            ssh_exec "curl -s http://localhost:8080/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/health"
        else
            log_warning "⚠️  Health endpoint not responding (service may still be starting)"
        fi
    else
        log_info "Service not running, skipping health endpoint test"
    fi
}

# Rollback function
rollback() {
    log_warning "Rolling back deployment..."
    
    # Find latest backup
    BACKUP_DIR=$(ssh_exec "ls -td ${DEPLOY_PATH}.backup.* 2>/dev/null | head -1 || echo ''")
    
    if [ -z "$BACKUP_DIR" ]; then
        log_error "No backup found for rollback"
        exit 1
    fi
    
    log_info "Rolling back to: $BACKUP_DIR"
    
    # Stop service
    ssh_exec "sudo systemctl stop ${SERVICE_NAME} || true"
    
    # Restore backup
    ssh_exec "rm -rf ${DEPLOY_PATH} && mv $BACKUP_DIR ${DEPLOY_PATH}"
    
    # Start service
    ssh_exec "sudo systemctl start ${SERVICE_NAME} || true"
    
    log_success "Rollback completed"
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "health")
        health_check
        ;;
    "rollback")
        rollback
        ;;
    *)
        echo "Usage: $0 [deploy|health|rollback]"
        echo "  deploy   - Deploy the application (default)"
        echo "  health   - Check application health"
        echo "  rollback - Rollback to previous deployment"
        exit 1
        ;;
esac
