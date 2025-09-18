#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Проверка зависимостей для развертывания Gavhar Menu"
echo "=================================================="

# Функция проверки
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 установлен${NC}"
        if [ "$1" = "node" ]; then
            echo "   Версия: $(node --version)"
        elif [ "$1" = "npm" ]; then
            echo "   Версия: $(npm --version)"
        elif [ "$1" = "pm2" ]; then
            echo "   Версия: $(pm2 --version)"
        fi
        return 0
    else
        echo -e "${RED}❌ $1 НЕ установлен${NC}"
        return 1
    fi
}

# Проверяем системные команды
echo ""
echo "📦 Системные пакеты:"
check_command "git"
check_command "curl"
check_command "wget"
check_command "unzip"

# Проверяем Node.js и npm
echo ""
echo "🟢 Node.js и npm:"
check_command "node"
check_command "npm"

# Проверяем PM2
echo ""
echo "🔄 PM2:"
check_command "pm2"

# Проверяем Nginx
echo ""
echo "🌐 Nginx:"
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx запущен${NC}"
    echo "   Статус: $(systemctl is-active nginx)"
else
    echo -e "${YELLOW}⚠️  Nginx не запущен${NC}"
fi

# Проверяем Certbot
echo ""
echo "🔒 SSL (Certbot):"
check_command "certbot"

# Проверяем файрвол
echo ""
echo "🔥 Файрвол (UFW):"
if command -v ufw &> /dev/null; then
    echo -e "${GREEN}✅ UFW установлен${NC}"
    echo "   Статус: $(ufw status | head -1)"
else
    echo -e "${RED}❌ UFW НЕ установлен${NC}"
fi

# Проверяем Fail2ban
echo ""
echo "🛡️  Fail2ban:"
if systemctl is-active --quiet fail2ban; then
    echo -e "${GREEN}✅ Fail2ban запущен${NC}"
else
    echo -e "${YELLOW}⚠️  Fail2ban не запущен${NC}"
fi

# Проверяем порты
echo ""
echo "🔌 Проверка портов:"
if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}✅ Порт 80 открыт${NC}"
else
    echo -e "${YELLOW}⚠️  Порт 80 не открыт${NC}"
fi

if netstat -tlnp 2>/dev/null | grep -q ":443 "; then
    echo -e "${GREEN}✅ Порт 443 открыт${NC}"
else
    echo -e "${YELLOW}⚠️  Порт 443 не открыт${NC}"
fi

if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
    echo -e "${GREEN}✅ Порт 3000 открыт${NC}"
else
    echo -e "${YELLOW}⚠️  Порт 3000 не открыт${NC}"
fi

# Проверяем права доступа
echo ""
echo "📁 Права доступа:"
if [ -d "/opt/gavhar" ]; then
    echo -e "${GREEN}✅ Директория /opt/gavhar существует${NC}"
    echo "   Владелец: $(ls -ld /opt/gavhar | awk '{print $3":"$4}')"
else
    echo -e "${YELLOW}⚠️  Директория /opt/gavhar не существует${NC}"
fi

# Итоговая оценка
echo ""
echo "=================================================="
echo "📊 Итоговая оценка готовности:"

MISSING_COUNT=0

# Подсчитываем отсутствующие компоненты
if ! command -v node &> /dev/null; then ((MISSING_COUNT++)); fi
if ! command -v npm &> /dev/null; then ((MISSING_COUNT++)); fi
if ! command -v pm2 &> /dev/null; then ((MISSING_COUNT++)); fi
if ! command -v git &> /dev/null; then ((MISSING_COUNT++)); fi
if ! command -v curl &> /dev/null; then ((MISSING_COUNT++)); fi

if [ $MISSING_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 Все основные компоненты установлены!${NC}"
    echo -e "${GREEN}✅ Сервер готов к развертыванию${NC}"
else
    echo -e "${YELLOW}⚠️  Отсутствует $MISSING_COUNT компонентов${NC}"
    echo -e "${YELLOW}📋 Установите недостающие компоненты перед развертыванием${NC}"
fi

echo ""
echo "📖 Для установки недостающих компонентов используйте:"
echo "   QUICK_VPS_SETUP.md - быстрая установка"
echo "   VPS_SETUP_GUIDE.md - подробная инструкция"
