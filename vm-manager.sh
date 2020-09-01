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

# define networking

nic='-nic bridge,model=e1000,mac=52:54:00:e8:59:0f'

# define display

# PCIe passthrough
#NVIDIA 1060 GPU and audio card
graphics='-vga none'
graphics=$graphics' -device vfio-pci,host=01:00.0,x-vga=on,multifunction=on'
graphics=$graphics' -device vfio-pci,host=01:00.1'

# USB card

usb='-device vfio-pci,host=07:00.0'

# define clock

# localtime because windows
clock='-rtc base=localtime'

# pid

pid='-pidfile /tmp/win10vm.pid'

#IOMMU

iommu_args='-device intel-iommu'
#iommu_vendor='Intel'

# misc options

name='-name win10'
uuid='-uuid b2bbf4eb-4359-47cf-8477-05c481ee92fc'


# final commandline

#E adds echo in front of command
CMDLINE=$E' sudo '$qemu_cmd
CMDLINE=$CMDLINE' -daemonize -runas kvm -nodefaults '$name
CMDLINE=$CMDLINE' '$iommu_args' '$cpu_args
CMDLINE=$CMDLINE' '$memory' '$bios' '$drive
CMDLINE=$CMDLINE' '$nic' '$graphics' '$usb
CMDLINE=$CMDLINE' '$clock' '$pid' '$uuid
}




