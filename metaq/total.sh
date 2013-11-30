#! /bin/bash

nodehost=$1
rm -rf result.tmp
#pgm -A -b $nodehost 'echo -e "stats store\r\n\r\n"|nc localhost 8123' >result.tmp
count=0
for h in `armory -leg $nodehost`;do
	count=`expr $count + 1`
	echo -e "stats store\r\n\r\n"|nc $h 8123 >>result.tmp
done

echo "$nodehost $count"
echo "putTps"
fgrep "putTps" result.tmp |awk '{total+=$2;total60+=$3;total600+=$4}END{print total;print total60;print total600}'
echo "getTps"
fgrep "getTransferedTps" result.tmp |awk '{total+=$2;total60+=$3;total600+=$4}END{print total;print total60;print total600}'
