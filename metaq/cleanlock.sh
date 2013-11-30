#! /bin/bash

help()
{
	echo "clean the specified group lock, use as the follow:"
	echo "	./cleanlock.sh -g group"
	echo "clean all lock:"
	echo "	./cleanlock.sh"
}


while getopts "g:h" options;do
        case $options in
                g)
                        group=$OPTARG;;
		h)
			helpme=true;;
                /?)
                        true
        esac
done

if [ $helpme ]; then
	help
	exit 1	
elif [ -z $group ]; then
	echo -e "stats cleanlock\r\n\r\n" |nc localhost 8123
else
	echo -e "stats cleanlock $group\r\n\r\n" |nc localhost 8123
fi

echo 
sleep 1
