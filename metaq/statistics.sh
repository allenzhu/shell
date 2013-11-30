#! /bin/bash

timestamp=`date '+%Y%m%d'`
directory="logs/"
if [ $# -eq 0 ]; then
	filename="registerData_test.log"
else
	filename=$1
fi

n10="unkown"
n11="newRegister"
n12="newEmailRegTwo"
n13="newEmailRegThree"
n14="newCellphoneRegTwo"
n15="newCellphoneRegSuc"
n16="newAlipayQ"
n17="registerConfirm"
n18="whenGoEmail"

f1="$directory/${n11}_${timestamp}.log"   # newRegister page statistics file
f2="$directory/${n12}_${timestamp}.log"   # newEmailRegTwo page statistics file
f3="$directory/${n13}_${timestamp}.log"   # newEmailRegThree page statistics file
f4="$directory/${n14}_${timestamp}.log"   # newCellphoneRegTwo page statistics file
f5="$directory/${n15}_${timestamp}.log"   # newCellphoneRegSuc page statistics file
f6="$directory/${n16}_${timestamp}.log"   # newAliayQ page statistics file
f7="$directory/${n17}_${timestamp}.log"   # registerConfirm page statistics file
f8="$directory/${n18}_${timestamp}.log"   # whenGoEmail page statistics file
f0="$directory/${n10}_${timestamp}.log"   # unkown statistics file

# fd
exec 11<>$f1
exec 12<>$f2
exec 13<>$f3
exec 14<>$f4
exec 15<>$f5
exec 16<>$f6
exec 17<>$f7
exec 18<>$f8
exec 10<>$f0

cat $filename | (
n11No=0  # newRegister page number
n12No=0  # newEmailRegTwo page number
n13No=0  # newEmailRegThree page number
n14No=0  # newCellphoneRegTwo page number
n15No=0  # newCellphoneRegSuc page number
n16No=0  # newAlipayQ page number
n17No=0  # registerConfirm page number
n18No=0  # whenGoEmail page number
n10No=0  # unkown page number

while read line
do
	for j in `seq 10 18`
	do
		## case 1:newRegister page
		inn="n${j}"
		inno="n${j}No"
		#echo "inn:${!inn}"
		#echo "inno name:${inno}"
		#echo "inno:${!inno}"
		
		temp=`echo $line | fgrep -o "${!inn}"`
		#echo "temp:$temp"
		if [ "$temp" == "${!inn}" ]; then
			#echo "inn:${!inn}"
			#echo "inno name:${inno}"
			#echo "inno:${!inno}"
			#echo "j:$j"
			cost=`echo $line | awk '{ print $4 }'`
			#echo "cost:$cost"
			echo "$cost" >&$j
			#(( ${!inno}++ ));
			#${!inno}=`expr ${!inno} + 1`
			let "${inno}=${!inno}+1"
			#echo "${inno}:${!inno}"
			break
		fi
	done
done

#statistic total records
seperate='----------------------'
for i in `seq 10 18`
do
	indirect="n${i}No"
	echo "${seperate}" >&$i
	echo "total records are: ${!indirect}" >&$i
done 

#close
exec 11<&-
exec 12<&-
exec 13<&-
exec 14<&-
exec 15<&-
exec 16<&-
exec 17<&-
exec 18<&-
exec 10<&-

)

echo "finish statistic log."

