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

# Update system and install required packages:
apt update && apt upgrade -y
apt install nginx mysql-server php-fpm php-mysql php-cli php-curl php-xml unzip

# Stop and disable Apache if it's running:
if systemctl is-active --quiet apache2; then
	systemctl stop apache2
	systemctl disable apache2
fi

# Download WordPress:

