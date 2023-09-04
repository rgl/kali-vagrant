This builds an up-to-date Vagrant Kali Linux Base Box.

Currently this targets [Kali Linux 2023.3](https://www.kali.org).

[Kali Linux is based on Debian Testing](https://www.kali.org/docs/policy/kali-linux-relationship-with-debian/).


# Usage

Install Packer 1.9+ and Vagrant 2.3+.


## Ubuntu Host

On a Ubuntu host, install the dependencies by running the file at:

    https://github.com/rgl/xfce-desktop-vagrant/blob/master/provision-virtualization-tools.sh

And you should also install and configure the NFS server. E.g.:

```bash
# install the nfs server.
sudo apt-get install -y nfs-kernel-server

# enable password-less configuration of the nfs server exports.
sudo bash -c 'cat >/etc/sudoers.d/vagrant-synced-folders' <<'EOF'
Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/*
Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY
EOF
```

For more information see the [Vagrant NFS documentation](https://www.vagrantup.com/docs/synced-folders/nfs.html).


## qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
```

Type `make build-libvirt` and follow the instructions.

Try the example guest:

```bash
cd example
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt # see https://github.com/vagrant-libvirt/vagrant-libvirt
vagrant up --provider=libvirt --no-destroy-on-error
vagrant ssh
exit
vagrant destroy -f
```


## proxmox usage

Install [proxmox](https://www.proxmox.com/en/proxmox-ve).

**NB** This assumes proxmox was installed alike [rgl/proxmox-ve](https://github.com/rgl/proxmox-ve).

Set your proxmox details:

```bash
cat >secrets-proxmox.sh <<EOF
export PROXMOX_URL='https://192.168.1.21:8006/api2/json'
export PROXMOX_USERNAME='root@pam'
export PROXMOX_PASSWORD='vagrant'
export PROXMOX_NODE='pve'
EOF
source secrets-proxmox.sh
```

Create the template:

```bash
make build-proxmox
```

**NB** There is no way to use the created template with vagrant (the [vagrant-proxmox plugin](https://github.com/telcat/vagrant-proxmox) is no longer compatible with recent vagrant versions). Instead, use packer or terraform.


# Alternatives

* https://gitlab.com/kalilinux/build-scripts/kali-vagrant


# References

* [What is Kali Linux?](https://www.kali.org/docs/introduction/what-is-kali-linux/)
* [Should I Use Kali Linux?](https://www.kali.org/docs/introduction/should-i-use-kali-linux/)
* [Minimum Install Setup Information](https://www.kali.org/docs/troubleshooting/common-minimum-setup/).
* [Kali Linux Metapackages](https://www.kali.org/docs/general-use/metapackages/).
