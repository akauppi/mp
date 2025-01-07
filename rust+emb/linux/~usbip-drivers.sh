#!/bin/bash
set -e

#---
# !!!NOTE!!!
#
# You _must_ update 'linux-modules-extra-$(uname -r) _manually_ when kernel changes, by re-running the below commands.
#
# Another approach wwould be to:
#   <<
#     $ sudo apt install --reinstall linux-image-generic
#   <<
#   ..but that causes "[...] 523 MB of additional disk space will be used." We don't want that (since those packages
#   are not actually needed).
#
# For more info: https://ubuntuforums.org/showthread.php?t=2470820
#---

# References:
#   - "How to install usbip vhci_hcd drivers on an AWS EC2 Ubuntu Kernel Version" (Ask Ubuntu; Dec 2020)
#     -> https://askubuntu.com/questions/1303403/how-to-install-usbip-vhci-hcd-drivers-on-an-aws-ec2-ubuntu-kernel-version
#
sudo DEBIAN_FRONTEND=noninteractive \
  apt install -y linux-tools-generic linux-modules-extra-$(uname -r)
  #
  # linux-tools-generic:  'usbip' command line tool
  # ...-extra-...:        'vhci-hcd' and 'usbip' drivers, for the particular kernel

sudo modprobe vhci-hcd

# Automatically enable those drivers, in case of VM restart.
sudo -- sh -c "\
  echo 'vhci_hcd\nusbip_core' >> /etc/modules-load.d/modules.conf \
"
