#!/bin/bash
. /etc/profile

nodehost=$1
rm -rf /home/lansheng.zj/1111/msg_total.tmp
count=0
for h in `/usr/local/bin/armory -leg $nodehost`;do
	count=`expr $count + 1`
	echo -e "stats store\r\n\r\n"|nc $h 8123 >>/home/lansheng.zj/1111/msg_total.tmp
done

time=`date`
echo "$time putMessageTimesTotal" >>/home/lansheng.zj/1111/msg_total.txt
#fgrep "putMessageTimesTotal" msg_total.tmp |awk -F: '{total+=$2;print $2;}END{print "total:"total}' >>msg_total.txt

fgrep "putMessageTimesTotal" /home/lansheng.zj/1111/msg_total.tmp |awk -F: '{total+=$2;print $2;}END{print "'"$time"'"" '$nodehost'('$count') total:"total}' >>/home/lansheng.zj/1111/msg_total.txt
