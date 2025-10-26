# Многостадийный Dockerfile для сборки бэкенда и фронтенда
FROM node:18-alpine AS backend-builder
WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Финальный образ
FROM node:18-alpine
RUN apk add --no-cache curl
WORKDIR /app

# Копируем собранный бэкенд
COPY --from=backend-builder /app/backend/node_modules ./backend/node_modules
COPY backend/ ./backend/

# Копируем статичные файлы фронтенда
COPY --from=frontend-builder /app/frontend/dist ./backend/public

# Создаем не-root пользователя для безопасности
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup
USER appuser

# Настройка здоровья приложения
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/api/health || exit 1

EXPOSE 5000

CMD ["node", "backend/server.js"]
