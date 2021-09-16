# sh
快速脚本



## hexoAddUser

新建git用户

```
bash <(curl -Ls https://raw.githubusercontent.com/cksspk/sh/master/hexoAddUser.sh)
```

如果是谷歌云服务器，需要修改ssh登录

```
# 待修改文件
vim /etc/ssh/sshd_config 
#修改内容
PasswordAuthentication yes
```

重启ssh服务

```
systemctl restart sshd
```

将本地公钥复制到服务器

```
ssh-copy-id -i ~/.ssh/id_rsa.pub user@server
```

禁止用户在服务器登录

```
usermod -s /usr/sbin/nologin git
```

### 配置Nginx

梭哈版 安装

```
yum install nginx
```

启动

```
systemctl start nginx
```

修改配置

```ß
 #1. 修改顶部user 为root
user root;

#2. 修改server配置
server {
		listen       80;
	    server_name  localhost;
        location / {
    		 #地址修改为项目git仓库地址
             root   /home/git/projects/blog;
             index  index.html index.htm;
         }
 
         error_page   500 502 503 504  /50x.html;
         location = /50x.html {
             root   html;
         }
      }
```

