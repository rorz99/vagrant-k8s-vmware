
source /vagrant/scripts/source-env.sh
AT "Start sshkey script......."
grep KC@IBM .ssh/authorized_keys >/dev/null || echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEApOIRyBheNz0pPe2J8z5+Kg+yHmY1uSwXClzzKofM2KFRdDbihs+6byk6aKlR7Pn0n/pANlveml1jbVYnWHNTjfoOj2zzUPiruar86S45sX2EVBHt8XsqNZo+Iu2h7CtaXtq62siAsKswxeDivru/bSSTLNfhZmJcghx9BTbxA2UMD89MoL+5iNekTb5mwH9Ku2EURug8HpiU8C0bSofJNCAtzss5eihndwJnATRlfjQlqw7V6v6pGBKtzrGnXN3/lpofINOPGx7wtQ/zmJ2MI1EHoaglZu+yqIuGssQcLLJIVhV48XU2dPYCUlfUJsNuZfsi+sq/WP1sJCBuW0KmDw== KC@IBM" >>.ssh/authorized_keys

aptfile=tsinghua.sources.list
if ! grep -q tuna.tsinghua /etc/apt/$aptfile; then
    sudo cp /etc/apt/$aptfile /etc/apt/$aptfile.kc.bak;
    # UBUNTU_Name=$(awk -F= '/VERSION_CODENAME=/{print $2}' /etc/os-release);
    UBUNTU_Name=$(lsb_release -cs);
    echo "#
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-security main restricted universe multiverse

# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_Name-security main restricted universe multiverse" | sudo tee /etc/apt/$aptfile
    apt-get update -y
fi
