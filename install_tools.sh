#!/bin/bash

#----------------------------------------------------------
# Install functions
#----------------------------------------------------------
function updateProfile() {
	cd $HOME
	cp /opt/tools/s2s_tools/.profile $HOME/.profile
	cp /opt/tools/s2s_tools/.bashrc $HOME/.bashrc
	
	source .profile
}

function installToolGit() {
	local repo=$1
	local url=$2

	#Install tool
	if [ -d "$tools/$repo" ]; then
		cd "$tools/$repo"
		git pull
	else
		cd "$tools"
		git clone $url
	fi
}

function installRepoGit() {
	local repo=$1
	local url=$2

	#Install git repo
	if [ -d "$repos/$repo" ]; then
		cd "$repos/$repo"
		git pull
	else
		cd "$repos"
		git clone $url
	fi
}

#----------------------------------------------------------
# Install script
#----------------------------------------------------------

function installBase() {

	echo "2a01:4f8:c010:d56::2 github.com" >> /etc/hosts
	echo "2a01:4f8:c010:d56::3 api.github.com" >> /etc/hosts
	echo "2a01:4f8:c010:d56::4 codeload.github.com" >> /etc/hosts
	echo "2a01:4f8:c010:d56::5 objects.githubusercontent.com" >> /etc/hosts
	
	sudo mkdir -p /opt/tools/resources
	#sudo mkdir -p /opt/repos


	# Install tools and software via APT
	sudo apt update

	distro=$(lsb_release -d | awk -F"\t" '{print $2}')

	echo $distro

	if [[ $distro == *"Debian"* ]]; then
	   echo "Found Debian distro"
	   sudo apt install -y jq python3 git curl unzip zip python3-pip build-essential nmap xsltproc dos2unix
	elif [[ $distro == *"Ubuntu"* ]]; then
	   echo "Found Ubuntu distro"
	   sudo apt install -y jq python3 git curl unzip zip python3-pip build-essential nmap xsltproc dos2unix
	elif [[ $distro == *"Kali"* ]]; then
	   echo "Found Kali distro"
	   sudo apt install -y jq python3 git curl unzip zip python3-pip build-essential nmap xsltproc dos2unix
	else
	   echo "Found another distro"
	   exit 2
	fi

	# Install golang in the home directory! Maybe this should be general
	cd ~
	if ! command -v go >/dev/null 2>&1; then
	   echo "GO command not found installing it from source"
	   local goarchive=go1.20.6.linux-amd64.tar.gz
	   wget https://go.dev/dl/$goarchive
	   rm -rf /usr/local/go
	   tar -C /usr/local -xzf $goarchive
	   export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
	   rm $goarchive
	else
	   echo "GO already installed"
	fi
	
	installToolGit s2s_tools https://github.com/secinto/s2s_tools.git
	
	curl -s https://install.zerotier.com | bash

}

function installGOTools() {

	# Install GO tools
	go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
	go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
	go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
	go install -v github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest
	go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
	go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
	go install -v github.com/tomnomnom/anew@latest
	go install -v github.com/tomnomnom/hacks/unfurl@latest
	go install -v github.com/ffuf/ffuf@latest
	go install -v github.com/projectdiscovery/alterx/cmd/alterx@latest
	go install -v github.com/secinto/elasticPusher/cmd/elasticPusher@latest
	go install -v github.com/secinto/simpleFinder/cmd/simpleFinder@latest
	go install -v github.com/secinto/duplicateRemover/cmd/duplicateRemover@latest
	go install -v github.com/secinto/nmapParser/cmd/nmapParser@latest
	go install -v github.com/d3mondev/puredns/v2@latest
	go install -v github.com/rverton/webanalyze/cmd/webanalyze@latest
	mkdir -p ~/.config/nmapParser
	mkdir -p ~/.config/simpleFinder
	mkdir -p ~/.config/duplicateRemover
	cp $s2s_tools/resources/settings.yaml ~/.config/duplicateRemover/.
	cp $s2s_tools/resources/settings.yaml ~/.config/simpleFinder/.
	cp $s2s_tools/resources/settings.yaml ~/.config/nmapParser/.

}

function installAdditionalNonGOTools() {

	# Install feroxbuster
	curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh | bash -s /usr/local/bin

	# Install additional tools
	installToolGit ffuf-scripts https://github.com/ffuf/ffuf-scripts.git
	installToolGit nmapXMLParser https://github.com/secinto/nmapXMLParser.git
	installToolGit testssl.sh https://github.com/drwetter/testssl.sh.git
	
	installToolGit massdns https://github.com/blechschmidt/massdns.git
	cd "$tools/massdns"
	make
	sudo make install
	cp $tools/massdns/lists/resolvers.txt $tools/resources/.
	mkdir -p $HOME/.config/puredns
	cp $tools/massdns/lists/resolvers.txt $HOME/.config/puredns/resolvers.txt
	
	
	installToolGit Interlace https://github.com/codingo/Interlace.git
	cd "$tools/Interlace"
	python3 setup.py install
	

}

function installWordlists() {
	# Install complete repos (usually wordlists)
	#installRepoGit SecLists https://github.com/danielmiessler/SecLists.git
	#installRepoGit OneListForAll https://github.com/six2dez/OneListForAll.git
	#$repos/OneListForAll/olfa.sh
	echo "Nothing is done since all resources are now in $s2s_tools/resources/"
	#cp $s2s_tools/resources/*.txt /opt/tools/resources/.
}

export tools=/opt/tools
export s2s_tools=/opt/tools/s2s_tools

# First install base requirements - must be performed
installBase
# Installing different tools and resources
installGOTools
installAdditionalNonGOTools
#installWordlists
# Setting up the environment
updateProfile
