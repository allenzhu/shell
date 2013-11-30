#!/bin/bash
. /etc/profile

echo "`date`"
for node in `cat /home/lansheng.zj/1111/nodelist.txt`;do
	/home/lansheng.zj/1111/msg_total.sh $node
	echo $node" success."
done
