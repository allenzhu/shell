#!/bin/bash

nodehost=$1

(
expect<<@
        spawn /usr/bin/pgm -A -b $nodehost "fgrep -i put_tps /home/admin/taobao-metaq/metaq-server/logs/meta_store.log |awk \'BEGIN{max=0} {if(\'$7\'>max){max=\'$7\'}fi} END {print max}\'"
        expect "Password:"
        send "allen_zhu\r"
        send "exit\r"
        expect eof
@
)
