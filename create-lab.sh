#!/usr/bin/env bash
# The script will create lab VMs, networks and bridges
# connect to KVM host via SSH
echo "connecting to 192.168.178.178 via SSH"
ssh petr@192.168.178.178 << EOF
# creating network and bridges
echo "1) Creating netwok and bridges."
cd ~
mkdir net_definitions
cd ~/net_definitions
# creating network net00000200 XML profile
touch net00000200.xml
echo "<network>" > net00000200.xml
echo "  <name>net00000200</name>" >> net00000200.xml
echo "  <bridge name='br00000200' stp='off' delay='0'/>" >> net00000200.xml
echo "  <mtu size='9000'/>" >> net00000200.xml
echo "</network>" >> net00000200.xml
# define and start the network net00000200
sudo virsh net-define net00000200.xml
sudo virsh net-autostart net00000200
sudo virsh net-start net00000200
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00000200/bridge/group_fwd_mask"
# creating network net00000300 XML profile
touch net00000300.xml
echo "<network>" > net00000300.xml
echo "  <name>net00000300</name>" >> net00000300.xml
echo "  <bridge name='br00000300' stp='off' delay='0'/>" >> net00000300.xml
echo "  <mtu size='9000'/>" >> net00000300.xml
echo "</network>" >> net00000300.xml
# define and start the network net00000300
sudo virsh net-define net00000300.xml
sudo virsh net-autostart net00000300
sudo virsh net-start net00000300
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00000300/bridge/group_fwd_mask"
# creating network net00000400 XML profile
touch net00000400.xml
echo "<network>" > net00000400.xml
echo "  <name>net00000400</name>" >> net00000400.xml
echo "  <bridge name='br00000400' stp='off' delay='0'/>" >> net00000400.xml
echo "  <mtu size='9000'/>" >> net00000400.xml
echo "</network>" >> net00000400.xml
# define and start the network net00000400
sudo virsh net-define net00000400.xml
sudo virsh net-autostart net00000400
sudo virsh net-start net00000400
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00000400/bridge/group_fwd_mask"
# creating network net00000500 XML profile
touch net00000500.xml
echo "<network>" > net00000500.xml
echo "  <name>net00000500</name>" >> net00000500.xml
echo "  <bridge name='br00000500' stp='off' delay='0'/>" >> net00000500.xml
echo "  <mtu size='9000'/>" >> net00000500.xml
echo "</network>" >> net00000500.xml
# define and start the network net00000500
sudo virsh net-define net00000500.xml
sudo virsh net-autostart net00000500
sudo virsh net-start net00000500
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00000500/bridge/group_fwd_mask"
# creating network net00100200 XML profile
touch net00100200.xml
echo "<network>" > net00100200.xml
echo "  <name>net00100200</name>" >> net00100200.xml
echo "  <bridge name='br00100200' stp='off' delay='0'/>" >> net00100200.xml
echo "  <mtu size='9000'/>" >> net00100200.xml
echo "</network>" >> net00100200.xml
# define and start the network net00100200
sudo virsh net-define net00100200.xml
sudo virsh net-autostart net00100200
sudo virsh net-start net00100200
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00100200/bridge/group_fwd_mask"
# creating network net00100300 XML profile
touch net00100300.xml
echo "<network>" > net00100300.xml
echo "  <name>net00100300</name>" >> net00100300.xml
echo "  <bridge name='br00100300' stp='off' delay='0'/>" >> net00100300.xml
echo "  <mtu size='9000'/>" >> net00100300.xml
echo "</network>" >> net00100300.xml
# define and start the network net00100300
sudo virsh net-define net00100300.xml
sudo virsh net-autostart net00100300
sudo virsh net-start net00100300
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00100300/bridge/group_fwd_mask"
# creating network net00100400 XML profile
touch net00100400.xml
echo "<network>" > net00100400.xml
echo "  <name>net00100400</name>" >> net00100400.xml
echo "  <bridge name='br00100400' stp='off' delay='0'/>" >> net00100400.xml
echo "  <mtu size='9000'/>" >> net00100400.xml
echo "</network>" >> net00100400.xml
# define and start the network net00100400
sudo virsh net-define net00100400.xml
sudo virsh net-autostart net00100400
sudo virsh net-start net00100400
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00100400/bridge/group_fwd_mask"
# creating network net00100500 XML profile
touch net00100500.xml
echo "<network>" > net00100500.xml
echo "  <name>net00100500</name>" >> net00100500.xml
echo "  <bridge name='br00100500' stp='off' delay='0'/>" >> net00100500.xml
echo "  <mtu size='9000'/>" >> net00100500.xml
echo "</network>" >> net00100500.xml
# define and start the network net00100500
sudo virsh net-define net00100500.xml
sudo virsh net-autostart net00100500
sudo virsh net-start net00100500
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00100500/bridge/group_fwd_mask"
# creating network net00200300 XML profile
touch net00200300.xml
echo "<network>" > net00200300.xml
echo "  <name>net00200300</name>" >> net00200300.xml
echo "  <bridge name='br00200300' stp='off' delay='0'/>" >> net00200300.xml
echo "  <mtu size='9000'/>" >> net00200300.xml
echo "</network>" >> net00200300.xml
# define and start the network net00200300
sudo virsh net-define net00200300.xml
sudo virsh net-autostart net00200300
sudo virsh net-start net00200300
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00200300/bridge/group_fwd_mask"
# creating network net00200301 XML profile
touch net00200301.xml
echo "<network>" > net00200301.xml
echo "  <name>net00200301</name>" >> net00200301.xml
echo "  <bridge name='br00200301' stp='off' delay='0'/>" >> net00200301.xml
echo "  <mtu size='9000'/>" >> net00200301.xml
echo "</network>" >> net00200301.xml
# define and start the network net00200301
sudo virsh net-define net00200301.xml
sudo virsh net-autostart net00200301
sudo virsh net-start net00200301
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00200301/bridge/group_fwd_mask"
# creating network net00200600 XML profile
touch net00200600.xml
echo "<network>" > net00200600.xml
echo "  <name>net00200600</name>" >> net00200600.xml
echo "  <bridge name='br00200600' stp='off' delay='0'/>" >> net00200600.xml
echo "  <mtu size='9000'/>" >> net00200600.xml
echo "</network>" >> net00200600.xml
# define and start the network net00200600
sudo virsh net-define net00200600.xml
sudo virsh net-autostart net00200600
sudo virsh net-start net00200600
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00200600/bridge/group_fwd_mask"
# creating network net00300600 XML profile
touch net00300600.xml
echo "<network>" > net00300600.xml
echo "  <name>net00300600</name>" >> net00300600.xml
echo "  <bridge name='br00300600' stp='off' delay='0'/>" >> net00300600.xml
echo "  <mtu size='9000'/>" >> net00300600.xml
echo "</network>" >> net00300600.xml
# define and start the network net00300600
sudo virsh net-define net00300600.xml
sudo virsh net-autostart net00300600
sudo virsh net-start net00300600
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00300600/bridge/group_fwd_mask"
# creating network net00400500 XML profile
touch net00400500.xml
echo "<network>" > net00400500.xml
echo "  <name>net00400500</name>" >> net00400500.xml
echo "  <bridge name='br00400500' stp='off' delay='0'/>" >> net00400500.xml
echo "  <mtu size='9000'/>" >> net00400500.xml
echo "</network>" >> net00400500.xml
# define and start the network net00400500
sudo virsh net-define net00400500.xml
sudo virsh net-autostart net00400500
sudo virsh net-start net00400500
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00400500/bridge/group_fwd_mask"
# creating network net00400501 XML profile
touch net00400501.xml
echo "<network>" > net00400501.xml
echo "  <name>net00400501</name>" >> net00400501.xml
echo "  <bridge name='br00400501' stp='off' delay='0'/>" >> net00400501.xml
echo "  <mtu size='9000'/>" >> net00400501.xml
echo "</network>" >> net00400501.xml
# define and start the network net00400501
sudo virsh net-define net00400501.xml
sudo virsh net-autostart net00400501
sudo virsh net-start net00400501
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00400501/bridge/group_fwd_mask"
# creating network net00400700 XML profile
touch net00400700.xml
echo "<network>" > net00400700.xml
echo "  <name>net00400700</name>" >> net00400700.xml
echo "  <bridge name='br00400700' stp='off' delay='0'/>" >> net00400700.xml
echo "  <mtu size='9000'/>" >> net00400700.xml
echo "</network>" >> net00400700.xml
# define and start the network net00400700
sudo virsh net-define net00400700.xml
sudo virsh net-autostart net00400700
sudo virsh net-start net00400700
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00400700/bridge/group_fwd_mask"
# creating network net00500700 XML profile
touch net00500700.xml
echo "<network>" > net00500700.xml
echo "  <name>net00500700</name>" >> net00500700.xml
echo "  <bridge name='br00500700' stp='off' delay='0'/>" >> net00500700.xml
echo "  <mtu size='9000'/>" >> net00500700.xml
echo "</network>" >> net00500700.xml
# define and start the network net00500700
sudo virsh net-define net00500700.xml
sudo virsh net-autostart net00500700
sudo virsh net-start net00500700
# change group_fwd_mask to forward special MACs (LLDP, STP, LACP)
# Linux kernel has to be patched to support group_fwd_mask = 65535
# as current kernel always forwards, keep this as comment
# sudo su -c "echo 65535 > /sys/class/net/br00500700/bridge/group_fwd_mask"
# creating VM disks
sudo cp /home/petr/images/vEOS-lab-4.22.4M.qcow2 /var/lib/libvirt/images/SPINE1-vEOS-lab-4.22.4M.qcow2
sudo cp /home/petr/images/vEOS-lab-4.22.4M.qcow2 /var/lib/libvirt/images/SPINE2-vEOS-lab-4.22.4M.qcow2
sudo cp /home/petr/images/vEOS-lab-4.22.4M.qcow2 /var/lib/libvirt/images/LEAF1-vEOS-lab-4.22.4M.qcow2
sudo cp /home/petr/images/vEOS-lab-4.22.4M.qcow2 /var/lib/libvirt/images/LEAF2-vEOS-lab-4.22.4M.qcow2
sudo cp /home/petr/images/vEOS-lab-4.22.4M.qcow2 /var/lib/libvirt/images/LEAF3-vEOS-lab-4.22.4M.qcow2
sudo cp /home/petr/images/vEOS-lab-4.22.4M.qcow2 /var/lib/libvirt/images/LEAF4-vEOS-lab-4.22.4M.qcow2
sudo cp /home/petr/images/vEOS-lab-4.22.4M.qcow2 /var/lib/libvirt/images/HOST1-vEOS-lab-4.22.4M.qcow2
sudo cp /home/petr/images/vEOS-lab-4.22.4M.qcow2 /var/lib/libvirt/images/HOST2-vEOS-lab-4.22.4M.qcow2

# Add VMs
echo 'Creating VMs...'
echo 'Creating SPINE1'
sudo virt-install --name SPINE1 --memory 2048 --vcpus 1 --cpu host --boot hd --events on_poweroff=destroy,on_reboot=restart,on_crash=restart --console pty,target_type=serial --os-type linux --os-variant fedora18 --graphics vnc,port=5901 --wait 0 --disk /var/lib/libvirt/images/SPINE1-vEOS-lab-4.22.4M.qcow2,device=disk,format=qcow2,bus=ide --network=network:default,model=e1000,mac=00:0c:29:78:01:00 --network=network:net00000200,model=e1000,mac=00:0c:29:78:01:01 --network=network:net00000300,model=e1000,mac=00:0c:29:78:01:02 --network=network:net00000400,model=e1000,mac=00:0c:29:78:01:03 --network=network:net00000500,model=e1000,mac=00:0c:29:78:01:04
echo 'Creating SPINE2'
sudo virt-install --name SPINE2 --memory 2048 --vcpus 1 --cpu host --boot hd --events on_poweroff=destroy,on_reboot=restart,on_crash=restart --console pty,target_type=serial --os-type linux --os-variant fedora18 --graphics vnc,port=5902 --wait 0 --disk /var/lib/libvirt/images/SPINE2-vEOS-lab-4.22.4M.qcow2,device=disk,format=qcow2,bus=ide --network=network:default,model=e1000,mac=00:0c:29:78:02:00 --network=network:net00100200,model=e1000,mac=00:0c:29:78:02:01 --network=network:net00100300,model=e1000,mac=00:0c:29:78:02:02 --network=network:net00100400,model=e1000,mac=00:0c:29:78:02:03 --network=network:net00100500,model=e1000,mac=00:0c:29:78:02:04
echo 'Creating LEAF1'
sudo virt-install --name LEAF1 --memory 2048 --vcpus 1 --cpu host --boot hd --events on_poweroff=destroy,on_reboot=restart,on_crash=restart --console pty,target_type=serial --os-type linux --os-variant fedora18 --graphics vnc,port=5911 --wait 0 --disk /var/lib/libvirt/images/LEAF1-vEOS-lab-4.22.4M.qcow2,device=disk,format=qcow2,bus=ide --network=network:default,model=e1000,mac=00:0c:29:78:11:00 --network=network:net00000200,model=e1000,mac=00:0c:29:78:11:01 --network=network:net00100200,model=e1000,mac=00:0c:29:78:11:02 --network=network:net00200300,model=e1000,mac=00:0c:29:78:11:03 --network=network:net00200301,model=e1000,mac=00:0c:29:78:11:04 --network=network:net00200600,model=e1000,mac=00:0c:29:78:11:05
echo 'Creating LEAF2'
sudo virt-install --name LEAF2 --memory 2048 --vcpus 1 --cpu host --boot hd --events on_poweroff=destroy,on_reboot=restart,on_crash=restart --console pty,target_type=serial --os-type linux --os-variant fedora18 --graphics vnc,port=5912 --wait 0 --disk /var/lib/libvirt/images/LEAF2-vEOS-lab-4.22.4M.qcow2,device=disk,format=qcow2,bus=ide --network=network:default,model=e1000,mac=00:0c:29:78:12:00 --network=network:net00000300,model=e1000,mac=00:0c:29:78:12:01 --network=network:net00100300,model=e1000,mac=00:0c:29:78:12:02 --network=network:net00200300,model=e1000,mac=00:0c:29:78:12:03 --network=network:net00200301,model=e1000,mac=00:0c:29:78:12:04 --network=network:net00300600,model=e1000,mac=00:0c:29:78:12:05
echo 'Creating LEAF3'
sudo virt-install --name LEAF3 --memory 2048 --vcpus 1 --cpu host --boot hd --events on_poweroff=destroy,on_reboot=restart,on_crash=restart --console pty,target_type=serial --os-type linux --os-variant fedora18 --graphics vnc,port=5913 --wait 0 --disk /var/lib/libvirt/images/LEAF3-vEOS-lab-4.22.4M.qcow2,device=disk,format=qcow2,bus=ide --network=network:default,model=e1000,mac=00:0c:29:78:13:00 --network=network:net00000400,model=e1000,mac=00:0c:29:78:13:01 --network=network:net00100400,model=e1000,mac=00:0c:29:78:13:02 --network=network:net00400500,model=e1000,mac=00:0c:29:78:13:03 --network=network:net00400501,model=e1000,mac=00:0c:29:78:13:04 --network=network:net00400700,model=e1000,mac=00:0c:29:78:13:05
echo 'Creating LEAF4'
sudo virt-install --name LEAF4 --memory 2048 --vcpus 1 --cpu host --boot hd --events on_poweroff=destroy,on_reboot=restart,on_crash=restart --console pty,target_type=serial --os-type linux --os-variant fedora18 --graphics vnc,port=5914 --wait 0 --disk /var/lib/libvirt/images/LEAF4-vEOS-lab-4.22.4M.qcow2,device=disk,format=qcow2,bus=ide --network=network:default,model=e1000,mac=00:0c:29:78:14:00 --network=network:net00000500,model=e1000,mac=00:0c:29:78:14:01 --network=network:net00100500,model=e1000,mac=00:0c:29:78:14:02 --network=network:net00400500,model=e1000,mac=00:0c:29:78:14:03 --network=network:net00400501,model=e1000,mac=00:0c:29:78:14:04 --network=network:net00500700,model=e1000,mac=00:0c:29:78:14:05
echo 'Creating HOST1'
sudo virt-install --name HOST1 --memory 2048 --vcpus 1 --cpu host --boot hd --events on_poweroff=destroy,on_reboot=restart,on_crash=restart --console pty,target_type=serial --os-type linux --os-variant fedora18 --graphics vnc,port=5921 --wait 0 --disk /var/lib/libvirt/images/HOST1-vEOS-lab-4.22.4M.qcow2,device=disk,format=qcow2,bus=ide --network=network:default,model=e1000,mac=00:0c:29:78:21:00 --network=network:net00200600,model=e1000,mac=00:0c:29:78:21:01 --network=network:net00300600,model=e1000,mac=00:0c:29:78:21:02
echo 'Creating HOST2'
sudo virt-install --name HOST2 --memory 2048 --vcpus 1 --cpu host --boot hd --events on_poweroff=destroy,on_reboot=restart,on_crash=restart --console pty,target_type=serial --os-type linux --os-variant fedora18 --graphics vnc,port=5922 --wait 0 --disk /var/lib/libvirt/images/HOST2-vEOS-lab-4.22.4M.qcow2,device=disk,format=qcow2,bus=ide --network=network:default,model=e1000,mac=00:0c:29:78:22:00 --network=network:net00400700,model=e1000,mac=00:0c:29:78:22:01 --network=network:net00500700,model=e1000,mac=00:0c:29:78:22:02
EOF

