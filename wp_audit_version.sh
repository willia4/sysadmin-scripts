#!/bin/bash
# SCRIPT: 		Audit Wordpress Versions
# AUTHOR: 		James Williams <james@jameswilliams.me>
#
# DESCRIPTION: 	This script will scan a root directory (presumably the directory you keep all of your websites) for wordpress blogs. 
#			   	For each blog, it will indicate the current wordpress version for that blog.
#				This is useful if you want to see which blogs are out of date and need to be updated to the current wordpress version.
#
#
# CONFIGURATION: One variable, WWW_ROOT, indicates the root directory where your websites and blogs live. 

WWW_ROOT='/www'

# Find all the files in $WWW_ROOT named version.php
find $WWW_ROOT -name version.php | \
# Only find the ones that are actually WordPress version files
grep '/wp-includes/version.php' | \
# In each version file, find all the references to $wp_version and print the file name it's in along with the line (-H)
xargs -I {} grep -H 'wp_version' {} | \
# Strip out the line where $wp_version is declared @global
grep -v '@global' | \
# Grep used : to seperate the fields. Change it to be a bit more obvious
awk -F ':' '{ print $1 " === " $2}' | \
# Get rid of the full file path since we only care about the root wordpress directory 
sed 's/wp-includes\/version.php//' | \
# Get rid of actually setting the variable and the opening quote around the version number
sed "s/\$wp_version = '//" | \
# Get rid of the closing quote and semicolon
sed "s/';//" | \
# Sort by version number (-k means column) 
sort -k3 -k1 | \
# Print them in neat columns using '===' (added above) as the column seperator
column -s '===' -t 

