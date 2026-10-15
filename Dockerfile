# Образ приложения в два этапа: компилятор остаётся на первом этапе,
# во второй попадает только результат — виртуальное окружение /venv.

# ----- Этап 1: сборка зависимостей -----
FROM python:3.12-slim AS build

# Пакеты этапа сборки: компилятор и заголовки
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libc6-dev libpq-dev default-libmysqlclient-dev pkg-config \
 && rm -rf /var/lib/apt/lists/*

# Виртуальное окружение: соберём зависимости в него
RUN python -m venv /venv

WORKDIR /app
COPY requirements.txt .
RUN /venv/bin/pip install --no-cache-dir -r requirements.txt

# ----- Этап 2: рабочий образ -----
FROM python:3.12-slim

# Пакеты этапа запуска: только библиотеки баз, без заголовков и компилятора
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 libmariadb3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Копируем готовое окружение из этапа сборки
COPY --from=build /venv /venv
ENV PATH=/venv/bin:$PATH

COPY app.py .

ARG VERSION=5.0
RUN echo "$VERSION" > /app/VERSION

ENV PYTHONDONTWRITEBYTECODE=1
STOPSIGNAL SIGINT
CMD ["python", "app.py"]
