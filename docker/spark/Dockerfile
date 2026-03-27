FROM bitnamilegacy/spark:3.5.0-debian-12-r18

# Install networking tools
USER root
RUN apt-get update && apt-get install -y \
    dnsutils \
    iputils-ping \
    telnet \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

USER 1001
RUN curl https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar \
    --output /opt/bitnami/spark/jars/aws-java-sdk-bundle-1.12.262.jar \
&& curl https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar \
--output /opt/bitnami/spark/jars/hadoop-aws-3.3.4.jar \
&& curl https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.5/postgresql-42.7.5.jar \
--output /opt/bitnami/spark/jars/postgresql-42.7.5.jar

RUN pip install --upgrade pip
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt