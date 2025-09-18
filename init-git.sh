#!/bin/bash
set -euo pipefail

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Проверка аргументов
if [ $# -eq 0 ]; then
    echo "Использование: $0 <GITHUB_REPO_URL> [COMMIT_MESSAGE]"
    echo "Пример: $0 https://github.com/username/gavhar-menu.git 'Initial commit'"
    exit 1
fi

GITHUB_REPO=$1
COMMIT_MESSAGE=${2:-"Initial commit"}

log "🚀 Инициализация Git репозитория для Gavhar Menu"
log "📦 Репозиторий: $GITHUB_REPO"

# Проверка, что мы в правильной директории
if [ ! -f "package.json" ]; then
    warn "package.json не найден. Убедитесь, что вы находитесь в корневой директории проекта."
    exit 1
fi

# Инициализация Git (если еще не инициализирован)
if [ ! -d ".git" ]; then
    log "📁 Инициализация Git репозитория..."
    git init
    git branch -M main
else
    log "📁 Git репозиторий уже инициализирован"
fi

# Добавление удаленного репозитория
log "🔗 Настройка удаленного репозитория..."
git remote remove origin 2>/dev/null || true
git remote add origin $GITHUB_REPO

# Добавление всех файлов
log "📝 Добавление файлов в Git..."
git add .

# Создание коммита
log "💾 Создание коммита..."
git commit -m "$COMMIT_MESSAGE"

# Отправка в GitHub
log "📤 Отправка в GitHub..."
git push -u origin main

log "✅ Репозиторий успешно настроен!"
log "🌐 Код доступен по адресу: $GITHUB_REPO"
log ""
log "📋 Следующие шаги:"
log "1. Убедитесь, что все файлы загружены корректно"
log "2. Настройте GitHub Actions (если нужно)"
log "3. Создайте релизы для версионирования"
log "4. Настройте защиту ветки main"
