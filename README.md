# NexoPOS Docker
This project aims to give a docker configuration necessary to deploy NexoPOS. This project uses Ubuntu 22.04 as distro and installs the following packages:

- Nodejs (NVM)
- Nginx
- MariaDB
- Supervisor
- Composer 
- PHP 8.2
- Redis Server
- Certbot
- GNUPG (for signing commit for developpers)

# Building The Image

We'll start by building our image.

`docker build -t nexopos .`

This will install all the above package and copy/install NexoPOS on the directory `/var/www/html/nexopos`. It will also install PHPMyadmin and create a symbolic link at `/var/www/html/database`.

The default domain for both NexoPOS and phpmyadmin are: nexopos.dev and phpmyadmin.dev. You're invited to change those on:

- `/etc/nginx/sites-available/nexopos.conf`: For NexoPOS
- `/etc/nginx/sites-available/database.conf`: For PHPMyAdmin

# Running The Image
To run the image in interactive mode you'll use this command:

`docker run -it -e DB_USER=nexocloud -e DB_NAME=nexocloud -e DB_PWD=123456 -p 80:80 -p 443:443 nexopos`

# Access NexoPOS

By default, NexoPOS is configured to be available on the virtual domain `nexocloud.dev`. You'll then need to edit your system hosts file accordingly to match.
You can add the following code to your hosts file.

`127.0.0.1      nexocloud.dev`

You might change this domain by editing the configuration located at `/etc/nginx/sites-available/nexopos.conf`.