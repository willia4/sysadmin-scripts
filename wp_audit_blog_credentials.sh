#!/bin/bash
# SCRIPT: 		Audit Wordpress Usernames
# AUTHOR: 		James Williams <james@jameswilliams.me>
#
# DESCRIPTION: 	This script will scan a root directory (presumably the directory you keep all of your websites) for wordpress blogs. 
#			   	It will then use the database credentials for those blogs to log in and list all of the usernames that can log into each blog.
#				This is useful if, for example, there is an Internet-wide attack against default usernames like "admin"			  
#
#
#
# CONFIGURATION: One variable, WWW_ROOT, indicates the root directory where your websites and blogs live. 

WWW_ROOT='/www'

#array variables to hold information about blog names, database hosts, database names, database users, database passwords, and wordpress table prefixes
#Use six arrays because I don't know how to do structs in bash
declare -a BLOGS
declare -a DATABASEHOSTS
declare -a DATABASES
declare -a USERS
declare -a PASSWORDS
declare -a PREFIXES 

let I=0
#find /www -name wp-config.php | while read FILENAME; do
for FILENAME in $( find $WWW_ROOT -name wp-config.php ); do
	
	BLOGS[$I]=${FILENAME%wp\-config\.php}

	USERS[$I]=`grep "define('DB_USER'" $FILENAME | sed "s/define('DB_USER', '//" | sed "s/');.*//"`
	DATABASEHOSTS[$I]=`grep "define('DB_HOST'" $FILENAME | sed "s/define('DB_HOST', '//" | sed "s/');.*//"`
	DATABASES[$I]=`grep "define('DB_NAME'" $FILENAME | sed "s/define('DB_NAME', '//" | sed "s/');.*//"`
	PASSWORDS[$I]=`grep "define('DB_PASSWORD'" $FILENAME | sed "s/define('DB_PASSWORD', '//" | sed "s/');.*//"`
		
	PREFIXES[$I]=`grep '$table_prefix' $FILENAME | sed s/"^.*= '"// | sed s/"';.*$"//`

 	# echo "${BLOGS[I]}"
 	# echo "       ${DATABASEHOSTS[I]}"
 	# echo "       ${DATABASES[I]}" 
 	# echo "       ${USERS[I]}"
 	# echo "       ${PASSWORDS[I]}"
 	# echo "       ${PREFIXES[I]}"
	let I+=1
done

COUNT=${#BLOGS[@]}

let I=0
while [ $I -lt $COUNT ]; do
	echo "${BLOGS[I]}"

	# Get all the wordpress usernames from the database. The \G option makes the output easier to pass to grep and sed
	mysql -h ${DATABASEHOSTS[I]} -D ${DATABASES[I]} -u ${USERS[I]} --password=${PASSWORDS[I]} -e "select user_login from ${PREFIXES[I]}users order by user_login asc \G;" | \
	# The rows we care about all start with the column name, user_login:
	grep "user_login:" | \
	# ...but we don't actually need to know the column name, so get rid of it
	sed s/'user_login: '// | \
	# Change the beginning of the string into some spaces for indentation with the blog name we outputted above
	sed s/'^'/'       '/

	let I+=1
done
