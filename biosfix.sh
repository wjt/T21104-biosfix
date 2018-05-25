#!/bin/bash
set -e

biosfix_boot=/boot/biosfix/
biosfix_bls=/boot/loader/entries/ostree-eos-biosfix.conf
current_bls=/boot/loader/entries/ostree-eos-0.conf

ENDLESS_IMAGE_DEVICE=/dev/mapper/endless-image-device

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <biosfix-data-file | cleanup>"
	exit 1 
fi

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 
	exit 1
fi

umount $ENDLESS_IMAGE_DEVICE || true
mount_c=$(mktemp -d)
mount $ENDLESS_IMAGE_DEVICE "$mount_c"

mount -o remount,rw /usr

if [[ $1 == "cleanup" ]]; then
	echo "==> cleaning up <=="
	rm -fr ${biosfix_boot}
	rm -fr /usr/lib/modules/*biosfix*
	rm -f ${biosfix_bls}
	grub-editenv "$mount_c/endless/grub/grubenv" set timeout=0
	umount "$mount_c"
	echo "==> done <=="
	exit 0
fi

cleanup() {      
	umount "$mount_c"
	rm -rf "${tmpdir}"
}
trap cleanup EXIT

echo "==> Installing biosfix <=="
biosfix_data=$1

tmpdir=$(mktemp -d)
tar -zxf "$biosfix_data" -C "$tmpdir"

biosfix_data_dir=${tmpdir}/biosfix_data/

kver=$(cat "$biosfix_data_dir/kernel.release")
linux_image="vmlinuz-$kver"
linux_initrd="initramfs-$kver"

cp -Rpd "$biosfix_data_dir"/modules/lib/modules/* /usr/lib/modules/

## kernel
mkdir -p /boot/biosfix
cp -Rpd "$biosfix_data_dir"/boot/* ${biosfix_boot}

## initramfs
dracut -N --force "$biosfix_boot/$linux_initrd" "$kver"

## BLS entry
cp ${current_bls} ${biosfix_bls}

sed -i '/initrd/d' ${biosfix_bls}
echo "initrd /biosfix/${linux_initrd}" >> ${biosfix_bls}

sed -i '/linux/d' ${biosfix_bls}
echo "linux /biosfix/${linux_image}" >> ${biosfix_bls}

sed -i '/title/d' ${biosfix_bls}
echo "title [BIOSFIX]" >> ${biosfix_bls}

sed -i '/options/s/$/ intel-spi.bios_fix=1/' ${biosfix_bls}

## GRUB
grub-editenv "$mount_c/endless/grub/grubenv" set timeout=-1

echo "==> done <=="
echo "Please, reboot the system and when the menu is presented select \"Advanced ...\" and then \"[BIOSFIX]\""
