#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

# Variable Declaration
KUBERNETES_short_VERSION=1.29
KUBERNETES_short_VERSION=1.32
CRIO_VERSION=$KUBERNETES_short_VERSION
KUBERNETES_VERSION="1.32.8-1.1"

# OS="xUbuntu_20.04"
# OS="xUbuntu_21.10"
OS="xUbuntu_22.04"
CRIO_VERSION="1.32"

COLOR() {
  export RED='\033[1;31m'
  export GREEN='\033[1;32m'
  export YELLOW='\033[1;33m'
  export BLUE='\033[1;34m'
  export NC='\033[0m\n'
  export INFO='\033[0;34mINFO: \033[0m'
  export ERROR='\033[1;31mERROR: \033[0m'
  export SUCCESS='\033[1;32mSUCCESS: \033[0m'
  export DATE=$(date +%Y-%m-%d)
  export TIME=$(date +%Y%m%d_%H%M%S)
}
COLOR

LOGFILE() {
  #ST=`date +%Y%m%d_%H%M%S`
  st=$(date +%s)
  [[ -d /logs ]] || mkdir /logs
  LOGFILE="/logs/$(basename "$0")-$HOSTNAME-$TIME.log"
  chmod 1777 /logs
}
LOGFILE

LFON() {
  LOGFILE
  exec &> >(tee -ia "$LOGFILE") 2>&1
}

CMD() {
  comment=$1
  shift
  time=$(date +%Y-%m%d-%H:%M:%S)
  printf "%s${BLUE}$time Comment:$comment PATH:$PWD$NC     CMD:$GREEN$* $NC\n"
  eval "$*" && echo "$time $*" >>"/logs/command.history.$HOSTNAME.log"
}

AT() {
  printf "%s \n$GREEN$(date +%Y-%m%d-%H:%M:%S) Attention:$1 $NC"
}

YAT() {
  printf "%s \n$YELLOW$(date +%Y-%m%d-%H:%M:%S) Attention:$1 $NC\n"
}

ERR() {
  printf "%s \n$RED$(date +%Y-%m%d-%H:%M:%S) Error:$1\n $NC"
  exit 1
}

chk_add_if_not_exist() {
  file=$1
  key=$2
  update=$3
  grep "$key" "$file" &>/dev/null || echo "$update" >>"$file"
}

Prompt() {
  export PS1="\[\e[01;32m\]\u@\h\[\e[0m\]:\[\e[01;34m\]\w\[\e[1;31m\]\\$\[\e[0m\]"
}

Pscom() {
  export HISTTIMEFORMAT="%Z-%Y-%m%d-%H%M%S "
  WHO="$USER@$(who am i | awk -F[\(\)] '{print $2}')"
  export PROMPT_COMMAND='{ RC=$?; history 1 | { read s TIME PCMD; echo "$TIME ### $WHO RC=$RC ## $PCMD"; } |tee -a /var/log/command.log; } |logger -p local6.debug'
}

export -f COLOR CMD AT ERR YAT LOGFILE LFON chk_add_if_not_exist Prompt Pscom

AT "Starting setup..............."

if ! grep -q hub.kc2288.dynv6.net.cer /etc/ca-certificates.conf; then
    grep -q 'hub.kc2288.dynv6.net' /etc/hosts  || echo '192.168.1.2 hub.kc2288.dynv6.net' >>/etc/hosts
    echo '192.168.1.2 registry.k8s.io' >>/etc/hosts
    echo -n | openssl s_client -showcerts -connect hub.kc2288.dynv6.net:9090 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' >/usr/share/ca-certificates/hub.kc2288.dynv6.net.cer
    # openssl s_client -connect  hub.kc2288.dynv6.net:4999 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM > ca.crt
    echo hub.kc2288.dynv6.net.cer >>/etc/ca-certificates.conf
    update-ca-certificates
fi

# disable swap
sudo swapoff -a

# keeps the swaf off during reboot
(
    crontab -l 2>/dev/null
    echo "@reboot /sbin/swapoff -a"
) | crontab - || true
# sudo apt-get update -y
# Install CRI-O Runtime

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

if command -v nft &> /dev/null; then
    echo "Resetting nftables rules..."
    nft flush ruleset || true
fi

# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
# echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

# curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
# curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
# OS=xUbuntu_20.04
# CRIO_VERSION=1.26
# echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
# echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

# if [[ ! -f /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list ]] && [[ $INST_CRIO == 'true' ]]; then
#     echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
#     echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
#     sudo mkdir -p /usr/share/keyrings
#     sudo rm -f /usr/share/keyrings/libcontainers-archive-keyring.gpg
#     sudo rm -f /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg
#     curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
#     # curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg
#     curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_22.04/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

#     # apt update --allow-unauthenticated --allow-insecure-repositories
#     sudo apt-get update --allow-unauthenticated --allow-insecure-repositories
#     sudo apt-get install cri-o cri-o-runc -y --allow-unauthenticated
#     sudo systemctl daemon-reload
#     sudo systemctl enable crio --now
#     sudo apt-get remove -y docker docker.io containerd runc
#     echo "CRI runtime installed susccessfully"
# fi

INST_CRIO=false
if [[ ! -f /etc/apt/sources.list.d/kubernetes.crio.$KUBERNETES_short_VERSION.list ]] && [[ $INST_CRIO == 'true' ]];then
    AT "Install CRIO........."
    # curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    # curl -L  https://mirrors.tuna.tsinghua.edu.cn/kubernetes/addons:/cri-o:/stable:/v$KUBERNETES_short_VERSION/deb/Release.key  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-crio-apt-keyring.gpg
    [[ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]] && curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_short_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    # deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors6.tuna.tsinghua.edu.cn/kubernetes/core:/stable:/v$KUBERNETES_short_VERSIO/deb/ /
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors6.tuna.tsinghua.edu.cn/kubernetes/addons:/cri-o:/stable:/v$KUBERNETES_short_VERSION/deb/ / " > /etc/apt/sources.list.d/kubernetes.crio.$KUBERNETES_short_VERSION.list
    sudo apt-get update
    sudo apt-get install cri-o -y
    sudo systemctl daemon-reload
    sudo systemctl enable crio --now
    sudo systemctl status crio
    sudo apt-get remove -y docker docker.io containerd runc
    echo "CRI runtime installed susccessfully"
fi


sudo apt-get install -y ca-certificates curl gnupg lsb-release net-tools jq apt-transport-https ca-certificates curl
alidocker=/etc/apt/keyrings/ali-docker.gpg
[[ -f $alidocker ]] && [[ $INST_CRIO != 'true' ]] || (
    AT "Install Containered........."
    sudo mkdir -p /etc/apt/keyrings
    # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o $alidocker && sudo chmod a+r $alidocker
    # echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$alidocker ] https://mirrors.aliyun.com/docker-ce/linux/ubuntu  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y containerd.io # docker-compose-plugin docker-ce docker-ce-cli

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo sed -i 's#registry.k8s.io/pause:3.8#registry.aliyuncs.com/google_containers/pause:3.9#g' /etc/containerd/config.toml
openssl s_client -connect  hub.kc2288.dynv6.net:4999 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM >  /etc/containerd/hub.kc2288.dynv6.net.crt
sed -i '/\[plugins\."io\.containerd\.grpc\.v1\.cri"\.registry\.configs\]/a\\n[plugins."io.containerd.grpc.v1.cri".registry.configs."hub.kc2288.dynv6.net:4999".tls]\ninsecure_skip_verify = true\nca_file = "/etc/containerd/hub.kc2288.dynv6.net.crt"' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl status containerd
systemctl daemon-reload || true
systemctl enable containerd || true

)


apt autoremove -y
# sudo apt-get update
# sudo apt-get install -y apt-transport-https ca-certificates curl

# echo '{"insecure-registries":["https://kc.io"],"exec-opts":["native.cgroupdriver=systemd"],"registry-mirrors":["https://kc.io", "https://docker.io" ] }' |sudo tee /etc/docker/daemon.json

# sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
# echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg
# sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B53DC80D13EDEF05
# gpg --keyserver keyserver.ubuntu.com --recv-keys B53DC80D13EDEF05
# gpg --export --armor B53DC80D13EDEF05 | sudo apt-key add -
# gpg --export --armor B53DC80D13EDEF05 | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

AT "Install kubernets........."
if [[ ! -f /etc/apt/sources.list.d/kubernetes.$KUBERNETES_short_VERSION.list ]];then
    [[ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]] && curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_short_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/kubernetes/core:/stable:/v$KUBERNETES_short_VERSION/deb/ /" >/etc/apt/sources.list.d/kubernetes.$KUBERNETES_short_VERSION.list
fi

#| apt-key add -
# echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/kubernetes/apt kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
# echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
# sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-get install -y kubelet  kubectl  kubeadm
sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
sudo crictl config image-endpoint unix:///var/run/containerd/containerd.sock

AT "完成配置第一阶段, next........"
# echo 'podSandboxImage: "registry.aliyuncs.com/google_containers/pause:3.8"' >> /var/lib/kubelet/config.yaml
# systemctl restart kubelet
# CMD "systemctl cat kubelet"
# systemctl edit kubelet
# systemctl daemon-reload

# local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
# cat > /etc/default/kubelet << EOF
# KUBELET_EXTRA_ARGS=--node-ip=$local_ip --node-labels=node.kubernetes.io/node=
# EOF
