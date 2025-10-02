#!/bin/bash

# Quick Domain Setup Script for Customer Management App
# Usage: ./quick-domain-setup.sh your-domain.com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if domain is provided
if [ $# -eq 0 ]; then
    print_error "Please provide your domain name"
    echo "Usage: $0 your-domain.com"
    exit 1
fi

DOMAIN=$1
APP_DIR="/fin-custome"

print_status "Setting up domain: $DOMAIN"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script as root (use sudo)"
        exit 1
    fi
}

# Function to install certbot
install_certbot() {
    print_status "Installing Certbot for SSL certificates..."
    
    # Update system
    apt update
    
    # Install snapd if not present
    if ! command -v snap &> /dev/null; then
        apt install -y snapd
        systemctl enable snapd
        systemctl start snapd
    fi
    
    # Install certbot
    snap install core
    snap refresh core
    snap install --classic certbot
    
    # Create symlink
    ln -sf /snap/bin/certbot /usr/bin/certbot
    
    print_success "Certbot installed successfully"
}

# Function to obtain SSL certificate
obtain_ssl_certificate() {
    print_status "Obtaining SSL certificate for $DOMAIN..."
    
    # Stop nginx temporarily
    systemctl stop nginx
    
    # Obtain certificate
    certbot certonly --standalone \
        -d $DOMAIN \
        -d www.$DOMAIN \
        --non-interactive \
        --agree-tos \
        --email admin@$DOMAIN \
        --no-eff-email
    
    # Start nginx
    systemctl start nginx
    
    print_success "SSL certificate obtained successfully"
}

# Function to configure nginx
configure_nginx() {
    print_status "Configuring Nginx for subdirectory hosting..."
    
    # Create nginx configuration from template
    cat > /etc/nginx/sites-available/fin-customer-subdirectory << EOF
# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Root redirect to application
    location = / {
        return 301 https://\$server_name/fin-customer/;
    }
    
    # Customer Management Application
    location /fin-customer/ {
        proxy_pass http://localhost:3000/fin-customer/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
        
        # Handle Next.js routing
        try_files \$uri \$uri/ @nextjs;
    }
    
    # Next.js fallback
    location @nextjs {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Static files with long cache
    location /fin-customer/_next/static/ {
        proxy_pass http://localhost:3000;
        proxy_cache_valid 200 365d;
        add_header Cache-Control "public, immutable";
    }
    
    # Public files
    location /fin-customer/public/ {
        proxy_pass http://localhost:3000;
        proxy_cache_valid 200 1d;
        add_header Cache-Control "public";
    }
    
    # API routes
    location /fin-customer/api/ {
        proxy_pass http://localhost:3000/fin-customer/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check endpoint
    location /fin-customer/health {
        proxy_pass http://localhost:3000/fin-customer/health;
        access_log off;
    }
    
    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
EOF
    
    # Remove existing configurations
    rm -f /etc/nginx/sites-enabled/default
    rm -f /etc/nginx/sites-enabled/fin-custome
    
    # Enable new configuration
    ln -sf /etc/nginx/sites-available/fin-customer-subdirectory /etc/nginx/sites-enabled/
    
    # Test configuration
    nginx -t
    
    # Reload nginx
    systemctl reload nginx
    
    print_success "Nginx configured successfully"
}

# Function to update environment variables
update_environment() {
    print_status "Updating environment variables..."
    
    if [ -f "$APP_DIR/.env.production" ]; then
        # Update the API URL in .env.production
        sed -i "s|NEXT_PUBLIC_API_URL=.*|NEXT_PUBLIC_API_URL=https://$DOMAIN/fin-customer|g" "$APP_DIR/.env.production"
        print_success "Environment variables updated"
    else
        print_warning ".env.production not found in $APP_DIR"
    fi
}

# Function to restart application
restart_application() {
    print_status "Restarting application..."
    
    cd $APP_DIR
    
    # Stop application
    pm2 stop fin-custome-app 2>/dev/null || true
    
    # Rebuild application (in case of config changes)
    if [ -f "package.json" ]; then
        npm run build
    fi
    
    # Start application
    pm2 start ecosystem.config.js
    
    print_success "Application restarted successfully"
}

# Function to setup auto-renewal for SSL
setup_ssl_renewal() {
    print_status "Setting up SSL certificate auto-renewal..."
    
    # Test renewal
    certbot renew --dry-run
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    print_success "SSL auto-renewal configured"
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw reload
    
    print_success "Firewall configured"
}

# Function to test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Wait a moment for services to start
    sleep 5
    
    # Test HTTP redirect
    print_status "Testing HTTP to HTTPS redirect..."
    if curl -s -I "http://$DOMAIN" | grep -q "301"; then
        print_success "HTTP to HTTPS redirect working"
    else
        print_warning "HTTP to HTTPS redirect may not be working"
    fi
    
    # Test HTTPS
    print_status "Testing HTTPS access..."
    if curl -s -k "https://$DOMAIN/fin-customer/" | grep -q "Customer"; then
        print_success "Application accessible via HTTPS"
    else
        print_warning "Application may not be accessible via HTTPS"
    fi
    
    print_success "Deployment test completed"
}

# Main execution
main() {
    print_status "Starting domain setup for Customer Management App"
    print_status "Domain: $DOMAIN"
    print_status "Application Directory: $APP_DIR"
    
    check_root
    install_certbot
    obtain_ssl_certificate
    configure_nginx
    update_environment
    restart_application
    setup_ssl_renewal
    configure_firewall
    test_deployment
    
    echo ""
    print_success "🎉 Domain setup completed successfully!"
    echo ""
    echo "Your Customer Management App is now available at:"
    echo "🌐 https://$DOMAIN/fin-customer/"
    echo ""
    echo "Next steps:"
    echo "1. Update your DNS records to point $DOMAIN to this server's IP"
    echo "2. Wait for DNS propagation (can take up to 48 hours)"
    echo "3. Test your application at the new URL"
    echo ""
    echo "Useful commands:"
    echo "• Check application status: pm2 status"
    echo "• View application logs: pm2 logs fin-custome-app"
    echo "• Check nginx status: systemctl status nginx"
    echo "• Check SSL certificate: certbot certificates"
    echo ""
}

# Run main function
main "$@"