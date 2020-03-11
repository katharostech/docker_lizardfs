#!/bin/bash

if [ "$DEBUG" = "true" ]; then set -x; fi

usage_message="usage: docker run kadimasolutions/lizardfs [master|metalogger|chunkserver|cgiserver|client]"

# Configure LizardFS
if [ ! "$SKIP_CONFIGURE" = "true" ]; then
    /configure.sh $@
fi

if [ "$1" = "master" ]; then
    extra_options=""
    if [ "$2" = "ha" ]; then
        echo "Starting uRaft"
        lizardfs-uraft -d
        extra_options="-o ha-cluster-managed -o initial-personality=${3-master}"
    fi
    echo "Starting LizardFS master"
    exec mfsmaster $extra_options -d

elif [ "$1" = "metalogger" ]; then
    echo "Starting LizardFS Metalogger"
    exec mfsmetalogger -d

elif [ "$1" = "chunkserver" ]; then
    echo "Starting LizardFS Chunkserver"
    exec mfschunkserver -d

elif [ "$1" = "cgiserver" ]; then
    echo "Starting LizardFS CGI Server"
    
    if [ "$MASTER_HOST" != "" ]; then
        # Proxy localhost:9421 to the actual master and port so that you don't have to add
        # the master host and port to the query string.
        ncat --sh-exec "ncat $MASTER_HOST ${MASTER_PORT:-9421}" -l 9421 --keep-open > /dev/null 2>&1 &
    fi

    exec lizardfs-cgiserver -v -P ${2-80}

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
