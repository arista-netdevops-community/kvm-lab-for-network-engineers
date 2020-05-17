#!/usr/bin/env bash
# The script will DELETE lab VMs, networks and bridges
echo "connecting to 192.168.178.178 via SSH"
ssh petr@192.168.178.178 << EOF
cd ~
sudo rm -rf ./net_definitions
sudo virsh destroy SPINE1
sudo virsh undefine SPINE1
sudo rm /var/lib/libvirt/images/SPINE1-vEOS-lab-4.22.4M.qcow2
sudo virsh destroy SPINE2
sudo virsh undefine SPINE2
sudo rm /var/lib/libvirt/images/SPINE2-vEOS-lab-4.22.4M.qcow2
sudo virsh destroy LEAF1
sudo virsh undefine LEAF1
sudo rm /var/lib/libvirt/images/LEAF1-vEOS-lab-4.22.4M.qcow2
sudo virsh destroy LEAF2
sudo virsh undefine LEAF2
sudo rm /var/lib/libvirt/images/LEAF2-vEOS-lab-4.22.4M.qcow2
sudo virsh destroy LEAF3
sudo virsh undefine LEAF3
sudo rm /var/lib/libvirt/images/LEAF3-vEOS-lab-4.22.4M.qcow2
sudo virsh destroy LEAF4
sudo virsh undefine LEAF4
sudo rm /var/lib/libvirt/images/LEAF4-vEOS-lab-4.22.4M.qcow2
sudo virsh destroy HOST1
sudo virsh undefine HOST1
sudo rm /var/lib/libvirt/images/HOST1-vEOS-lab-4.22.4M.qcow2
sudo virsh destroy HOST2
sudo virsh undefine HOST2
sudo rm /var/lib/libvirt/images/HOST2-vEOS-lab-4.22.4M.qcow2
sudo virsh net-destroy net00000200
sudo virsh net-undefine net00000200
sudo virsh net-destroy net00000300
sudo virsh net-undefine net00000300
sudo virsh net-destroy net00000400
sudo virsh net-undefine net00000400
sudo virsh net-destroy net00000500
sudo virsh net-undefine net00000500
sudo virsh net-destroy net00100200
sudo virsh net-undefine net00100200
sudo virsh net-destroy net00100300
sudo virsh net-undefine net00100300
sudo virsh net-destroy net00100400
sudo virsh net-undefine net00100400
sudo virsh net-destroy net00100500
sudo virsh net-undefine net00100500
sudo virsh net-destroy net00200300
sudo virsh net-undefine net00200300
sudo virsh net-destroy net00200301
sudo virsh net-undefine net00200301
sudo virsh net-destroy net00200600
sudo virsh net-undefine net00200600
sudo virsh net-destroy net00300600
sudo virsh net-undefine net00300600
sudo virsh net-destroy net00400500
sudo virsh net-undefine net00400500
sudo virsh net-destroy net00400501
sudo virsh net-undefine net00400501
sudo virsh net-destroy net00400700
sudo virsh net-undefine net00400700
sudo virsh net-destroy net00500700
sudo virsh net-undefine net00500700

