# Linux Live ISO or USB image using Dracut livenet for stateless PXE 

A recipe for non-destructive booting and hardware discovery


# How it is intended to work

A man with a USB stick walks into a data center...

*   Plug the stick into one node and boot it via USB
*   The node loads the live image (non-destructive)
*   In isolation the node becomes a PXE server
*   Power on the other nodes and boot them via PXE
*   These peer nodes load the live image find the master
*   Peers do inventory of hardware and copy data back to master
*   Peers will power down after collection is done - iff IPMI available
*   Power down the master and remove the USB stick with the data


# How it is built

## build script invoking make

The script to invoke

    ./make-recipe-target

without argument produces this help:

    Usage: make-recipe-target <recipe> <target>
    
    Where:
    
     <recipe> is the descriptions/<dirname> for the kiwi description to build
              possibilites include: suse-leap-15.1
 	     
     <target> is one of the Makefile targets for that recipe
     	      use 'all' to get help from the makefile for the given recipe
	     
The script invokes make ('target' and 'http' being the most useful)

    ./make-recipe-target suse-leap-15.1

Passing a recipe without a make target produces this help:
    
    Possible targets are:
        'target' for a dracut live ISO that can also be used with USB storage
        'http' place target ISO, kernel and initrd in server http dir on host
        'clean' to remove build artifaacts from related dirs
    
    Make these AFTER 'target' as they embed the dracut live ISO
        'virtual' for a raw disk image.
        'disk' for an image to boot and install to a menu selected target disk
    

## dracut livenet

The ISO Live PXE makes use of the (Fedora LiveOS)[https://fedoraproject.org/wiki/LiveOS_image] image format and (dracut tooling)[https://github.com/dracutdevs/dracut/].

The kernel args in play w/iPXE vars for BOOTIF MAC and pxe server:

    initrd=initrd-15.x.1 root=live:http://bang/install/recon/recon.x86_64-15.x.1.iso rd.live.ram=1 rd.live.image rd.live.overlay.persistent rd.live.overlay.cowfs=ext4 extra iomem=relaxed ksdevice=bootif BOOTIF=01-${mac:hexhyp} pxeaddr=${next-server} postaction=liveboot nomodeset noquiet splash=off console=tty0 console=ttyS1,115200n8 console=ttyS0,115200n8 earlyprintk=serial,ttyS0,115200
    
## KIWI

(SUSE)[https://www.suse.com/] sponsors an opensource project for image building called (KIWI)[https://osinside.github.io/kiwi/]. This tool is used to create the ISO Hybrid image and then embed that same image in an image.

The recipe uses the [KIWI ISO Hybrid Live Image](https://osinside.github.io/kiwi/building/build_live_iso.html) with the (image description)[https://github.com/OSInside/kiwi-descriptions] based on suse-leap-15.4, with `profile=LiveDracut` and with this latest profile it includes the needed bootstrap packages.

The rest of the RPMs needed for recon are added to the same config.xml. The remaining logic and configuration and services go into the overlay 'root' area of the build with any permissions or service starting in kiwi config.sh.

### type

    <preferences profiles="DracutLive">
        <type image="iso" primary="true" flags="dmsquash" hybrid="true" firmware="efi" hybridpersistent_filesystem="ext4" hybridpersistent="true" mediacheck="false"/>
    </preferences>

### bootstrap

These used to be included in 15.1 with older kiwi to get it working. These days it's reduced to module-init-tools and syslinux.

    <packages profiles="DracutLive" type="bootstrap">
        ...
        <package name="module-init-tools"/>
        <package name="dracut-kiwi-live"/>
        <package name="dracut-kiwi-lib"/>
        <package name="dracut-kiwi-oem-dump"/>
        <package name="dracut-kiwi-oem-repart"/>
        <package name="syslinux"/>
    </packages>

### suseInsertService

The master server and peer inventory collector service is injected into the 'root' overlay of the image and configured to start on boot with a new suseInsertService in the config.sh file.

## root overlay

### Apache config

When master, serve up /export /isos /install /nodes and iPXE menu.ipxe and post.tgz peer inventory workload.

### dnsmasq in root/recon

When master, serve up DNS and TFTP.

### dhcpd and dhcpd6 services

When master, serve up DHCP and DHCP6 for addressing and PXE booting.

### root and recon users

When master, files from this area are placed for server configuration

### /opt/sesame

Where aux files for the `banghook` service rests, along with a few aux helper bins

