# 🚀 Полная инструкция по развертыванию Gavhar Menu на VPS

## 📋 Что нужно установить на сервере

### Системные требования

- **ОС**: Ubuntu 20.04+ или Debian 11+
- **RAM**: минимум 1GB (рекомендуется 2GB+)
- **Диск**: минимум 10GB свободного места
- **Процессор**: 1 ядро (рекомендуется 2+)

## 🔧 Пошаговая установка

### Шаг 1: Подключение к серверу

```bash
# Подключитесь к серверу по SSH
ssh root@YOUR_SERVER_IP

# Или если у вас есть пользователь
ssh username@YOUR_SERVER_IP
```

### Шаг 2: Обновление системы

```bash
# Обновляем список пакетов
sudo apt update

# Обновляем систему
sudo apt upgrade -y

# Перезагружаемся (если нужно)
sudo reboot
```

### Шаг 3: Создание пользователя (рекомендуется)

```bash
# Создаем пользователя gavhar
sudo adduser gavhar

# Добавляем в группу sudo
sudo usermod -aG sudo gavhar

# Переключаемся на пользователя
su - gavhar
```

### Шаг 4: Установка Node.js и npm

```bash
# Устанавливаем Node.js 20.x (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Устанавливаем Node.js и npm
sudo apt install -y nodejs

# Проверяем версии
node --version
npm --version
```

**Ожидаемый результат:**

```
v20.x.x
10.x.x
```

### Шаг 5: Установка PM2

```bash
# Устанавливаем PM2 глобально
sudo npm install -g pm2

# Проверяем установку
pm2 --version
```

### Шаг 6: Установка Nginx

```bash
# Устанавливаем Nginx
sudo apt install -y nginx

# Запускаем и включаем автозапуск
sudo systemctl start nginx
sudo systemctl enable nginx

# Проверяем статус
sudo systemctl status nginx
```

### Шаг 7: Установка SSL сертификатов (Let's Encrypt)

```bash
# Устанавливаем Certbot
sudo apt install -y certbot python3-certbot-nginx

# Проверяем установку
certbot --version
```

### Шаг 8: Настройка файрвола

```bash
# Устанавливаем UFW
sudo apt install -y ufw

# Настраиваем правила
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000

# Включаем файрвол
sudo ufw --force enable

# Проверяем статус
sudo ufw status
```

### Шаг 9: Установка дополнительных пакетов

```bash
# Устанавливаем Git и другие необходимые пакеты
sudo apt install -y git fail2ban curl wget unzip

# Настраиваем Fail2ban для защиты от брутфорса
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

### Шаг 10: Создание директории проекта

```bash
# Создаем директорию для проекта
sudo mkdir -p /opt/gavhar
sudo chown -R gavhar:gavhar /opt/gavhar

# Переходим в директорию
cd /opt/gavhar
```

## 🚀 Развертывание приложения

### Вариант A: Автоматическое развертывание (рекомендуется)

```bash
# Скачиваем скрипт развертывания
wget https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-github.sh

# Делаем исполняемым
chmod +x deploy-github.sh

# Запускаем развертывание
./deploy-github.sh https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

### Вариант B: Ручное развертывание

#### 1. Клонирование репозитория

```bash
# Клонируем репозиторий
git clone https://github.com/your-username/gavhar-menu.git .

# Проверяем содержимое
ls -la
```

#### 2. Установка зависимостей

```bash
# Устанавливаем зависимости
npm install --production

# Проверяем установку
npm list --depth=0
```

#### 3. Создание конфигурации

```bash
# Создаем .env файл
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

#### 4. Создание необходимых директорий

```bash
# Создаем директории
mkdir -p data uploads backups logs

# Устанавливаем права
chmod 755 data uploads backups logs
```

#### 5. Инициализация базы данных

```bash
# Инициализируем базу данных
npm run init-db

# Проверяем создание файла
ls -la data/
```

#### 6. Сборка проекта

```bash
# Собираем проект
npm run build

# Проверяем результат
ls -la public/
```

#### 7. Настройка Nginx

```bash
# Создаем конфигурацию Nginx
sudo tee /etc/nginx/sites-available/gavhar << 'EOF'
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # Логи
    access_log /var/log/nginx/gavhar.access.log;
    error_log /var/log/nginx/gavhar.error.log;

    # Основное приложение
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
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Статические файлы
    location /uploads/ {
        alias /opt/gavhar/uploads/;
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

# Активируем сайт
sudo ln -sf /etc/nginx/sites-available/gavhar /etc/nginx/sites-enabled/

# Удаляем дефолтный сайт
sudo rm -f /etc/nginx/sites-enabled/default

# Проверяем конфигурацию
sudo nginx -t

# Перезапускаем Nginx
sudo systemctl restart nginx
```

#### 8. Запуск приложения через PM2

```bash
# Запускаем приложение
pm2 start ecosystem.config.js --name gavhar-menu

# Сохраняем конфигурацию PM2
pm2 save

# Настраиваем автозапуск
pm2 startup

# Проверяем статус
pm2 status
```

#### 9. Настройка SSL сертификата

```bash
# Получаем SSL сертификат
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com --email your-email@example.com --agree-tos --non-interactive --redirect

# Проверяем статус сертификата
sudo certbot certificates
```

## 🔧 Проверка развертывания

### 1. Проверка статуса сервисов

```bash
# Проверяем PM2
pm2 status

# Проверяем Nginx
sudo systemctl status nginx

# Проверяем порты
sudo netstat -tlnp | grep :3000
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

### 2. Проверка логов

```bash
# Логи приложения
pm2 logs gavhar-menu

# Логи Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Системные логи
sudo journalctl -u nginx -f
```

### 3. Тестирование в браузере

- Откройте `https://yourdomain.com` - должно показать меню
- Откройте `https://yourdomain.com/admin` - должно показать админ панель
- Войдите с логином `admin` и паролем `gavhar2024`

## 🛠 Управление приложением

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

# Удаление
pm2 delete gavhar-menu
```

### Обновление приложения

```bash
# Перейти в директорию
cd /opt/gavhar

# Обновить код
git pull origin main

# Установить зависимости
npm ci --production

# Собрать проект
npm run build

# Перезапустить
pm2 restart gavhar-menu
```

### Создание бэкапа

```bash
# Создать бэкап базы данных
cp data/database.sqlite backups/database_$(date +%Y%m%d_%H%M%S).sqlite

# Очистить старые бэкапы (старше 7 дней)
find backups/ -name "database_*.sqlite" -mtime +7 -delete
```

## 🔒 Настройка безопасности

### 1. Настройка SSH

```bash
# Редактируем конфигурацию SSH
sudo nano /etc/ssh/sshd_config

# Изменяем настройки:
# Port 2222
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes

# Перезапускаем SSH
sudo systemctl restart ssh
```

### 2. Настройка Fail2ban

```bash
# Создаем конфигурацию для Nginx
sudo tee /etc/fail2ban/jail.d/nginx.conf << 'EOF'
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF

# Перезапускаем Fail2ban
sudo systemctl restart fail2ban
```

## 📊 Мониторинг

### 1. Установка htop для мониторинга

```bash
# Устанавливаем htop
sudo apt install -y htop

# Запускаем мониторинг
htop
```

### 2. Настройка логирования

```bash
# Создаем скрипт для ротации логов
sudo tee /etc/logrotate.d/gavhar << 'EOF'
/opt/gavhar/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 gavhar gavhar
}
EOF
```

## 🆘 Устранение неполадок

### Проблема: Приложение не запускается

```bash
# Проверяем логи
pm2 logs gavhar-menu

# Проверяем порт
sudo netstat -tlnp | grep :3000

# Проверяем права доступа
ls -la /opt/gavhar/
```

### Проблема: Nginx не работает

```bash
# Проверяем конфигурацию
sudo nginx -t

# Проверяем статус
sudo systemctl status nginx

# Перезапускаем
sudo systemctl restart nginx
```

### Проблема: SSL сертификат не работает

```bash
# Проверяем сертификаты
sudo certbot certificates

# Обновляем сертификаты
sudo certbot renew --dry-run

# Принудительное обновление
sudo certbot renew --force-renewal
```

## ✅ Финальная проверка

После выполнения всех шагов проверьте:

1. ✅ Сайт открывается по `https://yourdomain.com`
2. ✅ Админ панель доступна по `https://yourdomain.com/admin`
3. ✅ SSL сертификат работает (зеленый замок в браузере)
4. ✅ Приложение перезапускается при перезагрузке сервера
5. ✅ Логи пишутся корректно
6. ✅ Бэкапы создаются автоматически

---

**🎉 Поздравляем! Ваше приложение успешно развернуто на VPS!**
