# 🚀 Развертывание Gavhar Menu на VPS

Это руководство поможет вам развернуть приложение Gavhar Menu на облачном VPS сервере через GitHub.

## 📋 Предварительные требования

- VPS сервер с Ubuntu 20.04+ или Debian 11+
- Домен, указывающий на IP адрес сервера
- SSH доступ к серверу
- GitHub репозиторий с кодом проекта

## 🎯 Способы развертывания

### 1. 🐳 Развертывание через Docker (Рекомендуется)

**Преимущества:**

- Изоляция приложения
- Легкое обновление
- Простое масштабирование
- Консистентная среда

**Команды:**

```bash
# Скачать скрипт развертывания
wget https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-docker.sh
chmod +x deploy-docker.sh

# Запустить развертывание
./deploy-docker.sh https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

### 2. 🔧 Прямое развертывание (PM2 + Nginx)

**Преимущества:**

- Прямой контроль над процессом
- Меньше накладных расходов
- Простая отладка

**Команды:**

```bash
# Скачать скрипт развертывания
wget https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-github.sh
chmod +x deploy-github.sh

# Запустить развертывание
./deploy-github.sh https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

## 📝 Пошаговая инструкция

### Шаг 1: Подготовка GitHub репозитория

1. Создайте репозиторий на GitHub
2. Загрузите код в репозиторий:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/your-username/gavhar-menu.git
git push -u origin main
```

### Шаг 2: Подготовка VPS сервера

1. Подключитесь к серверу по SSH:

```bash
ssh root@your-server-ip
```

2. Создайте пользователя (если нужно):

```bash
adduser gavhar
usermod -aG sudo gavhar
su - gavhar
```

### Шаг 3: Развертывание

#### Вариант A: Docker развертывание

```bash
# Скачать и запустить скрипт
curl -fsSL https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-docker.sh | bash -s -- https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

#### Вариант B: Прямое развертывание

```bash
# Скачать и запустить скрипт
curl -fsSL https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-github.sh | bash -s -- https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

### Шаг 4: Проверка развертывания

1. Откройте браузер и перейдите на `https://yourdomain.com`
2. Проверьте админ панель: `https://yourdomain.com/admin`
3. Войдите с учетными данными:
   - Логин: `admin`
   - Пароль: `gavhar2024`

## 🔧 Управление приложением

### Docker развертывание

```bash
# Перейти в директорию проекта
cd /opt/gavhar

# Просмотр статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f gavhar

# Перезапуск
docker-compose restart gavhar

# Остановка
docker-compose down

# Обновление
./update.sh

# Создание бэкапа
./backup.sh
```

### Прямое развертывание (PM2)

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

# Обновление
./update.sh

# Создание бэкапа
./backup.sh
```

## 🔄 Обновление приложения

### Автоматическое обновление

```bash
cd /opt/gavhar
./update.sh
```

### Ручное обновление

#### Docker:

```bash
cd /opt/gavhar
git pull origin main
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### PM2:

```bash
cd /opt/gavhar
git pull origin main
npm ci --production
npm run build
pm2 restart gavhar-menu
```

## 💾 Бэкапы

### Автоматические бэкапы

- Настроены автоматические бэкапы базы данных каждый день в 2:00
- Бэкапы хранятся в `/opt/gavhar/backups/`
- Старые бэкапы (старше 7 дней) удаляются автоматически

### Ручное создание бэкапа

```bash
cd /opt/gavhar
./backup.sh
```

### Восстановление из бэкапа

```bash
cd /opt/gavhar
cp backups/database_YYYYMMDD_HHMMSS.sqlite data/database.sqlite
pm2 restart gavhar-menu  # или docker-compose restart gavhar
```

## 🔒 Безопасность

### Настройки безопасности

- SSL сертификат от Let's Encrypt
- Настроенный файрвол (UFW)
- Fail2ban для защиты от брутфорса
- Заголовки безопасности в Nginx

### Рекомендации

1. Смените пароль админа после первого входа
2. Регулярно обновляйте систему
3. Настройте мониторинг
4. Делайте регулярные бэкапы

## 🐛 Устранение неполадок

### Проверка логов

```bash
# Docker
docker-compose logs gavhar

# PM2
pm2 logs gavhar-menu

# Nginx
sudo tail -f /var/log/nginx/error.log
```

### Проверка статуса сервисов

```bash
# Docker
docker-compose ps

# PM2
pm2 status

# Nginx
sudo systemctl status nginx
```

### Перезапуск сервисов

```bash
# Docker
docker-compose restart

# PM2
pm2 restart all

# Nginx
sudo systemctl restart nginx
```

## 📞 Поддержка

Если у вас возникли проблемы:

1. Проверьте логи приложения
2. Убедитесь, что все сервисы запущены
3. Проверьте настройки файрвола
4. Убедитесь, что домен правильно настроен

## 🔗 Полезные ссылки

- [Документация Docker](https://docs.docker.com/)
- [Документация PM2](https://pm2.keymetrics.io/docs/)
- [Документация Nginx](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/)

---

**Удачного развертывания! 🎉**
