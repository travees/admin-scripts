#!/bin/bash
##
# Create a set number of rsync style snapshots (using --link-dest) 
# of directories
#
# Requires: rsync >= 2.5.6
##

################################
# Config
################################

# Snapshots to keep
SNAPSHOTS=5

# Space delimited list of directories
SOURCES=""

# Where to put the snapshots
BACKUPDIR=""

# Print informational messages
DEBUG=1

################################
# Check config
################################
if [ -z "$SNAPSHOTS" ] 
then
    echo "SNAPSHOTS not set. Exiting."
    exit 1
elif [ $SNAPSHOTS -lt 1 ]
then
    echo "SNAPSHOTS must be set to a number greater than zero. Exiting."
    exit 1
elif [ $? -gt 1 ]
then
    echo "SNAPSHOTS must be set to a number"
    exit 1
fi

[ -z "$SOURCES" ] && {
    echo "SOURCES not set. Exiting."
    exit 1
}

[ -z "$BACKUPDIR" ] && {
    echo "BACKUPDIR not set. Exiting."
    exit 1
}

################################
# Main script
################################

_debug() { if [ $DEBUG ]; then echo "$@"; fi }

for SRC in $SOURCES
do
    _debug ""
    # Get the basename of source directory
    DST=`basename "$SRC"` || {
        echo "Couldn't get basename of $SRC"
        exit 1
    }

    if [ ! -e "${BACKUPDIR}/${DST}" ]
    then
        _debug "Making ${BACKUPDIR}/${DST}"
        mkdir "${BACKUPDIR}/${DST}" || {
            echo "Couldn't create directory ${BACKUPDIR}/${DST}"
            continue
        }
    fi

    _debug "cd to ${BACKUPDIR}/${DST}"
    cd "${BACKUPDIR}/${DST}" || {
        echo "Couldn't cd to ${BACKUPDIR}/${DST}"
        continue
    }

    MVFROM=$SNAPSHOTS
    while [ $MVFROM -ge 0 ]
    do
        if [ -e "${DST}.${MVFROM}" ]
        then
            if [ $MVFROM -eq $SNAPSHOTS ]
            then
                _debug "Moving ${DST}.${MVFROM} => ${DST}.$$.del"
                mv "${DST}.${MVFROM}" "${DST}.$$.del"
            else
                _debug "Moving ${DST}.${MVFROM} => ${DST}.${MVTO}"
                let MVTO=$MVFROM+1
                mv "${DST}.${MVFROM}" "${DST}.${MVTO}"
            fi
        fi
        let MVFROM=$MVFROM-1
    done

    _debug "Removing *.del directories in background"
    rm -rf *.del &    

    # rsync the source directory using the last rsync as the value for
    # --link-dest which creates hardlinks to unchanged files
    # requires rsync >= 2.5.6
    # see rsync(1)
    _debug "rsync $SRC => ${DST}.0"
    rsync -a --delete --link-dest="../${DST}.1" "$SRC"/ "${DST}.0" 
done
