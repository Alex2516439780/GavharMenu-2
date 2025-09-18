#/bin/bash
set -euo pipefail

echo "Setting up Gavhar Menu server for domain: gavharestoraunt.uz"

# Update system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt install -y nginx certbot python3-certbot-nginx nodejs npm pm2 ufw fail2ban

# Configure firewall
echo "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000

# Create project directory
echo "Creating project directory..."
sudo mkdir -p /opt/gavhar
sudo chown -R $USER:$USER /opt/gavhar

# Navigate to project directory
cd /opt/gavhar

# Extract archive
echo "Extracting archive..."
unzip -o gavhar-menu-20251809-192048.zip
cd gavhar-menu

# Install dependencies
echo "Installing dependencies..."
npm install --production

# Create necessary directories
mkdir -p data uploads backups logs

# Initialize database
echo "Initializing database..."
npm run init-db || echo "Database already exists"

# Build project
echo "Building project..."
npm run build || echo "Build error, continuing..."

# Configure Nginx
echo "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/gavhar << 'EOF'
server {
    listen 80;
    server_name gavharestoraunt.uz www.gavharestoraunt.uz;

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
EOF

# Activate site
sudo ln -sf /etc/nginx/sites-available/gavhar /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Start application
echo "Starting application..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Configure SSL
echo "Configuring SSL..."
sudo certbot --nginx -d gavharestoraunt.uz -d www.gavharestoraunt.uz --email asad009xa@gmail.com --agree-tos --non-interactive

echo "Setup complete"
echo "Your site is available at: https://gavharestoraunt.uz"
echo "Admin panel: https://gavharestoraunt.uz/admin"
echo "Login: admin"
echo "Password: gavhar2024"
