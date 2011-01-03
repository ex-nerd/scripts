#!/bin/bash
#
# Dar backup and burn script
#
# @url       $URL: svn+ssh://svn.forevermore.net/var/svn/misc/trunk/scripts/dar/dar_backup.sh $
# @date      $START_DATE: 2007-12-26 11:47:28 -0800 (Wed, 26 Dec 2007) $
# @version   $Revision: 97 $
# @author    $Author: xris $
# @copyright Silicon Mechanics
#

# Dar database directory
    DAR_DB_DIR='/var/dar/'

# Temporary location to store pre-burn backup files
    BACKUP_TMP='/tmp/dar_backup'

# Root backup directory.  All other backup commands are in relation to this.
    BACKUP_ROOT=''

# Prefix for the db files
    DB_PREFIX=''

# Backup subdirectories.  Leave blank to back up the entire $BACKUP_ROOT
    BACKUP_DIRS=''

# Backup file globs.  Leave blank to back up the entire $BACKUP_ROOT
    BACKUP_FILES=''

# File and directory globs to ignore
    IGNORE_DIRS=''

# File globs to ignore (default: emacs tmp files)
    IGNORE_FILES='*~    .*~    .DS_Store'

# File globs not to compress
    NO_COMPRESS="
                 *.dar                         *.DAR
                 *.crypt                       *.CRYPT
                 *.Z   *.gz                    *.Z   *.GZ
                 *.tgz *.gtar *.shar *.ustar   *.TGZ *.GTAR *.SHAR *.USTAR
                 *.taz *.zoo                   *.TAZ *.ZOO
                 *.bz  *.bz2                   *.BZ  *.BZ2
                 *.zip                         *.ZIP
                 *.arj *.lzh *.lhz             *.ARJ *.LZH *.LHZ
                 *.rar *.r[0-9][0-9]           *.RAR *.R[0-9][0-9]
                 *.[0-9][0-9][0-9]
                 *.rpm *.deb *.cpio            *.RPM *.DEB *.CPIO
                 *.ogg *.mp3 *.mp4 *.wma       *.OGG *.MP3 *.MP4 *.WMA
                 *.m4b                         *.M4B
                 *.wmv *.avi *.mpg *.mpeg      *.WMV *.AVI *.MPG *.MPEG
                 *.png *.gif *.jpg *.jpeg      *.PNG *.GIF *.JPG *.JPEG
                 *.ram *.rm                    *.RAM *.RM
                "

# Rewrite the slice root path in dar_manager with the following?
    DAR_PATH_REWRITE='/media/dar'

# Percentage relative to the data should be made up of par files.  This also
# affects the amount of data on each disk, since this script will only allow
# a total of 4450M of data per disk.  Smaller par files, more data.  Keep in
# mind that bash doesn't support floating point numbers.
    PAR_SIZE=10

# Number of slices per disk.  Set this to whatever you feel is appropriate, but
# remember that Windows sometimes has trouble with files > 2GB, if you think
# you may someday need to use a Windows-based machine to retrieve archives from
# your disks.
    SLICES_PER_DISK=4

################################################################################
# Make sure we're running as root, and gather some env info
#

    if [ `whoami` != 'root' ]; then
        echo "Please login as root before running this script (or use sudo)."
        exit 1
    fi

# Make sure our required programs exist
    for EXE in dar dar_manager par2create; do
        type -P "$EXE" 2>&1 >/dev/null
        if [ $? -ne 0 ]; then
            echo "Cannot find $EXE in the execution path."
            exit 1
        fi
    done

################################################################################
# Did we get passed a backup settings name?
#

    if [ -z "$1" ]; then
        echo "Please specify a settings filename:  $0 settings_file"
        exit 0
    fi

    SETTINGS=`echo "$1" | sed -e 's/.conf\$//'`
    SETTINGS="`dirname $0`"/`echo "$SETTINGS".conf`

    if [ ! -f "$SETTINGS" ]; then
        echo "Settings file $SETTINGS does not exist"
        exit 1
    fi

    . "$SETTINGS"

################################################################################
# Make sure BACKUP_ROOT, DAR_DB_DIR and BACKUP_TMP exist
#

# Clean BACKUP_ROOT to make sure it has one and only one trailing slash
    BACKUP_ROOT=`echo "$BACKUP_ROOT" | sed -e 's,/\+$,,'`/

# Clean the others to remove trailing slashes
    DAR_DB_DIR=`echo "$DAR_DB_DIR" | sed -e 's,/\+$,,'`
    BACKUP_TMP=`echo "$BACKUP_TMP" | sed -e 's,/\+$,,'`

# Make sure BACKUP_ROOT is proper
    if [ "${BACKUP_ROOT:0:1}" != '/' ]; then
        echo "BACKUP_ROOT must be an absolute path (starts with /)"
        exit 1
    elif [ ! -d "$BACKUP_ROOT" ]; then
        echo "BACKUP_ROOT directory $BACKUP_ROOT does not exist"
        exit 1
    fi

# Make sure DAR_DB_DIR is defined exists
    if [ -z "$DAR_DB_DIR" ]; then
        echo "DAR_DB_DIR must be defined to something other than /"
        exit 1
    elif [ "${DAR_DB_DIR:0:1}" != '/' ]; then
        echo "DAR_DB_DIR must be an absolute path (starts with /)"
        exit 1
    else
        mkdir -p "$DAR_DB_DIR"
        if [ $? -ne 0 ]; then
            echo "Can't create DAR_DB_DIR path: $DAR_DB_DIR"
            exit 1
        fi
    fi

# Make sure the backup tmp directory is defined and doesn't exist
    if [ -z "$BACKUP_TMP" ]; then
        echo "BACKUP_TMP must be defined to something other than /"
        exit 1
    elif [ "${BACKUP_TMP:0:1}" != '/' ]; then
        echo "BACKUP_TMP must be an absolute path (starts with /)"
        exit 1
    elif [ "$BACKUP_TMP/" == "$BACKUP_ROOT" ]; then
        echo "BACKUP_TMP cannot be the same as BACKUP_ROOT"
        exit 1
    fi

################################################################################
# Get the date for the backup directory names, in case this takes more than
# one day to finish.
#

    START_DATE=`date -I`

################################################################################
# Are we running in --duc mode?
#

    if [ ! -z "$2" -a "$2" == '--duc' ]; then
    # Load dar's variables from the commandline
        SPATH="$3"
        BASENAME="$4"
        SLICENUM="$5"
        EXTENSION="$6"
        CONTEXT="$7"
        LINKDIR="$DAR_DB_DIR/$DB_PREFIX.tmp.$START_DATE"
    # Skip out during the init phase
        if [ "$CONTEXT" == 'init' ]; then
            exit 0
        fi
    # Don't do anything unti we have enough data, or this is the last slice
        CURSIZE="`du -sm \"$SPATH/$BASENAME.\"*dar | awk '{ i += \$1 } END { print i }'`"
        if [ "$CURSIZE" -gt 4000 -o "$CONTEXT" == 'last_slice' ]; then
        # Find the next available backup directory name
            TARGET="$DAR_DB_DIR/$DB_PREFIX.$START_DATE"
            if [ -d "$TARGET" ]; then
                I=1
                while [ true ]; do
                    I=$(($I + 1))
                    if [ $I -lt '10' ]; then
                        N="0$I"
                    else
                        N="$I"
                    fi
                    if [ ! -d "$TARGET.$N" ]; then
                        break
                    fi
                done
                TARGET="$TARGET.$N"
            fi
        # Create the backup target dir and move the current slice into it
            mkdir "$TARGET"
            mv "$SPATH/$BASENAME"*"$EXTENSION" "$TARGET/"
        # Create a symlink to this slice, so we can extract the catalogue later
            ln -s "$TARGET/$BASENAME"*"$EXTENSION" "$LINKDIR/$SLICENAME"
        # If this is the last slice, bring the commands file along to the target
        # directory, too.
            if [ "$CONTEXT" == 'last_slice' ]; then
                mv "$SPATH/commands.batch" "$TARGET/"
            fi
        # Are we running par at all?
            if [ "$PAR_SIZE" -gt 0 ]; then
            # Wait for any previous par process to finish
                while [ -f "$BACKUP_TMP/par.lock" ]; do
                    sleep 15
                done
            # Figure out the archive range numbers so we can make a nice par name
                cd "$TARGET"
                RANGE="`ls -1 \"$BASENAME\"*\"$EXTENSION\" \
                        | awk -F . '{
                                      if ( x < 1 || x > \$3 ) { x = \$3 }
                                      if (          y < \$3 ) { y = \$3 }
                                    }
                                    END {
                                      if ( x == y ) { print x }
                                      else          { print x\"-\"y }
                                    }'`"
                cd - > /dev/null
            # Calculate parity, but background it so dar can continue backing
            # things up or creating the final catalogue extract
                (
                  ( par2create -r"$PAR_SIZE" "$TARGET/$BASENAME.$RANGE.par2" "$TARGET/$BASENAME"*"$EXTENSION" ) &
                  echo $! > "$BACKUP_TMP/par.lock"
                  wait
                  rm -f "$BACKUP_TMP/par.lock"
                ) &
            fi
        fi
    # Exit gracefully
        exit 0
    fi

################################################################################
# Now that we're past the --duc section, we can finish checking on and setting
# up BACKUP_TMP and DAR_DB_DIR.
#

# Clean out old empty directories so we don't error needlessly
    rmdir "$BACKUP_TMP" 2>/dev/null

# Check
    if [ -d "$BACKUP_TMP" ]; then
        echo "$BACKUP_TMP already exists.  Please make sure dar_backup isn't"
        echo "already running, or delete the stale directory."
        exit 1
    else
        mkdir -p "$BACKUP_TMP"
        if [ $? -ne 0 ]; then
            echo "Can't create BACKUP_TMP path: $BACKUP_TMP"
            exit 1
        fi
    fi

# If needed, strip BACKUP_ROOT off of the beginning of BACKUP_TMP, and add it
# to the ignored subdirs
    echo "$BACKUP_TMP" | grep "^$BACKUP_ROOT" &> /dev/null
    if [ $? -eq 0 ]; then
        BACKUP_IGNORE="$BACKUP_IGNORE ${BACKUP_TMP:${#BACKUP_ROOT}}"
    fi

# If needed, strip BACKUP_ROOT off of the beginning of DAR_DB_DIR, and add it
# to the ignored subdirs
    echo "$DAR_DB_DIR" | grep "^$BACKUP_ROOT" &> /dev/null
    if [ $? -eq 0 ]; then
        BACKUP_IGNORE="$BACKUP_IGNORE ${DAR_DB_DIR:${#BACKUP_ROOT}}"
    fi

################################################################################
# A couple of handy functions
#

# Normalize all whitespace to a single space, and trim leading/trailing spaces
    function clean_whitespace {
        echo "`echo "$1" | tr -s ' \t\f\v\r\n' ' ' | sed -e 's,^\s\+,,' -e 's,\s\+$,,'`"
    }

# Return the absolute path to a file/directory
    function abspath {
        F=""
        D="$1"
        if [ -f "$D" ]; then
            F="/`basename \"$D\"`"
            D="`dirname \"$D\"`"
        fi
        echo "`cd \"$D\" && pwd -P`$F"
    }

################################################################################
# Build the dar commands file
#

# Figure out the data segment size
    DATA_SIZE=$(( 445000 / $SLICES_PER_DISK / (100 + $PAR_SIZE) ))

# The commands file lives here:
    COMMANDS="$BACKUP_TMP/commands.batch"

# First, clear out the file
    rm -f "$COMMANDS"

# Add the main shared options
    cat > "$COMMANDS" <<EOF
# Slice size
-s ${DATA_SIZE}M

# Compress, including large files
-y9 -m 0

# Verbose
-v

# Do not read default dar config files
-N

# Pause between slices
#-p

# Sound the term bell with pauses
-b

# Root directory to back up
-R '$BACKUP_ROOT'
EOF

# Subdirs to include (Expand shell globs as necessary)
    BACKUP_DIRS="`clean_whitespace "$BACKUP_DIRS"`"
    if [ ! -z "$BACKUP_DIRS" ]; then
        echo -e "\n\n# Back up the following subdirs:" >> "$COMMANDS"
        for D in $BACKUP_DIRS; do
            cd "$BACKUP_ROOT"
            for F in $D; do
                echo "-g '$F'" >> "$COMMANDS"
            done
            cd -
        done
    fi

# File globs to include
    BACKUP_FILES="`clean_whitespace "$BACKUP_FILES"`"
    if [ ! -z "$BACKUP_FILES" ]; then
        echo -e "\n\n# Back up the following file patterns:" >> "$COMMANDS"
        echo -n "$BACKUP_FILES"               \
             | sed -e 's,/*$,'\'',g'          \
                   -e 's,/* ,'\''\n-I '\'',g' \
                   -e 's,^,-I '\'',g'         \
             >> "$COMMANDS"
    fi

# Ignored subdirs
    IGNORE_DIRS="`clean_whitespace "$IGNORE_DIRS"`"
    if [ ! -z "$IGNORE_DIRS" ]; then
        echo -e "\n\n# Ignore the following directory patterns:" >> "$COMMANDS"
        echo -n "$IGNORE_DIRS"                \
             | sed -e 's,/*$,'\'',g'          \
                   -e 's,/* ,'\''\n-P '\'',g' \
                   -e 's,^,-P '\'',g'         \
             >> "$COMMANDS"
    fi

# Ignored file globs
    IGNORE_FILES="`clean_whitespace "$IGNORE_FILES"`"
    if [ ! -z "$IGNORE_FILES" ]; then
        echo -e "\n\n# Ignore the following file patterns:" >> "$COMMANDS"
        echo -n "$IGNORE_FILES"               \
             | sed -e 's,/*$,'\'',g'          \
                   -e 's,/* ,'\''\n-X '\'',g' \
                   -e 's,^,-X '\'',g'         \
             >> "$COMMANDS"
    fi

# No-compress globs
    NO_COMPRESS="`clean_whitespace "$NO_COMPRESS"`"
    if [ ! -z "$NO_COMPRESS" ]; then
        echo -e "\n\n# Do not compress the following file patterns:" >> "$COMMANDS"
        echo -n "$NO_COMPRESS"                \
             | sed -e 's,/*$,'\'',g'          \
                   -e 's,/* ,'\''\n-Z '\'',g' \
                   -e 's,^,-Z '\'',g'         \
             >> "$COMMANDS"
    fi

# And the mid-slice handler
    echo -e "\n\n# Don't forget to run the mid-slice script:"        >> "$COMMANDS"
    echo "-E \"`abspath $0` '$1' '--duc' '%p' '%b' '%n' '%e' '%c'\"" >> "$COMMANDS"

################################################################################
# Run the backup
#

# Current slice name
    DAR_SLICE="$BACKUP_TMP/$DB_PREFIX.$START_DATE"
    SLICE_BASE=`basename "$DAR_SLICE"`

# Create a directory to hold the slice symlinks
    LINKDIR="$DAR_DB_DIR/$DB_PREFIX.tmp.$START_DATE"
    if [ ! -d "$LINKDIR" ]; then
        mkdir "$LINKDIR"
    fi

# Search for an old backup DB file
    OLD_DB=`ls -1 "$DAR_DB_DIR/$DB_PREFIX.db."* 2>/dev/null | tail -n 1`

# Ask about doing an incremental backup
    INCREMENTAL=''
    if [ ! -z "$OLD_DB" ]; then
        OLD_DB="`echo \"$OLD_DB\" | sed -e 's/\.[0-9]\+\.dar\$//'`"
        echo    "Old backup database found:  $OLD_DB"
        echo -n "Perform incremental backup?  [Y/n] "
        read INCREMENTAL
        if [ -z "$INCREMENTAL" -o "${INCREMENTAL:0:1}" == 'Y' -o "${INCREMENTAL:0:1}" == 'y' ]; then
            INCREMENTAL=1
        else
            INCREMENTAL=''
        fi
    fi

# Full backup
    if [ -z "$INCREMENTAL" ]; then
        dar -c "$DAR_SLICE" -B "$COMMANDS"
    else
# Incremental backup
        dar -c "$DAR_SLICE" -B "$COMMANDS" -A "$OLD_DB"
    fi

# Extract a new catalogue file
    dar -C "$DAR_DB_DIR/$DB_PREFIX.db.$START_DATE" -A "$LINKDIR/$SLICE_BASE"

# Add the entries to a dar_manager db
    if [ ! -e "$DAR_DB_DIR/$DB_PREFIX.dmd" ]; then
        dar_manager -C "$DAR_DB_DIR/$DB_PREFIX.dmd"
    fi
    dar_manager -B "$DAR_DB_DIR/$DB_PREFIX.dmd" -A "$LINKDIR/$SLICE_BASE"

# Do we want to rewrite the path?
    if [ ! -z "$DAR_PATH_REWRITE" ]; then
        ARCHIVE_NUM=`dar_manager -B "$DAR_DB_DIR/$DB_PREFIX.dmd" -l | grep "$SLICE_BASE" | awk '{ print $1 }'`
        dar_manager -B "$DAR_DB_DIR/$DB_PREFIX.dmd" -p "$ARCHIVE_NUM" "$DAR_PATH_REWRITE"
    fi

# Wait for child processes to catch up
    wait

# Wait for any previous par process to finish, in case something somehow got
# zombied.
    while [ -f "$BACKUP_TMP/par.lock" ]; do
        sleep 15
    done

# Cleanup
    rm -rf "$LINKDIR"
    rmdir "$BACKUP_TMP"

