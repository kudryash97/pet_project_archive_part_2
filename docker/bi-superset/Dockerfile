FROM apache/superset:4.1.2
USER root
RUN apt-get update && apt-get install -y \
    python3-dev \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    postgresql-client

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt