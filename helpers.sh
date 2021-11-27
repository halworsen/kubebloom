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

prompt_continue()
{
    ANS=""

    while [[ "$ANS" != "Y" && "$ANS" != "y" && "$ANS" != "N" && "$ANS" != "n" ]]; do
        read -p "Continue? [y/n] " ANS
    done

    if [[ "$ANS" == "N" || "$ANS" == "n" ]]; then
        return 1
    fi
    return 0
}

prompt_yn()
{
    ANS=""

    while [[ "$ANS" != "Y" && "$ANS" != "y" && "$ANS" != "N" && "$ANS" != "n" ]]; do
        read -p "$1 [y/n] " ANS
    done

    if [[ "$ANS" == "N" || "$ANS" == "n" ]]; then
        return 1
    fi
    return 0
}

prompt_continue_abort()
{
    prompt_continue
    if [[ $? == 1 ]]; then
        echo "Aborting"
        exit 1
    fi
}
