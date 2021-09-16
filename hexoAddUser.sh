#!/bin/bash

# desc：新建用户
# auth：cks

green='\033[0;32m'
red='\033[0;31m'

user_name=git
pass=123456v.
#允许用户登录
login_flag=n

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# 新建git用户
add_user(){
    read -p "请输入新的名:" user_name
    # 添加用户
    useradd $user_name
    if [ $? -eq 0 ];then
        echo -e "${green}用户名：${user_name} 创建成功"
    else
        echo -e "${red}错误：${user_name} 创建失败\n"
        exit 1
    fi

    read -p "请设置一个密码:" pass
    # 设置密码
    echo $pass | sudo passwd $user_name --stdin  &>/dev/null
    if [ $? -eq 0 ];then
        echo "${user_name} 密码设置成功"
    else
        echo "${user_name}'密码设置失败"
    fi

    # 切换用户
    su $user_name -c "
    mkdir -p /home/${user_name}/projects/blog  
    mkdir -p /home/${user_name}/repos
    git init --bare /home/${user_name}/repos/blog.git
    touch /home/${user_name}/repos/blog.git/post-receive

    cat > /home/${user_name}/repos/blog.git/post-receive <<-EOF
#!/bin/sh
git --work-tree=/home/${user_name}/projects/blog --git-dir=/home/${user_name}/repos/blog.git checkout -f 
EOF

        chmod +x /home/${user_name}/repos/blog.git/post-receive
    "
    echo -e "${green} ${user_name} 用户操作执行完毕"
    chown -R git:git /home/${user_name}/repos/blog.git

    # 账户是否可登录
    read -p "是否允许用户登录 y/n:" login_flag
    if [ -z $login_flag ] || [ $login_flag != "y" ]; then
        usermod -s /usr/sbin/nologin ${user_name}
    fi
}

add_user