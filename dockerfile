FROM armv7/armhf-debian
MAINTAINER Tomasz Derkowski <derkowskitomasz@gmail.com>

RUN dpkg --print-architecture \
    && groupadd -r mysql && useradd -r -g mysql mysql

RUN apt-get update \
    && echo "mysql-server mysql-server/root_password password root" | debconf-set-selections \
    && echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections \
    && apt-get install -y --no-install-recommends --no-install-suggests \
       supervisor \
       mysql-server \
       mysql-client \
       apache2 \
       php5-mysql \
       php5-gd \
       php5-ldap \
       php5 \
       snmpd \
       ttf-dejavu-core \
       ttf-japanese-gothic \
       libiksemel3 \
       libodbc1 \
       libopenipmi0 \
       nano \
       fping \
       libc6 \
       libcurl3 \
       libldap-2.4-2 \
       libsnmp30 \
       libssh2-1 \
       libssl1.0.0 \
       libxml2 \
       libmysqlclient18 \
       locales \
    && mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld 

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf  
COPY mysqld.cnf /etc/mysql/my.cnf
COPY zabbix-release_3.0-1+jessie_all.deb /tmp/
COPY zabbix-frontend-php_3.0.2-1+jessie_all.deb /tmp/ 
COPY zabbix-server-mysql_3.0.2-1+jessie_armhf.deb /tmp/

RUN dpkg -i /tmp/zabbix-release* \
    && dpkg -i /tmp/zabbix-frontend-php* \
    && dpkg -i /tmp/zabbix-server-mysql* \
    && dpkg -i /tmp/zabbix-agent* \
    && rm -rf /tmp/* \
    && apt-get clean \
    && apt-get autoclean
COPY zabbix_server.conf /etc/zabbix/zabbix_server.conf
COPY apache.conf /etc/apache2/apache.conf
COPY php.ini /etc/php5/apache2/php.ini

RUN service apache2 restart \
    && usermod -d /var/lib/mysql/ mysql \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && service mysql start \
    && echo "Grant root privileges" \
    && mysql -u root -proot -e "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;" \
    && echo "Create zabbix database and add privileges to zabbix user" \
    && mysql -u root -proot -e "CREATE DATABASE zabbix CHARACTER SET UTF8 COLLATE UTF8_BIN; GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@'%' IDENTIFIED BY 'zabbix'; FLUSH PRIVILEGES;" \
    && echo "Add zabbix server schema to mysql database" \
    && zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u zabbix -pzabbix zabbix \
    && echo "Show databases" \
    && mysql -u root -proot -e "SHOW DATABASES;" \
    && echo "Show root privileges" \
    && mysql -u root -proot -e "SHOW GRANTS FOR root;" \
    && echo "Show zabbix user privileges" \
    && mysql -u root -proot -e "SHOW GRANTS FOR zabbix;"

VOLUME /var/lib/mysql

EXPOSE 80 3306 10050

CMD ["/usr/bin/supervisord"]
