#!/bin/bash

function loadScripts() {
	local init="$currentDirectory/s2s_init.bash"

	if [ -s "$init" ]; then
		echo "============================================================================"
		echo "Sourcing init script from location "
		echo "$init"
		echo "============================================================================"
		
		source "$init"
		
	else
		echo "Init script not available from $init."
		#exit 1
	fi

	local support="$currentDirectory/s2s_support.bash"

	if [ -s "$support" ]; then
		echo "============================================================================"
		echo "Sourcing support script from location "
		echo "$support"
		echo "============================================================================"
		
		source "$support"
		
	else
		echo "Support script not available from $support."
		#exit 1
	fi

	local recon_tools="$currentDirectory/s2s_recon_tools.bash"

	if [ -s "$recon_tools" ]; then
		echo "============================================================================"
		echo "Sourcing RECON tools script from location "
		echo "$recon_tools"
		echo "============================================================================"
		
		source "$recon_tools"
		
	else
		echo "RECON tools script not available from $recon_tools."
		#exit 1
	fi
	
	local recon_filter="$currentDirectory/s2s_recon_filter.bash"

	if [ -s "$recon_filter" ]; then
		echo "============================================================================"
		echo "Sourcing RECON filter script from location "
		echo "$recon_filter"
		echo "============================================================================"
		
		source "$recon_filter"
		
	else
		echo "RECON filter script not available from $recon_filter."
		#exit 1
	fi
	
	local scan_web_dir="$currentDirectory/s2s_scan_web_dir.bash"

	if [ -s "$scan_web_dir" ]; then
		echo "============================================================================"
		echo "Sourcing Web Directory scanning script from location "
		echo "$scan_web_dir"
		echo "============================================================================"
		
		source "$scan_web_dir"
		
	else
		echo "Web Directory scanning script not available from $scan_web_dir."
		#exit 1
	fi

	local scan_net="$currentDirectory/s2s_scan_net.bash"

	if [ -s "$scan_net" ]; then
		echo "============================================================================"
		echo "Sourcing network scanning script from location "
		echo "$scan_net"
		echo "============================================================================"
		
		source "$scan_net"
		
	else
		echo "Network scanning script not available from $scan_net."
		#exit 1
	fi

	local resolve_addresses="$currentDirectory/s2s_resolve_addresses.bash"

	if [ -s "$resolve_addresses" ]; then
		echo "============================================================================"
		echo "Sourcing address resolving script from location "
		echo "$resolve_addresses"
		echo "============================================================================"
		
		source "$resolve_addresses"
		
	else
		echo "Address resolving script not available from $resolve_addresses."
		#exit 1
	fi
	
	local brute_force="$currentDirectory/s2s_brute_force.bash"

	if [ -s "$brute_force" ]; then
		echo "============================================================================"
		echo "Sourcing brute forcing script from location "
		echo "$brute_force"
		echo "============================================================================"
		
		source "$brute_force"
		
	else
		echo "Brute forcing script not available from $brute_force."
		#exit 1
	fi

	local remote="$currentDirectory/remote.bash"

	if [ -s "$remote" ]; then
		echo "============================================================================"
		echo "Sourcing remote handling script from location "
		echo "$remote"
		echo "============================================================================"
		
		source "$remote"
		
	else
		echo "Remote handling script not available from $remote."
		#exit 1
	fi

	echo "============================================================================"
	echo "Loaded all include scripts"
	echo "============================================================================"

}

if [[ $(echo "$SHELL" | grep -w zsh -o) == "zsh" ]]
then
    currentDirectory="${0:A:h}"
else 
    currentDirectory="${BASH_SOURCE%/*}"
fi

if [[ ! -d "$currentDirectory" ]]; then 
	currentDirectory="$PWD"; 
fi

loadScripts
