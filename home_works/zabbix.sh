#!/bin/bash

# Checking for root rights:
if [ "$EUID" -ne 0 ]; then
	echo "Please run this script with root privileges."
	exit 1
fi

# Install and update locales:
apt install locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Update system and install PostgreSQL:
apt update && apt upgrade -y
apt install postgresql postgresql-contrib -y

# Adding a ZABBIX repository:
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu24.04_all.deb
dpkg -i zabbix-release_7.0-2+ubuntu24.04_all.deb

# Update system and install ZABBIX:
apt update && apt upgrade -y
apt install zabbix-server-pgsql zabbix-frontend-php php8.3-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent -y

# Configure PostgreSQL for ZABBIX:
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

# Backup ZABBIX configuration:
cp -p /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bak

# Configure ZABBIX server:
cat <<EOL > /etc/zabbix/zabbix_server.conf
# Logging settings
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0

# Pid settings
PidFile=/run/zabbix/zabbix_server.pid
SocketDir=/run/zabbix

# Database settings
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix

# SNMP settings
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=10

# Fping settings
FpingLocation=/usr/bin/fping
Fping6Location=/usr/bin/fping6

# Other settings
LogSlowQueries=3000
StatsAllowedIP=127.0.0.1
EnableGlobalScripts=0
EOL

# Install and configure UFW firewall:
# apt install ufw
# ufw allow 22/tcp
# ufw allow 10050/tcp
# ufw allow 10051/tcp
# ufw allow 80/tcp
# ufw allow 443/tcp
# systemctl start ufw
# systemctl enable ufw

# Restart and enable ZABBIX server:
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

echo "Installation and configuration of ZABBIX server is complete!"
