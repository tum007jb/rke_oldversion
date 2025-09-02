#!/bin/bash
# rke-setup.sh : Auto setup RHEL for RKE v2.5.7
# Run as root

set -e

RKE_VERSION="v1.3.14"   # ใช้ RKE CLI เวอร์ชันที่รองรับ Rancher 2.5.7
DOCKER_VERSION="20.10"

echo "[1/6] Disable SELinux..."
setenforce 0 || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

echo "[2/6] Disable swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[3/6] Install required packages..."
dnf install -y yum-utils device-mapper-persistent-data lvm2 curl tar

echo "[4/6] Install Docker ${DOCKER_VERSION}..."
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce-${DOCKER_VERSION}* docker-ce-cli-${DOCKER_VERSION}* containerd.io
systemctl enable --now docker

echo "[5/6] Configure sysctl for Kubernetes..."
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
modprobe br_netfilter
sysctl --system

echo "[6/6] Download RKE ${RKE_VERSION}..."
curl -Lo /usr/local/bin/rke https://github.com/rancher/rke/releases/download/${RKE_VERSION}/rke_linux-amd64
chmod +x /usr/local/bin/rke

echo "Setup complete! Please create cluster.yml and run 'rke up'."