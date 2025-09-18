# ⚡ Быстрый старт - Развертывание на VPS

## 🎯 Быстрое развертывание за 3 шага

### 1️⃣ Загрузите код в GitHub

```bash
# Инициализируйте Git репозиторий
chmod +x init-git.sh
./init-git.sh https://github.com/your-username/gavhar-menu.git "Initial commit"
```

### 2️⃣ Подготовьте VPS сервер

```bash
# Подключитесь к серверу
ssh root@your-server-ip

# Создайте пользователя (рекомендуется)
adduser gavhar
usermod -aG sudo gavhar
su - gavhar
```

### 3️⃣ Запустите развертывание

#### 🐳 Вариант A: Docker (Рекомендуется)

```bash
# Скачайте и запустите скрипт развертывания
curl -fsSL https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-docker.sh | bash -s -- https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

#### 🔧 Вариант B: Прямое развертывание

```bash
# Скачайте и запустите скрипт развертывания
curl -fsSL https://raw.githubusercontent.com/your-username/gavhar-menu/main/deploy-github.sh | bash -s -- https://github.com/your-username/gavhar-menu.git yourdomain.com main
```

## ✅ Готово!

После завершения развертывания:

- 🌐 Сайт: `https://yourdomain.com`
- 🔧 Админка: `https://yourdomain.com/admin`
- 👤 Логин: `admin`
- 🔑 Пароль: `gavhar2024`

## 🔄 Обновление

```bash
cd /opt/gavhar
./update.sh
```

## 📞 Нужна помощь?

Смотрите подробную инструкцию в [DEPLOY_VPS.md](DEPLOY_VPS.md)

---

**Время развертывания: ~5-10 минут** ⏱️
