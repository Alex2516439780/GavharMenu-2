#!/bin/bash
set -euo pipefail

echo "🚀 Настройка сервера Gavhar Menu..."

# Переходим в папку проекта
cd /opt/gavhar

# Создаем .env файл
echo "📝 Создание .env файла..."
cat > .env << 'EOF'
PORT=3000
NODE_ENV=production
DB_PATH=./data/database.sqlite
UPLOAD_PATH=./uploads
FRONTEND_URL=http://81.162.55.13
ADMIN_USERNAME=admin
ADMIN_PASSWORD=gavhar2024
BACKUP_ENABLED=true
EOF

# Запускаем приложение
echo "🔄 Запуск приложения..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Настраиваем Nginx
echo "🌐 Настройка Nginx..."
sudo tee /etc/nginx/sites-available/gavhar << 'EOF'
server {
    listen 80;
    server_name 81.162.55.13;

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

# Активируем сайт
sudo ln -sf /etc/nginx/sites-available/gavhar /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Проверяем статус
echo "✅ Проверка статуса..."
pm2 status
echo "🌐 Приложение доступно по адресу: http://81.162.55.13"
echo "🔧 Админ панель: http://81.162.55.13/admin"
echo "👤 Логин: admin"
echo "🔑 Пароль: gavhar2024"
