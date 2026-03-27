FROM apache/airflow:slim-2.10.4-python3.12
USER root

# install common linux dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      libpq-dev \
      pkg-config \
      libxml2-dev \
      libxmlsec1-dev \
      curl \
      build-essential \
      openjdk-17-jdk \
      procps \
      git \
      dnsutils \
      iputils-ping \
      telnet \
      netcat-openbsd \
      net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV SPARK_HOME="/opt/bitnami/spark"

RUN mkdir -p ${SPARK_HOME} \
    && curl https://storage.yandexcloud.net/rzv-de-pet-project-dependencies/spark-3.5.0-bin-hadoop3.tgz -o spark-3.5.0-bin-hadoop3.tgz \
    && tar xvzf spark-3.5.0-bin-hadoop3.tgz --directory ${SPARK_HOME} --strip-components 1 \
    && rm -rf spark-3.5.0-bin-hadoop3.tgz \
    && chown -R airflow ${SPARK_HOME}

ARG TARGETARCH
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-${TARGETARCH}"
ENV PATH="${JAVA_HOME}:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"
ENV SPARK_MASTER_PORT="7077"
ENV SPARK_MASTER_HOST="spark-master"

USER airflow

RUN curl https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar \
    --output "${SPARK_HOME}/jars/aws-java-sdk-bundle-1.12.262.jar" \
  && curl https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar \
    --output "${SPARK_HOME}/jars/hadoop-aws-3.3.4.jar" \
  && curl https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.5/postgresql-42.7.5.jar \
    --output "${SPARK_HOME}/jars/postgresql-42.7.5.jar"
    
RUN pip install --upgrade pip
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
RUN pip install --upgrade --no-cache-dir git+https://github.com/LexxaRRioo/opendbt.git@404f395

RUN pip install dotenv