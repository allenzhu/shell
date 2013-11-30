#!/bin/bash

nodehost=$1
data=/home/lansheng.zj/1111/msg_total.txt
head=`fgrep -i " $nodehost" $data |head -1 |awk -F: '{print $4}'`
last=`fgrep -i " $nodehost" $data |tail -1 |awk -F: '{print $4}'`
total=`expr $last - $head`
echo "$nodehost total:$total"
