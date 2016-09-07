#!/usr/bin/bash -x
export LANG=en_US.UTF-8
GITURL="https://github.com/kushaldas/puiterwijk-Atomic.git"
dnf install -y git
CONFIGDIR="/srv/rpm-ostree/config"
mkdir -p $CONFIGDIR
(
    git clone $GITURL $CONFIGDIR
)

# Make sure we always get the most recent build script
# (githubusercontent.com is cached)
source $CONFIGDIR/kdas-build.sh
