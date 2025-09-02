# RKE v2.5.7 Deployment on RHEL via Ansible - Comprehensive Plan

This document outlines a comprehensive plan for deploying a highly available Rancher Kubernetes Engine (RKE) v2.5.7 cluster on Red Hat Enterprise Linux (RHEL) using Ansible for automation.

---

## 1. Architectural Design

### 1.1 Cluster Structure:
-   **HA Control Plane:** 3 Nodes (e.g., `rke-master-01`, `rke-master-02`, `rke-master-03`) acting as `etcd`, `controlplane`, and `worker` roles.
-   **Worker Nodes:** 2+ Nodes (e.g., `rke-worker-01`, `rke-worker-02`) acting as `worker` roles.
-   **Load Balancer:** 1 Node (e.g., `rke-lb-01`) for Kubernetes API (6443) and Ingress (80/443). Can be HAProxy, Nginx, or cloud LB.
-   **Ansible/RKE CLI Management Host:** 1 Node (e.g., `ansible-mgmt-01`) for running Ansible playbooks and RKE commands.

### 1.2 Resource Requirements (Minimum per Node):
-   **RKE Master Node (all roles):** 2 Cores, 8 GB RAM, 50 GB Disk (for OS/binaries) + etcd data disk.
-   **RKE Worker Node:** 2 Cores, 4 GB RAM, 50 GB Disk + workload storage.
-   **Load Balancer:** 1 Core, 2 GB RAM, 20 GB Disk.
-   **Ansible/RKE CLI Host:** 1 Core, 2 GB RAM, 30 GB Disk.

---

## 2. OS Design (RHEL 8.x / 9.x) - For All RKE Nodes

### 2.1 Operating System:
-   **RHEL 8.x or RHEL 9.x:** Latest stable minor version.
-   Minimal Install recommended.
-   Ensure Red Hat Subscription is active and required repositories are enabled.

### 2.2 Disk Partitioning (Example):
-   `/boot`: 1 GB (ext4)
-   `/`: 20 GB (ext4/xfs)
-   `/var`: 10 GB (ext4/xfs)
-   `/var/lib/containerd` (or `/var/lib/docker`): 50GB-100GB+ (dedicated partition/LV recommended).
-   **SWAP:** Disabled.

### 2.3 Network Configuration:
-   **Static IP Address:** Required for all nodes.
-   **Hostname:** FQDN (e.g., `rke-master-01.yourdomain.com`).
-   **DNS Resolution:** Proper DNS server configuration.
-   **Firewall Ports (TCP):**
    -   `6443`: Kubernetes API Server
    -   `2379`, `2380`: etcd client & peer (Master nodes)
    -   `10250`: Kubelet API
    -   `10251`: Kube-scheduler
    -   `10252`: Kube-controller-manager
    -   `80`, `443`: Ingress (if applicable)
    -   `22`: SSH
    -   `9099`: RKE healthcheck (Master nodes)
    -   `8472` (UDP): Flannel overlay network
    -   `6783`, `6784` (TCP/UDP): Calico (if used)
    -   Load Balancer: Must forward `6443`, `80`, `443` to respective cluster components.

### 2.4 User Management & Security:
-   **Non-Root User:** Create a dedicated user (e.g., `rancher` or `ansible`) for SSH.
-   **Sudoers:** Grant `NOPASSWD` sudo privileges for the automation user.
-   **SSH Key Authentication:** Use SSH keys exclusively.
-   **Disable Root Login:** Harden SSH daemon (`PermitRootLogin no`).
-   **SELinux:** Set to `Permissive` during installation, consider `Enforcing` with specific policies for production.
-   **FirewallD:** Enabled and configured with necessary rules.

### 2.5 Package Installation (Common to RKE Nodes):
-   **Container Runtime:** `containerd` (recommended, from Docker CE repo or CRI-O) or `docker-ce`.
-   **Kubernetes Prerequisites:** `socat`, `conntrack-tools`, `crictl`, `iptables`.
-   **Utility Tools:** `curl`, `wget`, `git`, `vim`, `jq`, `net-tools`.

### 2.6 Kernel Modules & System Settings:
-   **Kernel Modules:** Load `overlay`, `br_netfilter`.
-   **Sysctl:** `net.bridge.bridge-nf-call-iptables = 1`, `net.ipv4.ip_forward = 1`.
-   **SWAP:** Disable.

### 2.7 Time Synchronization:
-   **NTP Client:** Install and enable `chronyd` or `ntpd`.

---

## 3. Other Considerations

-   **Load Balancer:** HAProxy + Keepalived (for VIP failover) is a common on-prem solution.
-   **DNS:** Ensure proper DNS resolution for all cluster hostnames.
-   **Storage (Persistent Storage):**
    -   **NFS:** Simple to start.
    -   **Longhorn:** Rancher's distributed block storage (runs on Kubernetes).
    -   **CephFS/RBD:** Robust but complex.
    -   **Cloud Provider CSI:** For cloud deployments.
-   **Certificates:** RKE self-signs by default. For Rancher UI and production, use trusted CA certificates.

---

## 4. Auto Scripting with Ansible

This section provides the Ansible project structure and example content for automated deployment.

### 4.1 Ansible Project Structure:
