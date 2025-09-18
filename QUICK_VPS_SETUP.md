# ⚡ Быстрая установка на VPS - Пошаговая инструкция

## 🎯 Что нужно установить

### 1. Подключение к серверу

```bash
ssh root@YOUR_SERVER_IP
```

### 2. Обновление системы

```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Создание пользователя

```bash
adduser gavhar
usermod -aG sudo gavhar
su - gavhar
```

### 4. Установка Node.js 20.x

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # должно показать v20.x.x
```

### 5. Установка PM2

```bash
sudo npm install -g pm2
pm2 --version
```

### 6. Установка Nginx

```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 7. Установка SSL (Let's Encrypt)

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 8. Установка файрвола

```bash
sudo apt install -y ufw
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000
sudo ufw --force enable
```

### 9. Установка дополнительных пакетов

```bash
sudo apt install -y git fail2ban curl wget unzip
```

### 10. Создание директории проекта

```bash
sudo mkdir -p /opt/gavhar
sudo chown -R gavhar:gavhar /opt/gavhar
cd /opt/gavhar
```

## 🚀 Развертывание приложения

### Автоматический способ (рекомендуется)

```bash
# Скачать и запустить скрипт
wget https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-github.sh
chmod +x deploy-github.sh
./deploy-github.sh https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

### Ручной способ

#### 1. Клонирование

```bash
git clone https://github.com/your-username/gavhar-menu.git .
```

#### 2. Установка зависимостей

```bash
npm install --production
```

#### 3. Создание .env файла

```bash
cat > .env << 'EOF'
PORT=3000
NODE_ENV=production
DB_PATH=./data/database.sqlite
UPLOAD_PATH=./uploads
FRONTEND_URL=https://yourdomain.com
ADMIN_USERNAME=admin
ADMIN_PASSWORD=gavhar2024
BACKUP_ENABLED=true
EOF
```

#### 4. Создание директорий

```bash
mkdir -p data uploads backups logs
```

#### 5. Инициализация БД

```bash
npm run init-db
```

#### 6. Сборка проекта

```bash
npm run build
```

#### 7. Настройка Nginx

```bash
sudo tee /etc/nginx/sites-available/gavhar << 'EOF'
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

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

sudo ln -sf /etc/nginx/sites-available/gavhar /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

#### 8. Запуск приложения

```bash
pm2 start ecosystem.config.js --name gavhar-menu
pm2 save
pm2 startup
```

#### 9. SSL сертификат

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com --email your-email@example.com --agree-tos --non-interactive --redirect
```

## ✅ Проверка

```bash
# Проверка статуса
pm2 status
sudo systemctl status nginx

# Проверка в браузере
# https://yourdomain.com - меню
# https://yourdomain.com/admin - админка (admin/gavhar2024)
```

## 🔧 Управление

```bash
# Перезапуск
pm2 restart gavhar-menu

# Логи
pm2 logs gavhar-menu

# Обновление
cd /opt/gavhar
git pull origin main
npm ci --production
npm run build
pm2 restart gavhar-menu
```

---

**Время установки: ~15-20 минут** ⏱️
