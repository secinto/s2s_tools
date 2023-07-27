#!/bin/bash
#*****************************************************************************
# This file is used for better automation of the remote actions of s2s_tools.
#*****************************************************************************

#*****************************************************************************
# Checks if the recon process has finished and compresses the results into 
# a <project>.zip file in the defaultPath of the project.
#*****************************************************************************
function checkFinished() {
	if ! initialize "$@"; then	
		echo "Exiting"
		return
	fi
	
	local finished=$defaultPath/recon_finished
	local started=$defaultPath/recon_started
	
	if [ -s "$finished" ]; then
		zip -q -r $defaultPath/$project.zip $defaultPath &> /dev/null
		if [ -f "$started" ]; then
			cat $started > $defaultPath/timing.txt
			rm $started &> /dev/null
		fi
		cat $finished >> $defaultPath/timing.txt
		rm $finished &> /dev/null
		echo "$project FINISHED"
	elif [ -s "$recon_started" ]; then
		echo "RUNNING"
	else
		echo "NOT STARTED"
	fi
	
}

#*****************************************************************************
# Starts the recon process for the specified project.
#*****************************************************************************
function performRecon() {
	if ! initialize "$@"; then	
		echo "Exiting"
		return
	fi
	
	rm $defaultPath/s2s.log
	recon $project &> $defaultPath/s2s.log

}
