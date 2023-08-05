# s2s_tools

Bash scripts for S2S tools

## Installation directory for the scripts

The scripts should be cloned into the folder s2s_tools. Should be the default case. 

## Installing dependencies

This contains all the bash scripts for automation of many recon steps. Several tools and libraries are required to be installed.
Therefore the following script needs to be executed. It should ask for the SUDO password where required. 

```
./install_tools.sh 
```

If you want directly to run it via github rawusercontent, just enter the following command and everything will be set up.

```
bash <(curl https://raw.githubusercontent.com/secinto/s2s_tools/main/install_tools.sh)
```

## Environment 

In order that the scripts can be called directly from the console they must either be included directly in the .bashrc or .profile 
environment scripts. 

It is best to use the following lines and add them to the .profile script. If the s2s.tools folder exists in the home directory the 
s2s_main.bash file is sourced, which then includes all the other bash scripts.

```
export GOPATH=~/go
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

if [ -d "$HOME/s2s_tools" ] ; then
    source s2s_tools/s2s_main.bash
fi

```

In order to use IP Info resolving IPINFO.IO is used. Therefore a API key is needed. The S2S_IPINFO_TOKEN environment variable is used to provide this information and must be set therefore.

```
export S2S_IPINFO_TOKEN="<ipinfo.io api token>"

```

