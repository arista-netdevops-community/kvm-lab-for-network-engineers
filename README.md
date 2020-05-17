# KVM Lab for Network Engineers (How-To Cheatsheet)

<!-- TOC -->

- [KVM Lab for Network Engineers (How-To Cheatsheet)](#kvm-lab-for-network-engineers-how-to-cheatsheet)
  - [Document Description](#document-description)
  - [Lab Materials](#lab-materials)
  - [Building The Lab](#building-the-lab)
    - [Step 1: Build New Kernel](#step-1-build-new-kernel)
    - [Step 2: Boot New Kernel](#step-2-boot-new-kernel)

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

Unfortunately KVM can not be used to build a network lab by default. The main problem is that Linux kernel drops protocols like LLDP and LACP by default. Fortunately it's easy to compile a new kernel to remove this limitation. Similar to what EVE-NG maintainers have done.

> NOTE: If you want learn more about the limitations and GROUP_FWD_MASK, read [this post](https://interestingtraffic.nl/2017/11/21/an-oddly-specific-post-about-group_fwd_mask/). It's very helpful and informative. You can also find these two mail threads interesting:
>
> - [remove BR_GROUPFWD_RESTRICTED for arbitrary forwarding of reserved addresses](https://lists.linuxfoundation.org/pipermail/bridge/2015-January/009456.html)
> - [](https://lists.openwall.net/netdev/2018/10/01/128)

To compile the kernel you have to get source files first. Best options to do that (Ubuntu) are apt-get and Git. Git is superior and using `git clone` instead of `apt-get` is strongly encouraged.

How to get source code with Git:

```bash
# get kernel src code
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/linux/5.3.0-43.36/linux_5.3.0.orig.tar.gz
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/linux/5.3.0-43.36/linux_5.3.0-43.36.diff.gz
# install requirements
sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison
# extract archive
tar xvzf ./linux_5.3.0.orig.tar.gz linux-5.3
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

Change to source code directory using `cd linux-5.3/` and edit following files:

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

```bash
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
