# Adapted for Spark 2.0.2 from https://raw.githubusercontent.com/jupyter/docker-stacks/master/pyspark-notebook/Dockerfile
FROM jupyter/scipy-notebook

USER jovyan

# Import modules from Jupyter Notebooks
# https://github.com/ipython/ipynb
RUN /opt/conda/bin/pip install --upgrade pip && \
    /opt/conda/bin/pip install ipynb

USER root

# Dev dependencies
RUN apt-get -y update && \
    apt-get -y install apt-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Spark dependencies
# Currently, Java8 is not available from Debian Jessie.
# So, we're installing it from Jessie Backports.
ENV APACHE_SPARK_VERSION 2.0.2
RUN echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-get -y update && \
    apt-get -t jessie-backports -y install openjdk-8-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN cd /tmp && \
    wget -q http://www.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop2.7.tgz && \
    echo "9a1d19ab295d1252ecb0a4adcaaf5f215a75dc7427597af9a9475f0c0fe0a59713ff601e5c13ece25eccd67913167fab85a04d1c104a51c027d4f39e2c414034 *spark-${APACHE_SPARK_VERSION}-bin-hadoop2.7.tgz" | sha512sum -c - && \
    tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop2.7.tgz -C /usr/local && \
    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop2.7.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop2.7 spark

# Mesos dependencies
# Currently, Mesos is not available from Debian Jessie.
# So, we are installing it from Debian Wheezy. Once it
# becomes available for Debian Jessie. We should switch
# over to using that instead.
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
    DISTRO=debian && \
    CODENAME=wheezy && \
    echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-get -y update && \
    apt-get --no-install-recommends -y --force-yes install mesos=0.22.1-1.0.debian78 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Spark and Mesos config
ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.3-src.zip
ENV MESOS_NATIVE_LIBRARY /usr/local/lib/libmesos.so
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info

USER $NB_USER
