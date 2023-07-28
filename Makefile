SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=2023.2

help:
	@echo type make build-libvirt

build-libvirt: kali-${VERSION}-amd64-libvirt.box

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

.PHONY: help buid-libvirt
