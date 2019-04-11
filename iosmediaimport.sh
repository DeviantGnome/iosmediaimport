#!/bin/bash

function createFileName {
	inc=2

	if [[ -e "$IMPORTDIR/$basefile.$extension" ]]; then

		while [[ -e "$IMPORTDIR/$basefile-$inc.$extension" ]]; do
			let inc++
		done

		basefile="$basefile-$inc"

	fi
}

function process {

	i=$1

	# Set file names and extensions
	fileName=$(basename -- $i)   # IMG_1369.JPG
	basefile=${fileName%.*}      # IMG_1369
	extension=${fileName##*.}    # JPG
	fullDir=$(dirname ${i})      # /home/user/.iosmediaimport/iosmountdir/DCIM/101APPLE

	# Create THUMBNAIL_DIRECTORY
	THUMBNAIL_DIRECTORY="${fullDir/$DCIMDIR/$THUMBNAIL_DIRECTORY_STUB}/$fileName"


	# Get date of file
	# This works fine if the file hasn't been monkied with,
	# but after I accidentally moved all the pictures from my phone to my comp,
	# I found that the date it is getting is today's date. My phone is still Using
	# the original file date, so I just need to figure out how to reliably pull
	# that date
	#
	# exiftool is a good option here, but that's another piece of software
	# that the user will have to have installed first. Not a big issue, but
	# something to consider. Also, how does exiftool handle MOV creation dates?
	# they are a different tag in the metadata.
	local FILE_DATE=$(date -r $fullDir/$fileName +%F)

	# Convert FILE_DATE to timestamp
	local FILE_TIMESTAMP=$(date -d $FILE_DATE +%s)

	# Compare the dates, and if the file's date is less, process
	if [[ $FILE_TIMESTAMP > $LIMIT_TIMESTAMP ]]; then
		printf "File is newer than 30 days. Skipping...\n"
		return
	fi

	# Check file extension and take appropriate action
	if [[ $extension = "HEIC" ]]; then
		if [[ $HEIC_CONVERT = "true" ]]; then
			printf "Converting HEIC file $fileName..."
			extension="jpg"
			createFileName
			./tifig -v -p $i "$IMPORTDIR/$basefile.$extension"
		else
			printf "Copying HEIC file $fileName... "
			extension="heic"
			createFileName
			cp $i "$IMPORTDIR/$basefile.$extension"
		fi
	elif [[ $extension = "MOV" ]]; then
		if [[ $HANDBRAKE_CONVERT = "true" ]]; then
			printf "Converting MOV file $fileName... "
			extension="m4v"
			createFileName
			HandBrakeCLI -i $i -o "$IMPORTDIR/$basefile.$extension" -e x264 -q 20
		else
			printf "Copying MOV file $fileName... "
			extension="mov"
			createFileName
			cp $i "$IMPORTDIR/$basefile.$extension"
		fi
	elif [[ $extension = "JPG" ]]; then
		printf "Copying JPG file $fileName... "
		extension="jpg"
		createFileName
		cp $i "$IMPORTDIR/$basefile.$extension"
	elif [[ $extension = "PNG" ]]; then
		printf "Copying PNG file $fileName... "
		extension="png"
		createFileName
		cp $i "$IMPORTDIR/$basefile.$extension"
	else
		printf "Copying file $fileName... "
		createFileName
		cp $i "$IMPORTDIR/$basefile.$extension"
	fi

	# Remove the file from the device if the previous move command was successful
	if [[ $? -eq 0 ]]; then
		printf "done.\n"

		printf "Removing $fileName from device... "
		rm $i

		if [[ $? -eq 0 ]]; then
			printf "done.\n"
		else
			printf "$fileName not deleted from device.\n"
		fi

		# Also need to remove THUMBNAIL_DIRECTORY
		printf "Removing thumbnail from device... "
		rm -rf $THUMBNAIL_DIRECTORY

		if [[ $? -eq 0 ]]; then
			printf "done.\n"
		else
			printf "Thumbnail not removed from device.\n"
		fi

	else
		printf "$fileName not copied from device.\n"
	fi

}

function recursion {

	for i in $1/*
	do
		if [ -d $i ]; then
			recursion $i
		elif [ -f $i ]; then
			process $i
		fi
	done

}

#
#
# Set some variables
#
#

# Get current date as unix timestamp
CURRENT_TIMESTAMP=$(date +%s)
#printf "Current timestamp: "$CURRENT_TIMESTAMP"\n"

# Then subtract 30 days from it
LIMIT_TIMESTAMP=$[CURRENT_TIMESTAMP-2592000]
#printf "Limit timestamp: "$LIMIT_TIMESTAMP"\n"

# Should be pretty unique so as to not override any existing directory
ROOTHIDDEN=~/.iosmediaimport

# Subdirectory to mount device to. This way config files or anything else can
# live in ROOTHIDDEN, if that happens at some point.
HIDDENMOUNT=/iosmountdir
MOUNTDIR=$ROOTHIDDEN$HIDDENMOUNT
DCIMDIR=$MOUNTDIR/DCIM

# Define import directory
IMPORTDIR=~/iOSMediaImport

# Define thumbnail directory stub
THUMBNAIL_DIRECTORY_STUB=$MOUNTDIR"/PhotoData/Thumbnails/V2/DCIM"


# Print some general information to the user
printf "INFO: This program will move all image and movie files found in the DCIM "
printf "directory of the connected device older than 30 days, and will then delete them from the device.\n"

# Check to see if ifuse is installed
if ! command -v ifuse >/dev/null 2>&1; then
	printf "ifuse is not installed. Please install ifuse and retry. Exiting.\n"
	exit 1
fi

# Set TIFIG_CONVERT to true, change to false if not available
HEIC_CONVERT="true"

# Check that tifig is found in the current directory, and make it executable
if [[ -f tifig ]]; then
	chmod u+x ./tifig
else
	printf "tifig should be in the same directory as this script and wasn't found.\n"
	printf "Any HEIC images will not be converted.\n"
	HEIC_CONVERT="false"
fi

# Set HEIC_CONVERT to true, change to false if not available
HANDBRAKE_CONVERT="true"

# Check to see if HandBrakeCLI is installed
if ! command -v HandBrakeCLI >/dev/null 2>&1; then
	printf "HandBrakeCLI is not installed. Any MOV files will not be converted.\n"
	HANDBRAKE_CONVERT="false"
fi

# Check to see if the MOUNTDIR is mounted
# Do this before checking if it exists, because if it's already mounted,
# the check below won't find it
if [[ $(findmnt -M $MOUNTDIR) ]]; then

        printf "$MOUNTDIR is already mounted. Unmounting...\n"

        # Unmount the directory
		fusermount -u $MOUNTDIR

        if [[ $? -ne 0 ]]; then
                printf "Error unmounting $MOUNTDIR. fusermount command exited with error code $?. Exiting.\n"
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
#+recursion calls the process method to convert/move files
recursion $DCIMDIR


# Rename the photos database to force the device to rebuild the database
#+with only the remaining photos
printf "Deleting Photos.sqlite database on device... "
mv "$MOUNTDIR/PhotoData/Photos.sqlite" "$MOUNTDIR/PhotoData/Photos.sqlite.bak"

if [[ $? -eq 0 ]]; then
	printf "done.\n"
	printf "Please note that your device may require a restart to trigger "
	printf "the database to rebuild with your remaining photos and videos.\n"
else
	printf "The database failed to be removed.\n"
fi


# Unmount the phone so it can just be unplugged without issue
fusermount -u $MOUNTDIR
if [[ $? -ne 0 ]]; then
	printf "Device failed to unmount. Use care when disconnecting device. Exiting.\n"
	exit 1
fi

printf "Device unmounted successfully. You can now disconnect the device.\n"

exit 0
