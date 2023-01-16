SHELL=/bin/bash

# project KIWI description is from github OSInside/kiwi-descriptions/suse/x86_64/suse-leap-15.1

# This Makefile supports building various images with augmentation of their root overlay
# and placement of the generated ISO in the root filesystem of the host for PXE booting

work=$(BASEDIR)/builds/$(RECIPE)
name=$(shell sed -n -re 's/.*<image schemaversion=[^ ]+ name="([^"]+)">/\1/p' config.xml)
version=$(shell sed -n -re 's/.*<version>([0-9.]+)<\/version>/\1/p' config.xml)

all:
	@echo ""
	@echo "Possible targets are:"
	@echo "    'target' for a dracut live ISO that can also be used with USB storage"
	@echo "    'http' place target ISO, kernel and initrd in server http dir on host"
	@echo "    'clean' to remove build artifaacts from related dirs"
	@echo ""
	@echo "Make these AFTER 'target' as they embed the dracut live ISO"
	@echo "    'virtual' for a raw disk image."
	@echo "    'disk' for an image to boot and install to a menu selected target disk"
	@echo ""

target=$(work)/$(name).x86_64-$(version).iso
livework=/export/$(name).live.out
live=$(livework)/$(name).x86_64-$(version).iso
virtwork=/export/$(name).virtual.out
virtual=$(virtwork)/$(name).x86_64-$(version).raw
diskwork=/export/$(name).disk.out
disk=$(diskwork)/$(name).x86_64-$(version).install.iso

thisdir=$(shell pwd)
opts=$(thisdir)/root/opt/recon
htdocs=$(thisdir)/root/srv/www/htdocs
tftpboot=$(thisdir)/root/srv/tftpboot
a2confd=$(thisdir)/root/etc/apache2/conf.d

# mechanics of live booting
#
mntpnt=/mnt
loader=boot/x86_64/loader
host=/export/install/$(name)
install=$(thisdir)/root/$(host)


# embed live image in image so live USB can be a live PXE server
#
target: $(target)
$(target): $(thisdir)/config.xml $(thisdir)/config.sh 
	sudo rm -f $(install)/*
	sudo rm -rf $(work)
	sudo kiwi-ng --profile=DracutLive system build --description=$(thisdir) --target-dir=$(work)

live: $(live)
$(live): $(thisdir)/config.xml $(thisdir)/config.sh
	sudo rm -rf $(livework)
	sudo kiwi-ng --profile=Live system build --description=$(thisdir) --target-dir=$(livework)

virtual: $(virtual)
$(virtual): $(thisdir)/config.xml $(thisdir)/config.sh
	sudo rm -rf $(virtwork)
	sudo kiwi-ng --profile=Virtual system build --description=$(thisdir) --target-dir=$(virtwork)

disk: $(disk)
$(disk): $(thisdir)/config.xml $(thisdir)/config.sh 
	sudo rm -rf $(diskwork)
	sudo kiwi-ng --profile=Disk system build --description=$(thisdir) --target-dir=$(diskwork)

# locally host files for PXE service
#
http: $(target)
	[ -d $(host) ] || sudo mkdir -p $(host)
	sudo cp $(target) $(host)/.
	sudo mount -oloop,ro $(target) $(mntpnt)
	sudo cp $(mntpnt)/$(loader)/initrd $(host)/initrd-$(version)
	sudo cp $(mntpnt)/$(loader)/linux $(host)/linux-$(version)
	sudo chmod 644 $(host)/linux-$(version) $(host)/initrd-$(version)
	sudo umount $(mntpnt)
	sed -i.name -re 's/^set livename .*$$/set livename $(name)/' /srv/www/htdocs/boot.ipxe
	sed -i.ver -re 's/^set livever .*$$/set livever $(version)/' /srv/www/htdocs/boot.ipxe

# copy image to node/location where test virtualization expects it
#
node: $(target)
	cp $(target) /export/isos/.

clean:
	sudo rm -rf $(work)
	sudo rm -f root/$(host)/*
