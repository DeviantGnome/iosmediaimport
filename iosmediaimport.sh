#!/bin/bash

process(){


	#
	#
	#
	# Need to add code to check if the file about to be moved already exists,
	# then add something to filename until it is unique
	#
	#
	# Also need to do a check to only import/delete if file is older
	# than 30 days so as to leave recent files on the device
	#
	#

	i=$1

	# Set file names and extensions
	fileName=$(basename -- $i)   # IMG_1369.JPG
	basefile=${fileName%.*}      # IMG_1369
	extension=${fileName##*.}    # JPG
	fullDir=$(dirname ${i})      # /home/user/iPhone/DCIM/101APPLE

	# Check if file is HEIC, then convert it while moving it
	if [[ $extension = "HEIC" ]]; then
		printf "HEIC file!!!\r"
	elif [[ $extension = "MOV" ]]; then
		printf "MOV file!!!\r"
	else
		printf "Some other file!!!\r"
	fi


	# Remove the file from the device if the previous move command was successful
	if [[ $? -eq 0 ]]; then
		#rm $i
		printf "Removing $fileName from device...\r"
	else
		printf "$fileName not copied from device.\n"
	fi

	sleep .1s

	# Remove the current line's text in the console
	printf "\033[K"

}

recursion(){

	for i in $1/*
	do
		if [ -d $i ]; then
			recursion $i
		elif [ -f $i ]; then
			process $i
		fi
	done

}

# Check to see that the file is being run as root
if [[ $EUID -ne 0 ]]; then
	printf "You must run this as root. Exiting.\n"
	exit 1
fi

# Check to see if ifuse is installed
if ! command -v ifuse >/dev/null 2>&1; then
	printf "ifuse is not installed. Please install ifuse and retry. Exiting.\n"
	exit 1
fi

# Check to see if tifig is installed
if ! command -v tifig >/dev/null 2>&1; then
	printf "tifig should be in the same directory as this script and wasn't found."
	printf " Any HEIC images will not be converted.\n"
fi

# Check to see if HandBrakeCLI is installed
if ! command -v HandBrakeCLI >/dev/null 2>&1; then
	printf "HandBrakeCLI is not installed. Any MOV files will not be converted.\n"
fi

# Should be pretty unique so as to not override any existing directory
ROOTHIDDEN=~/.iosmediaimport

# Subdirectory to mount device to. This way config files or anything else can
# live in ROOTHIDDEN, if that happens at some point.
HIDDENMOUNT=/iosmountdir
MOUNTDIR=$ROOTHIDDEN$HIDDENMOUNT
DCIMDIR=$MOUNTDIR/DCIM

# Check to see if the MOUNTDIR is mounted
# Do this before checking if it exists, because if it's already mounted,
# the check below won't find it
if [[ $(findmnt -M $MOUNTDIR) ]]; then

        printf "$MOUNTDIR is already mounted. Unmounting...\n"

        # Unmount the directory
        umount $MOUNTDIR

        if [[ $? -ne 0 ]]; then
                printf "Error unmounting $MOUNTDIR. umount command exited with error code $?. Exiting.\n"
                exit 1
        fi

fi

# Check to see if ROOTHIDDEN exists
if [[ -d "$ROOTHIDDEN" ]]; then
	printf "Found application root directory .iosmediaimport.\n"
else
	printf "$ROOTHIDDEN not found. Creating...\n"
	mkdir $ROOTHIDDEN
	if [[ $? -ne 0 ]]; then
		printf "Error creating application root directory $ROOTHIDDEN. mkdir command exited with error code $?. Exiting.\n"
		exit 1
	fi
fi

# Check to see if the MOUNTDIR exists
if [[ -d "$MOUNTDIR" ]]; then
	printf "Found mount directory $MOUNTDIR.\n"
else
	printf "$MOUNTDIR not found. Creating...\n"
	mkdir $MOUNTDIR
	if [[ $? -ne 0 ]]; then
		printf "Error creating $MOUNTDIR. mkdir command exited with error code $?. Exiting.\n"
		exit 1
	fi
fi

# Define import directory
IMPORTDIR=~/iOSMediaImport

# Check to see if import directory exists
if [[ -d $IMPORTDIR ]]; then
	printf "Found import directory $IMPORTDIR.\n"
else
	printf "$IMPORTDIR not found. Creating...\n"
	mkdir $IMPORTDIR
	if [[ $? -ne 0 ]]; then
		printf "Error creating $IMPORTDIR. mkdir command exited with error code $?. Exiting.\n"
		exit 1
	fi
fi

printf "Attempting to mount $MOUNTDIR...\n"

# Mount the directory with ifuse
# CAUTION: using the nonempty option can cause confusion if any files or directories
# are named the same
ifuse $MOUNTDIR -o nonempty

# Check to see if the mount was successful or not and report out
if [[ $? -ne 0 ]]; then
	printf "Mount failed with code $?. Exiting.\n"
	exit 1
fi

printf "iOS device mounted successfully.\n"


# Recursively loop through all files and directories found in DCIM
# recursion calls the process method to convert/move files
recursion $DCIMDIR


# Unmount the phone so it can just be unplugged without issue
umount $MOUNTDIR
if [[ $? -ne 0 ]]; then
	printf "Device failed to unmount. Use care when disconnecting device. Exiting.\n"
	exit 1
fi

printf "Device unmounted successfully. You can now disconnect the device.\n"

exit 0
