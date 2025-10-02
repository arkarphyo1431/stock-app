#!/bin/bash

# Deployment Scripts for Azure VM
# Run these commands on your Azure VM

echo "=== Customer Management App Deployment Script ==="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Node.js
install_nodejs() {
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "Node.js version: $(node --version)"
    echo "NPM version: $(npm --version)"
}

# Function to install MongoDB
install_mongodb() {
    echo "Installing MongoDB..."
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
    sudo systemctl start mongod
    sudo systemctl enable mongod
    echo "MongoDB installed and started"
}

# Function to install PM2
install_pm2() {
    echo "Installing PM2..."
    sudo npm install -g pm2
    echo "PM2 version: $(pm2 --version)"
}

# Function to install Nginx
install_nginx() {
    echo "Installing Nginx..."
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "Nginx installed and started"
}

# Function to setup application directory
setup_app_directory() {
    echo "Setting up application directory..."
    sudo mkdir -p /fin-custome
    sudo chown $USER:$USER /fin-custome
    mkdir -p /fin-custome/logs
    echo "Application directory created at /fin-custome"
}

# Function to configure firewall
configure_firewall() {
    echo "Configuring firewall..."
    sudo ufw allow 22    # SSH
    sudo ufw allow 80    # HTTP
    sudo ufw allow 443   # HTTPS
    sudo ufw --force enable
    echo "Firewall configured"
}

# Main installation function
main_install() {
    echo "Starting installation process..."
    
    # Update system
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    # Install Node.js if not exists
    if ! command_exists node; then
        install_nodejs
    else
        echo "Node.js already installed: $(node --version)"
    fi
    
    # Install MongoDB if not exists
    if ! command_exists mongod; then
        install_mongodb
    else
        echo "MongoDB already installed"
    fi
    
    # Install PM2 if not exists
    if ! command_exists pm2; then
        install_pm2
    else
        echo "PM2 already installed: $(pm2 --version)"
    fi
    
    # Install Nginx if not exists
    if ! command_exists nginx; then
        install_nginx
    else
        echo "Nginx already installed"
    fi
    
    # Setup application directory
    setup_app_directory
    
    # Configure firewall
    configure_firewall
    
    echo "=== Installation completed! ==="
    echo "Next steps:"
    echo "1. Upload your application files to /fin-custome"
    echo "2. Run: cd /fin-custome && npm install --production"
    echo "3. Run: npm run build"
    echo "4. Run: pm2 start ecosystem.config.js"
    echo "5. Configure Nginx (see deploy-guide.md)"
}

# Function to deploy application (run after uploading files)
deploy_app() {
    echo "Deploying application..."
    
    cd /fin-custome || exit 1
    
    # Install dependencies
    echo "Installing dependencies..."
    npm install --production
    
    # Build application
    echo "Building application..."
    npm run build
    
    # Start with PM2
    echo "Starting application with PM2..."
    pm2 start ecosystem.config.js
    pm2 save
    pm2 startup
    
    echo "Application deployed successfully!"
    echo "Check status with: pm2 status"
    echo "View logs with: pm2 logs fin-custome-app"
}

# Function to update application
update_app() {
    echo "Updating application..."
    
    cd /fin-custome || exit 1
    
    # Stop application
    pm2 stop fin-custome-app
    
    # Install dependencies
    npm install --production
    
    # Build application
    npm run build
    
    # Restart application
    pm2 restart fin-custome-app
    
    echo "Application updated successfully!"
}

# Check command line arguments
case "$1" in
    "install")
        main_install
        ;;
    "deploy")
        deploy_app
        ;;
    "update")
        update_app
        ;;
    *)
        echo "Usage: $0 {install|deploy|update}"
        echo "  install - Install all dependencies and setup environment"
        echo "  deploy  - Deploy the application (run after uploading files)"
        echo "  update  - Update existing application"
        exit 1
        ;;
esac