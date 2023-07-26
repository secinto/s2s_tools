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
	
	if [ -s "$finished" ]; then
		zip -q -r $defaultPath/$project.zip $defaultPath
		echo "$project FINISHED"
	else
		echo "RUNNING"
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
	
	recon $project &> $defaultPath/s2s.log & disown
	
	echo "STARTED"
}