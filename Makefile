SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=2023.3

export PROXMOX_URL?=https://192.168.1.21:8006/api2/json
export PROXMOX_USERNAME?=root@pam
export PROXMOX_PASSWORD?=vagrant
export PROXMOX_NODE?=pve

help:
	@echo type make build-libvirt, or make build-proxmox

build-libvirt: kali-${VERSION}-amd64-libvirt.box
build-proxmox: kali-${VERSION}-amd64-proxmox.box

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

.PHONY: help buid-libvirt build-proxmox
