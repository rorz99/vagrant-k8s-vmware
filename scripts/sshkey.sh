
source /vagrant/scripts/source-env.sh
AT "Start sshkey script......."
grep KC@IBM .ssh/authorized_keys >/dev/null || echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEApOIRyBheNz0pPe2J8z5+Kg+yHmY1uSwXClzzKofM2KFRdDbihs+6byk6aKlR7Pn0n/pANlveml1jbVYnWHNTjfoOj2zzUPiruar86S45sX2EVBHt8XsqNZo+Iu2h7CtaXtq62siAsKswxeDivru/bSSTLNfhZmJcghx9BTbxA2UMD89MoL+5iNekTb5mwH9Ku2EURug8HpiU8C0bSofJNCAtzss5eihndwJnATRlfjQlqw7V6v6pGBKtzrGnXN3/lpofINOPGx7wtQ/zmJ2MI1EHoaglZu+yqIuGssQcLLJIVhV48XU2dPYCUlfUJsNuZfsi+sq/WP1sJCBuW0KmDw== KC@IBM" >>.ssh/authorized_keys

# https://mirrors.ustc.edu.cn/help/ubuntu.html#__tabbed_2_1

aptfile=tsinghua.sources.list
if [[ ! -f /etc/apt/$aptfile ]]; then
    if  [ -f /etc/apt/sources.list ];then mv /etc/apt/sources.list /etc/apt/sources.list.bak ;fi
    # grep -v ^#  /etc/apt/sources.list.bak |  sed 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g'  | sudo tee -a /etc/apt/sources.list >/etc/apt/$aptfile

    grep -v ^#  /etc/apt/sources.list.bak |  sed 's@http://.*archive.ubuntu.com@https://mirrors.tuna.tsinghua.edu.cn@g'  | sudo tee -a /etc/apt/sources.list >/etc/apt/$aptfile
    # UBUNTU_Name=$(awk -F= '/VERSION_CODENAME=/{print $2}' /etc/os-release);
    # UBUNTU_Name=$(lsb_release -cs);
#     echo "#
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name main restricted universe multiverse
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-updates main restricted universe multiverse
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-backports main restricted universe multiverse
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-security main restricted universe multiverse

# # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name main restricted universe multiverse
# # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-updates main restricted universe multiverse
# # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-backports main restricted universe multiverse
# # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-security main restricted universe multiverse"
    apt-get update -y
fi
