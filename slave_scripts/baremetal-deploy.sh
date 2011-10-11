#!/bin/bash
HEAD_HOST=${HEAD_HOST:-10.14.247.43}
COMPUTE_HOSTS=${COMPUTE_HOSTS:-10.14.247.44,10.14.247.45}

for host in $HEAD_HOST ${COMPUTE_HOSTS//,/ }; do
    scp lvm-kexec-reset.sh root@$host:/var/tmp/
    ssh root@$host /var/tmp/lvm-kexec-reset.sh
done

cd ~/devstack
exec bash build_bm_multi.sh
