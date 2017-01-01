FROM python:3.5

ENV PYTHONUNBUFFERED 1
ENV REDIS_HOST "redis"

WORKDIR /app
COPY requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
