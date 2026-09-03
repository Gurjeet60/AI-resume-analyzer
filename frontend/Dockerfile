# ============================================================
# AI Resume Analyzer - Frontend
# Production Docker Image
# ============================================================

# ------------------------------------------------------------
# Stage 1: Build React application
# ------------------------------------------------------------

FROM node:22-alpine AS builder

WORKDIR /app

# Install dependencies first for better Docker layer caching
COPY package.json package-lock.json ./

RUN npm ci

# Copy source
COPY . .

# Build production frontend
RUN npm run build


# ------------------------------------------------------------
# Stage 2: Production Nginx image
# ------------------------------------------------------------

FROM nginx:1.29-alpine AS runtime

# Remove default Nginx configuration
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy production React build
COPY --from=builder /app/dist /usr/share/nginx/html

# React SPA configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# ------------------------------------------------------------
# Security
# ------------------------------------------------------------

RUN chown -R nginx:nginx \
        /usr/share/nginx/html \
        /var/cache/nginx \
        /var/log/nginx \
        /etc/nginx/conf.d

# ------------------------------------------------------------
# Container port
# ------------------------------------------------------------

EXPOSE 80

# ------------------------------------------------------------
# Start Nginx
# ------------------------------------------------------------

CMD ["nginx", "-g", "daemon off;"]
