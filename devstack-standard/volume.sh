#!/bin/bash

volume_device=$(curl http://169.254.169.254/latest/meta-data/block-device-mapping/ebs0)
mkfs.ext4 -F $volume_device
mkdir -p /opt/stack/data/nova/instances
mount $volume_device /opt/stack/data/nova/instances
chown -R ubuntu: /opt/stack
