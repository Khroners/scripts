#!/bin/bash
cd /var/sftp/uploads
mkdir $(date '+%Y-%m-%d') && cd "$_"
tar -czvf "bookstack-files-backup.tar.gz" /apps/bookstack/config/
docker exec bookstack_db /usr/bin/mysqldump -u balexis --password=your_mysql-password(not_root) bookstackapp > "bookstackapp.backup.sql"
