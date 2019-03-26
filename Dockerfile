FROM ubuntu:17.10

ENV HADOOP_HOME /opt/hadoop
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN apt-get update
RUN apt-get install -y --reinstall build-essential
RUN apt-get install -y ssh 
RUN apt-get install -y rsync 
RUN apt-get install -y vim 
RUN apt-get install -y net-tools
RUN apt-get install -y openjdk-8-jdk 
RUN apt-get install -y python2.7-dev 
RUN apt-get install -y libxml2-dev 
RUN apt-get install -y libkrb5-dev 
RUN apt-get install -y libffi-dev 
RUN apt-get install -y libssl-dev 
RUN apt-get install -y libldap2-dev 
RUN apt-get install -y python-lxml 
RUN apt-get install -y libxslt1-dev 
RUN apt-get install -y libgmp3-dev 
RUN apt-get install -y libsasl2-dev 
RUN apt-get install -y libsqlite3-dev  
RUN apt-get install -y libmysqlclient-dev
RUN apt-get install -y ant 
RUN apt-get install -y gcc 
RUN apt-get install -y g++ 
RUN apt-get install -y libmysqlclient-dev 
RUN apt-get install -y libsasl2-modules-gssapi-mit 
RUN apt-get install -y make 
RUN apt-get install -y wget 
RUN apt-get install -y maven 
RUN apt-get install -y python-dev 
RUN apt-get install -y python-setuptools 
RUN apt-get install -y libgmp3-dev
RUN apt-get install -y ant
RUN apt-get upgrade -y 

# Setup Scala
ENV SCALA_HOME=/root/scala
ENV SCALA_VERSION=2.11.12
ENV PATH=$PATH:$SCALA_HOME/bin

RUN wget https://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz && \
	tar -xzvf scala-$SCALA_VERSION.tgz -C /root/ && \ 
	mv /root/scala-$SCALA_VERSION $SCALA_HOME && \ 
	rm -rf scala-$SCALA_VERSION.tgz && \ 
	rm -rf $SCALA_HOME/doc

# Setup hadoop
ENV HADOOP_HOME=/usr/lib/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native/:/root/protobuf/lib
ENV PATH=$PATH:/root/protobuf/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:.

RUN wget http://apache.mirror.amaze.com.au/hadoop/common/hadoop-2.8.5/hadoop-2.8.5.tar.gz && \
	tar -xzvf hadoop-2.8.5.tar.gz -C /root/ && \
    mv /root/hadoop-2.8.5 $HADOOP_HOME && \
    rm -rf hadoop-2.8.5.tar.gz && \
    rm -rf $HADOOP_HOME/bin/*.cmd && \
    rm -rf $HADOOP_HOME/sbin/*.cmd && \
    rm -rf $HADOOP_HOME/sbin/*all* && \
    rm -rf $HADOOP_CONF_DIR/*.cmd && \
    rm -rf $HADOOP_CONF_DIR/*.template && \
    rm -rf $HADOOP_CONF_DIR/*.example 

ADD config/hadoop/* $HADOOP_HOME/etc/hadoop/

# Setup Spark
ENV SPARK_HOME=/usr/lib/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

RUN wget http://apache.mirror.amaze.com.au/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz && \
    tar -xzvf spark-2.4.0-bin-hadoop2.7.tgz -C /root/ && \
    mv /root/spark-2.4.0-bin-hadoop2.7 $SPARK_HOME && \
    rm -rf spark-2.4.0-bin-hadoop2.7.tgz && \
    rm -rf $SPARK_HOME/bin/*.cmd && \
    rm -rf $SPARK_HOME/sbin/*.cmd && \
    rm -rf $SPARK_HOME/examples 

COPY config/spark/* $SPARK_HOME/conf/

# copy env variables
ADD config/other/bashrc /root/.bashrc


RUN \
    for user in hadoop hdfs yarn mapred hue; do \
         useradd -U -M -d $HADOOP_HOME --shell /bin/bash ${user}; \
    done && \
    for user in root hdfs yarn mapred hue; do \
         usermod -G hadoop ${user}; \
    done && \

    echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_DATANODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
#    echo "export HDFS_DATANODE_SECURE_USER=hdfs" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_NAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_SECONDARYNAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_RESOURCEMANAGER_USER=root" >> $HADOOP_HOME/etc/hadoop/yarn-env.sh && \
    echo "export YARN_NODEMANAGER_USER=root" >> $HADOOP_HOME/etc/hadoop/yarn-env.sh && \
    echo "PATH=$PATH:$HADOOP_HOME/bin" >> ~/.bashrc

# HUE
ADD hue-4.3.0 /hue-4.3.0

##
RUN mv -f /hue-4.3.0 /opt/hue
WORKDIR /opt/hue
RUN make apps

RUN chown -R hue:hue /opt/hue

WORKDIR /

####################################################################################

RUN \
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

#ADD *xml $HADOOP_HOME/etc/hadoop/

ADD config/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && \
    chown root:root /root/.ssh/config

ADD hue.ini /opt/hue/desktop/conf

EXPOSE 8088 9870 9864 19888 8042 8888 50070 8080 8042

CMD [ "sh", "-c", "service sshd start; bash"]