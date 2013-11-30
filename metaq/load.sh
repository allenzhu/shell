#!/usr/bin/expect

nodehost=$1

(
expect<<@
        spawn /usr/bin/pgm -A -b $nodehost "/usr/bin/tsar --load -d20131111 -i 1|grep  MAX"
        expect "Password:"
        send "allen_zhu\r"
        send "exit\r"
        expect eof
@
) |fgrep -i "MAX" |awk 'BEGIN{max=0} {if(max<$2){max=$2}fi} END {print "'$nodehost' "max}'


