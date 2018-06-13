#!/bin/bash
# parallelize normalization and encoding from .flac
#
NUM=0
QUEUE=""

function echoqueue {
	for PID in $QUEUE
	do
		echo -n "$PID "
	done
	echo
}

function queue {
	QUEUE="$QUEUE
$1"
	NUM=$(($NUM+1))
	echo -n "QUEUE ";echoqueue
}

function dequeue {
	OLDDEQUEUE=$QUEUE
	QUEUE=""
	for PID in $OLDDEQUEUE
	do
		if [ ! "$PID" = "$1" ] ; then
			QUEUE="$QUEUE
$PID"
		fi
	done
	NUM=$(($NUM-1))
	echo -n "DEQUEUE ";echoqueue
}

function checkqueue {
	OLDCHQUEUE=$QUEUE
	for PID in $OLDCHQUEUE
	do
		if [ ! -d /proc/$PID ] ; then
			dequeue $PID
		fi
	done
	echo -n "CHECKQUEUE ";echoqueue
}

IFS="
"
for INS in $*
do
	#sleep $(($RANDOM/2000)) &
	
	#COMMAND TO SPAWN
	RF=`echo "$INS" | sed -e 's/.flac$//'`
	sh -c "flac -s -d \"$RF.flac\"
		   ssrc_hp --quiet --normalize \"$RF.wav\" \"$RF-norm.wav\"
		   lame --quiet -b 192 \"$RF-norm.wav\" \"$RF.mp3\"
		   rm \"$RF.wav\" \"$RF-norm.wav\" " &
	#COMMAND TO SPAWN STOP
	
	PID=$!
	queue $PID
	
	while [ $NUM -ge 6 ] # MAX PROCESSES
	do
		checkqueue
		sleep 1
	done
done
