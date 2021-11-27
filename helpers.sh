#!/bin/bash

step_info()
{
    echo -e "\e[0m\e[94m$1\e[0m"
}

step_warn()
{
    echo -e "\e[0m\e[33m$1\e[0m"
}

step_error()
{
    echo -e "\e[0m\e[31m$1\e[0m"
}

prompt()
{
    local ANS=""

    while [[ "${ANS,,}" != "${2,,}" && "${ANS,,}" != "${3,,}" ]]; do
        read -p "$1 [${2,,}/${3,,}] " ANS
    done

    if [[ "${ANS,,}" == "${3,,}" ]]; then
        return 1
    fi
    return 0
}

prompt_continue_abort()
{
    prompt "Continue?" "y" "n"
    if [[ $? == 1 ]]; then
        echo "Aborting"
        exit 1
    fi
}
