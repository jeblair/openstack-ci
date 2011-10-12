#!/bin/bash 

set -x
#HEAD_HOST=${HEAD_HOST:-10.14.247.43}
#COMPUTE_HOSTS=${COMPUTE_HOSTS:-10.14.247.44,10.14.247.45}

cd `dirname "$0"`

for host in $HEAD_HOST ${COMPUTE_HOSTS//,/ }; do
    scp -o StrictHostKeyChecking=no lvm-kexec-reset.sh root@$host:/var/tmp/
    ssh -o StrictHostKeyChecking=no root@$host /var/tmp/lvm-kexec-reset.sh
done

# wait for the host to come up (2 ping responses or timeout after 90 seconds)
echo "Waiting for head host to return after reset..."
if ! timeout 300 ./ping.py $HEAD_HOST; then
    echo "ERROR: Head node did not come back up after reset"
    exit 1
fi

echo "Done.  Executing build_bm_multi.sh."

cd ~/devstack
source ./functions.sh
cache_images ~/devstack/files
exec bash build_bm_multi.sh
