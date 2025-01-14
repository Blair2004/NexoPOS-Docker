# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y sudo

# Create a new user "nexocloud" and add it to sudoers
RUN useradd -m nexocloud && echo "nexocloud:nexocloud" | chpasswd && adduser nexocloud sudo
RUN usermod -aG sudo nexocloud
RUN echo 'nexocloud ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER root

RUN sudo chsh -s /bin/bash nexocloud

ARG DEBIAN_FRONTEND=noninteractive

# Switch to new user
USER nexocloud

# Set the working directory
WORKDIR /var/www/html

# Install MariaDB
RUN sudo apt-get update && \
    sudo apt-get install -y mariadb-server && \
    sudo apt-get install nginx -y && \
    sudo apt-get install htop -y && \
    sudo apt-get install nano -y && \
    sudo apt-get install cron -y && \
    sudo apt-get install curl -y && \
    sudo apt-get install wget -y

RUN sudo apt-get update && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx


# Install Supervisor
RUN sudo apt-get install -y supervisor
RUN sudo apt-get install -y dos2unix
RUN sudo apt-get install -y gnupg

# Install PHP 8.2 with commonly used extensions
RUN sudo apt-get install -y software-properties-common && \
    sudo add-apt-repository ppa:ondrej/php && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends php8.2 php8.2-fpm php8.2-bcmath php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-mysql php8.2-soap php8.2-xml php8.2-zip php8.2-redis

# Install NVM and set default Node version to 18
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
    && export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm install 18 \
    && nvm alias default 18

# Install Composer
RUN sudo apt-get install -y composer

# Install Redis
RUN sudo apt-get install -y redis-server

# STEP 1: install Database Manager
# Install phpMyAdmin
RUN sudo apt-get update && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin

# Create a symbolic link to the phpMyAdmin directory in the Nginx document root
RUN ln -s /usr/share/phpmyadmin /var/www/html/database

# Copy the Nginx configuration file for phpMyAdmin
COPY conf/database.conf /etc/nginx/sites-available/database.conf

# Step 2: Install NexoPOS
# Clone the NexoPOS repository to /var/www/html/default
RUN sudo apt-get install -y git && \
    git clone https://github.com/blair2004/NexoPOS.git /var/www/html/default && \
    git -C /var/www/html/default checkout master && \
    cp /var/www/html/default/.env.example /var/www/html/default/.env

# Configure PHP
RUN sudo sed -i "s/^user = www-data/user = nexocloud/" /etc/php/8.2/fpm/pool.d/www.conf
RUN sudo sed -i "s/^group = www-data/group = nexocloud/" /etc/php/8.2/fpm/pool.d/www.conf
RUN sudo sed -i 's/^\(;*\)[[:space:]]*listen.owner[[:space:]]*=[[:space:]]*.*/\1listen.owner = www-data/' /etc/php/8.2/fpm/pool.d/www.conf
RUN sudo sed -i 's/^\(;*\)[[:space:]]*listen.group[[:space:]]*=[[:space:]]*.*/\1listen.group = www-data/' /etc/php/8.2/fpm/pool.d/www.conf
RUN sudo sed -i "s/;?listen\.mode.*/listen.mode = 0666/" /etc/php/8.2/fpm/pool.d/www.conf
RUN sudo sed -i "s/;?request_terminate_timeout .*/request_terminate_timeout = 60/" /etc/php/8.2/fpm/pool.d/www.conf

# Configure Cron
RUN echo "* * * * * nexocloud php /var/www/html/default/artisan schedule:run >> /dev/null 2>&1" >> sudo /etc/crontab

# Set default PHP
RUN sudo update-alternatives --set php /usr/bin/php8.2

# Install Composer packages for the Laravel app
RUN cd /var/www/html/default && \
    composer install --no-progress --no-interaction && \
    composer require predis/predis --no-progress --no-suggest --no-interaction

# Change the queue connection on .env from sync to database
RUN sed -i "s/^QUEUE_CONNECTION=sync/QUEUE_CONNECTION=database/" /var/www/html/default/.env

RUN sudo chown -R nexocloud:nexocloud /var/www/html/default
RUN git config --global credential.helper store

# We'll get some bash script remotely, copy it to the bin directory and make them executable
RUN sudo wget https://raw.githubusercontent.com/Blair2004/localcert/refs/heads/main/localcert.sh -O /usr/local/bin/localcert.sh
RUN sudo chmod +x /usr/local/bin/localcert.sh

RUN sudo wget https://raw.githubusercontent.com/Blair2004/nginx-manager/refs/heads/main/nginx-manager.sh -O /usr/local/bin/nginx-manager.sh
RUN sudo chmod +x /usr/local/bin/nginx-manager.sh

RUN sudo wget https://raw.githubusercontent.com/Blair2004/xdebug-manager/refs/heads/main/xdebug.sh -O /usr/local/bin/xdebug.sh
RUN sudo chmod +x /usr/local/bin/xdebug.sh


# Copy the nginx configuration file

COPY sh/startup.sh /usr/local/bin/startup.sh
COPY conf/default.conf /etc/nginx/sites-available/default.conf
COPY conf/supervisor.conf /etc/supervisor/conf.d/default.conf

# We need to apply a CRLF to LF on the copied files using the "sed" method
RUN sudo sed -i 's/\r$//' /usr/local/bin/startup.sh
RUN sudo sed -i 's/\r$//' /etc/nginx/sites-available/default.conf
RUN sudo sed -i 's/\r$//' /etc/supervisor/conf.d/default.conf

RUN sudo chmod +x /usr/local/bin/startup.sh
RUN sudo ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
RUN sudo ln -s /etc/nginx/sites-available/database.conf /etc/nginx/sites-enabled/database.conf

# Start the MariaDB service
# CMD service mariadb start && /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf && service nginx start && /bin/bash
ENTRYPOINT [ "/usr/local/bin/startup.sh" ]
CMD [ "/bin/bash" ]

# docker run -d -p 80:80 -e DB_USER=nexocloud -e DB_PWD=Afromaster_2004 -e DB_NAME=nexocloud default
