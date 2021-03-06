FROM debian:buster
LABEL maintainer="Noah Sandman <noah@modulytic.com>"

# set version of OpenSIPs to install
ARG OPENSIPS_VERSION=3.0
ARG CTRLPANEL_VERSION=8.3.0
ARG PHP_VERSION=7.0

# update, install packages to be able to deal with https repos
RUN apt-get update -qq && apt-get install -y gnupg2 ca-certificates apt-utils curl

# update repositories
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 049AD65B \
	&& curl -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
	&& echo "deb https://apt.opensips.org buster ${OPENSIPS_VERSION}-releases" >>/etc/apt/sources.list \
	&& echo "deb https://apt.opensips.org bionic cli-releases" >/etc/apt/sources.list.d/opensips-cli.list \
	&& echo "deb https://packages.sury.org/php/ buster main" > /etc/apt/sources.list.d/php.list \
	&& curl -Ss https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash \
	&& apt-get update; apt-get upgrade -y

# add repo for OpenSIPs and install it
RUN apt-get install -y opensips opensips-cli opensips-mysql-module \
	&& touch /var/log/opensips.log

# Download and install OpenSIPs Control Panel
RUN apt-get install -y debconf-utils mariadb-server \
	&& echo "mariadb-server mariadb-server/root_password password mariadb" | debconf-set-selections \
	&& echo "mariadb-server mariadb-server/root_password_again password mariadb" | debconf-set-selections \
	&& apt-get -y install php${PHP_VERSION} php${PHP_VERSION}-gd php${PHP_VERSION}-mysql php${PHP_VERSION}-xmlrpc php-pear php${PHP_VERSION}-cli php-apcu php${PHP_VERSION}-curl php${PHP_VERSION}-xml libapache2-mod-php${PHP_VERSION} \
	&& apt-get -y install git iptables opensips-mysql-module expect 

COPY conf/apache2-opensips.conf /etc/apache2/sites-available/opensips.conf
COPY conf/etc-opensips/opensipsctlrc /etc/opensips/opensipsctlrc
COPY script/dbcreate.sh /root/dbcreate.sh

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf \
	&& a2dissite 000-default.conf \
	&& a2ensite opensips.conf \
	&& a2enmod ssl \
	&& pear install MDB2#mysql \
	&& sed -i "s#short_open_tag = Off#short_open_tag = On#g" /etc/php/${PHP_VERSION}/apache2/php.ini \
	&& pear install log

RUN cd /var/www \
	&& git clone --branch ${CTRLPANEL_VERSION} https://github.com/OpenSIPS/opensips-cp \
	&& chown -R www-data:www-data /var/www/opensips-cp/ \
	&& cd /var/www/opensips-cp/

COPY script/dbsetup.sh /root/dbsetup.sh
COPY sql/ocp_admin_privileges.mysql /var/www/opensips-cp/config/tools/admin/add_admin/ocp_admin_privileges.mysql
COPY sql/tables.mysql /var/www/opensips-cp/config/tools/system/smonitor/tables.mysql
RUN service mariadb start \
	&& expect -f /root/dbcreate.sh \
	&& mariadb --password=mariadb -e "GRANT ALL PRIVILEGES ON opensips.* TO opensips@localhost IDENTIFIED BY 'opensipsrw'" \
	&& mariadb --password=mariadb -Dopensips < /var/www/opensips-cp/config/tools/admin/add_admin/ocp_admin_privileges.mysql \
	&& mariadb --password=mariadb -Dopensips -e "INSERT INTO ocp_admin_privileges (username,password,ha1,available_tools,permissions) values ('admin','admin',md5('admin:admin'),'all','all');" \
	&& mariadb --password=mariadb -Dopensips < /var/www/opensips-cp/config/tools/system/smonitor/tables.mysql \
	&& cp /var/www/opensips-cp/config/tools/system/smonitor/opensips_stats_cron /etc/cron.d/ \
	&& expect -f /root/dbsetup.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy final config files
COPY conf/etc-opensips/opensips.cfg /etc/opensips/opensips.cfg

# Copy in the startup script and make it executable
# Set public ports and startup script
COPY script/run.sh /run.sh
RUN chmod 777 /run.sh 
EXPOSE 80 5060/udp
CMD ["/run.sh"]
