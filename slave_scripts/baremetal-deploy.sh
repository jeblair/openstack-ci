#!/bin/bash 

set -x
#HEAD_HOST=${HEAD_HOST:-10.14.247.43}
#COMPUTE_HOSTS=${COMPUTE_HOSTS:-10.14.247.44,10.14.247.45}

WORKSPACE=`pwd`
mkdir -p logs
rm -f logs/*
cd `dirname "$0"`

echo "Jenkins: resetting hosts..."
for host in $HEAD_HOST ${COMPUTE_HOSTS//,/ }; do
    scp -o lvm-kexec-reset.sh root@$host:/var/tmp/
    ssh -o root@$host /var/tmp/lvm-kexec-reset.sh
    sudo rm -f /var/log/orchestra/rsyslog/$host/syslog
done

# Have rsyslog reopen log files we rm'd from under it
sudo restart rsyslog

# wait for the host to come up (2 ping responses or timeout after 5 minutes)
echo "Jenkins: Waiting for head host to return after reset..."
if ! timeout 300 ./ping.py $HEAD_HOST; then
    echo "Jenkins: ERROR: Head node did not come back up after reset"
    exit 1
fi

echo "Jenkins: Pre-populating PIP cache"
for host in $HEAD_HOST ${COMPUTE_HOSTS//,/ }; do
    scp -r ~/cache/pip root@$host:/var/cache/pip
done

echo "Jenkins: Executing build_bm_multi.sh."

cd ~/devstack
source ./functions.sh
cache_images ~/devstack/files
bash build_bm_multi.sh

for host in $HEAD_HOST ${COMPUTE_HOSTS//,/ }; do
    cp /var/log/orchestra/rsyslog/$host/syslog $WORKSPACE/logs/$host-syslog.txt
done
