#! /usr/bin/env bash
set -e

parted -s -a opt /dev/sda "print free" "resizepart 3 100%" "print free"
if [ $? -ne 0 ]; then
  echo "Error resize partition"
  exit 1
fi

resize2fs /dev/sda3
if [ $? -ne 0 ]; then
  echo "Error resize filesystem"
  exit 1
fi

echo "Resize partition and filesystem success"
