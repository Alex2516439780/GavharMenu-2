#!/bin/bash
echo "🚀 Запуск Gavhar Menu..."

# Установка зависимостей
npm install

# Создание .env файла
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

# Запуск через PM2
pm2 start ecosystem.config.js
pm2 save

echo "✅ Приложение запущено!"
echo "🌐 Откройте: http://81.162.55.13"
echo "🔧 Админка: http://81.162.55.13/admin"
