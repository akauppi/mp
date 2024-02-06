#!/bin/bash
set -e

sudo DEBIAN_FRONTEND=noninteractive \
  apt install -y linux-tools-generic linux-modules-extra-$(uname -r)
  #
  # linux-tools-generic:  'usbip' command line tool
  # ...-extra-...:        'vhci-hcd' and 'usbip' drivers, for the particular kernel

sudo modprobe vhci-hcd

# Automatically enable those drivers, in case of VM restart.
#
# tbd. Make idempotent - don't add if already there!
sudo -- sh -c " \
  (echo vhci_hcd >> /etc/modules-load.d/modules.conf) && \
  (echo usbip_core >> /etc/modules-load.d/modules.conf) \
"
