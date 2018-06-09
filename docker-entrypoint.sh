#!/bin/bash

usage_message="usage: docker run kadimasolutions/lizardfs [master|metalogger|chunkserver|cgiserver|client]"

# Configure LizardFS
if [ ! "$SKIP_CONFIGURE" = "true" ]; then
    /configure.sh $1
fi

if [ "$1" = "master" ]; then
    echo "Starting LizardFS master"
    exec mfsmaster -d

elif [ "$1" = "metalogger" ]; then
    echo "Starting LizardFS Metalogger"
    exec mfsmetalogger -d

elif [ "$1" = "chunkserver" ]; then
    echo "Starting LizardFS Chunkserver"
    exec mfschunkserver -d

elif [ "$1" = "cgiserver" ]; then
    echo "Starting LizardFS CGI Server"
    exec lizardfs-cgiserver -v -P 80

elif [ "$1" = "client" ]; then
    if [ "$2" = "--help" -o "$2" = "-h" ]; then
        echo "Displaying help for 'mfsmount'"
        exec mfsmount --help
    fi
    echo "Mounting filesystem using LizardFS client"
    mountpoint=${2:-/mnt/mfs}
    mkdir -p $mountpoint
    mfsmount $mountpoint ${@:3}
    if [ $? -eq 0 ]; then
        trap "echo 'Termination signal caught: Unmounting and exiting.'; umount $mountpoint; exit \$?" SIGTERM SIGINT
        while true; do sleep 1; done
    else
        exit 1
    fi

elif [ "$1" = "--help" -o "$1" = "-h" ]; then
    echo $usage_message

else
    echo "Unknown option -- $@"
    echo $usage_message
fi
