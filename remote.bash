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
		if [ ! -f "$defaultPath/$project.zip" ]; then
			zip -q -r $defaultPath/$project.zip $defaultPath &> /dev/null
		fi
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

	local started=$defaultPath/recon_started
	
	if [ ! -f "$started" ]; then
		if [ -f "$defaultPath/s2s.log" ]; then
			rm $defaultPath/s2s.log
		fi
		
		recon $project &> $defaultPath/s2s.log & disown
	else
		echo "Recon already started and running."
	fi
}
