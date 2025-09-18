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

log "🐳 Начинаем развертывание Gavhar Menu через Docker"
log "📦 Репозиторий: $GITHUB_REPO"
log "🌐 Домен: $DOMAIN"
log "🌿 Ветка: $BRANCH"

# Обновление системы
log "📦 Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка Docker и Docker Compose
log "🐳 Установка Docker и Docker Compose..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Установка дополнительных пакетов
log "📦 Установка дополнительных пакетов..."
sudo apt install -y nginx certbot python3-certbot-nginx ufw fail2ban git

# Настройка файрвола
log "🔥 Настройка файрвола..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443

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

# Создание .env файла
log "⚙️ Создание конфигурации..."
cat > .env << EOF
NODE_ENV=production
PORT=3000
DB_PATH=./data/database.sqlite
UPLOAD_PATH=./uploads
FRONTEND_URL=https://$DOMAIN
ADMIN_USERNAME=admin
ADMIN_PASSWORD=gavhar2024
BACKUP_ENABLED=true
EOF

# Создание необходимых директорий
log "📁 Создание необходимых директорий..."
mkdir -p data uploads backups logs ssl

# Сборка и запуск контейнеров
log "🔨 Сборка и запуск контейнеров..."
docker-compose down --remove-orphans || true
docker-compose build --no-cache
docker-compose up -d

# Ожидание запуска приложения
log "⏳ Ожидание запуска приложения..."
sleep 30

# Проверка статуса
if docker-compose ps | grep -q "Up"; then
    log "✅ Приложение успешно запущено!"
else
    error "❌ Ошибка запуска приложения"
    docker-compose logs
    exit 1
fi

# Настройка Nginx (если не используется Docker nginx)
if [ "$DOMAIN" != "localhost" ]; then
    log "🌐 Настройка Nginx..."
    sudo tee /etc/nginx/sites-available/gavhar << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

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
    }
}
EOF

    # Активация сайта
    sudo ln -sf /etc/nginx/sites-available/gavhar /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo nginx -t
    sudo systemctl restart nginx

    # Настройка SSL
    log "🔒 Настройка SSL сертификата..."
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email asad009xa@gmail.com --agree-tos --non-interactive --redirect
fi

# Создание скриптов управления
log "📝 Создание скриптов управления..."

# Скрипт обновления
cat > update.sh << 'EOF'
#!/bin/bash
cd /opt/gavhar
git pull origin main
docker-compose down
docker-compose build --no-cache
docker-compose up -d
echo "✅ Обновление завершено!"
EOF
chmod +x update.sh

# Скрипт бэкапа
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

# Скрипт логов
cat > logs.sh << 'EOF'
#!/bin/bash
docker-compose logs -f gavhar
EOF
chmod +x logs.sh

# Скрипт перезапуска
cat > restart.sh << 'EOF'
#!/bin/bash
docker-compose restart gavhar
echo "✅ Приложение перезапущено!"
EOF
chmod +x restart.sh

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
log "  Логи: cd $PROJECT_DIR && ./logs.sh"
log "  Перезапуск: cd $PROJECT_DIR && ./restart.sh"
log "  Статус: docker-compose ps"
log "  Остановка: docker-compose down"
