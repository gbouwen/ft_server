service nginx start
service mysql start
service php7.3-fpm start

echo "127.0.0.1 localhost localhost.localdomain $(hostname)" >> /etc/hosts
service sendmail start
/bin/bash
