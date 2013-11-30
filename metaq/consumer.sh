#! /bin/bash

function help()
{
        echo "./run.sh -t topic -g group"
}

while getopts "t:g:" options;do
        case $options in
                t)
                        topic=$OPTARG;;
                g)
                        group=$OPTARG;;
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
fi

sh $(dirname $0)/run-class.sh com.taobao.metamorphosis.routine.Consumer20 $group $topic
