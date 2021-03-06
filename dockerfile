FROM armv7/armhf-debian
MAINTAINER Tomasz Derkowski <derkowskitomasz@gmail.com>

ARG root_passwd=toor
ARG zabbix_passwd=zabbix

RUN echo "mysql-server mysql-server/root_password password $root_passwd" | debconf-set-selections \
    && echo "mysql-server mysql-server/root_password_again password $root_passwd" | debconf-set-selections \
    && groupadd -r mysql && useradd -r -g mysql mysql \
    && apt-get update \
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
    && echo "pl_PL.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "cs_CZ.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "ko_KR.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "sk_SK.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "uk_UA.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen

COPY zabbix-release_3.0-1+jessie_all.deb /tmp/
COPY zabbix-frontend-php_3.0.2-1+jessie_all.deb /tmp/ 
COPY zabbix-server-mysql_3.0.2-1+jessie_armhf.deb /tmp/

RUN dpkg -i /tmp/zabbix-release* \
    && dpkg -i /tmp/zabbix-frontend-php* \
    && dpkg -i /tmp/zabbix-server-mysql* \
    && rm -rf /tmp/* \
    && apt-get clean \
    && apt-get autoclean

COPY zabbix_server.conf /etc/zabbix/zabbix_server.conf
COPY apache.conf /etc/apache2/apache.conf
COPY php.ini /etc/php5/apache2/php.ini
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf  
COPY mysqld.cnf /etc/mysql/my.cnf

RUN service apache2 restart \
    && mkdir -p /var/run/mysqld \
    && usermod -d /var/lib/mysql/ mysql \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && service mysql start \
    && echo "Grant root privileges" \
    && mysql -u root -p$root_passwd -e "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '$root_passwd' WITH GRANT OPTION; FLUSH PRIVILEGES;" \
    && echo "Create zabbix database and add privileges to zabbix user" \
    && mysql -u root -p$root_passwd -e "CREATE DATABASE zabbix CHARACTER SET UTF8 COLLATE UTF8_BIN; GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@'%' IDENTIFIED BY '$zabbix_passwd'; FLUSH PRIVILEGES;" \
    && echo "Add zabbix server schema to mysql database" \
    && zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u zabbix -p$zabbix_passwd zabbix \
    && echo "Show databases" \
    && mysql -u root -p$root_passwd -e "SHOW DATABASES;" \
    && echo "Show root privileges" \
    && mysql -u root -p$root_passwd -e "SHOW GRANTS FOR root;" \
    && echo "Show zabbix user privileges" \
    && mysql -u root -p$root_passwd -e "SHOW GRANTS FOR zabbix;"

VOLUME /var/lib/mysql

EXPOSE 80 3306 10051

CMD ["/usr/bin/supervisord"]

