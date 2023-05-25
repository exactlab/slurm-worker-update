#!/bin/bash

# francesco de giorgi - eXact lab 2023
# www.exactlab.it - support@exact-lab.it

# Requested by ETHZ - May 2023

# read nodes state on a Slurm cluster
# check drain / draining nodes
# force idle state in case node is clean

# USAGE:
# ./run.sh [additional nodes]
# The script will read `sinfo` and work only on # drain/draining nodes
# Additional nodes can be  given as arguments

####### LOGGING HERE ########

# uncomment here in case you want output to file
#LOGFILE="log.log"
#exec 3>&1 1>"$LOGFILE" 2>&1
############################


####### CHECKS HERE ########

# list of checks to run on all the Slurm workers
# they are just simple bash functions (see below)
# to add a check, just
# 1. write another function
# 2. add to LIST_OF_CHECKS
# 3. write the function
# The function must return 1 in case something is wrong

LIST_OF_CHECKS=(check_mount)
# list of checks to run on GPU Workers
LIST_OF_CHECKS_GPU=(check_gpu)

# check some mount points
# just check if ls is working
# otherwise return 1
check_mount() {
    CHECK_MOUNTS=(/u/ /opt/ /home/)
    for i in ${CHECK_MOUNTS[@]}
    do
	    ls $i &> /dev/null || return 1
    done

}

# check if nvidia-smi exits to 0
# return 1 otherwise
check_gpu() {
    nvidia-smi || return 1
    # deviceQuery from cuda samples?
}
#############################



####### SLURM STUFF HERE ########

# do something on server
do_something() {
    host=$1
    state=$2
    reason=$3
    scontrol update nodename=$host state=$state reason=reason
}


# gather info from sinfo, grep only drain / draining nodes
check_sinfo() {
    # no header
    # output only name and state
    # grep dra (drain or draining the same at this stage)
    sinfo -h  -o "%n %t" | grep -i dra |  awk '{print $1}' | xargs
}
################################





####### MAIN HERE ########

# get a list of node names to check
# additional nodes can be passed as args in case sinfo doesn't provide nodes
extranodes=$@
nodelist=($(check_sinfo) $extranodes)
ALL_CHECKS=(${LIST_OF_CHECKS[@]})
now=`date +"%d/%m/%Y %H:%M:%S"`
echo -e "\n\nRunning node checker [$now]\n"
for server in ${nodelist[@]}
do
    results=0
    # if this is a gpu server, run also gpu checks
    if grep -q "gpu" <<< $server
    then
        ALL_CHECKS=(${LIST_OF_CHECKS[@]} ${LIST_OF_CHECKS_GPU[@]})
    fi
    # loop on all the checks
    for check in ${ALL_CHECKS[@]}
    do
        echo -e "Server $server: doing $check"
        ssh $server "$(typeset -f ${ALL_CHECKS[@]});$check"
        this_check=$?
        results=$((results+$this_check))
        test $this_check -ne 0 && echo -e "Server $server: check $check exit is $this_check!"
    done
    # if one of the above checks has exit != 0, something is wrong
    if [ $results -eq 0 ]
    then
        echo -e "\nServer $server: clean, setting IDLE on Slurm"
        do_something $server "resume" "Apparently OK"
    else
        echo -e "\nServer $server: not ok, please check!\nSetting now DOWN on Slurm"
        do_something $server "down" "Apparently broken!"
    fi

done

now=`date +"%d/%m/%Y %H:%M:%S"`
echo -e "\nComplete node checker [$now]\n\n"

# EOF
