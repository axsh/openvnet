#!/bin/bash

# This must appear before sourcing bashsteps defaults so relative
# directories will work.
[ "$1" != "" ] && fullpath="$(readlink -f $1)"

source "$(dirname $(readlink -f "$0"))/simple-defaults-for-bashsteps.source"

if [[ "$DATADIR" != /* ]]; then
    # Choose current directory by default
    DATADIR="$(pwd)"
fi

touch "$DATADIR/datadir.conf" 2>/dev/null

source "$DATADIR/datadir.conf" 2>/dev/null
: ${imagesource:=$fullpath}

(
    $starting_step "Sanity checks before setting up VM dir"
    false # always do these
    $skip_step_if_already_done

    # ...what sanity checking would be good?
    [ -f "$DATADIR/kvm-boot.sh" ] && reportfailed "Apparently already set up in $DATADIR"
    [ -d "$DATADIR" ] || reportfailed "No directory found at DATADIR=$DATADIR"

    # Assumption just to get things going...
    [[ "$imagesource" == *.tar.gz ]] || reportfailed "Expecting .tar.gz file."
) ; prev_cmd_failed

(
    $starting_step "Copy initial VM image"
    # the next line conveniently fails if $IMAGEFILENAME is null, but points
    # to something awkward that needs some thought (TODO)
    [ -f "$DATADIR/$IMAGEFILENAME" ]
    $skip_step_if_already_done

    tar xzvf "$imagesource" -C "$DATADIR" >"$DATADIR"/tar.stdout || reportfailed "untaring of image"
    read IMAGEFILENAME rest <"$DATADIR"/tar.stdout
    [ "$rest" = "" ] || reportfailed "unexpected output from tar: $(<"$DATADIR"/tar.stdout)"
    echo 'IMAGEFILENAME="'$IMAGEFILENAME'"' >>"$DATADIR/datadir.conf"
set -x
    [ -f "${imagesource%.tar.gz}.sshuser" ] && cp "${imagesource%.tar.gz}.sshuser" "$DATADIR/sshuser"
    [ -f "${imagesource%.tar.gz}.sshkey" ] && {
	cp "${imagesource%.tar.gz}.sshkey" "$DATADIR/sshkey"
	chmod 600 "$DATADIR/sshkey" ; }
    exit 0
) ; prev_cmd_failed
source "$DATADIR/datadir.conf" 2>/dev/null

(
    $starting_step "Copy control scripts to VM directory"
    [ -f "$DATADIR/kvm-boot.sh" ]
    $skip_step_if_already_done
    ln -s "$ORGCODEDIR/vmdir-scripts"/* "$DATADIR"
)

(
    $starting_step "Put default KVM command line template in the VM directory"
    [ -f "$DATADIR/kvm-cmdline.template" ]
    $skip_step_if_already_done
    echo 'EXTRAHOSTFWD="'$EXTRAHOSTFWD'"' >>"$DATADIR/datadir.conf"
    cat >"$DATADIR/kvm-cmdline.template" <<'EOF'
      $KVMBIN
      -m $KVMMEM
      -smp 2
      -name kvmsteps
      -no-kvm-pit-reinjection
      
      -monitor telnet:127.0.0.1:$MONPORT,server,nowait
      -vnc 127.0.0.1:$VNCPORT
      -serial telnet:127.0.0.1:$SERPORT,server,nowait

      -drive file=$IMAGEFILENAME,id=vol-tu3y7qj4-drive,if=none,serial=vol-tu3y7qj4,cache=none,aio=native
      -device virtio-blk-pci,id=vol-tu3y7qj4,drive=vol-tu3y7qj4-drive,bootindex=0,bus=pci.0,addr=0x4
      
      -net nic,vlan=0,macaddr=52:54:00:65:28:dd,model=virtio,addr=10
      -net user,vlan=0,hostfwd=tcp::$SSHPORT-:22$EXTRAHOSTFWD
EOF
)
