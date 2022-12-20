# syntax=docker/dockerfile:1

ARG UID=1000
ARG GID=1000
ARG MAINTAINER="nullester"

FROM ubuntu as builder

ARG UID
ARG GID
ARG MAINTAINER

RUN echo "Maintainer is \033[032m${MAINTAINER}\033[0m"
LABEL maintainer="${MAINTAINER}"

ENV LC_ALL="C.UTF-8" \
    LANG="C.UTF-8" \
    HOME="/root" \
    DEBIAN_FRONTEND=noninteractive

# Base packages
FROM builder as build1
RUN echo 'apt::install-recommends "false";' > /etc/apt/apt.conf.d/00recommends
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils > /dev/null 2>&1
RUN set -e; apt-get install -y \
    apt-transport-https \
    gcc \
    g++ \
    make \
    build-essential \
    locales \
    curl \
    vim \
    nano \
    wget \
    gnupg \
    htop \
    ca-certificates \
    software-properties-common \
    libonig-dev \
    libxml2-dev \
    iputils-ping \
    sudo \
    tree \
    openssl \
    ssh \
    git \
    net-tools \
    libncurses5-dev \
    libzip-dev \
    zlib1g-dev \
    zip \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    rsync \
    p7zip \
    xz-utils \
    autoconf \
    libc-dev \
    pkg-config \
    systemd

# Locales
FROM build1 as build2
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen; \
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "pl_PL.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "nl_BE.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen
ENV LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8"

# OpenSSL
FROM build2 as build3
RUN sed -Ezi 's/\[\ *default_sect\ *\]\n\#\ ?/\[default_sect\]\n/' /etc/ssl/openssl.cnf
RUN sed -Ezi 's/\[\ *default_sect\ *\]/\[legacy_sect\]\nactive\ =\ 1\n\[default_sect\]/' /etc/ssl/openssl.cnf
RUN sed -Ezi 's/\n\[\ *provider_sect\ *\]\n/\n\[provider_sect\]\nlegacy\ \=\ legacy_sect\n/' /etc/ssl/openssl.cnf

# User stuff
FROM build3 as build4
USER root
RUN groupadd -g ${GID:-1000} -o docker
RUN useradd -m -u ${UID:-1000} -g docker -s /bin/bash docker
RUN usermod -a -G sudo docker
RUN mkdir /home/docker/.ssh
RUN chown -R docker:docker /home/docker
RUN usermod -d /root root
RUN usermod -d /home/docker docker
RUN su root -c "export HOME=/root && echo 'export HOME=/root' >> /root/.bashrc"
RUN su docker -c "export HOME=/home/docker && echo 'export HOME=/home/docker' >> /home/docker/.bashrc"
RUN echo "root:secret" > /tmp/passwd.txt && echo "docker:secret" >> /tmp/passwd.txt && chpasswd < /tmp/passwd.txt && shred -n 3 /tmp/passwd.txt && rm /tmp/passwd.txt
RUN echo '%docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Prepare entrypoint
FROM build4 as build5
COPY entrypoint.sh /entry/ubuntu
RUN chmod +x /entry/ubuntu

# FROM build5
# ENTRYPOINT ["/entry/ubuntu"]
