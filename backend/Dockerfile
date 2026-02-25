# Multi-stage build: compile frontend, then package FastAPI backend with baked-in static assets.
FROM node:20 AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --no-audit --prefer-offline
COPY frontend/ .
RUN npm run build

FROM python:3.11-slim AS backend
ENV PYTHONUNBUFFERED=1 \
    PORT=8080
WORKDIR /app

# Install backend and script dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source and attach compiled frontend assets
COPY backend/ ./backend/
COPY --from=frontend-builder /app/frontend/dist ./backend/static

WORKDIR /app/backend
EXPOSE 8080

# Serve FastAPI with Uvicorn in production mode
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
