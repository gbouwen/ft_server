# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: gbouwen <marvin@codam.nl>                    +#+                      #
#                                                    +#+                       #
#    Created: 2020/01/22 08:20:46 by gbouwen       #+#    #+#                  #
#    Updated: 2020/02/01 13:57:30 by gbouwen       ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

FROM	debian:buster

EXPOSE	80 443

RUN		apt-get update -y
RUN		apt-get upgrade -y

#		Install necessary packages
RUN		apt-get install	-y wget
RUN		apt-get install -y sudo
RUN		apt-get install -y sendmail
RUN		apt-get install -y nginx
RUN		apt-get install -y mariadb-server
RUN		apt-get install -y php php-fpm php-mysql php-zip php-mbstring php-json

#		Download & install PHPMyAdmin
RUN		mkdir -p /var/www/html/wordpress
RUN		wget https://files.phpmyadmin.net/snapshots/phpMyAdmin-4.9+snapshot-all-languages.tar.gz -P tmp
RUN		tar -zxvf /tmp/phpMyAdmin-4.9+snapshot-all-languages.tar.gz -C /tmp
RUN		cp -r /tmp/phpMyAdmin-4.9+snapshot-all-languages/. \
		/var/www/html/wordpress/phpmyadmin
RUN		chmod 755 /var/www/html/wordpress/phpmyadmin/tmp

#		Create database & admin user
RUN		service mysql start && mysql -e "CREATE DATABASE wordpress_db;" && \
		mysql -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'admin';" && \
		mysql -e \
		"GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;" && \
		mysql -e "FLUSH PRIVILEGES;"

#		Create super user to configure wordpress
RUN		adduser --disabled-password --gecos "" gijs
RUN		sudo adduser gijs sudo

#		Download & install wordpress-cli
RUN		wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P tmp
RUN		chmod 755 tmp/wp-cli.phar
RUN		mv /tmp/wp-cli.phar /usr/local/bin/wp
RUN		wp cli update

#		Download & configure wordpress
RUN		service mysql start && sudo -u gijs -i wp core download && \
		sudo -u gijs -i wp core config --dbname=wordpress_db --dbuser=admin --dbpass=admin && \
		sudo -u gijs -i wp core install --url=https://localhost/ --title=WordPress \
		--admin_user=admin --admin_password=admin --admin_email=gijsbouwen@gmail.com
RUN		cp -r /home/gijs/. /var/www/html/wordpress
RUN		chown -R www-data:www-data /var/www/html/*

COPY	/srcs/server.key /etc/ssl/private/
COPY	/srcs/server.crt /etc/ssl/certs/
COPY	/srcs/server.conf /etc/nginx/sites-enabled
COPY	/srcs/server.conf /etc/nginx/sites-available
COPY	/srcs/config.inc.php /var/www/html/wordpress/phpmyadmin
COPY	/srcs/php.ini /etc/php/7.3/fpm/php.ini
COPY	/srcs/start.sh /tmp

CMD		/bin/bash /tmp/start.sh
