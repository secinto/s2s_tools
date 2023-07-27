#!/bin/bash


#*****************************************************************************
# 				INITIALIZATION FUNCTIONS
#*****************************************************************************
send_results="false"

#============================================================================
# General initialization for creating the project directory to store all 
# generated files in also checking if a license is available if results should
# be sent to the portal and stored there also.
#============================================================================
function initialize() {
	if [ "$#" -ge 1 ]; then
		project=$1
		initProject
		echo "Initialization for $project finished"
		true
	else
		echo "No project/domain to perform analysis on has been specified."
		false
	fi
}
	
#============================================================================
# Creating the project and working directory to store all generated files in.
# The defaultPath contains all the "relevant" files, whereas the workPath 
# contains intermediate or temporary files which will be kept there but are 
# not consolidated.
#============================================================================
function initProject() {
	
	# Create the default path for reading and storing files associated with 
	# a specific project. 
	defaultPath="/opt/s2s/$project"
	workPath="$defaultPath/work"
	reconPath="$defaultPath/recon"
	responsePath="$defaultPath/responses"
	brutePath="$defaultPath/brute"

	mkdir -p $defaultPath
	mkdir -p $workPath
	mkdir -p $reconPath
	mkdir -p $responsePath
	mkdir -p $brutePath
}

#============================================================================
# Initializes the project for broad scope evaluation. It can be used either
# by providing the project name (FQDN) and an input file with all the domains
# which should be included under this project such as
# initBroad example.com domains.txt
# or by providing the project name and the domains as arguments separately. 
# In any case the list of domains included in the project are stored in the 
# resulting project folder in the multi_domains.txt file. 
#============================================================================
initBroad() {

	initialize "$@"
	local input=$2
	local domains=$defaultPath/domains.txt
	local output=$defaultPath/multi_domains.txt

	echo "============================================================================"
	echo "Performing broad scope initialization for $project"
	echo "============================================================================"

	# Get all associated domains - Either via an input file or specified in the command line
	if [ -s "$input" ]; then
		cat $input | sort -u | anew $output
	else
		for var in "$@"
		do
			echo $var | anew $output
		done
	fi

	recon "$1" & disown
}

#============================================================================
# Perform the recon process on a remote host
#============================================================================
function doRemoteRecon() {
	initialize "$@"
	
	if [[ -n "${SSH_S2S_USER+set}" && -n "${SSH_S2S_SERVER+set}" ]]; then
		
		local ssh_base="$SSH_S2S_USER@$SSH_S2S_SERVER"
		echo "SSH base command: $ssh_base"
			
		if [ -f $defaultPath/multi_domains.txt ]; then
			echo "Multi domain project"
			echo "Creating s2s directory for $project on remote machine $SSH_S2S_SERVER"
			local ssh_command="mkdir -p /opt/s2s/$project"
			local return="$(ssh $ssh_base -t $ssh_command)"
			#scp $defaultPath/multi_domains.txt $SSH_S2s_USER:$SSH_S2S_PAS@$SSH_SERVER:/opt/s2s/$project/multi_domains.txt 
			echo "Copying multi_domains file to remote machine $SSH_S2S_SERVER"
			local return="$(scp $defaultPath/multi_domains.txt $ssh_base:/opt/s2s/$project/multi_domains.txt)"
		else
			echo "Single domain project"
			
		fi

		echo "Starting recon on remote machine $SSH_S2S_SERVER"
		if [ "$SSH_S2S_USER" == "root" ]; then
			local ssh_command="nohup /$SSH_S2S_USER/executeRecon.sh $project"
		else 
			local ssh_command="nohup /home/$SSH_S2S_USER/executeRecon.sh $project"
		fi
		echo "SSH command $ssh_command"
		local return="$(ssh $ssh_base -t $ssh_command)"

	fi
}

#============================================================================
# Check if the results of the remote recon process are already available. 
# If yes, download the resulting ZIP file, delete the local project directory
# and decompress and replace the local project directory with the results.
#============================================================================
function getRemoteReconResults() {
	initialize "$@"
	
	if [[ -n "${SSH_S2S_USER+set}" && -n "${SSH_S2S_SERVER+set}" ]]; then
		
		local ssh_base="$SSH_S2S_USER@$SSH_S2S_SERVER"
		echo "SSH base command: $ssh_base"
			
		echo "Checking if recon for $project has finished"
		local ssh_command="checkFinished $project"
		echo "SSH command $ssh_command"
		local return="$(ssh $ssh_base -t $ssh_command)"
		echo "$return"
		if [[ "$return" == *"$project FINISHED"* ]]; then
			echo "Getting $project.zip file from remote host $SSH_S2S_SERVER"
			rm -rf $defaultPath
			local return="$(scp $ssh_base:/opt/s2s/$project/$project.zip /tmp/$project.zip)"
			unzip /tmp/$project.zip -d /
		fi
	fi
}


#============================================================================
# Create the configuration file for the elasticPusher tools with information
# stored in environment variables S2S_ELK_SERVER, S2S_ELK_USER, and 
# S2S_ELK_PASS. 
#============================================================================
function createElasticEnvironment() {

	if [[ -n "${S2S_ELK_SERVER+set}" && -n "${S2S_ELK_USER+set}" && -n "${S2S_ELK_PASS+set}" ]]; then
		local configFile=~/.config/elasticPusher/settings.yaml
		echo "---" > $configFile
		echo "elk_host: \"$S2S_ELK_SERVER\"" >> $configFile
		echo "username: \"$S2S_ELK_USER\"" >> $configFile
		echo "password: \"$S2S_ELK_PASS\"" >> $configFile
	else
		echo "Not all required environment variables exist. S2S_ELK_SERVER, S2S_ELK_USER, S2S_ELK_PASS"
	fi
	
}

function joinZerotierNetwork() {
	zerotier-cli join $ZEROTIER_NETWORK_ID
}
