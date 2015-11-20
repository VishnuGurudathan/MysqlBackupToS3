#!/bin/sh

source /path/to/db.conf

# Database details.

DB_NAME=
DB_USER=backupUser
DB_PASSWORD=password
HOST=hostname
BUCKET=bucket-name

# Set correct dates
NOWDATE=`date +%F_%H_%M_%S_%Z`
LASTDATE=$(date +%F_%H_%M_%S_%Z --date='6 months ago')
LOGDATE=`date +%F`
LAST_LOGDATE=$(date +%F --date='3 months ago')
DESTINATION=/home/ubuntu/database_backup

BACKUP_FOLDER=`date +%F`

mkdir  $DESTINATION/$BACKUP_FOLDER
# Logging
echo "Created backup_folder - " $BACKUP_FOLDER $(date -u) >>/home/ubuntu/database_backup/log/log-$LOGDATE.log

# Dump database to its own file
mysqldump -h $HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME |gzip > /home/ubuntu/database_backup/$BACKUP_FOLDER/$DB_NAME-$NOWDATE.sql.gz

# Logging
echo "MySQL dump created : " $(date -u) " with filename "$DB_NAME-$NOWDATE.sql.gz>>/home/ubuntu/database_backup/log/log-$LOGDATE.log


cd $DESTINATION

# Tar all the databases
tar -czf $BACKUP_FOLDER.tar.gz $BACKUP_FOLDER

rm -r $BACKUP_FOLDER


# Upload database to S3
s3cmd put $DESTINATION/$BACKUP_FOLDER.tar.gz s3://$BUCKET/$NOWDATE/>>/home/ubuntu/database_backup/log/log-$LOGDATE.log


# Logging
echo "MySQL dump copyed to S3 at : " $(date -u) " to location  s3:/"/$BUCKET/$NOWDATE/>>/home/ubuntu/database_backup/log/log-$LOGDATE.log

# Rotate out old backups
s3cmd del --recursive s3://$BUCKET/$LASTDATE/>>/home/ubuntu/database_backup/log/log-$LOGDATE.log

# Logging
echo "Old MySQLdump file " $BUCKET/$LASTDATE " delated in S3 : " $(date -u)>>/home/ubuntu/database_backup/log/log-$LOGDATE.log


# Remove dump file from local instance.
rm -r $BACKUP_FOLDER.tar.gz

rm -r /home/ubuntu/database_backup/log/log-$LAST_LOGDATE.log

