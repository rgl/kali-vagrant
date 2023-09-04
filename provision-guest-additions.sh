#!/bin/bash
set -eux

# install the Guest Additions.
if [ -n "$(lspci | grep 'Red Hat' | head -1)" ]; then
# install the qemu-kvm Guest Additions.
apt-get install -y qemu-guest-agent spice-vdagent
# configure the system to automatically resize the xfce desktop.
install -m 755 /dev/null /usr/local/bin/x-resize
cat >/usr/local/bin/x-resize <<'EOF'
#!/bin/bash
# Troubleshot:
# - Make sure auto-resize is enabled in your virt-viewer/spicy client
# - Make sure spice-vdagentd running without errors
# - Reload udev rules with: sudo udevadm control --reload-rules
# - Watch udev events on resize with: udevadm monitor
# - Watch x-resize logs with: tail -f /var/log/x-resize.log
# Credits:
# - Finding Sessions as Root: https://unix.stackexchange.com/questions/117083/how-to-get-the-list-of-all-active-x-sessions-and-owners-of-them
# - Resizing via udev: https://superuser.com/questions/1183834/no-auto-resize-with-spice-and-virt-manager
LOG_FILE=/var/log/x-resize.log
## Function to find User Sessions & Resize their display
function x_resize() {
    declare -A usrs disps
    local usrs=()
    local disps=()
    for u in $(users); do
        [[ "$u" = root ]] && continue # skip root
        usrs["$u"]='1'
    done
    for u in "${!usrs[@]}"; do
        for i in $(sudo ps e -u "$u" | sed -rn 's/.* DISPLAY=(:[0-9]*).*/\1/p' | sort -u); do
            disps["$i"]="$u"
        done
    done
    for d in "${!disps[@]}";do
        local session_user="${disps[$d]}"
        local session_display="$d"
        local session_output="$(sudo -u "$session_user" PATH=/usr/bin DISPLAY="$session_display" xrandr | awk '/ connected /{print $1;exit}')"
        echo "Session User: $session_user" | tee -a $LOG_FILE
        echo "Session Display: $session_display" | tee -a $LOG_FILE
        echo "Session Output: $session_output" | tee -a $LOG_FILE
        sudo -u "$session_user" PATH=/usr/bin DISPLAY="$session_display" xrandr --output "$session_output" --auto | tee -a $LOG_FILE
    done
}
echo "Resize Event: $(date)" | tee -a $LOG_FILE
x_resize
EOF
cat >/etc/udev/rules.d/50-x-resize.rules <<'EOF'
ACTION=="change", KERNEL=="card0", SUBSYSTEM=="drm", RUN+="/usr/local/bin/x-resize"
EOF
cat >/etc/logrotate.d/x-resize <<'EOF'
/var/log/x-resize.log {
    daily
    rotate 2
    missingok
    notifempty
    compress
    nocreate
}
EOF
elif [ -n "$(lspci | grep VMware | head -1)" ]; then
# install the VMware Guest Additions.
apt-get install -y open-vm-tools
elif [ "$(cat /sys/devices/virtual/dmi/id/sys_vendor)" == 'Microsoft Corporation' ]; then
# no need to install the Hyper-V Guest Additions (aka Linux Integration Services)
# as they were already installed from tmp/preseed-hyperv.txt.
exit 0
else
echo 'ERROR: Unknown VM host.' || exit 1
fi

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
