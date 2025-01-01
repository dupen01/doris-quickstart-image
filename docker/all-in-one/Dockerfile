ARG JDK=17
# 选择基础镜像
FROM registry.cn-chengdu.aliyuncs.com/mirror_d/busybox AS base

ARG VERSION=3.0.3
ARG CPU=arm64

WORKDIR /
RUN wget -q https://apache-doris-releases.oss-accelerate.aliyuncs.com/apache-doris-${VERSION}-bin-${CPU}.tar.gz
RUN tar zxf apache-doris-${VERSION}-bin-${CPU}.tar.gz && \
    rm -f apache-doris-${VERSION}-bin-${CPU}.tar.gz && \
    mv apache-doris-* apache-doris && \
    chmod g+w /apache-doris 

# 选择运行环境
FROM registry.cn-chengdu.aliyuncs.com/mirror_d/openjdk:${JDK}-slim-bullseye

ARG JDK=17
ARG VERSION=3.0.3
ENV JAVA_HOME="/usr/local/openjdk-${JDK}"
ENV TZ=Asia/Shanghai

COPY --from=base /apache-doris/fe/ /opt/apache-doris/fe/
COPY --from=base /apache-doris/be/ /opt/apache-doris/be/

RUN echo 'deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main \n\
deb-src http://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main \n'\
> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends default-mysql-client supervisor vim netcat iproute2 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    ls -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone

COPY ./resource/entrypoint.sh /opt/entrypoint.sh
COPY ./resource/start_be-${VERSION}.sh /opt/apache-doris/be/bin/start_be.sh 
COPY ./resource/supervisord.conf /etc/supervisor/supervisord.conf
COPY ./resource/deploy.sh /opt/deploy.sh

WORKDIR /opt/apache-doris

ENTRYPOINT ["bash", "/opt/entrypoint.sh"]
