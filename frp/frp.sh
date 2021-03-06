#!/bin/bash
# 指此脚本使用/bin/bash来解释执行


# 设置版本数据

FRP_VER=0.43.0
FRP_TYPE=
github_download_url="https://github.com/fatedier/frp/releases/download"

# INSTALL_PATH='/opt/frp'
# 配置路径
# 如果路径最后面有 / ，去除 /
# 如果路径最后没有指定项目名，添加项目名
if [ ! -n "$2" ];then
    INSTALL_PATH='/opt/frp'
else
    if [[ $2 == */ ]];then
        INSTALL_PATH=${2%?}
    else INSTALL_PATH=$2
    fi
    if ! [[ $INSTALL_PATH == */frp， ]];then
        INSTALL_PATH="$INSTALL_PATH/frp"
    fi
fi


RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
SHAN='\e[1;33;5m'
RES='\e[0m'
clear



# Get platform
if command -v arch >/dev/null 2>&1; then
    platform=`arch`
else
    platform=`uname -m`
fi

ARCH="UNKNOWN"

if [ "$platform" = "x86_64" ];then
    ARCH=amd64
elif [ "$platform" = "aarch64" ];then
    ARCH=arm64
fi

# 判断端口是否占用 
if [ "$(id -u)" != "0" ]; then
    echo -e "\r\n${RED_COLOR}出错了，请使用 root 权限重试！${RES}\r\n" 1>&2
    exit 1;
    elif [ "$ARCH" == "UNKNOWN" ];then
    echo -e "\r\n${RED_COLOR}出错了${RES}，一键安装目前仅支持 x86_64和arm64 平台。"
    exit 1;
    elif ! command -v systemctl >/dev/null 2>&1; then
    echo -e "\r\n${RED_COLOR}出错了${RES}，无法确定你当前的 Linux 发行版。\r\n建议手动安装：${GREEN_COLOR} $github_download_url ${RES}\r\n"
    exit 1;
else
    if command -v netstat >/dev/null 2>&1; then
        check_port=`netstat -lnp|grep 5244|awk '{print $7}'|awk -F/ '{print $1}'`
    else
        echo -e "${GREEN_COLOR}端口检查 ...${RES}"
        if command -v yum >/dev/null 2>&1; then
            yum install net-tools -y >/dev/null 2>&1
            check_port=`netstat -lnp|grep 5244|awk '{print $7}'|awk -F/ '{print $1}'`
        else
            apt-get update >/dev/null 2>&1
            apt-get install net-tools -y >/dev/null 2>&1
            check_port=`netstat -lnp|grep 5244|awk '{print $7}'|awk -F/ '{print $1}'`
        fi
    fi
fi


CHECK() {
    echo "check"
    # echo "$FRP_TYPE"
    if [ -f "$INSTALL_PATH/$FRP_TYPE" ];then
        echo "此位置已经安装，请选择其他位置，或使用更新命令"
        exit 0
    fi
    if [ $check_port ];then
        kill -9 $check_port
    fi
    if [ ! -d "$INSTALL_PATH/" ];then
        mkdir -p $INSTALL_PATH
    else
        rm -rf $INSTALL_PATH && mkdir -p $INSTALL_PATH
    fi
}


INSTALL() {
    # 下载 Frp 程序
    echo -e "\r\n${GREEN_COLOR}下载 Frp $latest_version2 ...${RES}"
    program_download_url=https://ghproxy.com/$github_download_url
    program_latest_filename="frp_${FRP_VER}_linux_${ARCH}"
    program_latest_filename_gz="frp_${FRP_VER}_linux_${ARCH}.tar.gz"
    program_latest_file_url="${program_download_url}/v${FRP_VER}/${program_latest_filename_gz}"

    curl -L ${program_latest_file_url} -o /tmp/frp.tar.gz $CURL_BAR
    tar zxf /tmp/frp.tar.gz -C $INSTALL_PATH/
    
    if [ -d $INSTALL_PATH/$program_latest_filename ];then
        mv $INSTALL_PATH/$program_latest_filename $INSTALL_PATH/frp
    else
        echo -e "${RED_COLOR}下载 $program_latest_filename 失败！${RES}"
        exit 1;
    fi
    
    # 删除下载缓存
    rm -f /tmp/frp*
}

INIT() {
    if [ ! -d "$INSTALL_PATH/frp" ];then
        echo -e "\r\n${RED_COLOR}出错了${RES}，当前系统未安装 Frp\r\n"
        exit 1;
    fi
    echo "创建启动文件$FRP_TYPE.service"
    # 创建 systemd
cat >/etc/systemd/system/$FRP_TYPE.service <<EOF
[Unit]
Description=Frp Service
Wants=network.target
After=network.target network.service

[Service]
Type=simple
WorkingDirectory=$INSTALL_PATH
ExecStart=$INSTALL_PATH/frp/$FRP_TYPE -c $INSTALL_PATH/frp/$FRP_TYPE.ini
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
    
    # 添加开机启动
    systemctl daemon-reload
    systemctl enable $FRP_TYPE >/dev/null 2>&1
    systemctl restart $FRP_TYPE
}


SUCCESS() {
    clear
    echo "Frp 安装成功！"
    echo -e "\r\n访问地址：${GREEN_COLOR}http://YOUR_IP:5244/${RES}\r\n"
    
    echo -e "配置文件：${GREEN_COLOR}$INSTALL_PATH/frp/$FRP_TYPE.ini${RES}"
    
    sleep 1s
    # cd $INSTALL_PATH/frp
    # get_password=$(./alist -password 2>&1)
    # echo -e "初始管理密码：${GREEN_COLOR}$(echo $get_password | awk -F'your password: ' '{print $2}')${RES}"
    
    echo
    echo -e "查看状态：${GREEN_COLOR}systemctl status $FRP_TYPE${RES}"
    echo -e "启动服务：${GREEN_COLOR}systemctl start $FRP_TYPE${RES}"
    echo -e "重启服务：${GREEN_COLOR}systemctl restart $FRP_TYPE${RES}"
    echo -e "停止服务：${GREEN_COLOR}systemctl stop $FRP_TYPE${RES}"
    echo -e "\r\n温馨提示：如果端口无法正常访问，请检查 \033[36m服务器安全组、本机防火墙、$FRP_TYPE状态\033[0m"
    echo
}

UNINSTALL() {
    echo -e "\r\n${GREEN_COLOR}卸载 Frp ...${RES}\r\n"
    echo -e "${GREEN_COLOR}停止进程${RES}"
    systemctl disable $FRP_TYPE >/dev/null 2>&1
    systemctl stop $FRP_TYPE >/dev/null 2>&1
    echo -e "${GREEN_COLOR}清除残留文件${RES}"
    rm -rf $INSTALL_PATH /etc/systemd/system/$FRP_TYPE.service
    systemctl daemon-reload
    echo -e "\r\n${GREEN_COLOR}Frp 已在系统中移除！${RES}\r\n"
}


# CURL 进度显示
if curl --help | grep progress-bar >/dev/null 2>&1; then # $CURL_BAR
    CURL_BAR="--progress-bar";
fi

# The temp directory must exist
if [ ! -d "/tmp" ];then
    mkdir -p /tmp
fi

# Fuck bt.cn (BT will use chattr to lock the php isolation config)
chattr -i -R $INSTALL_PATH >/dev/null 2>&1


# 软件类型 0 frps； 1 frpc 
echo ""
echo -e "请选择类型:"
echo -e "  ${GREEN_COLOR}1.${RES}   服务端Frps"
echo -e "  ${GREEN_COLOR}2.${RES}   客户端Frpc"
echo -e "  ${GREEN_COLOR}0.${RES}   退出"

read -p "请选择操作[0-2]：" answer
echo "daan: ${answer}"
case $answer in
    0) exit 1 ;;
    1) FRP_TYPE=frps;;
    2) FRP_TYPE=frpc;;
    *) echo -e "$RED_COLOR 请选择正确的操作！${RES}" && exit 1 ;;
esac
echo -e "Frp类型$FRP_TYPE"


if [ "$1" = "uninstall" ];then
    UNINSTALL
    elif [ "$1" = "update" ];then
    UPDATE
    elif [ "$1" = "install" ];then
    CHECK
    INSTALL
    INIT
    if [ -d "$INSTALL_PATH/$SOFT_NAME" ];then
        SUCCESS
    else
        echo -e "${RED_COLOR} 安装失败${RES}"
    fi
else
    echo -e "${RED_COLOR} 错误的命令${RES}"
fi

# TODO 对 .ini 文件进行填充