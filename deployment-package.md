# Deployment Package for Azure VM
## Customer Management App - Domain Hosting Setup

This guide will help you deploy your Customer Management App from your local machine to your Azure VM with custom domain hosting.

## 📦 Files to Transfer to Azure VM

### 1. **Core Application Files**
Transfer your entire application directory, but these files are specifically updated for domain hosting:

**Updated Configuration Files:**
- `next.config.mjs` - Configured for subdirectory deployment
- `.env.production` - Updated with domain URL
- `package.json` - Application dependencies
- All `app/` directory contents
- All `models/` directory contents
- All `lib/` directory contents

### 2. **Server Configuration Files**
- `ecosystem.config.js` - PM2 process management
- `nginx-subdirectory.conf` - Nginx configuration for domain hosting
- `quick-domain-setup.sh` - Automated setup script

### 3. **Documentation**
- `domain-deployment-guide.md` - Comprehensive setup guide
- `deploy-guide.md` - Original Azure VM deployment guide

## 🚀 Step-by-Step Deployment Process

### Step 1: Prepare Your Domain
**Before starting, ensure:**
1. You own a domain name (e.g., `yourdomain.com`)
2. You have access to DNS management
3. You know your Azure VM's public IP address

### Step 2: Update Configuration Files
**Replace `your-domain.com` with your actual domain in these files:**

1. **Update .env.production:**
```bash
# Replace 'your-domain.com' with your actual domain
NEXT_PUBLIC_API_URL=https://yourdomain.com/fin-customer
```

2. **Update nginx-subdirectory.conf:**
```bash
# Replace all instances of 'your-domain.com' with your actual domain
server_name yourdomain.com www.yourdomain.com;
ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
```

3. **Update quick-domain-setup.sh:**
```bash
# The script will automatically use the domain you provide as parameter
# No manual editing needed
```

### Step 3: Create Deployment Archive
Run these commands on your local machine:

```powershell
# Create a deployment archive (excluding node_modules and .next)
tar -czf deployment-package.tar.gz --exclude=node_modules --exclude=.next --exclude=.git .
```

### Step 4: Transfer Files to Azure VM
Use one of these methods to transfer files:

#### Option A: Using SCP (if you have SSH key)
```bash
# Transfer the archive
scp deployment-package.tar.gz username@your-vm-ip:/tmp/

# Connect to VM
ssh username@your-vm-ip

# Extract files
cd /fin-custome
sudo tar -xzf /tmp/deployment-package.tar.gz
sudo chown -R $USER:$USER /fin-custome
```

#### Option B: Using Azure CLI
```bash
# Upload using Azure CLI
az vm run-command invoke --resource-group your-resource-group --name your-vm-name --command-id RunShellScript --scripts "mkdir -p /tmp/deployment"

# Then use SCP or other transfer method
```

#### Option C: Manual Upload via Portal
1. Use Azure VM's serial console or connect via RDP/SSH
2. Use file transfer tools like WinSCP, FileZilla, or rsync

### Step 5: Configure DNS
**On your domain registrar:**
1. Log into your domain control panel
2. Navigate to DNS management
3. Create/Update A record:
   ```
   Type: A
   Name: @ (or yourdomain.com)
   Value: YOUR_AZURE_VM_PUBLIC_IP
   TTL: 300
   ```
4. Create CNAME record:
   ```
   Type: CNAME
   Name: www
   Value: yourdomain.com
   TTL: 300
   ```

### Step 6: Run Automated Setup on Azure VM
```bash
# Connect to your Azure VM
ssh username@your-vm-ip

# Navigate to application directory
cd /fin-custome

# Make setup script executable
chmod +x quick-domain-setup.sh

# Run the automated setup (replace with your actual domain)
sudo ./quick-domain-setup.sh yourdomain.com
```

**The script will automatically:**
- ✅ Install SSL certificates (Let's Encrypt)
- ✅ Configure Nginx for subdirectory hosting
- ✅ Set up HTTPS with security headers
- ✅ Configure firewall rules
- ✅ Install dependencies and build the app
- ✅ Start the application with PM2
- ✅ Test the deployment

### Step 7: Verify Deployment
1. **Test HTTP to HTTPS redirect:**
   ```bash
   curl -I http://yourdomain.com
   # Should return 301 redirect
   ```

2. **Test application access:**
   - Open browser: `https://yourdomain.com/fin-customer/`
   - Verify SSL certificate (green lock icon)
   - Test all features (add/edit/delete customers)

3. **Test API endpoints:**
   ```bash
   curl https://yourdomain.com/fin-customer/api/customer
   ```

## 🔧 Manual Setup (Alternative to Automated Script)

If you prefer manual setup instead of using the automated script:

### 1. Install Dependencies
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2

# Install Nginx
sudo apt install -y nginx
```

### 2. Install SSL Certificate
```bash
# Install Certbot
sudo apt install snapd
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Stop Nginx temporarily
sudo systemctl stop nginx

# Get SSL certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Start Nginx
sudo systemctl start nginx
```

### 3. Configure Application
```bash
cd /fin-custome

# Install dependencies
npm install --production

# Build application
npm run build

# Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 4. Configure Nginx
```bash
# Copy nginx configuration
sudo cp nginx-subdirectory.conf /etc/nginx/sites-available/fin-customer-subdirectory

# Enable configuration
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/fin-customer-subdirectory /etc/nginx/sites-enabled/

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Configure Firewall
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

## 🛠️ Troubleshooting

### Common Issues:

1. **DNS not propagated:**
   - Wait up to 48 hours for DNS propagation
   - Test with: `nslookup yourdomain.com`

2. **SSL certificate issues:**
   ```bash
   sudo certbot certificates
   sudo certbot renew --dry-run
   ```

3. **Application not starting:**
   ```bash
   pm2 status
   pm2 logs fin-custome-app
   ```

4. **Nginx errors:**
   ```bash
   sudo nginx -t
   sudo tail -f /var/log/nginx/error.log
   ```

## 📊 Monitoring Commands

```bash
# Check application status
pm2 status
pm2 logs fin-custome-app

# Check Nginx status
sudo systemctl status nginx

# Check SSL certificate
sudo certbot certificates

# Monitor logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 🎯 Final Result

Your Customer Management App will be accessible at:
- **Main URL:** `https://yourdomain.com/fin-customer/`
- **API Endpoints:** `https://yourdomain.com/fin-customer/api/`
- **Automatic HTTPS:** All HTTP requests redirect to HTTPS
- **SSL Certificate:** Free Let's Encrypt certificate with auto-renewal

## 📝 Important Notes

1. **Replace Domain:** Always replace `yourdomain.com` with your actual domain
2. **DNS Propagation:** Can take up to 48 hours
3. **SSL Renewal:** Automatically configured for renewal
4. **Firewall:** Only necessary ports (22, 80, 443) are open
5. **Monitoring:** Set up monitoring for production use

Your application is now ready for production hosting with custom domain and SSL!