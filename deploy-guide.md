# Azure VM Deployment Guide for Customer Management App

## Prerequisites
- Azure VM with Ubuntu 20.04 or later
- SSH access to the VM
- Domain name or public IP address

## Step 1: Prepare Your Application

### 1.1 Build the Application
```bash
npm run build
```

### 1.2 Create deployment package
```bash
# Create a tar file excluding node_modules and .git
tar --exclude='node_modules' --exclude='.git' --exclude='.next' -czf fin-custome-app.tar.gz .
```

## Step 2: Set Up Azure VM

### 2.1 Connect to your Azure VM
```bash
ssh username@your-azure-vm-ip
```

### 2.2 Update system packages
```bash
sudo apt update && sudo apt upgrade -y
```

### 2.3 Install Node.js (v18 or later)
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2.4 Install MongoDB
```bash
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```

### 2.5 Install PM2 globally
```bash
sudo npm install -g pm2
```

### 2.6 Install Nginx
```bash
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Step 3: Deploy Application

### 3.1 Create application directory
```bash
sudo mkdir -p /fin-custome
sudo chown $USER:$USER /fin-custome
```

### 3.2 Transfer files to VM
From your local machine:
```bash
scp fin-custome-app.tar.gz username@your-azure-vm-ip:/fin-custome/
```

### 3.3 Extract and setup application
```bash
cd /fin-custome
tar -xzf fin-custome-app.tar.gz
rm fin-custome-app.tar.gz
```

### 3.4 Install dependencies
```bash
npm install --production
```

### 3.5 Build the application
```bash
npm run build
```

### 3.6 Create logs directory
```bash
mkdir -p /fin-custome/logs
```

## Step 4: Configure Environment

### 4.1 Set up environment variables
```bash
cp .env.production .env.local
```

Edit the .env.local file:
```bash
nano .env.local
```

Update the MongoDB URI and API URL:
```
MONGODB_URI=mongodb://localhost:27017/fin-custome-db
NODE_ENV=production
PORT=3000
NEXT_PUBLIC_API_URL=http://your-azure-vm-ip:3000
```

## Step 5: Start Application with PM2

### 5.1 Start the application
```bash
pm2 start ecosystem.config.js
```

### 5.2 Save PM2 configuration
```bash
pm2 save
pm2 startup
```

### 5.3 Check application status
```bash
pm2 status
pm2 logs fin-custome-app
```

## Step 6: Configure Nginx (Optional but Recommended)

### 6.1 Create Nginx configuration
```bash
sudo nano /etc/nginx/sites-available/fin-custome
```

Add the following configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com your-azure-vm-ip;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 6.2 Enable the site
```bash
sudo ln -s /etc/nginx/sites-available/fin-custome /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Step 7: Configure Firewall

### 7.1 Allow necessary ports
```bash
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS (if using SSL)
sudo ufw enable
```

## Step 8: Test Deployment

### 8.1 Check if application is running
```bash
curl http://localhost:3000
```

### 8.2 Access from browser
Open your browser and navigate to:
- `http://your-azure-vm-ip` (if using Nginx)
- `http://your-azure-vm-ip:3000` (direct access)

## Useful Commands

### PM2 Management
```bash
pm2 restart fin-custome-app    # Restart app
pm2 stop fin-custome-app       # Stop app
pm2 delete fin-custome-app     # Delete app from PM2
pm2 logs fin-custome-app       # View logs
pm2 monit                      # Monitor resources
```

### MongoDB Management
```bash
sudo systemctl status mongod   # Check MongoDB status
sudo systemctl restart mongod  # Restart MongoDB
mongo                          # Connect to MongoDB shell
```

### Application Updates
```bash
# To update the application:
cd /fin-custome
git pull origin main           # If using git
# OR upload new tar file and extract
npm install --production
npm run build
pm2 restart fin-custome-app
```

## Troubleshooting

### Check logs
```bash
pm2 logs fin-custome-app
tail -f /fin-custome/logs/combined.log
```

### Check MongoDB connection
```bash
mongo --eval "db.adminCommand('ismaster')"
```

### Check port availability
```bash
netstat -tlnp | grep :3000
```

### Restart services
```bash
sudo systemctl restart mongod
pm2 restart fin-custome-app
sudo systemctl restart nginx
```

## Security Considerations

1. **Firewall**: Only open necessary ports
2. **MongoDB**: Configure authentication if needed
3. **SSL**: Consider setting up SSL certificates with Let's Encrypt
4. **Updates**: Keep system and dependencies updated
5. **Backups**: Set up regular database backups

## Performance Optimization

1. **PM2 Clustering**: Use multiple instances for better performance
2. **Nginx Caching**: Configure caching for static assets
3. **MongoDB Indexing**: Add appropriate indexes for better query performance
4. **Monitoring**: Set up monitoring with PM2 Plus or other tools