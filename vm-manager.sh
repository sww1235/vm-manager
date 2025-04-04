#!/bin/sh

# DEPENDANCIES: socat, qemu/kvm, bridge-utils

# need to create kvm user
# add KVM kernal module
# create bridge interface for NIC
# setup vfio-pci

# Inspired by and heavily borrowed from https://github.com/mzch/vmmaestro.
# This was designed to be very simple to manage, and not need libvirt
# all configuration takes place inside vm specific functions inside this file

#comment out to run commands for real
#E='echo'

sudo='sudo'

# if number of command line arguements is less than 2
if [ $# -lt 2 ]
then
	cmds='[start|stop|shutdown|restart|kill|monitor|status]'
	echo "Usage: $0 $cmds vm-name"
	exit 1
fi

# check for dependancies

depMissing=0
deps="socat qemu-system-x86_64"
for cmd in $deps
do
	printf '%-10s' "$cmd"
	if command -v "$cmd" 2>&1 /dev/null
	then
		echo present
	else
		echo missing
		: $((depMissing=depMissing+1))
	fi
done

if [ $depMissing -gt 0 ]
then
	exit 1
fi

boot_qemu_delay=10

win10_cfg() {

	# define vm architecture and qemu command

	# use x86_64 as that is the target arch of the VM

	qemu_cmd='qemu-system-x86_64 -enable-kvm'

	# define machine architecture

	machine='-machine q35,accel=kvm'

	# define CPU

	# where to put kvm=off from https://bbs.archlinux.org/viewtopic.php?id=224021
	# we want quotes to be literals
	# shellcheck disable=SC2089
	cpu_args='-cpu host,kvm=off,hv-vendor-id="testing234" -smp sockets=2,cores=2,threads=1'

	# define memory

	# 24GB of ram
	# leaving 8GB for host
	memory='-m 24G'

	# define bios

	# https://unix.stackexchange.com/questions/530674/qemu-doesnt-respect-the-boot-order-when-booting-with-uefi-ovmf

	# Don't actually have to use the -bios flag
	bios_file='/usr/share/ovmf/OVMF_CODE-pure-efi.fd'
	bios_nvram='/var/lib/qemu/nvram/win10_VARS.fd'
	bios='-drive if=pflash,format=raw,readonly=on,file='$bios_file
	bios=$bios' -drive if=pflash,format=raw,file='$bios_nvram


	# define ahci bus

	ahci='-device ahci,id=achi0'
	
	# define CD ROM for booting ISOs (temporary)

	# https://unix.stackexchange.com/a/603352/81810 

	iso_file='/home/toxicsauce/Downloads/Win10_2004_English_x64.iso'
	#cdrom='-drive format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on,file='$iso_file
	#cdrom=$cdrom' -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=0'

	#define disk drives

	disk_file='/var/lib/qemu/images/win10.qcow2'

	#disk_file='/mnt/pool0/tmp/win10.qcow2'
	drive='-drive if=none,id=drive-hd1,format=qcow2,file='$disk_file
	drive=$drive' -device ide-hd,bus=achi0.1,drive=drive-hd1,id=hd1,bootindex=1'
	
	# define networking

	#nic='-nic bridge,br=vmbridge,model=e1000,mac=52:54:00:e8:59:0f'
	nic='-device vfio-pci,host=05:00.0,bus=pcie.0'

	# define display

	# PCIe passthrough

	# set up pcie root heirarchy - Q35 only

	# slot/chassis pair is mandatory for each PCIe root port
	# https://github.com/qemu/qemu/blob/053a4177817db307ec854356e95b5b350800a216/docs/pcie.txt#L114
	pcie='-device pcie-root-port,id=root.1,chassis=0,slot=0,bus=pcie.0'
	#NVIDIA 1060 GPU and audio card
	graphics='-vga none -display none -nographic'
	# bug with IOMMU groups and multifunction devices. Need to use PCIe-PCI bridge to
	# mask requester ID
	#https://www.mail-archive.com/qemu-devel@nongnu.org/msg607680.html
	graphics=$graphics' -device vfio-pci,host=01:00.0,bus=pcie.0,x-vga=on'


	# USB card
	# need softdep xhci_hcd pre: vfio_pci in modprobe.d config + make sure to regenerate initramfs.
	# this prevents xhci_hcd binding to the pcie card before vfio_pci
	usb='-device vfio-pci,host=07:00.0,bus=pcie.0'

	# define clock

	# localtime because windows
	clock='-rtc base=localtime'

	# pid

	pidFile='/tmp/win10.pid'
	pid='-pidfile '$pidFile

	#IOMMU

	iommu_args='-device intel-iommu,caching-mode=on'
	#iommu_vendor='Intel'

	# define monitor

	socketFile='/tmp/win10.sock'
	monitor='-monitor unix:'$socketFile',server,nowait'

	# misc options

	name='-name win10'
	uuid='-uuid b2bbf4eb-4359-47cf-8477-05c481ee92fc'


	# final commandline

	#E adds echo in front of command
	CMDLINE=$E' '$sudo' '$qemu_cmd
	CMDLINE=$CMDLINE' -daemonize -runas kvm -nodefaults '$name
	CMDLINE=$CMDLINE' '$iommu_args' '$cpu_args' '$machine' '$ahci
	CMDLINE=$CMDLINE' '$memory' '$bios' '$drive' '$monitor
	CMDLINE=$CMDLINE' '$nic' '$pcie' '$graphics' '$usb' '$cdrom
	CMDLINE=$CMDLINE' '$clock' '$pid' '$uuid
}

void_cfg() {

	# define vm architecture and qemu command

	# use x86_64 as that is the target arch of the VM

	qemu_cmd='qemu-system-x86_64 -enable-kvm'

	# define machine architecture

	#TODO: switch to q35 once this is working

	# alias of pc-i440fx-5.1
	machine='-machine q35,accel=kvm'

	# define CPU

	# where to put kvm=off from https://bbs.archlinux.org/viewtopic.php?id=224021
	# we want quotes to be literals
	# shellcheck disable=SC2089
	cpu_args='-cpu host,kvm=off,hv-vendor-id="testing234" -smp sockets=2,cores=2,threads=1'

	# define memory

	# 24GB of ram
	# leaving 8GB for host
	memory='-m 24G'

	# define bios

	# https://unix.stackexchange.com/questions/530674/qemu-doesnt-respect-the-boot-order-when-booting-with-uefi-ovmf

	# Don't actually have to use the -bios flag
	bios_file='/usr/share/ovmf/OVMF_CODE-pure-efi.fd'
	bios_nvram='/var/lib/qemu/nvram/void_VARS.fd'
	bios='-drive if=pflash,format=raw,readonly=on,file='$bios_file
	bios=$bios' -drive if=pflash,format=raw,file='$bios_nvram


	# define ahci bus

	ahci='-device ahci,id=achi0'

	# define CD ROM for booting ISOs (temporary)

	# https://unix.stackexchange.com/a/603352/81810

	iso_file='/home/toxicsauce/void-live-x86_64-20191109.iso'
	#cdrom='-drive format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on,file='$iso_file
	#cdrom=$cdrom' -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=0'

	#define disk drives

	disk_file='/var/lib/qemu/images/void.qcow2'

	drive='-drive if=none,id=drive-hd1,format=qcow2,file='$disk_file
	drive=$drive' -device ide-hd,bus=achi0.1,drive=drive-hd1,id=hd1,bootindex=1'

	# define networking

	#nic='-nic bridge,br=vmbridge,model=e1000,mac=52:54:00:e8:59:0f'
	nic='-device vfio-pci,host=05:00.0,bus=pcie.0'

	# define display

	# PCIe passthrough

	# set up pcie root heirarchy - Q35 only

	# slot/chassis pair is mandatory for each PCIe root port
	# https://github.com/qemu/qemu/blob/053a4177817db307ec854356e95b5b350800a216/docs/pcie.txt#L114
	pcie='-device pcie-root-port,id=root.1,chassis=0,slot=0,bus=pcie.0'
	#NVIDIA 1060 GPU and audio card
	graphics='-vga none -display none -nographic'
	graphics=$graphics' -device vfio-pci,host=01:00.0,bus=root.1,x-vga=on'

	# USB card

	usb='-device vfio-pci,host=07:00.0,bus=pcie.0'

	# define clock

	# localtime because windows
	clock='-rtc base=localtime'

	# pid

	pidFile='/tmp/void.pid'
	pid='-pidfile '$pidFile

	#IOMMU

	iommu_args='-device intel-iommu,caching-mode=on'
	#iommu_vendor='Intel'

	# define monitor

	socketFile='/tmp/void.sock'
	monitor='-monitor unix:'$socketFile',server,nowait'

	# misc options

	name='-name void'
	uuid='-uuid b2bbf4eb-4359-47cf-8477-05c481ee92fc'


	# final commandline

	#E adds echo in front of command
	CMDLINE=$E' '$sudo' '$qemu_cmd
	CMDLINE=$CMDLINE' -daemonize -runas kvm -nodefaults '$name
	CMDLINE=$CMDLINE' '$iommu_args' '$cpu_args' '$machine' '$ahci
	CMDLINE=$CMDLINE' '$memory' '$bios' '$drive' '$monitor
	CMDLINE=$CMDLINE' '$nic' '$pcie' '$graphics' '$usb' '$cdrom
	CMDLINE=$CMDLINE' '$clock' '$pid' '$uuid
}
proc_check(){

	if [ ! -f $pidFile ]
	then
		return 1
	fi
	# from man kill: if signal is 0, then no actual signal is sent,
	# but error checking is still performed
	$sudo kill -0 "$(sudo cat $pidFile)" > /dev/null 2>&1
	# $? = return value of last command
	return $?
}

# Generic stop function. Relies on VM name being in $2
# this attempts to shutdown VM gracefully
stopVM(){

	echo "Shutting down $2"
	echo system_powerdown | $sudo socat - unix-connect:/tmp/"$2".sock
	delay=0
	proc_check
	while [ ! $? ] && [ $delay -lt $boot_qemu_delay ];
	do
		# discard output of arith expression with `:` command
		: $((delay=delay+1))
		sleep 1
		proc_check
	done

	if [ $boot_qemu_delay = "$delay" ]
	then
		echo "Failed to shutdown $2"
		exit 1
	fi
}

# Generic halt function. Relies on VM name being in $2
# this this kils vm
haltVM(){

	echo "Halting $2"
	echo stop | $sudo socat - unix-connect:/tmp/"$2".sock
	delay=0
	proc_check
	while [ ! $? ] && [ $delay -lt $boot_qemu_delay ];
	do
		# discard output of arith expression with `:` command
		: $((delay=delay+1))
		sleep 1
		proc_check
	done

	if [ $boot_qemu_delay = "$delay" ]
	then
		echo "Failed to stop $2"
		exit 1
	fi
}

# connect to monitor socket of kvm VM
connectMonitor(){

	clear
	echo "For reasons unknown, ^O is the panic button."
	$sudo socat -,raw,echo=0,escape=0x0f unix-connect:/tmp/"$2".sock

}
# show vm status
statusVM(){

	if proc_check 
	then
		printf "%s is stopped" "$2"
		return 1
	else
		printf "%s is running" "$2"
		return 0
	fi
}

# $0 command vm_name

# check vm first
case $2 in 
	win10)
		case $1 in
			start)
				# build and then run commandline
				win10_cfg
				# we want quotes to be literals
				# shellcheck disable=SC2090
				$CMDLINE
				;;
			stop)
				# need to pass $@ to function in order to use script positional arguments inside function
				stopVM "$@" 
				;;
			restart)
				stopVM "$@"
				win10_cfg
				# we want quotes to be literals
				# shellcheck disable=SC2090
				$CMDLINE
				;;
			shutdown)
				stopVM "$@"
				;;
			kill)
				haltVM "$@"
				;;
			status)
				statusVM "$@"
				;;
			monitor)
				connectMonitor "$@"
				;;
			*)
				echo "Unknown command: $1 $2" >&2
				echo "$cmds"
				;;
		esac
		;;
	void)
		case $1 in
			start)
				# build and then run commandline
				void_cfg
				# we want quotes to be literals
				# shellcheck disable=SC2090
				$CMDLINE
				;;
			stop)
				# need to pass $@ to function in order to use script positional arguments inside function
				stopVM "$@" 
				;;
			restart)
				stopVM "$@"
				void_cfg
				# we want quotes to be literals
				# shellcheck disable=SC2090
				$CMDLINE
				;;
			shutdown)
				stopVM "$@"
				;;
			kill)
				haltVM "$@"
				;;
			status)
				statusVM "$@"
				;;
			monitor)
				connectMonitor "$@"
				;;
			*)
				echo "Unknown command: $1 $2" >&2
				echo "$cmds"
				;;
		esac
		;;
	*)
		echo "Unknown command: $1 $2" >&2
		;;
esac


