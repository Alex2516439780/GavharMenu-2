#!/bin/bash
set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Проверка аргументов
if [ $# -eq 0 ]; then
    error "Использование: $0 <GITHUB_REPO_URL> [DOMAIN] [BRANCH]"
    echo "Пример: $0 https://github.com/username/gavhar-menu.git gavharestoraunt.uz main"
    exit 1
fi

GITHUB_REPO=$1
DOMAIN=${2:-"gavharestoraunt.uz"}
BRANCH=${3:-"main"}
PROJECT_DIR="/opt/gavhar"
SERVICE_NAME="gavhar-menu"

log "🚀 Начинаем развертывание Gavhar Menu с GitHub"
log "📦 Репозиторий: $GITHUB_REPO"
log "🌐 Домен: $DOMAIN"
log "🌿 Ветка: $BRANCH"

# Обновление системы
log "📦 Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
log "📦 Установка необходимых пакетов..."
sudo apt install -y nginx certbot python3-certbot-nginx nodejs npm pm2 ufw fail2ban git

# Настройка файрвола
log "🔥 Настройка файрвола..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000

# Создание директории проекта
log "📁 Создание директории проекта..."
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR

# Переход в директорию проекта
cd $PROJECT_DIR

# Клонирование или обновление репозитория
if [ -d ".git" ]; then
    log "🔄 Обновление репозитория..."
    git fetch origin
    git reset --hard origin/$BRANCH
    git clean -fd
else
    log "📥 Клонирование репозитория..."
    git clone -b $BRANCH $GITHUB_REPO .
fi

# Установка зависимостей
log "📦 Установка зависимостей..."
npm ci --production

# Создание необходимых директорий
log "📁 Создание необходимых директорий..."
mkdir -p data uploads backups logs

# Создание .env файла
log "⚙️ Создание конфигурации..."
cat > .env << EOF
PORT=3000
NODE_ENV=production
DB_PATH=./data/database.sqlite
UPLOAD_PATH=./uploads
FRONTEND_URL=https://$DOMAIN
ADMIN_USERNAME=admin
ADMIN_PASSWORD=gavhar2024
BACKUP_ENABLED=true
EOF

# Инициализация базы данных
log "🗄️ Инициализация базы данных..."
npm run init-db || warn "База данных уже существует"

# Сборка проекта
log "🔨 Сборка проекта..."
npm run build || warn "Ошибка сборки, продолжаем..."

# Настройка Nginx
log "🌐 Настройка Nginx..."
sudo tee /etc/nginx/sites-available/$SERVICE_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # Логи
    access_log /var/log/nginx/$SERVICE_NAME.access.log;
    error_log /var/log/nginx/$SERVICE_NAME.error.log;

    # Основное приложение
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Статические файлы
    location /uploads/ {
        alias $PROJECT_DIR/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

# Активация сайта
sudo ln -sf /etc/nginx/sites-available/$SERVICE_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Настройка PM2
log "🔄 Настройка PM2..."
pm2 delete $SERVICE_NAME 2>/dev/null || true
pm2 start ecosystem.config.js --name $SERVICE_NAME
pm2 save
pm2 startup

# Настройка SSL
log "🔒 Настройка SSL сертификата..."
if [ "$DOMAIN" != "localhost" ]; then
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email asad009xa@gmail.com --agree-tos --non-interactive --redirect
else
    warn "Пропускаем SSL для localhost"
fi

# Настройка автозапуска
log "🔄 Настройка автозапуска..."
sudo systemctl enable nginx
pm2 startup | grep -E '^sudo' | bash || true

# Создание скрипта обновления
log "📝 Создание скрипта обновления..."
cat > update.sh << 'EOF'
#!/bin/bash
cd /opt/gavhar
git pull origin main
npm ci --production
npm run build
pm2 restart gavhar-menu
echo "✅ Обновление завершено!"
EOF
chmod +x update.sh

# Создание скрипта бэкапа
log "💾 Создание скрипта бэкапа..."
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/gavhar/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
cp /opt/gavhar/data/database.sqlite $BACKUP_DIR/database_$DATE.sqlite
find $BACKUP_DIR -name "database_*.sqlite" -mtime +7 -delete
echo "✅ Бэкап создан: database_$DATE.sqlite"
EOF
chmod +x backup.sh

# Настройка cron для бэкапов
log "⏰ Настройка автоматических бэкапов..."
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/gavhar/backup.sh") | crontab -

log "✅ Развертывание завершено!"
log "🌐 Сайт доступен по адресу: https://$DOMAIN"
log "🔧 Админ панель: https://$DOMAIN/admin"
log "👤 Логин: admin"
log "🔑 Пароль: gavhar2024"
log ""
log "📋 Полезные команды:"
log "  Обновление: cd $PROJECT_DIR && ./update.sh"
log "  Бэкап: cd $PROJECT_DIR && ./backup.sh"
log "  Логи: pm2 logs $SERVICE_NAME"
log "  Перезапуск: pm2 restart $SERVICE_NAME"
log "  Статус: pm2 status"
