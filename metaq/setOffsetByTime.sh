#! /bin/bash

function help()
{
	echo "./run.sh -t topic -g group -p timestamp"
}

while getopts "t:g:p:" options;do
	case $options in
		t)
			topic=$OPTARG;;
		g)
			group=$OPTARG;;
		p)
			period=$OPTARG;;
		/?)
			true
	esac
done

if [ -z $topic ]; then
	help
	exit 1;
elif [ -z $group ]; then
	help
	exit 1;
elif [ -z $period ]; then
	help
	exit 1;
fi

export ZK_SERVER="10.232.133.167:2181"
#export ZK_SERVER="172.24.113.126:2181"

sh $(dirname $0)/run-class.sh com.taobao.metamorphosis.routine.ChangeZKOffsetByStamp $group $topic $period
