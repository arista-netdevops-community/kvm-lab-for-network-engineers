# KVM Lab for Network Engineers (How-To Cheatsheet)

<!-- TOC -->

- [KVM Lab for Network Engineers (How-To Cheatsheet)](#kvm-lab-for-network-engineers-how-to-cheatsheet)
  - [Document Description](#document-description)
  - [Lab Materials](#lab-materials)
  - [Building The Lab](#building-the-lab)
    - [Step 1: Build New Kernel](#step-1-build-new-kernel)

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
- net/bridge/br_private.c
- net/bridge/br_sysfs_br.c
- bridge/br_sysfs_if.c
