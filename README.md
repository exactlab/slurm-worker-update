# Update OS of Ubuntu Slurm Worker Nodes

1. Submit the update.sh script to Slurm on selected worker nodes
2. Immediately perform _scontrol reboot_ on selected node
 
_scontrol reboot ASAP nextstate=DOWN_ will reboot the selected nodes when they become idle.

As per documentation in https://slurm.schedmd.com/scontrol.html, 

>The "ASAP" option adds the "DRAIN" flag to each node's state, preventing additional jobs from running on the node so it can be rebooted and returned to service "As Soon As Possible" (i.e. ASAP). "ASAP" will also set the node reason to "Reboot ASAP" if the "reason" option isn't specified. If the "nextstate" option is specified as "DOWN", then the node will remain in a down state after rebooting. 



You may want to use the following example.


```console
LIST_NODES=(node001 node002 node003)
for node in ${LIST_NODES[@]}
do
  echo "Running updates on node $node"
  sbatch --mem=0 --exclusive --nodelist=$node -J "Updating OS" update.sh
  [[ $? == 0 ]] && scontrol reboot ASAP nextstate=DOWN $node
  [[ $? == 0 ]] && echo -e "Node $node has been marked for reboot ASAP\n"
done
```

The node will update itself thanks to the update.sh Slurm job script and, once idle, will run a reboot as soon as possible. After reboot, will come back in DOWN state.



