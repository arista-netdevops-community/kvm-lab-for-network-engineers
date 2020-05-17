#!/usr/bin/env python3

#
# Copyright (c) 2019, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#   Neither the name of Arista Networks nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ARISTA NETWORKS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

__author__ = 'Petr Ankudinov'

import yaml
import argparse
import os

def load_yaml_file(filename, load_all=False):
    """
    Load YAML data from the specified file.

    Args:
        filename        (str):      file to load the data
        ignore_error    (bool):     do not sys.exit on failure, but return False instead. Default - False
        debug           (bool):     print load time, default - False
        load_all        (bool):     load all YAML documents from YAML file (splitted by ---), default - False
    
    Returns:
        JSON data loaded from YAML or False   
    """
    file = open(filename, mode='r')
    if load_all:
        yaml_data = list(yaml.load_all(file, Loader=yaml.FullLoader))
    else:
        yaml_data = yaml.load(file, Loader=yaml.FullLoader)
    file.close()
    return yaml_data


def merge_data_objects(d1, d2, deduplicate_lists=True, merge_dict_in_lists=False):
    # a very simple function to merge 2 data objects into one recursively
    if isinstance(d1, dict) and isinstance(d2, dict):
        result = dict()
        all_keys = set(d1.keys()).union(d2.keys())
        for key in all_keys:
            if key not in d1.keys():
                result[key] = d2[key]
            elif key not in d2.keys():
                result[key] = d1[key]
            else:
                result[key] = merge_data_objects(d1[key], d2[key])
    elif isinstance(d1, list) and isinstance(d2, list):
        if deduplicate_lists:
            if merge_dict_in_lists:
                result = list()
                temp_dict = dict()
                for element in d1 + d2:
                    if isinstance(element, dict):
                        temp_dict = merge_data_objects(temp_dict, element)
                    else:
                        if element not in result:
                            result.append(element)
                result.append(temp_dict)
            else:
                result = list()
                for element in d1 + d2:
                    if element not in result:
                        result.append(element)
        else:
            result = d1 + d2
    else:  # 2nd object has higher priority if objects are different or not dict/list/str type
        result = d2

    return result

def get_next_mac_address(mac_address, increment=1):
    mac_address = [int(b, 16) for b in mac_address.split(':')]
    mac_address[-1] += increment
    new_mac_address = list()
    for b in mac_address:
        if len(hex(b)[2:]) > 1:
            new_mac_address.append(hex(b)[2:])
        else:
            new_mac_address.append('0'+hex(b)[2:])
    mac_address = ':'.join(new_mac_address)
    return mac_address

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='=== Build Shell Scripts for KVM Lab Setup ===', formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('yaml_filename', help='YAML file containing lab definition.')
    parser.add_argument('--create', help='Create shell script for lab setup.', action='store_true', default=False)
    parser.add_argument('--delete', help='Create shell script to delete the lab.', action='store_true', default=False)
    parser.add_argument('--username', '-u', help='Username to connect to KVM host.', required=True)
    parser.add_argument('--hostname', '-n', help='KVM host address or name.', required=True)
    args = parser.parse_args()

    lab = load_yaml_file(args.yaml_filename)

    # generate all network and bridge names and a dict of VM network parameters
    network_name_list = list()
    bridge_name_list = list()
    vm_network_map = dict()  # dict of VM network parameters
    for vm in lab['vm']:
        vm_network_map.update({
            vm['name']: {'connections': list()}
        })

        for connection_index, connection in enumerate(vm['connections']):
            # Get VM network profile. Create a new copy, to avoid updating original.
            network_profile = lab['profile'][vm['profile']]['network'].copy()

            if isinstance(connection, dict):

                if connection['network']['name'] == 'default':
                    pass  # nothing required as default network already exists (mangement connections)
                else:
                    pass  # TODO: support creating other shared networks

                # add network parameters without changing to profile
                network_profile = merge_data_objects(network_profile, connection['network'])
                # if VM base MAC address was defined, calculate VM interface MAC address
                if 'base_mac' in vm.keys():
                    network_profile.update({
                        'mac': get_next_mac_address(vm['base_mac'], increment=connection_index)
                    })

            else:  # expected to be p2p connection to another VM
                # find if there are multiple links connected to the same neighbor
                same_neighbor_link_indexes = [i for i, neighbor in enumerate(vm['connections']) if neighbor == connection]
                this_link_number = same_neighbor_link_indexes.index(connection_index)

                # as bridge names have limited length we'll define indexes for every VM
                local_vm_name_index = [i for i, v in enumerate(lab['vm']) if v['name'] == vm['name']][0]
                remote_vm_name_index = [i for i, v in enumerate(lab['vm']) if v['name'] == connection][0]
                vertex_list = [local_vm_name_index, remote_vm_name_index]  # local and remote node names
                vertex_list.sort()  # sort to have consistent order on both sides
                net_name = "net{:03}{:03}{:02}".format(vertex_list[0], vertex_list[1], this_link_number)
                bridge_name = "br{:03}{:03}{:02}".format(vertex_list[0], vertex_list[1], this_link_number)

                if net_name not in network_name_list:
                    network_name_list.append(net_name)
                    bridge_name_list.append(bridge_name)

                network_profile.update({'name': net_name})  # add network name to profile
                if 'base_mac' in vm.keys():
                    network_profile.update({
                        'mac': get_next_mac_address(vm['base_mac'], increment=connection_index)
                    })

            vm_network_map[vm['name']]['connections'].append({'network': network_profile})

    # build VM parameters
    vm_disks_to_be_created = list()
    vm_profile_dict = dict()
    for vm in lab['vm']:
        vm_profile = lab['profile'][vm['profile']]
        vm_profile = merge_data_objects(vm_profile, {'graphics': vm['graphics']})  # add graphics to the VM profile

        vm_profile_dict.update({
            vm['name']: vm_profile
        })
        vm_profile_dict[vm['name']].update({
            'connections': vm_network_map[vm['name']]['connections']
        })

        for disk in vm_profile['disk']:
            vm_profile_dict[vm['name']]['disk'] = list()  # clear disk entries for VM
            if 'image' in disk.keys():
                vm_disk_path = lab['disk']['path'] + vm['name'] + '-' + disk['image'].split('/')[-1]
                disk.update({'path': vm_disk_path})
                vm_profile_dict[vm['name']]['disk'].append(disk.copy())  # pass by value
                vm_disks_to_be_created.append({
                    'src_image': disk['image'],
                    'dst_path': disk['path']
                })
    pass
    create_vms_script = (
        f'#!/usr/bin/env bash\n'
        f'# The script will create lab VMs, networks and bridges\n'
        f'# connect to KVM host via SSH\n'
        f'echo "connecting to {args.hostname} via SSH"\n'
        f'ssh {args.username}@{args.hostname} << EOF\n'

        f'# creating network and bridges\n'
        f'echo "1) Creating netwok and bridges."\n'
        f'cd ~\n'  # change to user home directory
        f'mkdir net_definitions\n'  # create a directory to save XML network definitions
        f'cd ~/net_definitions\n'
    )

    delete_vms_script = (
        f'#!/usr/bin/env bash\n'
        f'# The script will DELETE lab VMs, networks and bridges\n'
        f'echo "connecting to {args.hostname} via SSH"\n'
        f'ssh {args.username}@{args.hostname} << EOF\n'
        f'cd ~\n'  # change to user home directory
        f'sudo rm -rf ./net_definitions\n'  # create a directory to save XML network definitions
    )

    for network_name, bridge_name in zip(network_name_list, bridge_name_list):
        create_vms_script += (
            f'# creating network {network_name} XML profile\n'
            f'touch {network_name}.xml\n'  # create XML file
            f'echo "<network>" > {network_name}.xml\n'
            f'echo "  <name>{network_name}</name>" >> {network_name}.xml\n'
            f'echo "  <bridge name=\'{bridge_name}\' stp=\'off\' delay=\'0\'/>" >> {network_name}.xml\n'
            f'echo "  <mtu size=\'9000\'/>" >> {network_name}.xml\n'
            f'echo "</network>" >> {network_name}.xml\n'
            f'# define and start the network {network_name}\n'
            f'sudo virsh net-define {network_name}.xml\n'
            f'sudo virsh net-autostart {network_name}\n'
            f'sudo virsh net-start {network_name}\n'
            f'# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)\n'
            f'# Linux kernel has to be patched to support group_fwd_mask = 65535\n'
            f'# as current kernel always forwards, keep this as comment\n'
            f'# sudo su -c "echo 65535 > /sys/class/net/{bridge_name}/bridge/group_fwd_mask"\n'
        )

    create_vms_script += "# creating VM disks\n"
    for disk_to_create in vm_disks_to_be_created:
        create_vms_script += f"sudo cp {disk_to_create['src_image']} {disk_to_create['dst_path']}\n"

    create_vms_script += "\n# Add VMs\n"
    create_vms_script += "echo 'Creating VMs...'\n"
    for vm_name, vm in vm_profile_dict.items():
        delete_vms_script +=(
            f"sudo virsh destroy {vm_name}\n"
            f"sudo virsh undefine {vm_name}\n"
        )

        create_vms_script += (
            
            f"echo 'Creating {vm_name}'\n"
            f"sudo virt-install --name {vm_name} --memory {vm['memory']} --vcpus {vm['vcpus']}"
            f" --cpu {vm['cpu']} --boot {vm['boot']} --events {vm['events']} --console {vm['console']}"
            f" --os-type {vm['os-type']} --os-variant {vm['os-variant']}"
            f" --graphics {vm['graphics']['type']},port={vm['graphics']['port']} --wait {vm['wait']}"
        )
        for disk in vm['disk']:
            create_vms_script += (
                f" --disk {disk['path']},device={disk['device']},format={disk['format']},bus={disk['bus']}"
            )
            delete_vms_script += f"sudo rm {disk['path']}\n"
        for connection in vm['connections']:
            net = connection['network']
            create_vms_script += f" --network=network:{net['name']},model={net['model']}"
            if 'mac' in net.keys():
                create_vms_script += f",mac={net['mac']}"
        create_vms_script += "\n"

    create_vms_script += (
        f'EOF\n'  # terminate SSH connection to KVM host
    )

    for network_name in network_name_list:
        delete_vms_script += (
                f"sudo virsh net-destroy {network_name}\n"
                f"sudo virsh net-undefine {network_name}\n"
            )

    if args.create:
        print(create_vms_script)
    elif args.delete:
        print(delete_vms_script)
