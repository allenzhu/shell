#! /bin/bash

h="10.232.10.151"
expect <<@
	spawn scp nobody@$h:/home/admin/mms/logs/logs/registerData.log /home/admin/mms/temp
	expect "password:"
	send "viewlog\r"
	send "exit\r"
	expect eof
@
echo "finish fetching log file."
echo "start to statistical analysis ..."
./statistics.sh ./registerData.log

echo 'auto finish.'

