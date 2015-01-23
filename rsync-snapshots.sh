#!/bin/bash
##
# Create a set number of rsync style snapshots (using --link-dest) 
# of directories
#
# Requires: rsync >= 2.5.6
##

# Snapshots to keep
SNAPSHOTS=10
# Space delimited list of directories, without a trailing slash, to be snapshotted
SOURCES=""
# Where to put the snapshots
BACKUPDIR=""

for SRC in $SOURCES
do
    # Strip everything up to and including the last slash
    DST="${SRC##*/}"

    if [ ! -e "${BACKUPDIR}/${DST}" ]
    then
        #echo "Making ${BACKUPDIR}/${DST}"
        mkdir "${BACKUPDIR}/${DST}" || {
            echo "Couldn't create directory ${BACKUPDIR}/${DST}"
            continue
        }
    fi

    #echo "cd to ${BACKUPDIR}/${DST}"
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
                mv "${DST}.${MVFROM}" "${DST}.$$.del"
            else
                let MVTO=$MVFROM+1
                mv "${DST}.${MVFROM}" "${DST}.${MVTO}"
            fi
        fi
        let MVFROM=$MVFROM-1
    done

    rm -rf *.del &    

    # rsync the source directory using the last rsync as the value for
    # --link-dest which creates hardlinks to unchanged files
    # requires rsync >= 2.5.6
    # see rsync(1)
    rsync -a --delete --link-dest="../${DST}.1" "$SRC"/ "${DST}.0" 
done
