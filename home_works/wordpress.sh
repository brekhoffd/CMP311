#!/bin/bash

# Checking for root rights:
if [ "$(id -u)" -ne 0 ]; then
	echo "Please run this script with root privileges."
	exit 1
fi

# Install and update locales:
apt install locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Update system and install required packages:
apt update && apt upgrade -y
apt install nginx mysql-server php-fpm php-mysql php-cli php-curl php-xml unzip -y

# Stop and disable Apache if it's running:
if systemctl is-active --quiet apache2; then
	systemctl stop apache2
	systemctl disable apache2
fi

# Download WordPress:
wget https://wordpress.org/latest.zip
unzip latest.zip
mv wordpress /var/www/html/

# Set the correct permissions:
chown -R www-data:www-data /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

# Create a database for WordPress:
read -p "Enter the name of the new WordPress database: " DB_NAME
read -p "Enter the name of the new WordPress user: " DB_USER
read -p "Enter the password of the WordPress user $DB_USER: " DB_PASS

mysql -e "CREATE DATABASE $DB_NAME;"
mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Configure Nginx:
read -p "Enter the domain or IP-address of your server: " SERVER_NAME

cat <<EOL > /etc/nginx/sites-available/wordpress
server {
	listen 80;
	server_name $SERVER_NAME;
	root /var/www/html/wordpress;

	index index.php index.html index.htm;

	location / {
		try_files \$uri \$uri/ /index.php?\$args;
	}

	location ~ \.php\$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/var/run/php/php-fpm.sock;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		include fastcgi_params;
	}

	location ~ /\.ht {
		deny all;
	}
}
EOL

# Enable Nginx configuration:
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

# Test Nginx configuration:
if nginx -t; then
	# Restart Nginx
	systemctl restart nginx
	echo "Nginx restarted successfully."
else
	echo "Error in Nginx configuration. Please fix the issues before restarting."
	exit 1
fi

# Completion message:
echo "Installation complete. Open your browser and complete the WordPress setup."
