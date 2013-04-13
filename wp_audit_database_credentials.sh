#!/bin/bash
# SCRIPT: 		Audit Wordpress Database Credentials
# AUTHOR: 		James Williams <james@jameswilliams.me>
#
# DESCRIPTION: 	This script will scan a root directory (presumably the directory you keep all of your websites) for wordpress blogs. 
#			   	For each blog, it will determine the username, database name, and database host that the blog uses for its database info. 
#				This is useful to ensure that no blogs share credentials (separation of privileges ftw)
#
#
# CONFIGURATION: One variable, WWW_ROOT, indicates the root directory where your websites and blogs live. 

WWW_ROOT='/www'

echo "#### All DB_USERs for our wordpress installs"
# Find all the files in $WWW_ROOT named wp-config.php
find $WWW_ROOT -name wp-config.php | \
# Find all the define username lines
xargs -I {} grep -H "define('DB_USER'" {} | \
# grep used : to seperate the fields. Change it to be a bit more obvious
awk -F ':' '{print $1 " === " $2}' | \
# get rid of the define stuff to just leave the beginning of the username field
sed "s/define('DB_USER', '//" | \
# get rid of everything after the username (which ends with '); left over from php)
sed "s/');.*//" | \
# sort by username so any installs using the same DB user will group together
sort -k3 -k1  | \
# Print them in neat columns using '===' (added above) as the column seperator
column -s '===' -t 

echo ""
echo ""
echo "#### All DB_NAMEs for our wordpress installs"
# Find all the files in $WWW_ROOT named wp-config.php
find $WWW_ROOT -name wp-config.php | \
# Find all the define username lines
xargs -I {} grep -H "define('DB_NAME'" {} | \
# grep used : to seperate the fields. Change it to be a bit more obvious
awk -F ':' '{print $1 " === " $2}' | \
# get rid of the define stuff to just leave the beginning of the username field
sed "s/define('DB_NAME', '//" | \
# get rid of everything after the username (which ends with '); left over from php)
sed "s/');.*//" | \
# sort by username so any installs using the same DB user will group together
sort -k3 -k1  | \
# Print them in neat columns using '===' (added above) as the column seperator
column -s '===' -t 


echo ""
echo ""
echo "#### All DB_HOSTs for our wordpress installs"
# Find all the files in $WWW_ROOT named wp-config.php
find $WWW_ROOT -name wp-config.php | \
# Find all the define username lines
xargs -I {} grep -H "define('DB_HOST'" {} | \
# grep used : to seperate the fields. Change it to be a bit more obvious
awk -F ':' '{print $1 " === " $2}' | \
# get rid of the define stuff to just leave the beginning of the username field
sed "s/define('DB_HOST', '//" | \
# get rid of everything after the username (which ends with '); left over from php)
sed "s/');.*//" | \
# sort by username so any installs using the same DB user will group together
sort -k3 -k1  | \
# Print them in neat columns using '===' (added above) as the column seperator
column -s '===' -t 
