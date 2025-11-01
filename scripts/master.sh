#!/bin/bash
#
# Setup for Control Plane (Master) servers

source /vagrant/scripts/source-env.sh
AT "Start master sedtup ..........."
set -euxo pipefail

MASTER_IP="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
# MASTER_IP="$local_ip"
NODENAME=$(hostname -s)
POD_CIDR="10.244.0.0/16"

Mirror='registry.aliyuncs.com/google_containers'
Mirror='hub.kc2288.dynv6.net:4999/k8s'

echo '[[registry]]
prefix = "mirror.ccs.tencentyun.com"
insecure = true
blocked = false
location = "registry.cn-hangzhou.aliyuncs.com "
[[registry.mirror]]
location = "hub-mirror.c.163.com"
insecure = true
[[registry.mirror]]
location = "docker.mirrors.ustc.edu.cn"
insecure = true ' > /etc/containerd/registries.conf

! grep "^insecure = true" /etc/containerd/registries.conf && echo "insecure = true" |sudo tee -a /etc/containerd/registries.conf
# sudo kubeadm config images pull --image-repository=$Mirror
# sudo crictl pull $Mirror/pause:3.8 && sudo ctr -n k8s.io images tag $Mirror/pause:3.8 registry.k8s.io/pause:3.8
# kubeadm config images pull --image-repository=$Mirror
# kubeadm config images list --image-repository kc.io --kubernetes-version v1.32.8

## --image-repository=kc.io
## kubeadm config images pull --image-repository arti.mydomain.net:8082/k8s-local
## kubeadm config print init-defaults ClusterConfiguration >kubeadm.conf
## kubeadm config print init-defaults      ##########kubeadm config print-defaults
## kubeadm config print init-defaults >kubeadm.yaml
## kubeadm config print init-defaults --component-configs KubeletConfiguration

## yum check-update ca-certificates; (($?==100)) && yum update ca-certificates || yum reinstall ca-certificates
#update-ca-trust extract

# kubeadm.yaml  # kubeadm init --config kubeadm.yaml
# advertiseAddress 参数需要修改成当前 master 节点的 ip
# bindPort 参数为 apiserver 服务的访问端口，可以自定义
# criSocket 参数定义 容器运行时 使用的套接字，默认是 dockershim ，这里需要修改为 contained 的套接字文件，在 conf.toml 里面可以找到
# imagePullPolicy 参数定义镜像拉取策略，IfNotPresent 本地没有镜像则拉取镜像；Always 总是重新拉取镜像；Never 从不拉取镜像，本地没有镜像，kubelet 启动 pod 就会报错 （注意驼峰命名，这里的大写别改成小写）
# certificatesDir 参数定义证书文件存储路径，没特殊要求，可以不修改
# controlPlaneEndpoint 参数定义稳定访问 ip ，高可用这里可以填 vip
# dataDir 参数定义 etcd 数据持久化路径，默认 /var/lib/etcd ，部署前，确认路径所在磁盘空间是否足够
# imageRepository 参数定义镜像仓库名称，默认 k8s.gcr.io ，如果要修改，需要注意确定镜像一定是可以拉取的到，并且所有的镜像都是从这个镜像仓库拉取的
# kubernetesVersion 参数定义镜像版本，和镜像的 tag 一致
# podSubnet 参数定义 pod 使用的网段，不要和 serviceSubnet 以及本机网段有冲突
# serviceSubnet 参数定义 k8s 服务 ip 网段，注意是否和本机网段有冲突
# cgroupDriver 参数定义 cgroup 驱动，默认是 cgroupfs
# mode 参数定义转发方式，可选为iptables 和 ipvs
# name 参数定义节点名称，如果是主机名需要保证可以解析（kubectl get nodes 命令查看到的节点名称）

echo "Preflight Check Passed: Downloaded All Required Images"

## --node-labels=node.kubernetes.io/node=''

if [[ ! -f /etc/kubernetes/admin.conf ]];then

  sudo kubeadm init --kubernetes-version=$k8s --image-repository=$Mirror --apiserver-advertise-address=$MASTER_IP --apiserver-cert-extra-sans=$MASTER_IP --pod-network-cidr=$POD_CIDR --node-name "$NODENAME"  --v=9 --ignore-preflight-errors Swap

  mkdir -p "$HOME"/.kube
  sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
  sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config
  kubectl config rename-context kubernetes-admin@kubernetes k8s-cluster-$MASTER_IP
  kubectl config set-context "$(kubectl config current-context )" --namespace=kube-system

  # Save Configs to shared /Vagrant location

  # For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

  config_path="/vagrant/configs"

  if [ -d $config_path ]; then
    rm -f $config_path/*
  else
    mkdir -p $config_path
  fi

  cp -i "$HOME"/.kube/config /vagrant/configs/config
  touch /vagrant/configs/join.sh
  chmod +x /vagrant/configs/join.sh
  command=$(kubeadm token create --print-join-command)

  echo "
if [[ \$(hostname) == 'node3' ]] ;then
    $command
    kubectl taint nodes \$(hostname) 'CriticalAddonsOnly=true:NoSchedule'
    echo 'apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.100-192.168.1.150' | kubectl -f -
else
    $command
fi" > /vagrant/configs/join.sh

  # Install Calico Network Plugin

  # curl https://docs.projectcalico.org/manifests/calico.yaml -O
  # kubectl apply -f calico.yaml

  # kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/calico.yaml
  kubectl create -f http://192.168.1.2:8080/soft/k8s/calico.yaml


  ### flannel ######################################
  # https://github.com/flannel-io/flannel
  # curl https://raw.githubusercontent.com/yutao517/mirror/main/profile/kube-flannel.yml -O
  # kubectl apply -f kube-flannel.yml

  # kubectl create ns kube-flannel
  # kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged

  # helm repo add flannel https://flannel-io.github.io/flannel/
  # helm install flannel --set podCidr="10.244.0.0/16" --namespace kube-flannel flannel/flannel

  # curl -O http://192.168.1.2:8080/soft/k8s/cni-plugins-linux-amd64-v1.7.1.tgz
  # tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.7.1.tgz
  ################################################################


  # Install Metrics Server
  # sed -i 's#registry.k8s.io/metrics-server/metrics-server:v0.8.0#swr.cn-north-4.myhuaweicloud.com/ddn-k8s/registry.k8s.io/metrics-server/metrics-server:v0.8.0#' deployment.yaml
  # kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml   # 0.8.x	metrics.k8s.io/v1beta1	1.31+
  # kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.0/components.yaml   # 0.8.x	metrics.k8s.io/v1beta1	1.31+
  # kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml   # 0.7.x	metrics.k8s.io/v1beta1	1.27+
  # kubectl apply -f http://192.168.1.2:8080/soft/k8s/metrics-server-0.7.2.yaml
  kubectl apply -f http://192.168.1.2:8080/soft/k8s/fix.metrics-server-0.8.0.yaml
  # kubectl delete -f  http://192.168.1.2:8080/soft/k8s/metrics-server-0.8.0.yaml
  # Install Kubernetes Dashboard
  kubectl create namespace kubernetes-dashboard
  # kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.1/aio/deploy/recommended.yaml
  kubectl apply -n kubernetes-dashboard -f http://192.168.1.2:8080/soft/k8s/kubernetes-dashboard-install.yml

  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

fi

# cat > metallb-config.yaml <<EOF
# apiVersion: metallb.io/v1beta1
# kind: IPAddressPool
# metadata:
#   name: production-pool
#   namespace: metallb-system
# spec:
#   addresses:
#   - 192.168.1.100-192.168.1.150
# EOF


# kubectl apply -f metallb-config.yaml

kubectl get ns  |grep ingress-basic || kubectl create ns ingress-basic
kubectl apply -f http://192.168.1.2:8080/soft/k8s/inst.ingress.yml


# Add kubernetes-dashboard repository
# helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
# helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# Create Dashboard User

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# kubectl -n kubernetes-dashboard get secret "$(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}")" -o go-template="{{.data.token | base64decode}}" >> /vagrant/configs/token

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF

AT "Completed master setup......."
