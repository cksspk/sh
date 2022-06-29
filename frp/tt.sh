#!/bin/bash

GREEN_COLOR='\e[1;32m'
RES='\e[0m'
RED_COLOR='\e[1;31m'

# 软件类型 0 frps； 1 frpc
SOFT_TYPE 

    echo -e "  ${GREEN_COLOR}1.${RES}   安装服务端Frps"
    echo -e "  ${GREEN_COLOR}2.${RES}   安装客户端Frpc"
    echo -e "  ${GREEN_COLOR}0.${RES}   退出"
    
    read -p "请选择操作[0-2]：" answer
    echo "daan: ${answer}"
    case $answer in
        0) exit 1 ;;
        1) echo "11" ;;
        2) echo "22" ;;
        *) echo -e "$RED_COLOR 请选择正确的操作！${RES}" && exit 1 ;;
    esac