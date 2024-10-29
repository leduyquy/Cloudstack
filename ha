#!/bin/bash
cmk="/usr/bin/cmk"
path="/cloudstack_ha"
list_node_down="/cloudstack_ha/id_node_down"
vm_impact="/cloudstack_ha/id_vm_impact"
log="/var/log/cloudstack-ha.log"
flag="/cloudstack_ha/have-node-issue"
date=
# $cmk list hosts type=ConsoleProxy zoneid=$zoneid | jq -r '.host[] | [.id] | @tsv' | sort -k4
# $cmk list hosts type=SecondaryStorageVM zoneid=$zoneid | jq -r '.host[] | [.id] | @tsv' | sort -k4

# cmd1="hostname -f"
# cmd2="date"
# result="$($cmd1)
# $($cmd2)"
# Dùng trong trường hợp thêm nhiều điều kiện check host down

host_down=$(/usr/bin/cmk list hosts state=Disconnected hypervisor=KVM | jq -r 'if .host then .host[] | [.id] | @tsv else empty end' | sort -k4)

if grep -q "true" $flag; then  
    if [[ -z "$host_down" ]]; then
        rm $vm_impact $node_down
        echo "false" > $flag
        echo "$(date) HA recover to health " >> $log
        exit 1
    # else
    #     "Check thêm node mới down và id_instance mới ảnh hưởng"
    fi
else
    if [[ -z "$host_down" ]]; then
        echo "false" > $flag
        exit 1
    else
        echo $host_down > $list_node_down
        while IFS= read -r node_id; do
            $cmk list virtualmachines hostid=$node_id| jq -r '.virtualmachine[] | [.id] | @tsv' | sort -k4 > $vm_impact
        done < "$node_down"
        while IFS= read -r vm_id; do
            $cmk "stop-commamd" $vm_id
            $cmk "start-commamd" $vm_id
        done < "$vm_impact"
        echo "true" > $flag
    fi
fi





