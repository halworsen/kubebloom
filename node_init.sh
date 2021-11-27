#!/bin/bash

# Initializes a control plane node
init_cp_node()
{
    step_warn "[cluster initialization] If your CRI socket is in a non-standard path, you may enter it now. Leave blank to have kubeadm attempt to autodetect it"
    # Give the user a chance to input the CRI socket
    local CRI="placeholder :)"
    while [[ $CRI != "" && ! -e $CRI ]]; do
        read -p "CRI path>" CRI
    done

    step_warn "[cluster initialization] You may enter a custom pod CIDR now. Leave blank to use defaults. Keep in mind that some container network interfaces (CNIs) may have strict pod CIDR requirements."
    local POD_CIDR=""
    read -p "Pod CIDR>" POD_CIDR

    step_warn "[cluster initialization] By default, kubeadm will advertise the API server as reachable on the default gateway to other nodes. If you want to use a different address, you may specify the API server advertisement address now. Leave blank to use defaults"
    local ADVERT_ADDR=""
    read -p "API server advertise address>" ADVERT_ADDR

    echo
    step_info "Cluster initialization summary"
    step_info "=============================="
    if [[ $CRI == "" ]]; then
        step_info "CRI socket: Attempt to auto-detect"
    else
        step_info "CRI socket: $CRI"
    fi
    if [[ $POD_CIDR == "" ]]; then
        step_info "Pod CIDR: Default"
    else
        step_info "Pod CIDR: $POD_CIDR"
    fi
    if [[ $ADVERT_ADDR == "" ]]; then
        step_info "API server advertisement address: Default gateway"
    else
        step_info "API server advertisement address: $ADVERT_ADDR"
    fi

    prompt_continue_abort

    local KUBEADM_ARGS=()
    if [[ $CRI != "" ]]; then
        KUBEADM_ARGS+=("--cri-socket $CRI")
    fi
    if [[ $POD_CIDR != "" ]]; then
        KUBEADM_ARGS+=("--pod-network-cidr $POD_CIDR")
    fi
    if [[ $ADVERT_ADDR != "" ]]; then
        KUBEADM_ARGS+=("--apiserver-advertise-address=$ADVERT_ADDR")
    fi
    local KUBEADM_FINAL_ARGS=$(IFS=" ";echo "${KUBEADM_ARGS[*]}")
    local KUBEADM_CMD="kubeadm init $KUBEADM_FINAL_ARGS"

    eval "$KUBEADM_CMD"

    step_info "Kubernetes is now running on the machine as a control plane node!"
    step_info "\e[1mCopy the kubeadm join command that was output by the cluster initalization step, you will need it to join worker nodes to the cluster.\e[0m"
    echo
    step_info "You will likely want to deploy a pod network as the first thing you do. This enables your pods to communicate."
    step_info "See https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network for more information."
}

# extremely complex init routine, innit?
init_worker_node()
{
    step_info "[cluster initialization] During control plane note initialization, you were given a join command. Please enter it now."
    step_info "[cluster initialization] If you have lost the join command, you can get a new one by running the following command on the control plane node: kubeadm token create --print-join-command"

    local KUBEADM_JOIN_CMD=""
    prompt -p "Kubeadm join command>" KUBEADM_JOIN_CMD
    eval "$KUBEADM_JOIN_CMD"
}
