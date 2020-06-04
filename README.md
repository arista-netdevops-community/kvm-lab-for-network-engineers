# KVM Lab for Network Engineers (How-To Cheatsheet)

<!-- TOC -->

- [KVM Lab for Network Engineers (How-To Cheatsheet)](#kvm-lab-for-network-engineers-how-to-cheatsheet)
  - [Document Description](#document-description)
  - [Lab Materials](#lab-materials)
  - [Building The Lab](#building-the-lab)
    - [Step 1: Build New Kernel](#step-1-build-new-kernel)
    - [Step 2: Boot New Kernel](#step-2-boot-new-kernel)
    - [Step 3: Prepare KVM Host](#step-3-prepare-kvm-host)
    - [Step 4: Prepare Images For The Lab](#step-4-prepare-images-for-the-lab)
    - [Step 5: Change Default Network Settings](#step-5-change-default-network-settings)
    - [Step 6: Deploy The Lab](#step-6-deploy-the-lab)
    - [Step 7: Lab Verification](#step-7-lab-verification)
  - [OPENVSWITCH FOR KVM Lab](#openvswitch-for-kvm-lab)

<!-- /TOC -->

## Document Description

This document explains how to build a KVM lab with Arista vEOS. But it can be used to run any other VM.

**WARNING**: This document is a draft and a lot can be optimized. Current version was published based on requests from the field.

## Lab Materials

- Intel NUC6i3, 32GB RAM, 1TB HDD
- Ubuntu 19.10 Server

You can use any other server or Linux distribution. That may slighly change the process documented below.

## Building The Lab

### Step 1: Build New Kernel

Unfortunately KVM can not be used to build a network lab with the default Linux kernel. The main problem is that Linux kernel drops protocols like LLDP and LACP. Fortunately it's easy to compile a new kernel to remove this limitation. Similar to what EVE-NG maintainers did.

> NOTE: If you want learn more about the limitations and GROUP_FWD_MASK, read [this post](https://interestingtraffic.nl/2017/11/21/an-oddly-specific-post-about-group_fwd_mask/). It's very helpful and informative. You can also find these two mail threads interesting:
>
> - [remove BR_GROUPFWD_RESTRICTED for arbitrary forwarding of reserved addresses](https://lists.linuxfoundation.org/pipermail/bridge/2015-January/009456.html)
> - [same, from 2018](https://lists.openwall.net/netdev/2018/10/01/128)

To compile the kernel you have to get source files first. Best options to do that (Ubuntu) are apt-get and Git. Git is superior and using `git clone` instead of `apt-get` is strongly encouraged.

How to get source code with Git:

```bash
git clone git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/eoan
cd ./eoan/
head Makefile -n 5
cat debian.master/changelog | head -n 10
```

How to get source code with apt-get:

```bash
sudo nano /etc/apt/sources.list  # uncomment deb-src
sudo apt-get update
sudo -i
apt-get source linux-image-unsigned-$(uname -r)
tar xvzf ./linux_5.3.0.orig.tar.gz linux-5.3
# install requirements
sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison
```

Change to source code directory using `cd linux-5.3/` (or any other directory with the source code) and edit following files:

- net/bridge/br_input.c
- net/bridge/br_netlink.c
- net/bridge/br_private.h
- net/bridge/br_sysfs_br.c
- net/bridge/br_sysfs_if.c

If for any reason you want to control what bridges are allowed to forward LACP and LLDP, use following diff to make required changes:

```diff
diff --git a/net/bridge/br_input.c b/net/bridge/br_input.c
index 09b1dd8cd853..4d64797271fa 100644
--- a/net/bridge/br_input.c
+++ b/net/bridge/br_input.c
@@ -307,7 +307,18 @@ rx_handler_result_t br_handle_frame(struct sk_buff **pskb)
                        return RX_HANDLER_PASS;


                case 0x01:      /* IEEE MAC (Pause) */
-                       goto drop;
+                       fwd_mask |= p->br->group_fwd_mask;
+                       if (fwd_mask & (1u << dest[5]))
+                goto forward;
+                       else
+                               goto drop;
+
+               case 0x02:      /* Link Aggregation */
+                       fwd_mask |= p->br->group_fwd_mask;
+                       if (fwd_mask & (1u << dest[5]))
+                goto forward;
+                       else
+                               goto drop;


                case 0x0E:      /* 802.1AB LLDP */
                        fwd_mask |= p->br->group_fwd_mask;
diff --git a/net/bridge/br_netlink.c b/net/bridge/br_netlink.c
index a0a54482aabc..0bf028418805 100644
--- a/net/bridge/br_netlink.c
+++ b/net/bridge/br_netlink.c
@@ -815,8 +815,6 @@ static int br_setport(struct net_bridge_port *p, struct nlattr *tb[])
        if (tb[IFLA_BRPORT_GROUP_FWD_MASK]) {
                u16 fwd_mask = nla_get_u16(tb[IFLA_BRPORT_GROUP_FWD_MASK]);


-               if (fwd_mask & BR_GROUPFWD_MACPAUSE)
-                       return -EINVAL;
                p->group_fwd_mask = fwd_mask;
        }


@@ -1134,8 +1132,6 @@ static int br_changelink(struct net_device *brdev, struct nlattr *tb[],
        if (data[IFLA_BR_GROUP_FWD_MASK]) {
                u16 fwd_mask = nla_get_u16(data[IFLA_BR_GROUP_FWD_MASK]);


-               if (fwd_mask & BR_GROUPFWD_RESTRICTED)
-                       return -EINVAL;
                br->group_fwd_mask = fwd_mask;
        }


diff --git a/net/bridge/br_private.h b/net/bridge/br_private.h
index 646504db0220..60b4d4d9c72b 100644
--- a/net/bridge/br_private.h
+++ b/net/bridge/br_private.h
@@ -33,15 +33,11 @@


/* Control of forwarding link local multicast */
#define BR_GROUPFWD_DEFAULT    0
-/* Don't allow forwarding of control protocols like STP, MAC PAUSE and LACP */
enum {
        BR_GROUPFWD_STP         = BIT(0),
-       BR_GROUPFWD_MACPAUSE    = BIT(1),
-       BR_GROUPFWD_LACP        = BIT(2),
};


-#define BR_GROUPFWD_RESTRICTED (BR_GROUPFWD_STP | BR_GROUPFWD_MACPAUSE | \
-                               BR_GROUPFWD_LACP)
+#define BR_GROUPFWD_RESTRICTED (BR_GROUPFWD_STP)
/* The Nearest Customer Bridge Group Address, 01-80-C2-00-00-[00,0B,0C,0D,0F] */
#define BR_GROUPFWD_8021AD     0xB801u


diff --git a/net/bridge/br_sysfs_br.c b/net/bridge/br_sysfs_br.c
index 9ab0f00b1081..be9b260a6b08 100644
--- a/net/bridge/br_sysfs_br.c
+++ b/net/bridge/br_sysfs_br.c
@@ -149,9 +149,6 @@ static ssize_t group_fwd_mask_show(struct device *d,


static int set_group_fwd_mask(struct net_bridge *br, unsigned long val)
{
-       if (val & BR_GROUPFWD_RESTRICTED)
-               return -EINVAL;
-
        br->group_fwd_mask = val;


        return 0;
diff --git a/net/bridge/br_sysfs_if.c b/net/bridge/br_sysfs_if.c
index 7a59cdddd3ce..9001f8e646d3 100644
--- a/net/bridge/br_sysfs_if.c
+++ b/net/bridge/br_sysfs_if.c
@@ -178,8 +178,6 @@ static ssize_t show_group_fwd_mask(struct net_bridge_port *p, char *buf)
static int store_group_fwd_mask(struct net_bridge_port *p,
                                unsigned long v)
{
-       if (v & BR_GROUPFWD_MACPAUSE)
-               return -EINVAL;
        p->group_fwd_mask = v;


        return 0;
```

Typically it is not required as all bridges in a typical lab have to be transparent and to avoid configuring `group_fwd_mask` for every bridge we can just allow forwarding unconditionally. That will only require `br_input.c` to be changed:

```diff
diff --git a/net/bridge/br_input.c b/net/bridge/br_input.c
index 09b1dd8cd..47514e78b 100644
--- a/net/bridge/br_input.c
+++ b/net/bridge/br_input.c
@@ -307,21 +307,20 @@ rx_handler_result_t br_handle_frame(struct sk_buff **pskb)
                        return RX_HANDLER_PASS;

                case 0x01:      /* IEEE MAC (Pause) */
-                       goto drop;
+                       goto forward;
+
+               case 0x02:      /* Link Aggregation */
+                       goto forward;

                case 0x0E:      /* 802.1AB LLDP */
-                       fwd_mask |= p->br->group_fwd_mask;
-                       if (fwd_mask & (1u << dest[5]))
-                               goto forward;
+                       goto forward;
                        *pskb = skb;
                        __br_handle_local_finish(skb);
                        return RX_HANDLER_PASS;

                default:
                        /* Allow selective forwarding for most other protocols */
-                       fwd_mask |= p->br->group_fwd_mask;
-                       if (fwd_mask & (1u << dest[5]))
-                               goto forward;
+                       goto forward;
                }

                /* The else clause should be hit when nf_hook():
```

> NOTE: You can just copy provided br_input.c if you linux kernel version is 5.3.

Copy current kernel config and change if required:

```shell
cp /boot/config-$(uname -r) .config
make menuconfig
make
sudo make INSTALL_MOD_STRIP=1 modules_install
sudo make install
```

`INSTALL_MOD_STRIP=1` is critical to reduce kernel size.

### Step 2: Boot New Kernel

You can select the new kernel manually on boot, but a better option is to update grub:

- Find kernel enry in `cat /boot/grub/grub.cfg`
- Change `GRUB_DEFAULT` in `/etc/default/grub` to corresponding name/number.

For example, `GRUB_DEFAULT` can be updated to the following string:

```ini
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 5.3.0"
```

Example:

```console
petr@nuc6i3:~$ sudo nano /etc/default/grub
petr@nuc6i3:~$ sudo update-grub
Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.3.0-45-generic
Found initrd image: /boot/initrd.img-5.3.0-45-generic
Found linux image: /boot/vmlinuz-5.3.0
Found initrd image: /boot/initrd.img-5.3.0
done
```

Reboot.
Use `uname -r` to compare kernel version before and after reboot.

### Step 3: Prepare KVM Host

Install your SSH key on KVM host with `ssh-copy-id`.

Install qemu, virt and other dependencies:

```console
petr@nuc6i3:~$ modprobe kvm
petr@nuc6i3:~$ modprobe kvm_intel
petr@nuc6i3:~$ lsmod | grep kvm_intel
kvm_intel             274432  0
kvm                   643072  1 kvm_intel
petr@nuc6i3:~$ sudo apt install qemu-kvm
petr@nuc6i3:~$ sudo apt install  virt-viewer
petr@nuc6i3:~$ sudo apt install virt-manager
petr@nuc6i3:~$ sudo apt install bridge-utils
petr@nuc6i3:~$ sudo systemctl enable libvirtd
petr@nuc6i3:~$ sudo systemctl start libvirtd
petr@nuc6i3:~$ systemctl status libvirtd
● libvirtd.service - Virtualization daemon
   Loaded: loaded (/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2020-04-04 11:44:24 UTC; 29s ago
     Docs: man:libvirtd(8)
           https://libvirt.org
 Main PID: 10257 (libvirtd)
    Tasks: 19 (limit: 32768)
   Memory: 21.5M
   CGroup: /system.slice/libvirtd.service
           ├─10257 /usr/sbin/libvirtd
           ├─10398 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/lib/libvirt/libvirt_leaseshelper
           └─10399 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/lib/libvirt/libvirt_leaseshelper

Apr 04 11:44:24 nuc6i3 dnsmasq[10398]: compile time options: IPv6 GNU-getopt DBus i18n IDN DHCP DHCPv6 no-Lua TFTP conntrack ipset auth DNSSEC loop-detect inotify dumpfile
Apr 04 11:44:24 nuc6i3 dnsmasq-dhcp[10398]: DHCP, IP range 192.168.122.2 -- 192.168.122.254, lease time 1h
Apr 04 11:44:24 nuc6i3 dnsmasq-dhcp[10398]: DHCP, sockets bound exclusively to interface virbr0
Apr 04 11:44:24 nuc6i3 dnsmasq[10398]: reading /etc/resolv.conf
Apr 04 11:44:24 nuc6i3 dnsmasq[10398]: using nameserver 127.0.0.53#53
Apr 04 11:44:24 nuc6i3 dnsmasq[10398]: read /etc/hosts - 7 addresses
Apr 04 11:44:24 nuc6i3 dnsmasq[10398]: read /var/lib/libvirt/dnsmasq/default.addnhosts - 0 addresses
Apr 04 11:44:24 nuc6i3 dnsmasq-dhcp[10398]: read /var/lib/libvirt/dnsmasq/default.hostsfile
Apr 04 11:44:24 nuc6i3 dnsmasq[10398]: reading /etc/resolv.conf
Apr 04 11:44:24 nuc6i3 dnsmasq[10398]: using nameserver 127.0.0.53#53
```

Validate KVM host:

```console
petr@nuc6i3:~$ sudo virt-host-validate
  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : PASS
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for device assignment IOMMU support                         : PASS
  QEMU: Checking if IOMMU is enabled by kernel                               : WARN (IOMMU appears to be disabled in kernel. Add intel_iommu=on to kernel cmdline arguments)
   LXC: Checking for Linux >= 2.6.26                                         : PASS
   LXC: Checking for namespace ipc                                           : PASS
   LXC: Checking for namespace mnt                                           : PASS
   LXC: Checking for namespace pid                                           : PASS
   LXC: Checking for namespace uts                                           : PASS
   LXC: Checking for namespace net                                           : PASS
   LXC: Checking for namespace user                                          : PASS
   LXC: Checking for cgroup 'cpu' controller support                         : PASS
   LXC: Checking for cgroup 'cpuacct' controller support                     : PASS
   LXC: Checking for cgroup 'cpuset' controller support                      : PASS
   LXC: Checking for cgroup 'memory' controller support                      : PASS
   LXC: Checking for cgroup 'devices' controller support                     : PASS
   LXC: Checking for cgroup 'freezer' controller support                     : PASS
   LXC: Checking for cgroup 'blkio' controller support                       : PASS
   LXC: Checking if device /sys/fs/fuse/connections exists                   : PASS

petr@nuc6i3:~$ virsh nodeinfo
CPU model:           x86_64
CPU(s):              4
CPU frequency:       1670 MHz
CPU socket(s):       1
Core(s) per socket:  2
Thread(s) per core:  2
NUMA cell(s):        1
Memory size:         32775928 KiB

petr@nuc6i3:~$ virsh domcapabilities
petr@nuc6i3:~$ virsh domcapabilities | grep vcpu
  <vcpu max='255'/>
```

Confirm that [KSM](https://www.kernel.org/doc/html/latest/admin-guide/mm/ksm.html) is enabled:

```console
petr@nuc6i3:~$ cat /sys/kernel/mm/ksm/run
1
```

It is possible to add UKSM support in Linux kernel ([similar to EVE-NG](https://github.com/dolohow/uksm/issues/25)), but UKSM support seems to be far from optimal and some VMs (including vEOS) may experience problems. A quote from a related thread that explains it all:

> Too bad UKSM is not a more serious project...

The original thread is [available here](https://forum.proxmox.com/threads/can-you-please-add-uksm-into-kernel.32778/).

Still, if you want to experiment, start with: [https://github.com/dolohow/uksm](https://github.com/dolohow/uksm)
Looks like the project is still alive. There are 7 contributors, one active (as of May 2020). If you decide to use UKSM, do not forget to star and contribute. If you know someone from EVE-NG team, tell them to do the same.

Allow `sudo` without password. Not secure, but simple and generally fine for the lab. Run `visudo` and add following for your account and/or group:

```ini
# User privilege specification
root    ALL=(ALL:ALL) ALL
petr    ALL=(ALL) NOPASSWD: ALL

# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
```

> **WARNING**: Do that at your own risk! Especially if security is critical for you lab. For example, it has direct connection to the Internet.

### Step 4: Prepare Images For The Lab

Download and transfer the image with SFTP or alternative tool:

```console
petr@nuc6i3:~$ ls ./images/
vEOS-lab-4.22.4M.vmdk
```

Create qcow2 image:

```shell
sudo qemu-img convert -o compat=1.1 -c -p -O qcow2 ./images/vEOS-lab-4.22.4M.vmdk ~/images/vEOS-lab-4.22.4M.qcow2
```

### Step 5: Change Default Network Settings

Verify existing configuration first:

```console
petr@nuc6i3:~$ brctl show
bridge name bridge id       STP enabled interfaces
docker0     8000.0242e0df70c3   no
virbr0      8000.525400ef0612   yes     virbr0-nic

petr@nuc6i3:~$ virsh net-list
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes

petr@nuc6i3:~$ virsh net-dumpxml default
<network>
  <name>default</name>
  <uuid>8e104c12-8a93-4972-93d1-cc99bfeca0d4</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:ef:06:12'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

Change mode to `route` and disable DHCP, as it will be replaced with dhcpd later:

```console
petr@nuc6i3:~$ mkdir network-profiles
petr@nuc6i3:~$ virsh net-dumpxml default > ./network-profiles/default.xml
petr@nuc6i3:~$ virsh net-destroy default
Network default destroyed
petr@nuc6i3:~$ nano ./network-profiles/default.xml
petr@nuc6i3:~$ cat ./network-profiles/default.xml
<network>
  <name>default</name>
  <uuid>8e104c12-8a93-4972-93d1-cc99bfeca0d4</uuid>
  <forward mode='route'>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:ef:06:12'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
  </ip>
</network>

petr@nuc6i3:~$ virsh net-define ./network-profiles/default.xml
Network default defined from ./network-profiles/default.xml

petr@nuc6i3:~$ virsh net-start default
Network default started

petr@nuc6i3:~$ virsh net-list
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes
```

### Step 6: Deploy The Lab

Deploying a lab manually is slow, error-prone and boring. Fortunately libvirt has a [robust API](https://libvirt.org/) that provides full control over VMs on KVM host.

To automate the lab, we are going to use the simplest option. Yet, it's powerful enough to deploy and destroy the lab quickly.

1st, clone this repository.

2nd, create (or edit) a YAML file to describe the lab topology. Take a look at `lab-topology.yml` as an example. This file defines a simple leaf-spine network topology.

> NOTE: If required, it's easy to build a GUI / visualization around that. But in my opinion, controlling your lab topology via YAML is way more powerful.

Create Python virtual environment and install required dependencies:

```shell
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

Next, run `build-shell-scripts.py` to build shell scripts to create and destroy the lab:

```console
(.venv) pa@MacBook-Pro kvm-lab-for-network-engineers % ./build-shell-scripts.py --help
usage: build-shell-scripts.py [-h] [--create] [--delete] --username USERNAME
                              --hostname HOSTNAME
                              yaml_filename

=== Build Shell Scripts for KVM Lab Setup ===

positional arguments:
  yaml_filename         YAML file containing lab definition.

optional arguments:
  -h, --help            show this help message and exit
  --create              Create shell script for lab setup.
  --delete              Create shell script to delete the lab.
  --username USERNAME, -u USERNAME
                        Username to connect to KVM host.
  --hostname HOSTNAME, -n HOSTNAME
                        KVM host address or name.
(.venv) pa@MacBook-Pro kvm-lab-for-network-engineers % ./build-shell-scripts.py lab-topology.yml --create --username petr --hostname 192.168.178.178 > create-lab.sh
(.venv) pa@MacBook-Pro kvm-lab-for-network-engineers % ./build-shell-scripts.py lab-topology.yml --delete --username petr --hostname 192.168.178.178 > delete-lab.sh
(.venv) pa@MacBook-Pro kvm-lab-for-network-engineers % chmod +x ./create-lab.sh
(.venv) pa@MacBook-Pro kvm-lab-for-network-engineers % chmod +x ./delete-lab.sh
```

Now just run `create-lab.sh` or `delete-lab.sh` to create or delete you lab.

### Step 7: Lab Verification

List running VMs:

```console
root@nuc6i3:~# virsh list
 Id    Name           State
-------------------------------
 40    CVP-2019.1.4   running
 119   SPINE2         running
 120   LEAF1          running
 121   LEAF2          running
 122   LEAF3          running
 123   LEAF4          running
 124   SPINE1         running
```

Network list (a network is created for each p2p link in the lab):

```console
root@nuc6i3:~# virsh net-list
 Name          State    Autostart   Persistent
------------------------------------------------
 default       active   yes         yes
 net00000200   active   yes         yes
 net00000300   active   yes         yes
 net00000400   active   yes         yes
 net00000500   active   yes         yes
 net00100200   active   yes         yes
 net00100300   active   yes         yes
 net00100400   active   yes         yes
 net00100500   active   yes         yes
 net00200300   active   yes         yes
 net00200301   active   yes         yes
 net00200600   active   yes         yes
 net00300600   active   yes         yes
 net00400500   active   yes         yes
 net00400501   active   yes         yes
 net00400700   active   yes         yes
 net00500700   active   yes         yes
```

Connect to a VM console: `virsh console <number>`

Verify if Linux bridges allow LLDP using `show lldp neighbors`. Configure LACP between 2 switches and verify that port-channel is up.
Test jumbo MTU up to 9000 bytes.

Run `htop` to verify memory and CPU utilization:

```bash
sudo apt install htop
htop
```

Verify KSM memory optimization stats: `./ksm-check.sh`

## OPENVSWITCH FOR KVM Lab

### KVM OPENVSWITCH VEOSLAB

Open Virtual Switch (OVS) can be used together with KVM to switch VM and/or container traffic. Among other things it allows you to directly pass L2 protocol frames (i.e. LLDP, LACP, EAPOL, etc) between VM ports and/or container interfaces by using openflow rules as described below, so veoslab VM instances can see the other ones as directly connected by a network cable.

First, after a fresh OVS install (“apt install openvswitch-switch”, etc) create the ovs instance (ovs0 in the example):

```
# ovs-vsctl add-br ovs0
```

### Attaching VM interfaces to OVS

To attach KVM VM interfaces to the ovs0 instance the VM XML definition can be edited like in the example below. There are many ways to do that, one is virsh edit (VLAB3 is the VM name):

```
# virsh edit VLAB3
```

Now the interfaces can be defined similar to this:

```xml
  <interface type='bridge'>
      <mac address='52:54:00:9d:bd:75'/>
      <source bridge='ovs0'/>
      <vlan>
        <tag id='34'/>
      </vlan>
      <virtualport type='openvswitch'>
        <parameters interfaceid='bd9ddb67-a0af-4564-ab08-000ab909f164'/>
      </virtualport>
      <target dev='veos3_ma1'/>   *** How the HOST end of veth VM interface is named in the HOST
      <model type='e1000'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <mac address='52:54:00:ab:16:23'/>
      <source bridge='ovs0'/>
      <vlan>
        <tag id='13'/>
      </vlan>
      <virtualport type='openvswitch'>
        <parameters interfaceid='7af2af86-c8e3-43cd-a466-fe0919060624'/>
      </virtualport>
      <target dev='veos3_e1'/>
      <model type='e1000'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <mac address='52:54:00:e9:15:a4'/>
      <source bridge='ovs0'/>
      <vlan>
        <tag id='13'/>
      </vlan>
      <virtualport type='openvswitch'>
        <parameters interfaceid='92f70f11-cfd6-4c17-a5ac-9da97712c8ad'/>
      </virtualport>
      <target dev='veos3_e2'/>
      <model type='e1000'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
    </interface>
```

Now, once the VM has been started interfaces are seen in the hypervisor host as regular interfaces:

```
# virsh start VLAB3
# ip address show
...
8: veos3_ma1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master ovs-system state UNKNOWN group default qlen 1000
    link/ether fe:54:00:9d:bd:75 brd ff:ff:ff:ff:ff:ff
9: veos3_e1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master ovs-system state UNKNOWN group default qlen 1000
    link/ether fe:54:00:ab:16:23 brd ff:ff:ff:ff:ff:ff
10: veos3_e2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master ovs-system state UNKNOWN group default qlen 1000
    link/ether fe:54:00:e9:15:a4 brd ff:ff:ff:ff:ff:ff
11: veos3_e3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master ovs-system state UNKNOWN group default qlen 1000
    link/ether fe:54:00:8d:93:40 brd ff:ff:ff:ff:ff:ff
12: veos3_e4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master ovs-system state UNKNOWN group default qlen 1000
    link/ether fe:54:00:82:cc:6b brd ff:ff:ff:ff:ff:ff
13: veos3_e5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master ovs-system state UNKNOWN group default qlen 1000
    link/ether fe:54:00:ba:6d:ff brd ff:ff:ff:ff:ff:ff
...
```

And they are now added to the OVS0 instance (as per XML VM config) as access ports on the corresponding OVS vlans:

```
# ovs-vsctl show
b2e9be2e-0bb4-4690-8a33-075e2b31d6eb
    Bridge "ovs0"
        Port "veos3_ma1"
            tag: 34
            Interface "veos3_ma1"
        Port "veos3_e5"
            tag: 30
            Interface "veos3_e5"
        Port "veos3_e4"
            tag: 23
            Interface "veos3_e4"
        Port "veos3_e3"
            tag: 23
            Interface "veos3_e3"
        Port "veos3_e2"
            tag: 13
            Interface "veos3_e2"
        Port "veos3_e1"
            tag: 13
            Interface "veos3_e1"
        Port "ovs0"
            Interface "ovs0"
                type: internal
```

### Attaching Docker container interfaces to OVS

Docker container interfaces can be also attached to OVS. On the same host we run a docker container (image name has been called host:v2 and it is a local lab image based on alpine linux with some packages added on top like open-lldp, tcpdump, iperf and others), and like in the VM, the HOST end of the veth interface is attached to the OVS0 instance:

```
# docker run -it --hostname=host1 --name=host1 --cap-add=NET_ADMIN --net=none host:v2 /bin/sh
# ovs-docker add-port ovs0 eth0 host1 --ipaddress=10.10.34.2/24 --gateway=10.10.34.1
# ovs-vsctl show (to see what is the new interface name)
# ovs-vsctl set port 73b6c8e075ea4_l tag=23
```

Now the OVS0 instance has the container interface in OVS vlan 23 (like the veos3_e3 interface):

```
# ovs-vsctl show
b2e9be2e-0bb4-4690-8a33-075e2b31d6eb
    Bridge "ovs0"
        Port "73b6c8e075ea4_l"
            tag: 23
            Interface "73b6c8e075ea4_l"
        Port "veos3_ma1"
            tag: 34
            Interface "veos3_ma1"
        Port "veos3_e5"
            tag: 30
            Interface "veos3_e5"
        Port "veos3_e4"
            tag: 23
            Interface "veos3_e4"
        Port "veos3_e3"
            tag: 23
            Interface "veos3_e3"
        Port "veos3_e2"
            tag: 13
            Interface "veos3_e2"
        Port "veos3_e1"
            tag: 13
            Interface "veos3_e1"
        Port "ovs0"
            Interface "ovs0"
                type: internal
```

As expected, inside the container the other end of the 73b6c8e075ea4_l veth is seen as a regular eth0 interface.
Inside the host1 docker container (i.e. docker attach host1) LLDP can be enabled similar to this (grabbed from [Docker Topo](github.com/networkop/docker-topo)

```
lldpad -d
for i in `ls /sys/class/net/ | grep 'eth\|ens\|eno'`
do
    lldptool set-lldp -i $i adminStatus=rxtx
    lldptool -T -i $i -V sysName enableTx=yes
    lldptool -T -i $i -V portDesc enableTx=yes
    lldptool -T -i $i -V sysDesc enableTx=yes
done
```

### Adding OVS openflow rules

At this point, even if LLDP has been enabled in the host1 container *no* LLDP neighbors are seen in the veos_lab VM yet:

```
VLAB3(config)#show lldp neighbors
Last table change time   : never
Number of table inserts  : 0
Number of table deletes  : 0
Number of table drops    : 0
Number of table age-outs : 0

Port       Neighbor Device ID               Neighbor Port ID           TTL
VLAB3(config)#
```

Note that at this point *no* openflow rules are in place:

```
# /usr/bin/ovs-ofctl dump-flows ovs0
 cookie=0x0, duration=1005.107s, table=0, n_packets=1545, n_bytes=156079, priority=0 actions=NORMAL
```

Adding the following openflow rules sets up “direct forwarding”:
From veos3_e3 to 73b6c8e075ea4_l (container interface)
From 73b6c8e075ea4_l (container interface) to veos3_e3

```
# cat connect.sh
#!/usr/bin/bash
/usr/bin/ovs-ofctl add-flow ovs0 in_port=$1,actions=output:$2
/usr/bin/ovs-ofctl add-flow ovs0 in_port=$2,actions=output:$1

# ./connect.sh 73b6c8e075ea4_l veos3_e3
```

Now the openflow rules are in place:

```
# /usr/bin/ovs-ofctl dump-flows ovs0
 cookie=0x0, duration=24.209s, table=0, n_packets=4, n_bytes=604, in_port="73b6c8e075ea4_l" actions=output:"veos3_e3"
 cookie=0x0, duration=24.207s, table=0, n_packets=14, n_bytes=1640, in_port="veos3_e3" actions=output:"73b6c8e075ea4_l"
 cookie=0x0, duration=1387.076s, table=0, n_packets=1890, n_bytes=198461, priority=0 actions=NORMAL
```

And now host1 container is seen as an LLDP neighbor in e3 interface as expected:

```
VLAB3(config)#show lldp neighbors
Last table change time   : 0:00:30 ago
Number of table inserts  : 1
Number of table deletes  : 0
Number of table drops    : 0
Number of table age-outs : 0

Port       Neighbor Device ID               Neighbor Port ID           TTL
Et3        host1                            626f.4ccf.42c9             120
```

### A word on mac addresses

### Veoslab System Mac Address

When setting up lab topologies sometimes is handy to manually define the System Mac Address of your veoslab swicthes. To do so you can edit ```/mnt/flash/veos-config``` to define the SYSTEMMACADDR variable.

```
# cat /mnt/flash/veos-config
SYSTEMMACADDR=5054.0000.0101
```

After the change is done and the veoslab switch rebooted you can see the new System Mac Address.

```
vlab01#show version
 vEOS
Hardware version:
Serial number:
System MAC address:  5054.0000.0101

Software image version: 4.22.3M
Architecture:           i686
Internal build version: 4.22.3M-14418192.4223M
Internal build ID:      413991dd-4451-4406-a16c-f1c6ac19d1f3

Uptime:                 0 weeks, 0 days, 0 hours and 10 minutes
Total memory:           1498424 kB
Free memory:            696436 kB
```

### Mlag

By default libvirt assigns mac addresses to VM interfaces beggining with 52:54:xx:xx:xx:xx. These macs are defined in the VM XML definition file like in the previous example in "Attaching VM interfaces to OVS" section. If you are using mlag and see your mlag state always in "connecting" then try to assign mac addresses to your veoslab VM interfaces with the locally administered bit cleared out. That is the second least significant bit of the first mac address byte. For instance, assign mac addresses beggining with 5*0*:54:xx:xx:xx:xx instead.
