#!/bin/bash

https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
https://kubernetes.io/docs/setup/independent/install-kubeadm/


# name       internal    public
centos-00    10.0.0.5    40.113.108.57
centos-01    10.0.0.4    40.113.111.21
centos-02    10.0.0.6    40.113.106.199

# Connect ssh

# kube-rg
sshpass -p 'xxxxx' ssh greg@40.113.108.57
sshpass -p 'xxxxx' ssh greg@40.113.111.21
sshpass -p 'xxxxx' ssh greg@40.113.106.199



# Set .bashrc
cat <<EOF >>~/.bashrc
PS1='\[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF

sudo -i

# Set .bashrc
cat <<EOF >>~/.bashrc
PS1='\[\e[01;31m\]$PS1\[\e[00m\]'
EOF

cat <<EOF >>/etc/sudoers
greg ALL=(ALL) NOPASSWD: ALL
EOF


# Enable bridges
cat <<EOF >>/etc/sysctl.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Disable security linux
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# Enable kernel module
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# Turn swap off && comment out line including 'swap'
swapoff -a

# Install package dependencies && install docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce


# Add the kubernetes repository
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install kubeadm kubelet kubectl
yum install -y kubelet kubeadm kubectl

# Login and start services
systemctl start docker && systemctl enable docker && reboot



# Start kubelet
systemctl start kubelet && systemctl enable kubelet

# Check driver; must equal 'cgroupfs'
docker info | grep -i cgroup

# Reload systemd system and restart kubelet
systemctl daemon-reload
systemctl restart kubelet


###############
# Master Only #
###############

https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/calico

# Start kube network with flannel
kubeadm init --pod-network-cidr=192.168.0.0/16

#
echo -e "
Expect return like this to run on workers for joining them:
kube-rg
kubeadm join 10.0.0.5:6443 --token ekd4pk.98no5tq2kh7ztj74 --discovery-token-ca-cert-hash sha256:5789922f11c834feb59d37720dd2505d5bccf5cc49f1d405c7b6a1d04d7e804e
"

# Create new '.kube' configuration directory and copy configuration 'admin.conf'
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
# kubectl can be installed on every node with the above saved certificate in $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/canal/rbac.yaml
kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/canal/canal.yaml

# Check config
kubectl get nodes
kubectl get services
kubectl get pods --all-namespaces


################
# Workers Only #
################

# Join workers to master

# kube-rg
kubeadm join 10.0.0.5:6443 --token ekd4pk.98no5tq2kh7ztj74 --discovery-token-ca-cert-hash sha256:5789922f11c834feb59d37720dd2505d5bccf5cc49f1d405c7b6a1d04d7e804e
# label workers
kubectl label node centos-01 node-role.kubernetes.io/worker=worker
kubectl label node centos-02 node-role.kubernetes.io/worker=worker

#########
# Addon #
#########

# Kubernetes configuration
yum install bash-completion -y
cat <<EOF >>~/.bashrc
# Kubernetes completion
alias k='kubectl'
source <(kubectl completion bash)
alias kcd='kubectl config set-context $(kubectl config current-context) --namespace '
EOF

#