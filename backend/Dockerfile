# ============================================================
# AI Resume Analyzer - Backend
# Production Docker Image
# ============================================================

FROM python:3.12-slim AS runtime

# Prevent Python from creating .pyc files and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# ------------------------------------------------------------
# System dependencies
# ------------------------------------------------------------
# libpq5 is required by psycopg2 at runtime.
# curl is useful for container health checks.
# ------------------------------------------------------------

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 \
        curl && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Install Python dependencies
# ------------------------------------------------------------

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# ------------------------------------------------------------
# Copy application
# ------------------------------------------------------------

COPY app ./app

# ------------------------------------------------------------
# Security: run as non-root
# ------------------------------------------------------------

RUN useradd \
        --create-home \
        --shell /usr/sbin/nologin \
        --uid 10001 \
        appuser && \
    chown -R appuser:appuser /app

USER appuser

# ------------------------------------------------------------
# Application port
# ------------------------------------------------------------

EXPOSE 8000

# ------------------------------------------------------------
# Container health check
# ------------------------------------------------------------

HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=20s \
    --retries=3 \
    CMD curl --fail http://127.0.0.1:8000/health || exit 1

# ------------------------------------------------------------
# Start FastAPI
# ------------------------------------------------------------

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
