#!/bin/bash

# Checking for root rights:
if [ "$EUID" -ne 0 ]; then
	echo "Please run this script with root privileges."
	exit 1
fi

# Create users
create_user() {
	echo "Create user..."
	read -p "Enter the name for create user: " NAME
	if id "$NAME" &>/dev/null; then
		echo "User $NAME is found!"
	else
		sudo useradd -m "$NAME"
		sudo passwd "$NAME"
		echo "User $NAME created!"
	fi
}

# Remove users
remove_user() {
	echo "Remove user..."
	read -p "Enter the name for remove user: " NAME
	if id "$NAME" &>/dev/null; then
		sudo userdel -r "$NAME"
		echo "User $NAME removed!"
	else
		echo "User $NAME not found!"
	fi
}

# Change passwords
change_password() {
	echo "Change password..."
	read -p "Enter the name for change password user: " NAME
	if id "$NAME" &>/dev/null; then
		sudo passwd "$NAME"
		echo "User $NAME password changed!"
	else
		echo "User $NAME not found!"
	fi
}

# Chek users
chek_user() {
	echo "Chek user..."
	read -p "Enter the name for chek user: " NAME
	if id "$NAME" &>/dev/null; then
		echo "User $NAME is found!"
	else
		echo "User $NAME not found!"
	fi
}

# List of commands
while true; do
	echo "USER MANAGER"
	echo "1) Create User"
	echo "2) Remove User"
	echo "3) Change Password"
	echo "4) Check User"
	echo "5) Exit"
	read -p "Input Number: " NUM

	case $NUM in
		1) create_user ;;
		2) remove_user ;;
		3) change_password ;;
		4) chek_user ;;
		5) echo "Exit..."; break ;;
		*) echo "ERROR! 1-5 only!" ;;
	esac
done
