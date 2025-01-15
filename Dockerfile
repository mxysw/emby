# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# 设置版本标签
ARG BUILD_DATE
ARG VERSION
ARG EMBY_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

ARG DEBIAN_FRONTEND="noninteractive"

# 添加所需的 NVIDIA 环境变量以支持 https://github.com/NVIDIA/nvidia-docker
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

# 安装软件包和 cron
RUN \
  echo "**** 安装 Emby 和 cron ****" && \
  mkdir -p \
    /app/emby \
    /tmp/emby && \
  if [ -z "${EMBY_RELEASE+x}" ]; then \
    EMBY_RELEASE=$(curl -s https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest \
    | jq -r '. | .tag_name'); \
  fi && \
  curl -o \
    /tmp/emby.deb -L \
    "https://github.com/MediaBrowser/Emby.Releases/releases/download/${EMBY_RELEASE}/emby-server-deb_${EMBY_RELEASE}_amd64.deb" && \
  dpkg-deb -xv /tmp/emby.deb /tmp/emby/ && \
  mv -t \
    /app/emby/ \
    /tmp/emby/opt/emby-server/* && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  apt-get update && apt-get install -y cron && \
  echo "**** 清理 ****" && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# 将更新主机文件的脚本复制到容器中，并设置为可执行
COPY update-hosts.sh /usr/local/bin/update-hosts.sh
RUN chmod +x /usr/local/bin/update-hosts.sh

# 创建日志文件并设置权限
RUN touch /var/log/update-hosts.log && chmod 666 /var/log/update-hosts.log

# 复制本地文件（如果有其他需要复制的文件）
COPY root/ /

# 设置定时任务以每30分钟运行一次更新主机文件的脚本
RUN echo "*/30 * * * * root /usr/local/bin/update-hosts.sh >> /var/log/update-hosts.log 2>&1" > /etc/cron.d/update-hosts

# 给予定时任务适当的权限
RUN chmod 0644 /etc/cron.d/update-hosts

# 暴露端口和卷
EXPOSE 8096 8920
VOLUME /config

# 复制并设置 entrypoint.sh 为可执行
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 使用自定义 entrypoint 启动所有服务
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]