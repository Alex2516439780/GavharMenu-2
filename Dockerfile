FROM node:20-alpine

WORKDIR /app

# Копируем package.json и устанавливаем зависимости
COPY package*.json ./
RUN npm ci --only=production

# Копируем код приложения
COPY . .

# Создаем необходимые папки
RUN mkdir -p data uploads logs

# Создаем пользователя
RUN addgroup -g 1001 -S nodejs
RUN adduser -S gavhar -u 1001
RUN chown -R gavhar:nodejs /app
USER gavhar

# Открываем порт
EXPOSE 3000

# Переменные окружения
ENV NODE_ENV=production
ENV PORT=3000
ENV DB_PATH=./data/database.sqlite
ENV UPLOAD_PATH=./uploads
ENV FRONTEND_URL=http://81.162.55.13
ENV ADMIN_USERNAME=admin
ENV ADMIN_PASSWORD=gavhar2024
ENV BACKUP_ENABLED=true

# Запуск приложения
CMD ["node", "server.js"]
