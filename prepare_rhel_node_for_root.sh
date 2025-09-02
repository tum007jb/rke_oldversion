#!/bin/bash
set -e

echo ">>> [STEP 1/7] Starting RHEL 8 Node Preparation for RKE (as root user)..."

# --- STEP 2: System Update ---
echo ">>> [STEP 2/7] Updating system packages..."
dnf update -y

# --- STEP 3: User setup is SKIPPED because we are using root ---
echo ">>> [STEP 3/7] Skipping user creation (using root)."

# --- STEP 4: Disable and turn off SWAP ---
echo ">>> [STEP 4/7] Disabling SWAP..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# --- STEP 5: Configure Kernel Parameters ---
echo ">>> [STEP 5/7] Loading br_netfilter kernel module..."
cat <<EOF > /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# --- STEP 6: Configure Firewall (firewalld) ---
echo ">>> [STEP 6/7] Configuring firewalld rules..."
firewall-cmd --permanent --add-port={2379,2380,6443,10250,10251,10252,10256,10257,10258,10259}/tcp
firewall-cmd --permanent --add-port={8472,4789}/udp
firewall-cmd --permanent --add-port={80,443}/tcp
firewall-cmd --reload
echo "Firewall configured."

# --- STEP 7: Disable SELinux ---
echo ">>> [STEP 7/7] Disabling SELinux..."
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo "SELinux set to permissive."

# --- STEP 8: Install Docker ---
echo ">>> [STEP 8/8] Installing Docker..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
echo "Docker installed and running."

echo "========================================================="
echo "Node preparation complete! (as root)"
echo "Please run this script on ALL your RHEL 8 nodes."
echo "After running on all nodes, setup SSH key access for the 'root' user from your Control Machine."
echo "========================================================="