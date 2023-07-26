#!/bin/bash

#*****************************************************************************
# 				Additional Recon Tools
#*****************************************************************************

function getWebserversWithProtocolIssues() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$reconPath/web_tech_all.output.log

	local findingsDir=$defaultPath/findings
	mkdir -p $findingsDir

	local webserver_protocol_issues=$findingsDir/web_server_protocol_issues.txt

	if [ -s "$input" ] ; then
		
		local now="$(date +'%d/%m/%Y-%::z')"

		echo "============================================================================"
		echo "Finding web servers with protocol issues for project $1"
		echo "Current time: $now"
		echo "============================================================================"
		
		cat $input | grep unsupported | awk '{ print $1}' | tee $webserver_protocol_issues > $(changeFileExtension $webserver_protocol_issues "new")

		local now="$(date +'%d/%m/%Y-%::z')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="
	else
		echo "============================================================================"
		echo "No relevant log ouput from web techologies. Not performing filtering "
		echo "============================================================================"
	fi
}
