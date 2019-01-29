#FROM phusion/baseimage:latest
FROM ubuntu:16.04
LABEL maintainer="Rui Fernandes (@bitkill)"

RUN DEBIAN_FRONTEND=noninteractive
RUN apt-get clean && apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8

ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TERM xterm

# Add the "PHP 7" ppa
RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php

#
#--------------------------------------------------------------------------
# Software Install
#--------------------------------------------------------------------------
#

# Install "PHP Extentions", "libraries", "software"
RUN apt-get update && \
    apt-get install -y --allow-downgrades --allow-remove-essential \
        --allow-change-held-packages \
        php7.3-cli \
        php7.3-common \
        php7.3-curl \
        php7.3-intl \
        php7.3-json \
        php7.3-xml \
        php7.3-mbstring \
        php7.3-mysql \
        php7.3-pgsql \
        php7.3-sqlite \
        php7.3-sqlite3 \
        php7.3-zip \
        php7.3-bcmath \
        php7.3-memcached \
        php7.3-gd \
        php7.3-dev \
        pkg-config \
        libcurl4-openssl-dev \
        libedit-dev \
        libssl-dev \
        libxml2-dev \
        xz-utils \
        libsqlite3-dev \
        sqlite3 \
        git \
        curl \
        vim \
        nano \
        postgresql-client \
        mysql-client \
	python \
        openssh-server && \
        mkdir /var/run/sshd

#####################################
# Composer:
#####################################

# Install composer and add its bin to the PATH.
RUN curl -s http://getcomposer.org/installer | php && \
    echo "export PATH=${PATH}:/var/www/vendor/bin" >> ~/.bashrc && \
    mv composer.phar /usr/local/bin/composer

# Source the bash
RUN . ~/.bashrc


#####################################
# Non-Root User:
#####################################

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ARG PGID=1000

ENV PUID ${PUID}
ENV PGID ${PGID}

RUN groupadd -g ${PGID} workspace && \
useradd -u ${PUID} -g workspace -m workspace

#####################################
# Set Timezone
#####################################

ARG TZ=UTC
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#####################################
# PHP REDIS EXTENSION FOR PHP 7.x
#####################################

ARG INSTALL_PHPREDIS=true
ENV INSTALL_PHPREDIS ${INSTALL_PHPREDIS}
RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    # update stuff
    pecl channel-update pecl.php.net && \
    # Install Php Redis extension
    printf "\n" | pecl -q install -o -f redis && \
    echo "extension=redis.so" >> /etc/php/7.2/mods-available/redis.ini && \
    phpenmod redis \
;fi

#####################################
# Node / NVM:
#####################################

# Check if NVM needs to be installed
ARG NODE_VERSION=stable
ENV NODE_VERSION ${NODE_VERSION}
ARG NPM_REGISTRY
ENV NPM_REGISTRY ${NPM_REGISTRY}
ENV NVM_DIR /home/workspace/.nvm
# Install nvm (A Node Version Manager)
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install ${NODE_VERSION} && \
    nvm use ${NODE_VERSION} && \
    nvm alias ${NODE_VERSION} && \
    if [ ${NPM_REGISTRY} ]; then \
    npm config set registry ${NPM_REGISTRY} \
    ;fi && \
    npm install -g gulp yarn webpack vue-cli \

# Wouldn't execute when added to the RUN statement in the above block
# Source NVM when loading bash since ~/.profile isn't loaded on non-login shell
RUN if true; then \
    echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc \
;fi
# Add NVM binaries to root's .bashrc
USER root
RUN if true; then \
    echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="/home/workspace/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc \
;fi

USER workspace
RUN if true; then \
    echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="/home/workspace/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc \
;fi

# Add PATH for node
ENV PATH $PATH:$NVM_DIR/versions/node/v${NODE_VERSION}/bin

USER root
# Add PATH for node
ENV PATH $PATH:$NVM_DIR/versions/node/v${NODE_VERSION}/bin

#--------------------------------------------------------------------------
# Final Stuff
#--------------------------------------------------------------------------

# Clean up
USER root
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#USER workspace
# Set default work directory

EXPOSE 22

WORKDIR /var/www

CMD    ["/usr/sbin/sshd", "-D"]
