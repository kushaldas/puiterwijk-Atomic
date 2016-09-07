#!/usr/bin/bash -x
export LANG=en_US.UTF-8
CONFIGDIR="/srv/rpm-ostree/config"
set -x

# Needs to be fully updated since the release data won't work with rpm-ostree
dnf update -y

# Install required packages
dnf install -y git rpm-ostree rpm-ostree-toolbox polipo docker fuse fuse-libs python-pip gnupg patch

mkdir -p /mnt/{data,logs}
mkdir -p /mnt/data/polipo
mkdir -p /mnt/data/repo
rmdir /var/cache/polipo
ln -s /mnt/data/polipo /var/cache/polipo
if [ ! -f /mnt/data/repo/config ];
then
    echo "Seems the repo was not yet initialized"
    ostree init --repo=/mnt/data/repo/ --mode=archive-z2
fi

# Stupid, VERY, stupid rpm-ostree bug workaround
# https://github.com/projectatomic/rpm-ostree/issues/264
mkdir -p /mnt/data/repo/refs/remotes

# Start the caching daemon, inside docker can not start the service
polipo

# Prepare the actual composing
mkdir -p /srv/rpm-ostree/{config,cache}

# Setup logging
LOGROOT="/mnt/logs/`date +%Y-%m-%d-%H:%M`"
mkdir $LOGROOT

# Remap logging
exec >$LOGROOT/script.log 2>&1
set -x

# Prepare composing
(
    cd $CONFIGDIR
    git show-ref HEAD >>$LOGROOT/clone.log 2>&1
    ./treefile-expander.py kdas-trees.json.in >$LOGROOT/expander.log 2>&1
    cp kdas-trees.json $LOGROOT/generated.json
    # For some weird reason, I need these manual imports...
    rpm --import 81B46521.txt
)

# COMPOSE
(
    cd /srv/rpm-ostree
    mkdir -p /mnt/data/repo/{tmp,uncompressed-objects-cache,state}
    rpm-ostree compose tree --repo=/mnt/data/repo --cachedir=/srv/rpm-ostree/cache $CONFIGDIR/kdas-trees.json --proxy=http://localhost:8123/ --touch-if-changed=/srv/rpm-ostree/changed >$LOGROOT/compose.log 2>&1
)

