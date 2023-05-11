#/bin/bash

# zero interaction requested
export DEBIAN_FRONTEND=noninteractive
# do not bother about details, be critical
export DEBIAN_PRIORITY=critical

# in case we are ubuntu 22, do not ask about services to be restarted
if test -f "/etc/needrestart/needrestart.conf"
then
  export NEEDRESTART_MODE=a
fi

# edit here in case you want to be sure not to update Slurm packages
# (unhold to release)
for pkg in "slurmd slurm-wlm"
do
  apt-mark hold $pkg
done

# options for apt-get
# do not ask (-y)
# do not show fancy progress bar (-q)
APT_GET_OPTIONS="-qy"

# will use sudo here
# -E will preserve environment in case non-root is used
# make it clean before starting
sudo -E apt-get $APT_GET_OPTIONS clean

# update
sudo -E apt-get $APT_GET_OPTIONS update

# upgrade and try to avoid prompting the user
# https://manpages.debian.org/buster/dpkg/dpkg.1#OPTIONS
sudo -E apt-get $APT_GET_OPTIONS -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
# remove unused stuff after
sudo -E apt-get $APT_GET_OPTIONS autoclean

# EOF
