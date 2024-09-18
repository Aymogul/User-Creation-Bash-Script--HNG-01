## Automating User Creation with Bash
As a SysOps engineer, one of the tasks you might encounter is the need to automate the creation of users and groups on your Linux servers. This script, create_users.sh, simplifies the process by reading a file containing usernames and group names, creating users and groups as specified, setting up home directories, and generating random passwords. In this article, we'll walk through the script step by step.

#### Script Overview
The create_users.sh script reads a text file where each line is formatted as user;groups, creates the users and groups, sets up home directories, and generates random passwords. Actions are logged to /var/log/user_management.log, and passwords are securely stored in /var/secure/user_passwords.csv.

#### Detailed Breakdown

- Log and Secure Password File Setup

The script begins by setting up the log file and secure password file. It ensures that the directories exist and sets appropriate permissions for the password file.

```sh
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

mkdir -p /var/log
touch $LOG_FILE

mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE
```

- Logging Function

A function is defined to log messages with timestamps.

```sh
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}
```

-  Password Generation
  
A helper function generates random passwords.

```sh
generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}
```

- Input File Check

The script checks if an input file is provided and exits if not.

```sh
if [ -z "$1" ]; then
    echo "Usage: $0 <user-file>"
    exit 1
fi

USER_FILE="$1"
```

-  Processing the Input File

The script reads the input file line by line, ignoring whitespace and empty lines, and processes each user.

```sh
while IFS=';' read -r username groups; do
    username=$(echo $username | xargs)
    groups=$(echo $groups | xargs)
    [ -z "$username" ] && continue
```

-  Creating Users and Groups

For each user, the script checks if the user already exists, creates the primary group (same as the username), creates the user, sets up home directory permissions, and generates a password.

```sh
if id -u "$username" >/dev/null 2>&1; then
    log_message "User $username already exists"
else
    groupadd "$username"
    log_message "Group $username created"

    useradd -m -g "$username" -s /bin/bash "$username"
    log_message "User $username created with home directory /home/$username"
    
    chmod 700 "/home/$username"
    log_message "Set permissions for /home/$username"
    
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    log_message "Password set for user $username"

    echo "$username,$password" >> $PASSWORD_FILE
fi
```

-  Adding Users to Additional Groups

The script then adds the user to any additional groups specified in the input file.

```sh
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
```

#### Completion

Finally, the script logs the completion of the user creation process.

"log_message "User creation process completed"

echo "User creation process completed. Check the log file at $LOG_FILE for details."

![alt text](./screenshots/s-1.PNG)



- To run and test the create_users.sh script, follow these steps:

Step 1:

#### Prepare Your Environment

Ensure you have the necessary permissions to create users, groups, and modify system files. Running the script might require superuser privileges.

Step 2: 

#### Create the Input File

Create a text file with the usernames and groups. For example, create a file named users.txt with the following content:

```sh
isreal;sudo,dev,www-data
isreal2;sudo
isreal3;dev,www-data
```

Step 3:

#### Ensure Necessary Directories Exist

Ensure that the directories /var/log and /var/secure exist and have the appropriate permissions. You might need to create them if they don't exist:

```sh
sudo mkdir -p /var/log /var/secure
sudo touch /var/log/user_management.log /var/secure/user_passwords.csv
sudo chmod 600 /var/secure/user_passwords.csv
```

Step 4: 

#### Run the Script

To execute the script, use the following command, passing the name of the input file as an argument:

```sh
sudo bash create_users.sh users.txt
```

Step 5: 

#### Verify the Script's Actions

Check the Log File: Verify the actions logged in /var/log/user_management.log.

```sh
sudo cat /var/log/user_management.log
```

Check the Passwords File: Verify the securely stored passwords in /var/secure/user_passwords.csv.

```sh
sudo cat /var/secure/user_passwords.csv
```

Verify User and Group Creation: Check if the users and groups were created correctly.

List users and groups

```sh
getent passwd | grep -E 'isreal|isreal2|isreal3'
getent group | grep -E 'isreal|sudo|dev|www-data'
```

Check Home Directory Permissions:

Ensure the home directories were created with the correct permissions.

```sh
ls -ld /home/isreal /home/isreal2 /home/isreal3
```


JPEGS TO HELP

![alt text](./screenshots/s-2.PNG)


![alt text](./screenshots/s-3.PNG)


![alt text](./screenshots/s-4.PNG)


![alt text](./screenshots/s-5.PNG)


![alt text](./screenshots/s-6.PNG)

## Conclusion
With this, we have successfully automated user creation with a Bash script which could help to reduce errorand ensure reliability, from defining user details in users.txt to execution, the project has transitioned from execution to completion.
To be part of the program that provided this task scenario, visit their official websites to gain more insights

https://hng.tech/internship

https://hng.tech/hire

Below is a link to the project article:

https://dev.to/adesokan_israel_109436759/linux-users-creation-with-bash-script-4733
