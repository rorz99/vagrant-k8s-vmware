#!/bin/bash
#
# Setup for Node servers

source /vagrant/scripts/source-env.sh
AT "Start worker $HOSTNAME sedtup ..........."
set -euxo pipefail



sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
sudo cp -i -r /home/vagrant/.kube /root
hostname -s
EOF

/bin/bash /vagrant/configs/join.sh -v
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker

AT "Completed worker $HOSTNAME sedtup ..........."
