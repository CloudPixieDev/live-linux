#!/bin/bash
#================
# FILE          : config.sh
#----------------
# PROJECT       : OpenSuSE KIWI Image System
# COPYRIGHT     : (c) 2006 SUSE LINUX Products GmbH. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : configuration script for SUSE based
#               : operating systems
#               :
#               :
# STATUS        : BETA
#----------------
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Activate services
#--------------------------------------
suseInsertService sshd
suseInsertService ipmi
suseInsertService lldpd
#suseInsertService salt-minion
suseInsertService banghook
if [[ ${kiwi_type} =~ oem|vmx ]];then
    suseInsertService grub_config
else
    suseRemoveService grub_config
fi

#======================================
# Setup default target, multi-user
#--------------------------------------
baseSetRunlevel 3

#======================================
# Fix ssh dir/file permissions
#--------------------------------------
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
chmod 644 /root/.ssh/config
chmod 644 /root/.ssh/id_*.pub
chown -R recon:users /home/recon
chmod 700 /home/recon/.ssh
chmod 600 /home/recon/.ssh/*
chmod 644 /home/recon/.ssh/config
chmod 644 /home/recon/.ssh/id_*.pub

#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
c_rehash

# clean up huge things that are not needed on a live iso

#==========================================
# remove package docs
#------------------------------------------
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/licenses/*

# unused locale -- removed them all somehow -- need for yast2 -- so comment out
#find /usr/share/locale -maxdepth 1 -type d ! -name en_US ! -name en -print0 | xargs -0 -r rm -rf

# unused firmware -- leave the wifi and more common addl nic firmware
#rm -f /lib/firmware/iwlwifi* /lib/firmware/i2400* /lib/firmware/i6050* /lib/firmware/vpu_* /lib/firmware/intel/dsp_fw* /lib/firmware/netronome /lib/firmware/liquidio /lib/firmware/qed /lib/firmware/amdgpu /lib/firmware/ti-connectivity
rm -f /lib/firmware/vpu_* /lib/firmware/intel/dsp_fw* /lib/firmware/netronome /lib/firmware/liquidio /lib/firmware/qed /lib/firmware/amdgpu /lib/firmware/ti-connectivity

# pyc files
find / -name '*.pyc' -delete

exit 0
