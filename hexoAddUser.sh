#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'

user_name=git
pass=123456v.

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# 新建git用户
add_user(){
    # 添加用户
    useradd $user_name
    if [ $? -eq 0 ];then
        echo -e "${green}用户名：${user_name} 创建成功"
    else
        echo -e "${red}错误：${user_name} 创建失败\n"
        exit 1
    fi

    # 设置密码
    echo $pass | sudo passwd $user_name --stdin  &>/dev/null
    if [ $? -eq 0 ];then
        echo "${user_name} 密码设置成功"
    else
        echo "${user_name}'密码设置失败"
    fi

    # 切换用户
    su $user_name -c "
        cd /home/git/ 
        mkdir -p projects/blog  
        mkdir repos && cd repos 
        git init --bare blog.git
        cd blog.git/hooks
        touch post-receive

        cat > post-receive <<-EOF
        #!/bin/sh
        git --work-tree=/home/git/projects/blog --git-dir=/home/git/repos/blog.git checkout -f
        EOF

        chmod +x post-receive
    "
    chown -R git:git /home/git/repos/blog.git
}

add_user
