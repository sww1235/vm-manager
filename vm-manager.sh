#!/bin/sh


# Inspired by and heavily borred from https://github.com/mzch/vmmaestro.
# This was designed to be very simple to manage, and not need libvirt
# all configuration takes place inside vm specific functions inside this file

#comment out to run commands for real
E=echo

# if number of command line arguements is less than 2
if [[ $# < 2 ]]; then
	  cmds='[start|consolestart|stop|shutdown|restart|kill|console|monitor|status]'
	    echo 'Usage: '$0' '$cmds' vm-name,...'
	      exit 1
fi


win10_cfg() {

# define vm architecture and qemu command

# use x86_64 as that is the target arch of the VM

qemu_cmd='qemu-system-x86_64 -enable-kvm -accel kvm'

# define machine architecture

# alias of pc-1440fx-5.1
machine='pc,accel=kvm'

# define CPU

# where to put kvm=off from https://bbs.archlinux.org/viewtopic.php?id=224021
cpu_args='-cpu host,kvm=off,vendor_id="testing234" -smp sockets=2,cores=2,threads=1'

# define memory

# 8GB of ram
memory='-m 8G'

# define bios

# https://unix.stackexchange.com/questions/530674/qemu-doesnt-respect-the-boot-order-when-booting-with-uefi-ovmf

# Don't actually have to use the -bios flag
bios_file='/usr/share/ovmf/OVMF_CODE-pure-efi.fd'
bios_nvram='/var/lib/libvirt/qemu/nvram/win10_VARS.fd'
bios='-drive if=pflash,format=raw,readonly=on,file='$bios_file
bios=$bios' -drive if=pflash,format=raw,file='$bios_nvram

# define disk drives

disk_file='/var/lib/libvirt/images/win10.qcow2'
drive='-drive if=virtio,format=qcow2,file='$disk_file

# define floppy

# define cdrom

# define bootorder

# define networking

# define display

# define keyboard

# define console

# define clock

# localtime because windows
clock='-localtime'

# define virtfs

# pid

pid='-pidfile /tmp/win10vm.pid'

# pcie/IOMMU

iommu_args='-device intel-iommu'
iommu_vendor='Intel'

# misc options

name='-name win10'
uuid='b2bbf4eb-4359-47cf-8477-05c481ee92fc'


# final commandline

#E adds echo in front of command
CMDLINE=$E' sudo '$qemu_cmd
}




