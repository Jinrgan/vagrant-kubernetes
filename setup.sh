DOCKER_VERSION=19.03.8
KUBE_VERSION=1.19.3
#/bin/sh
yum install -y wget
cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
cd /etc/yum.repos.d
wget  http://mirrors.aliyun.com/repo/Centos-7.repo
# yum -y update

# install some tools
yum install -y vim telnet bind-utils git net-tools

# open password auth for backup if ssh key doesn't work, bydefault, username=vagrant password=vagrant
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

ntpdate 0.asia.pool.ntp.org

# install docker
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y yum-utils
yum install -y docker-ce-"${DOCKER_VERSION}" docker-ce-cli-"${DOCKER_VERSION}" containerd.io-"${DOCKER_VERSION}"
systemctl start docker

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://registry.cn-hangzhou.aliyuncs.com"]
}
EOF

# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

cat >>/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

setenforce 0

# install kubeadm, kubectl, and kubelet.
yum install -y kubelet-"${KUBE_VERSION}" kubeadm-"${KUBE_VERSION}" kubectl-"${KUBE_VERSION}"

bash -c 'cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
EOF'
sysctl --system

systemctl stop firewalld
systemctl disable firewalld
swapoff -a

local_ip="$(ip addr show eth1 | grep  "inet " | cut -d '/' -f 1 | awk '{print $2}')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

systemctl enable kubelet

sed -i 's/#VAGRANT-END/GATEWAY=192.168.0.254/g' /etc/sysconfig/network-scripts/ifcfg-eth1
echo "#VAGRANT-END" >> /etc/sysconfig/network-scripts/ifcfg-eth1
systemctl restart network
sed -i 's/ONBOOT="yes"/ONBOOT="no"/g' /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl restart network