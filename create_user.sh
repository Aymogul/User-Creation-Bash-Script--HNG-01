#!/bin/bash

# Log file and secure password file locations
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure the log directory exists
mkdir -p /var/log
touch $LOG_FILE

# Ensure the secure directory exists and set permissions
mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to generate random password
generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <user-file>"
    exit 1
fi

USER_FILE="$1"

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Ignore whitespace and empty lines
    username=$(echo $username | xargs)
    groups=$(echo $groups | xargs)
    [ -z "$username" ] && continue

    # Create the user and primary group
    if id -u "$username" >/dev/null 2>&1; then
        log_message "User $username already exists"
    else
        # Create the primary group
        groupadd "$username"
        log_message "Group $username created"

        # Create the user
        useradd -m -g "$username" -s /bin/bash "$username"
        log_message "User $username created with home directory /home/$username"
        
        # Set up home directory permissions
        chmod 700 "/home/$username"
        log_message "Set permissions for /home/$username"
        
        # Generate a random password
        password=$(generate_password)
        echo "$username:$password" | chpasswd
        log_message "Password set for user $username"

        # Store the password securely
        echo "$username,$password" >> $PASSWORD_FILE
    fi

    # Add user to additional groups
    if [ -n "$groups" ]; then
        IFS=',' read -ra GROUP_ARRAY <<< "$groups"
        for group in "${GROUP_ARRAY[@]}"; do
            group=$(echo $group | xargs)
            if ! getent group "$group" >/dev/null; then
                groupadd "$group"
                log_message "Group $group created"
            fi
            usermod -aG "$group" "$username"
            log_message "User $username added to group $group"
        done
    fi
done < "$USER_FILE"

log_message "User creation process completed"

echo "User creation process completed. Check the log file at $LOG_FILE for details."