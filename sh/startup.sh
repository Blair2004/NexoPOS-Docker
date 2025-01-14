#!/bin/bash

# Starting the services
sudo service mariadb start 
sudo service supervisor start
sudo service php8.2-fpm start
sudo service cron start
sudo service nginx start

sudo mysql -u root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PWD';"
sudo mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# Define the keys and their corresponding environment variables
declare -A keys=(["DB_DATABASE"]=$DB_NAME ["DB_USERNAME"]=$DB_USER ["DB_PASSWORD"]=$DB_PWD)

# # Loop over the keys
for key in "${!keys[@]}"; do
    # If the key exists in the .env file, update it. Otherwise, add it.
    if grep -q "^$key=" /var/www/html/default/.env; then
        # The key exists, so update it
        sed -i "s/^$key=.*/$key=${keys[$key]}/" /var/www/html/default/.env
    else
        # The key doesn't exist, so add it
        echo "$key=${keys[$key]}" >> /var/www/html/default/.env
    fi
done

cd /var/www/html/default && sudo chown nexocloud:nexocloud . -R

# make sure supervisor is running
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start all

/bin/bash