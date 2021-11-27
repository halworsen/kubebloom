#!/bin/bash

source ./helpers.sh
source ./kubeadm_setup.sh
source ./node_init.sh

step_info "kubebloom"
step_info "========="
step_info "kubebloom will setup this machine as a kubernetes node according to the official kubeadm installation guide."
step_info "You will be prompted during installation for certain important choices."
step_info "Steps which utilize privilege escalation are always marked with bold text."
echo

# Determine whether to setup as control plane or worker node
KUBEBLOOM_MODE="c"
ANS=""
while [[ "$ANS" != "c" && "$ANS" != "w" ]]; do
    read -p "Do you want to setup the machine as a control plane (c) or worker node (w)? [c/w] " ANS
done
if [[ "$KUBEBLOOM_MODE" == "c" ]]; then
    step_info "kubebloom will setup and initialize a kubernetes control plane node"
else
    step_info "kubebloom will setup and initialize a kubernetes worker node"
fi
prompt_continue_abort

# slightly naive, but we assume worker nodes have at least some nodeports open in the default 30000-32767 range
KUBEADM_PORTS=(10250)
if [[ "$KUBEBLOOM_MODE" == "c" ]]; then
    KUBEADM_PORTS+=(6443 2379 2380 10259 10257)
fi

# Do setup stuff
setup_br_netfilter
setup_iptables_bridged_traffic
check_kube_ports_available $KUBEADM_PORTS
install_k8s_binaries

# Start the kubelet
if prompt_yn "Would you like to enable the kubelet now?"; then
    step_info "Enabling the kubelet..."
    systemctl enable --now kubelet
else
    step_info "Before continuing, you must enable the kubelet using: systemctl enable --now kubelet"
    exit 1
fi

# Initialize the node
if [[ "$KUBEBLOOM_MODE" == "c" ]]; then
    init_cp_node
else
    init_worker_node
fi
