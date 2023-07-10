FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
EXPOSE 8000 80

RUN apt-get update

# Initial Setup
RUN apt-get install curl -y
RUN apt-get install zip unzip

# Installing Mariadb
RUN curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash
RUN apt-get install mariadb-server mariadb-client -y

# Installing PHP
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ondrej/php
RUN apt-get install -y php8.2 php8.2-xml php8.2-mbstring php8.2-curl php8.2-bcmath php8.2-zip

# Installing Composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Installing Github
RUN apt-get install gh -y
RUN apt-get install git -y

# Installing Nginx
RUN apt-get install nginx -y

# Installing NVM
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
RUN source /root/.bashrc && nvm install 15
SHELL ["/bin/bash", "--login", "-c"]
