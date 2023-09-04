SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=2023.3

export PROXMOX_URL?=https://192.168.1.21:8006/api2/json
export PROXMOX_USERNAME?=root@pam
export PROXMOX_PASSWORD?=vagrant
export PROXMOX_NODE?=pve

help:
	@echo type make build-libvirt, make build-proxmox, or make build-vsphere

build-libvirt: kali-${VERSION}-amd64-libvirt.box
build-proxmox: kali-${VERSION}-amd64-proxmox.box
build-vsphere: kali-${VERSION}-amd64-vsphere.box

kali-${VERSION}-amd64-libvirt.box: preseed.txt provision.sh kali.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init kali.pkr.hcl
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.kali-amd64 -on-error=abort -timestamp-ui kali.pkr.hcl
	@./box-metadata.sh libvirt kali-${VERSION}-amd64 $@

kali-${VERSION}-amd64-proxmox.box: preseed.txt provision.sh kali.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init kali.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=proxmox-iso.kali-amd64 -on-error=abort -timestamp-ui kali.pkr.hcl

kali-${VERSION}-amd64-vsphere.box: tmp/preseed-vsphere.txt provision.sh kali-vsphere.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init kali-vsphere.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=vsphere-iso.kali-amd64 -timestamp-ui kali-vsphere.pkr.hcl
	echo '{"provider":"vsphere"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json
	@./box-metadata.sh vsphere kali-${VERSION}-amd64 $@

tmp/preseed-vsphere.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 open-vm-tools,g' preseed.txt >$@

.PHONY: help buid-libvirt build-proxmox build-vsphere
