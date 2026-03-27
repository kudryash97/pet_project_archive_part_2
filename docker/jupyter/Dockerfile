# jupyter/Dockerfile
FROM bitnamilegacy/spark:3.5.0-debian-12-r18

USER root

RUN install_packages curl python3-pip \
    && pip3 install --upgrade pip

# Add the same Hadoop AWS and AWS SDK jars as your other containers
RUN curl https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar \
    --output /opt/bitnami/spark/jars/aws-java-sdk-bundle-1.12.262.jar \
    && curl https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar \
    --output /opt/bitnami/spark/jars/hadoop-aws-3.3.4.jar \
    && curl https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.5/postgresql-42.7.5.jar \
    --output /opt/bitnami/spark/jars/postgresql-42.7.5.jar

# Create notebooks directory
RUN mkdir -p /notebooks && chmod 777 /notebooks

WORKDIR /notebooks

# Set environment variables
ENV SPARK_HOME=/opt/bitnami/spark
ENV PATH=$SPARK_HOME/bin:$PATH
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:$PYTHONPATH
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

USER 1001

ENV HOME=/opt/bitnami/spark
WORKDIR /opt/bitnami/spark
RUN mkdir -p ~/.jupyter ~/.local/share/jupyter/runtime && \
    chmod -R 755 ~/.jupyter ~/.local

# Create jupyter config in the spark home directory  
RUN jupyter notebook --generate-config && \
    echo "c.NotebookApp.token = ''" >> ~/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.password = ''" >> ~/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.ip = '0.0.0.0'" >> ~/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.allow_root = True" >> ~/.jupyter/jupyter_notebook_config.py