#!/bin/sh
set -e -x

#Localhost locations
HOSTNAME=`hostname`
HOSTBACKUPPATH=""
BORG_CONFIGDIR=""
BORG_CACHEDIR=""

BORG_ENV="-e BORG_RELOCATED_REPO_ACCESS_IS_OK=yes -e TZ=etc/GMT"
BORG_ARCHIVE=$HOSTNAME-{user}-{now:%Y-%m-%d_%H:%M:%S}
BORG_REMOTE="ssh://borgbackup"
BORG_REPO=$BORG_REMOTE/mnt/data/borgbackup/$HOSTNAME
CONTAINER_PATH="/tmp"
CONTAINER_VOLUMES="-v ${BORG_CONFIGDIR}:/root/.config/borg -v /root/.ssh:/root/.ssh:ro -v ${BORG_CACHEDIR}:/cache"
BORG="docker run -t --rm ${BORG_ENV} ${CONTAINER_VOLUMES} hobbsau/borgclient"



if [ "$1" = "--init" ]; then
#	ssh-copy-id $BORG_REMOTE
	$BORG init --encryption=keyfile $BORG_REPO
	exit

elif [ "$1" = "--break-lock" ]; then
	$BORG break-lock $BORG_REPO
	exit

elif [ "$1" = "--backup" ]; then
	#Set the volume mounts based on the selected backup paths
	for word in $HOSTBACKUPPATH
		do
		CONTAINER_VOLUMES="${CONTAINER_VOLUMES} -v $word:$CONTAINER_PATH$word:ro"
		done
	BORG="docker run -t --rm ${BORG_ENV} ${CONTAINER_VOLUMES} hobbsau/borgclient"
	$BORG create \
	--show-version --verbose --stats \
	$BORG_REPO::$BORG_ARCHIVE \
	$CONTAINER_PATH 
	exit

elif [ "$1" = "--extract" ]; then
	# borgbackup.sh --extract LOCAL_PATH REPO [PATH_TO_FILES]
	CONTAINER_VOLUMES="${CONTAINER_VOLUMES} -v $2:$CONTAINER_PATH"
	BORG="docker run -t --rm ${BORG_ENV} ${CONTAINER_VOLUMES} hobbsau/borgclient"
	$BORG extract \
	--verbose --list \
	$BORG_REPO::$3 \
	tmp/$4
	exit

elif [ "$1" = "--prune" ]; then
	$BORG prune \
	--verbose --stats --list \
	--keep-daily 7 \
	--keep-weekly 4 \
	--keep-monthly 12 \
	--keep-yearly 7 \
	$BORG_REPO
	exit

elif [ "$1" = "--list" ]; then
	$BORG list -v \
	$BORG_REPO
	exit

elif [ "$1" = "--check" ]; then
	$BORG check -v --repository-only \
	$BORG_REPO
	exit

elif [ "$1" = "--info" ]; then
	$BORG info -v \
	$BORG_REPO::$2
	exit

elif [ "$1" = "--delete" ]; then
	$BORG delete -v \
	$BORG_REPO::$2
	exit

elif [ "$1" = "--fulldelete" ]; then
	$BORG delete -v \
	$BORG_REPO
	exit
fi
