# VERSION 1.10.0-5
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.6-slim
LABEL maintainer="henrytxz"

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.0
ARG AIRFLOW_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_GPL_UNIDECODE yes
ARG HADOOP_DIR=/usr/local/hadoop
ARG HIVE_DIR=/usr/local/hive

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Resolve Hive and Hadoop stuff.
ENV PATH $PATH:$HIVE_DIR/bin:$HADOOP_DIR/bin
ENV HADOOP_HOME $HADOOP_DIR
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV HADOOP_OPTS "$HADOOP_OPTS -Djava.library.path=$HADOOP_HOME/lib/native"

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        python3-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        python3-pip \
        python3-requests \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && mkdir ${HADOOP_DIR} \
    && chown -R airflow: ${HADOOP_DIR} \
    && mkdir ${HIVE_DIR} \
    && chown -R airflow: ${HIVE_DIR} \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install thrift_sasl==0.3.0 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'celery[redis]>=4.1.1,<4.2.0' \
    && pip install six==1.11.0 \
    && pip install thrift==0.9.3 \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/*

# Java, Hadoop and Hive
RUN apt-get update \
&& apt-get install wget \
&& wget -q https://download.java.net/openjdk/jdk7u75/ri/openjdk-7u75-b13-linux-x64-18_dec_2014.tar.gz \
&& mkdir -p $JAVA_HOME \
&& tar xvf openjdk-7u75-b13-linux-x64-18_dec_2014.tar.gz \
&& rm openjdk-7u75-b13-linux-x64-18_dec_2014.tar.gz \
&& mv java-se-7u75-ri/* $JAVA_HOME \
&& ln -s $JAVA_HOME/bin/java /usr/bin/java \
&& rmdir java-se-7u75-ri \
&& wget -q https://archive.apache.org/dist/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz \
&& tar -xzf hadoop-2.6.0.tar.gz --directory $HADOOP_HOME \
&& rm hadoop-2.6.0.tar.gz \
&& mv $HADOOP_HOME/hadoop-2.6.0/* $HADOOP_HOME \
&& rmdir $HADOOP_HOME/hadoop-2.6.0 \
&& wget -q https://archive.cloudera.com/cdh5/cdh/5/hive-1.1.0-cdh5.11.0.tar.gz \
&& tar -xzf hive-1.1.0-cdh5.11.0.tar.gz --directory ${HIVE_DIR} \
&& rm hive-1.1.0-cdh5.11.0.tar.gz \
&& mv ${HIVE_DIR}/hive-1.1.0-cdh5.11.0/*  ${HIVE_DIR} \
&& rmdir ${HIVE_DIR}/hive-1.1.0-cdh5.11.0

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"] # set default arg for entrypoint
