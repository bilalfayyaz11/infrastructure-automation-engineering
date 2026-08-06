FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

WORKDIR /app

RUN groupadd --system --gid 10001 appgroup \
    && useradd \
       --system \
       --uid 10001 \
       --gid appgroup \
       --home-dir /app \
       --shell /usr/sbin/nologin \
       appuser

COPY requirements.txt .

RUN pip install \
      --no-cache-dir \
      --disable-pip-version-check \
      --requirement requirements.txt

COPY --chown=appuser:appgroup app.py .

USER appuser

EXPOSE 5000

HEALTHCHECK \
  --interval=15s \
  --timeout=5s \
  --start-period=10s \
  --retries=5 \
  CMD python -c \
  "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=3)"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "2", "--timeout", "30", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
