#!/bin/bash

# Configure LizardFS master
if [ "$1" = "master" ]; then
    # Copy the empty metadata file to /var/lib/mfs if it does not exist
    if [ ! -e /var/lib/mfs/metadata.mfs ]; then
        cp /metadata.mfs.empty /var/lib/mfs/metadata.mfs
    fi

    # Add config for mfsmaster.cfg
    # For each vairable that starts with `MFSMASTER_`, remove the
    # prefix and add the value to the `mfsmaster.cfg` file.
    rm -f /etc/mfs/mfsmaster.cfg # We remove the config file to reset config
    configs=${!MFSMASTER_*}
    for var in $configs; do
        config_name=${var#*_}
        echo "${config_name} = ${!var}" >> /etc/mfs/mfsmaster.cfg
    done

    # Add lines for mfsexports.cfg
    # For each variable that starts with `MFSEXPORTS_`, add the value
    # to `mfsexports.cfg` file.
    rm -f /etc/mfs/mfsexports.cfg # We remove the config file to reset config
    configs=${!MFSEXPORTS_*}
    for var in $configs; do
        echo "${!var}" >> /etc/mfs/mfsexports.cfg
    done

    # Add lines for mfsgoals.cfg
    # For each variable that starts with `MFSGOALS_`, add the value
    # to `mfsexports.cfg` file.
    rm -f /etc/mfs/mfsgoals.cfg # We remove the config file to reset config
    configs=${!MFSGOALS_*}
    for var in $configs; do
        echo "${!var}" >> /etc/mfs/mfsgoals.cfg
    done

    # Add lines for mfstopology.cfg
    # For each variable that starts with `MFSTOPOLOGY_`, add the value
    # to `mfsexports.cfg` file.
    rm -f /etc/mfs/mfstopology.cfg # We remove the config file to reset config
    configs=${!MFSTOPOLOGY_*}
    for var in $configs; do
        echo "${!var}" >> /etc/mfs/mfstopology.cfg
    done

# Configure LizardFS Metalogger
elif [ "$1" = "metalogger" ]; then
    # Add config for mfsmetalogger.cfg
    # For each vairable that starts with `MFSMETALOGGER_`, remove the
    # prefix and add the value to the `mfsmaster.cfg` file.
    rm -f /etc/mfs/mfsmetalogger.cfg # We remove the config file to reset config
    configs=${!MFSMETALOGGER_*}
    for var in $configs; do
        config_name=${var#*_}
        echo "${config_name} = ${!var}" >> /etc/mfs/mfsmetalogger.cfg
    done

# Configure LizardFS Chunkserver
elif [ "$1" = "chunkserver" ]; then
    # Add config for mfschunkserver.cfg
    # For each vairable that starts with `MFSCHUNKSERVER_`, remove the
    # prefix and add the value to the `mfsmaster.cfg` file.
    rm -f /etc/mfs/mfschunkserver.cfg # We remove the config file to reset config
    configs=${!MFSCHUNKSERVER_*}
    for var in $configs; do
        config_name=${var#*_}
        echo "${config_name} = ${!var}" >> /etc/mfs/mfschunkserver.cfg
    done

    # Add lines for mfshdd.cfg
    # For each variable that starts with `MFSHDD_`, add the value
    # to `mfsexports.cfg` file.
    rm -f /etc/mfs/mfshdd.cfg # We remove the config file to reset config
    configs=${!MFSHDD_*}
    for var in $configs; do
        # Add line to config
        echo "${!var}" >> /etc/mfs/mfshdd.cfg

        # Make sure dir exists and owner is correct if not prefixed with a `*`
        # to indicate that the drive should be evacuated.
        if [ ! $(echo ${!var} | grep '^\*.*') ]; then
            mkdir -p ${!var}
            chown -R mfs:mfs ${!var}
        fi
    done
fi

# Ensure proper ownership of the /var/lib/mfs directory
chown -R mfs:mfs /var/lib/mfs
