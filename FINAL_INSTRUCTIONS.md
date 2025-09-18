# 🎯 ФИНАЛЬНЫЕ ИНСТРУКЦИИ - Развертывание Gavhar Menu на VPS

## 📋 ЧТО НУЖНО УСТАНОВИТЬ НА СЕРВЕРЕ

### Системные требования

- Ubuntu 20.04+ или Debian 11+
- Минимум 1GB RAM (рекомендуется 2GB+)
- Минимум 10GB свободного места

## 🚀 ПОШАГОВОЕ ВЫПОЛНЕНИЕ

### Шаг 1: Подключение к серверу

```bash
ssh root@YOUR_SERVER_IP
```

### Шаг 2: Обновление системы

```bash
sudo apt update && sudo apt upgrade -y
```

### Шаг 3: Создание пользователя

```bash
adduser gavhar
usermod -aG sudo gavhar
su - gavhar
```

### Шаг 4: Установка Node.js 20.x

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### Шаг 5: Установка PM2

```bash
sudo npm install -g pm2
```

### Шаг 6: Установка Nginx

```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Шаг 7: Установка SSL

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Шаг 8: Настройка файрвола

```bash
sudo apt install -y ufw
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000
sudo ufw --force enable
```

### Шаг 9: Установка дополнительных пакетов

```bash
sudo apt install -y git fail2ban curl wget unzip
```

### Шаг 10: Создание директории проекта

```bash
sudo mkdir -p /opt/gavhar
sudo chown -R gavhar:gavhar /opt/gavhar
cd /opt/gavhar
```

## 🚀 РАЗВЕРТЫВАНИЕ ПРИЛОЖЕНИЯ

### Вариант A: Автоматическое развертывание (РЕКОМЕНДУЕТСЯ)

```bash
# Скачать скрипт развертывания
wget https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-github.sh

# Сделать исполняемым
chmod +x deploy-github.sh

# Запустить развертывание (замените на ваши данные)
./deploy-github.sh https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

### Вариант B: Ручное развертывание

#### 1. Клонирование репозитория

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

#### 5. Инициализация базы данных

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

#### 9. Настройка SSL

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com --email your-email@example.com --agree-tos --non-interactive --redirect
```

## ✅ ПРОВЕРКА РАЗВЕРТЫВАНИЯ

### Проверка статуса сервисов

```bash
pm2 status
sudo systemctl status nginx
```

### Проверка в браузере

- Откройте `https://yourdomain.com` - должно показать меню
- Откройте `https://yourdomain.com/admin` - должно показать админ панель
- Войдите с логином `admin` и паролем `gavhar2024`

## 🔧 УПРАВЛЕНИЕ ПРИЛОЖЕНИЕМ

### Основные команды

```bash
# Перейти в директорию проекта
cd /opt/gavhar

# Просмотр статуса
pm2 status

# Просмотр логов
pm2 logs gavhar-menu

# Перезапуск
pm2 restart gavhar-menu

# Остановка
pm2 stop gavhar-menu
```

### Обновление приложения

```bash
cd /opt/gavhar
git pull origin main
npm ci --production
npm run build
pm2 restart gavhar-menu
```

## 🆘 ЕСЛИ ЧТО-ТО НЕ РАБОТАЕТ

### Проверка логов

```bash
pm2 logs gavhar-menu
sudo tail -f /var/log/nginx/error.log
```

### Проверка портов

```bash
sudo netstat -tlnp | grep :3000
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

### Перезапуск сервисов

```bash
pm2 restart gavhar-menu
sudo systemctl restart nginx
```

## 📊 ПРОВЕРКА ГОТОВНОСТИ СЕРВЕРА

Перед развертыванием выполните:

```bash
# Скачать скрипт проверки
wget https://raw.githubusercontent.com/your-username/gavhar-menu/main/check-dependencies.sh
chmod +x check-dependencies.sh
./check-dependencies.sh
```

---

## 🎯 КРАТКИЙ ПЛАН ДЕЙСТВИЙ

1. **Подключитесь к серверу** по SSH
2. **Выполните команды установки** (шаги 2-10)
3. **Запустите автоматическое развертывание** (Вариант A)
4. **Проверьте работу** в браузере
5. **Настройте домен** на IP адрес сервера

**Время выполнения: ~20-30 минут** ⏱️

---

**🎉 После выполнения всех шагов ваше приложение будет доступно по адресу `https://yourdomain.com`!**
