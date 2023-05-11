# Update OS of Ubuntu Slurm Worker Nodes

1. Submit the _slurm_update_nodes.sh_ script to Slurm on selected worker nodes
2. Immediately perform _scontrol reboot_ on selected node
 
_scontrol reboot ASAP nextstate=DOWN_ will reboot the selected nodes when they become idle.

As per documentation in https://slurm.schedmd.com/scontrol.html, 

>The "ASAP" option adds the "DRAIN" flag to each node's state, preventing additional jobs from running on the node so it can be rebooted and returned to service "As Soon As Possible" (i.e. ASAP). "ASAP" will also set the node reason to "Reboot ASAP" if the "reason" option isn't specified. If the "nextstate" option is specified as "DOWN", then the node will remain in a down state after rebooting. 

_scontrol reboot_ needs the _RebootProgram_ to be properly configured in slurm.conf (https://slurm.schedmd.com/slurm.conf.html). 

You may want to use the following example.

```console
LIST_NODES=(node001 node002 node003)
for node in ${LIST_NODES[@]}
do
  echo "Running updates on node $node"
  sbatch --mem=0 --exclusive --nodelist=$node -J "Updating OS" slurm_update_nodes.sh
  # skipping if previous command fails
  if [[ $? != 0 ]]
  then
   echo "Something went wrong when submitting update script to node $node"
   echo -e "Skipping update on node $node\n"
   continue
  fi
  # give Slurm the time to have the job in the queue
  sleep 3
  # request a reboot when node is idle
  scontrol reboot ASAP nextstate=DOWN $node
  [[ $? == 0 ]] && echo -e "Node $node has been marked for reboot ASAP\n"
done
```

The node will update itself thanks to the update.sh Slurm job script and, once idle, will run a reboot as soon as possible. After reboot, will come back in DOWN state.

# Checks to run on the updated node

You may want to check on the newly updated node:

- _uname -a_ to know which is the last installed kernel
- _dmesg -T_ to check if something went wrong (kernel modules, DKMS issues?)

Suppose you have a list of mount point to check:

```console
MOUNTS=(/mnt/donald /mnt/mickey)
for mount in ${MOUNTS[@]}
do
 echo "Check $mount is mounted"
 # change directory to be sure is mounted if in autofs 
 cd $mount && ls
 mount | grep $mount
 [[ $? == 0 ]] && echo -e "Mount \n"
 
done
```

# Final steps

Update the node status to be ready to accept new jobs. 

```console
LIST_NODES=(node001 node002 node003)
for node in ${LIST_NODES[@]}
do
 scontrol update nodename=$node state=idle
 sleep 3
 srun --nodelist=$node /bin/hostname
done
```



