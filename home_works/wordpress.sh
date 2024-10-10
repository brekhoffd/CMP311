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
sudo apt update && apt upgrade -y
sudo apt install nginx mysql-server php-fpm php-mysql php-cli php-curl php-xml unzip

# Stop and disable Apache if it's running:
if systemctl is-active --quiet apache2; then
	sudo systemctl stop apache2
	sudo systemctl disable apache2
fi

# Download WordPress:
wget https://wordpress.org/latest.zip
unzip latest.zip
sudo mv wordpress /var/www/html/

# Set the correct permissions:
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# Create a database for WordPress:
DB_NAME="wordpress_db"
DB_USER="wp_user"
DB_PASS="securepassword"

sudo mysql -e "CREATE DATABASE $DB_NAME;"
sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Configure Nginx:
SERVER_NAME="your_domain_or_IP" # Change to your actual IP address or domain
sudo tee /etc/nginx/sites-available/wordpress <<EOL
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
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

# Test Nginx configuration:
if sudo nginx -t; then
    # Restart Nginx
    sudo systemctl restart nginx
    echo "Nginx restarted successfully."
else
    echo "Error in Nginx configuration. Please fix the issues before restarting."
    exit 1
fi

# Completion message:
echo "Installation complete. Open your browser and complete the WordPress setup."
