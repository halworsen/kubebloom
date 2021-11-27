#!/bin/bash

KUBEBLOOM_CNI_VERSION="v0.8.2"
KUBEBLOOM_ARCH="amd64"
KUBEBLOOM_DL_DIR=/usr/local/bin
KUBEBLOOM_CRICTL_VERSION="v1.22.0"
KUBEBLOOM_BINARIES_RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
KUBEBLOOM_BINARIES_RELEASE_VERSION="v0.4.0"

# br_netfilter setup
setup_br_netfilter()
{
    step_info "[kubeadm setup] Checking if br_netfilter is loaded..."
    if lsmod | grep "br_netfilter" &> /dev/null; then
        step_info "[kubeadm setup] br_netfilter module is already loaded"
    else
        step_info "\e[1m[kubeadm setup] br_netfilter is not loaded, loading now\e[0m"

        sudo modprobe br_netfilter
        if [[ $? != 0 ]]; then
            step_info "[kubeadm setup] Failed to load br_netfilter! Exiting"
            return
        fi

        step_info "[kubeadm setup] Successfully loaded br_netfilter!"
    fi
}

# Setup iptables to see bridged traffic
setup_iptables_bridged_traffic()
{
    local SYSCTL_CFG_PATH=/etc/sysctl.d/k8s.conf
    local IPTABLES_SYSCTL_CFG=""
    step_info "[kubeadm setup] Checking if iptables can see bridged traffic..."

    # ipv4
    if [[ "$(sysctl -n net.bridge.bridge-nf-call-iptables)" != "1" ]]; then
        step_info "[kubeadm setup] Enabling sending IPv4 bridged traffic to iptables"
        IPTABLES_SYSCTL_CFG="net.bridge.bridge-nf-call-iptables = 1"
    fi

    # ipv6
    if [[ "$(sysctl -n net.bridge.bridge-nf-call-ip6tables)" != "1" ]]; then
        step_info "[kubeadm setup] Enabling sending IPv6 bridged traffic to iptables"
        if [[ -n "$IPTABLES_SYSCTL_CFG" ]]; then
            IPTABLES_SYSCTL_CFG=$(echo -e "${IPTABLES_SYSCTL_CFG}\nnet.bridge.bridge-nf-call-ip6tables = 1")
        else
            IPTABLES_SYSCTL_CFG="net.bridge.bridge-nf-call-ip6tables = 1"
        fi
    fi

    if [[ "$IPTABLES_SYSCTL_CFG" != "" ]]; then
        step_info "\e[1m[kubeadm setup] Writing system configuration to $SYSCTL_CFG_PATH\e[0m"
        sudo tee -a $SYSCTL_CFG_PATH > /dev/null <<< "$IPTABLES_SYSCTL_CFG"
        step_info "\e[1m[kubeadm setup] Reloading sysctl config\e[0m"
        sudo sysctl --system
    fi
}

# Check if required ports are in use
check_kube_ports_available()
{
    step_info "[kubeadm setup] Checking if kubernetes ports are available"

    local PORTS=("$@")
    for i in $1; do
        if lsof -i -P -n | grep LISTEN | grep "${PORTS[$i]}"; then
            step_error "[kubeadm setup] Port ${PORTS[$i]} is in use, but is required by kubernetes. Aborting"
            exit 1
        fi
    done

    step_info "[kubeadm setup] All required ports available"
}

# what it says on the tin
install_k8s_binaries()
{
    local KUBEBLOOM_START_DIR=$(pwd)

    # Install CNI plugins
    step_info "\e[1m[kubeadm setup] Installing CNI plugins\e[0m"

    sudo mkdir -p /opt/cni/bin
    curl -L "https://github.com/containernetworking/plugins/releases/download/${KUBEBLOOM_CNI_VERSION}/cni-plugins-linux-${KUBEBLOOM_ARCH}-${KUBEBLOOM_CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz
    rm cni-plugins-linux-${KUBEBLOOM_ARCH}-${KUBEBLOOM_CNI_VERSION}.tgz

    # Install crictl
    step_info "\e[1m[kubeadm setup] Installing crictl\e[0m"


    sudo mkdir -p $KUBEBLOOM_DL_DIR
    curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${KUBEBLOOM_CRICTL_VERSION}/crictl-${KUBEBLOOM_CRICTL_VERSION}-linux-${KUBEBLOOM_ARCH}.tar.gz" | sudo tar -C $KUBEBLOOM_DL_DIR -xz

    # Install kubeadm, kubelet and kubectl
    step_info "\e[1m[kubeadm setup] Installing kubeadm, kubelet and kubectl\e[0m"

    cd $KUBEBLOOM_DL_DIR
    step_info "[kubeadm setup] Downloading kubeadm, kubelet and kubectl binaries"
    sudo curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${KUBEBLOOM_BINARIES_RELEASE}/bin/linux/${KUBEBLOOM_ARCH}/{kubeadm,kubelet,kubectl}
    sudo chmod +x {kubeadm,kubelet,kubectl}

    sudo mkdir -p /etc/systemd/system/kubelet.service.d
    step_info "[kubeadm setup] Downloading kubelet systemd config"
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${KUBEBLOOM_BINARIES_RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${KUBEBLOOM_DL_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
    step_info "[kubeadm setup] Downloading kubelet systemd config for kubeadm"
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${KUBEBLOOM_BINARIES_RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${KUBEBLOOM_DL_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

    cd $KUBEBLOOM_START_DIR
}
