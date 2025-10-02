# Custom Domain Deployment Guide
## Hosting at https://your-domain.com/fin-customer

This guide will help you deploy your Customer Management App to a custom domain with a subdirectory path and SSL certificate.

## 📋 Prerequisites

1. **Domain Name**: You need to own a domain (e.g., `your-domain.com`)
2. **Azure VM**: Running Ubuntu with public IP address
3. **DNS Access**: Ability to modify DNS records for your domain
4. **SSH Access**: To your Azure VM

## 🔧 Step 1: Configure DNS Settings

### A. Point Domain to Azure VM
1. Log into your domain registrar's control panel
2. Navigate to DNS management
3. Create/Update these DNS records:

```
Type: A
Name: @ (or your-domain.com)
Value: YOUR_AZURE_VM_PUBLIC_IP
TTL: 300 (or default)

Type: CNAME
Name: www
Value: your-domain.com
TTL: 300 (or default)
```

### B. Verify DNS Propagation
```bash
# Check if DNS is propagated
nslookup your-domain.com
dig your-domain.com
```

## 🚀 Step 2: Deploy Application with Subdirectory Support

### A. Update Application Configuration
The Next.js configuration has been updated to support subdirectory deployment:

**File: `next.config.mjs`**
```javascript
const nextConfig = {
  basePath: '/fin-customer',
  assetPrefix: '/fin-customer',
  trailingSlash: true,
  // ... other config
};
```

### B. Update Environment Variables
**File: `.env.production`**
```bash
MONGODB_URI=mongodb://localhost:27017/fin-custome-db
NODE_ENV=production
PORT=3000
NEXT_PUBLIC_API_URL=https://your-domain.com/fin-customer
```

### C. Deploy Updated Application
```bash
# On your Azure VM
cd /fin-custome

# Stop the current application
pm2 stop fin-custome-app

# Pull/upload your updated code with new configuration
# ... (upload process)

# Install dependencies and rebuild
npm install --production
npm run build

# Restart the application
pm2 restart fin-custome-app
```

## 🔒 Step 3: Set Up SSL Certificate with Let's Encrypt

### A. Install Certbot
```bash
# On your Azure VM
sudo apt update
sudo apt install snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

### B. Obtain SSL Certificate
```bash
# Stop Nginx temporarily
sudo systemctl stop nginx

# Obtain certificate
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Start Nginx again
sudo systemctl start nginx
```

### C. Set Up Auto-Renewal
```bash
# Test renewal
sudo certbot renew --dry-run

# Add to crontab for auto-renewal
sudo crontab -e

# Add this line to renew certificates twice daily
0 12 * * * /usr/bin/certbot renew --quiet
```

## 🌐 Step 4: Configure Nginx for Subdirectory Hosting

### A. Use the Subdirectory Configuration
```bash
# Copy the subdirectory nginx configuration
sudo cp /fin-custome/nginx-subdirectory.conf /etc/nginx/sites-available/fin-customer-subdirectory

# Update the configuration with your actual domain
sudo nano /etc/nginx/sites-available/fin-customer-subdirectory

# Replace 'your-domain.com' with your actual domain name
```

### B. Enable the Site
```bash
# Remove default configuration if exists
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/fin-custome

# Enable new configuration
sudo ln -s /etc/nginx/sites-available/fin-customer-subdirectory /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

## 🔧 Step 5: Update Firewall Settings

```bash
# Allow HTTPS traffic
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw reload
```

## 🧪 Step 6: Test Your Deployment

### A. Test HTTP to HTTPS Redirect
```bash
curl -I http://your-domain.com
# Should return 301 redirect to https://
```

### B. Test Application Access
1. Open browser and navigate to: `https://your-domain.com/fin-customer/`
2. Verify SSL certificate is valid (green lock icon)
3. Test all application features:
   - Customer listing
   - Add new customer
   - Edit customer
   - Delete customer

### C. Test API Endpoints
```bash
# Test API endpoint
curl https://your-domain.com/fin-customer/api/customer
```

## 📊 Step 7: Monitoring and Maintenance

### A. Monitor Application
```bash
# Check PM2 status
pm2 status
pm2 logs fin-custome-app

# Check Nginx status
sudo systemctl status nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### B. Monitor SSL Certificate
```bash
# Check certificate expiry
sudo certbot certificates

# Check certificate details
openssl x509 -in /etc/letsencrypt/live/your-domain.com/fullchain.pem -text -noout
```

## 🔄 Step 8: Application Updates

When you need to update your application:

```bash
cd /fin-custome

# Stop application
pm2 stop fin-custome-app

# Update code (git pull or upload new files)
# Make sure to keep the updated next.config.mjs and .env.production

# Install dependencies and rebuild
npm install --production
npm run build

# Restart application
pm2 restart fin-custome-app

# Check status
pm2 status
```

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Renew certificate manually
sudo certbot renew

# Check Nginx SSL configuration
sudo nginx -t
```

#### 2. Application Not Loading
```bash
# Check if app is running
pm2 status

# Check application logs
pm2 logs fin-custome-app

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

#### 3. 404 Errors on Routes
- Ensure `basePath` is correctly set in `next.config.mjs`
- Check Nginx rewrite rules
- Verify Next.js build completed successfully

#### 4. API Endpoints Not Working
- Check `NEXT_PUBLIC_API_URL` in environment variables
- Verify Nginx proxy configuration for `/api/` routes
- Check application logs for API errors

#### 5. Static Assets Not Loading
- Verify `assetPrefix` in `next.config.mjs`
- Check Nginx static file serving configuration
- Ensure build process completed successfully

## 📝 Configuration Files Summary

### Key Files Modified:
1. **`next.config.mjs`** - Added basePath and assetPrefix
2. **`.env.production`** - Updated API URL for custom domain
3. **`nginx-subdirectory.conf`** - Nginx configuration for subdirectory hosting
4. **SSL certificates** - Located in `/etc/letsencrypt/live/your-domain.com/`

### Important URLs:
- **Application**: `https://your-domain.com/fin-customer/`
- **API**: `https://your-domain.com/fin-customer/api/`
- **Health Check**: `https://your-domain.com/fin-customer/health`

## 🔐 Security Considerations

1. **SSL/TLS**: Always use HTTPS in production
2. **Firewall**: Only open necessary ports (22, 80, 443)
3. **Updates**: Keep system and dependencies updated
4. **Monitoring**: Set up monitoring for uptime and security
5. **Backups**: Regular database and application backups
6. **Access Control**: Limit SSH access and use key-based authentication

## 📈 Performance Optimization

1. **Nginx Caching**: Static assets are cached for 365 days
2. **Gzip Compression**: Enabled for text-based content
3. **HTTP/2**: Enabled for better performance
4. **PM2 Clustering**: Consider using multiple instances for high traffic

Your Customer Management App is now accessible at:
**https://your-domain.com/fin-customer/**

Remember to replace `your-domain.com` with your actual domain name throughout all configuration files!