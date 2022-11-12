---
title: "caddy-hugo-filebrowser搭建个人网站和后台管理"
date: 2019-09-06T17:40:56+08:00
tags: ["go", "caddy","hugo","filebrowser","网站","docker"]
categories: ["golang"]
---

使用caddy和hugo搭建个人网站

功能：

- 自动https
- 自动响应git hook，运行hugo编译markdown
- 开机启动服务
- docker部署
- 网站后台管理

*假定安装过程在非root用户下* 

## 安装 hugo

```shell
# 链接修改为自己需要的版本
wget https://github.com/gohugoio/hugo/releases/download/v0.56.3/hugo_0.56.3_Linux-64bit.tar.gz
mkdir hugo
tar xvfz hugo_0.56.3_Linux-64bit.tar.gz -C hugo
cp hugo /usr/local/bin/
# 解压后的hugo默认权限为755，如果不是，修改一下权限
sudo chmod 755 /usr/local/bin/hugo
```

## 安装caddy

caddy[下载页面](https://caddyserver.com/download)

[官方文档]https://caddyserver.com/docs

选择git插件让caddy响应github的webhook

### 自动安装

```shell
# 自动安装caddy
curl https://getcaddy.com | bash -s personal http.git
```

### 手动安装
```shell
wget https://caddyserver.com/download/linux/amd64?plugins=http.git&license=personal&telemetry=off

sudo cp /path/to/caddy /usr/local/bin
sudo chown root:root /usr/local/bin/caddy
sudo chmod 755 /usr/local/bin/caddy
```

## 配置caddy

不需要把caddy配置为服务的，请参考[Quick Start](https://caddyserver.com/tutorial)、[Beginner Tutorial](https://caddyserver.com/tutorial/beginner)或[https://github.com/caddyserver/caddy](https://github.com/caddyserver/caddy)，简单快速启动网站服务

linux下使用以下命令允许在非root用户下caddy绑定系统特权端口（e.g. 80, 443）
```shell
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy
或
sudo setcap cap_net_bind_service=+ep $(which caddy)
```

为了安全考虑，caddy不推荐在root用户下运行

### 添加用户

如果组id或用户id重复，可自行选择其他id

```shell
sudo groupadd -g 333 www-data
sudo useradd \
  -g www-data --no-user-group \
  --home-dir /var/www --no-create-home \
  --shell /usr/sbin/nologin \
  --system --uid 333 www-data
```

### Caddyfile

caddy可通过命令参数指定配置项启动运行，也可以通过配置文件启动，caddy的配置文件名称固定为Caddyfile，放置在网站根目录不同网站使用不同的Caddyfile或者放置在/etc/caddy/Caddyfile，多个网站共用同一个Caddyfile

**Caddyfile放置在/etc/caddy/Caddyfile**

```shell
sudo mkdir /etc/caddy
sudo chown -R root:root /etc/caddy

# 复制已有的Caddyfile或新建
sudo cp /path/to/Caddyfile /etc/caddy/
sudo touch /etc/caddy/Caddyfile

sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile
```

Caddyfile配置信息

```shell
example.com {
    root /var/www/website
    log /var/log/caddy/access.log {
        rotate_size 50  # 50M以后轮转
    }
    errors /var/log/caddy/errors.log {
        rotate_size 50  # 50M以后轮转
    }
    git {
        # hugo网站目录托管仓库
        repo https://github.com/githubusername/mysite
        # 使用key 托管仓库可以设置为私有但是要修改key的权限
        # key $HOME/.ssh/id_rsa
        # --recurse-submodules 目录包含有子模块
        clone_args --recurse-submodules
        pull_args --recurse-submodules
        # 放置仓库的路径，相对于网站根目录，默认是网站根目录
        path /var/www/mysite
        # git web hook 路径 口令
        hook /webhook xxxxxx
        # 成功拉取后执行的命令
        then hugo -s /var/www/mysite -d /var/www/website --logFile /var/log/hugo/hugo.log
    }
}

# 重定向www到example.com
www.example.com {
    redir https://example.com{uri}
}
```

### ssl配置信息

```shell
sudo mkdir /etc/ssl/caddy
sudo chown -R root:www-data /etc/ssl/caddy
sudo chmod 0770 /etc/ssl/caddy
```
### 日志文件

```shell
sudo mkdir /var/log/caddy
sudo touch /var/log/caddy/caddy.log
sudo touch /var/log/caddy/access.log

sudo mkdir /var/log/hugo
sudo touch /var/log/hugo/hugo.log

sudo chown -R www-data:www-data /var/log/caddy
sudo chmod -R 0775 /var/log/caddy

sudo chown -R www-data :www-data /var/log/caddy
sudo chmod -R 0775 /var/log/hugo
```

## 配置网站

### 网站根目录
```shell
sudo mkdir /var/www
sudo chown www-data:www-data /var/www
sudo chmod 555 /var/www

# caddy不会自动创建网站根目录 复制已有网站目录到/var/www/或者新建一个根目录
sudo cp -R example.com /var/www/
或
sudo mkdir /var/www/example.com

sudo chown -R www-data:www-data /var/www/example.com
sudo chmod -R 555 /var/www/example.com
```

## 安装caddy为系统服务

**检查系统自启动控制方式**
```shell
# 检查系统自启动方式
Linux系统目前存在的三种系统初始化控制方式，对应的配置文件目录分别为
/usr/lib/systemd systemd方式
/usr/share/upstart Upstart方式
/etc/init.d SysVinit方式（sysvinit 就是 system V 风格的 init 系统）
```
详细介绍三个体系：Sysvinit、Upstart、Systemd

Sysvinit：https://www.ibm.com/developerworks/cn/linux/1407_liuming_init1/index.html

Upstart：https://www.ibm.com/developerworks/cn/linux/1407_liuming_init2/index.html

Systemd：https://www.ibm.com/developerworks/cn/linux/1407_liuming_init3/index.html

### caddy hook.service 插件安装

下载页面选择hook.service插件，该插件没有经过完整的测试，可能存在某些问题。
```shell
curl https://getcaddy.com | bash -s personal hook.service,http.git
```
hook.service的[使用方法](https://github.com/hacdias/caddy-service/blob/master/README.md)：

-name 项指定服务的名称，默认是caddy，如果指定了名字，每次运行`caddy -service`命令时，需要指定服务的名字

使用`caddy -service install`安装会根据不同系统类型自动创建启动配置

**Install a Caddy service:**
```shell
caddy -service install -agree -email myemail@email.com -conf /path/to/Caddyfile [-name optionalServiceName] [-option optionValue]
```
**Uninstall a Caddy service:**
```shell
caddy -service uninstall [-name optionalName]
```
**Start a Caddy service:**
```shell
caddy -service start [-name optionalName]
```
**Stop a Caddy service:**
```shell
caddy -service stop [-name optionalName]
```
**Restart a Caddy service:**
```shell
caddy -service restart [-name optionalName]
```
### upstart 模式安装

CentOS release 6.10 只支持Sysvinit

#### 安装步骤

[Upstart conf for Caddy](https://github.com/caddyserver/caddy/tree/master/dist/init/linux-upstart)

[Running Caddy Server as a service with Upstart](https://denbeke.be/blog/servers/running-caddy-server-as-a-service/)

CentOS 安装问题
```shell
[root@localhost ~]# service caddy start
Starting caddy
/etc/init.d/caddy: line 52: start-stop-daemon: command not found

需要安装start-stop-daemon
https://blog.csdn.net/wh211212/article/details/53523457

安装 start-stop-daemon 又需要
checking for perl >= 5.20.2... configure: error: cannot find perl >= 5.20.2

又需要安装perl
耐心已耗完
正在安装Centos 7 …… ^_^
```

#### 启动运行
```shell
sudo service caddy start|stop|restart
```

### systemd 模式安装

#### 安装步骤

[systemd Service Unit for Caddy](https://github.com/caddyserver/caddy/tree/master/dist/init/linux-systemd)

[Running Caddy Server as a service with systemd](https://denbeke.be/blog/servers/running-caddy-server-as-a-service-with-systemd/)

#### 启动运行
```shell
# 启用服务开机启动
sudo systemctl enable caddy.service

# 关闭服务开机启动
sudo systemctl disable caddy.service

# 启动服务
sudo systemctl start caddy.service

# 重启服务
sudo systemctl restart caddy.service

# 关闭服务
sudo systemctl stop caddy.service
```

### sysvinit 模式安装

暂未尝试

如果启动后出现或其他错误，先使用
```
/usr/local/bin/caddy -conf /etc/caddy/Caddyfile 
查看错误原因
```
```
Nov 11 04:10:30 localhost.localdomain systemd[1]: Started Caddy HTTP/2 web server.
Nov 11 04:10:30 localhost.localdomain systemd[1]: caddy.service: main process exited, code=exited, status=2/INVALIDARGUMENT
Nov 11 04:10:30 localhost.localdomain systemd[1]: Unit caddy.service entered failed state.
Nov 11 04:10:30 localhost.localdomain systemd[1]: caddy.service failed.
```

## filebrowser实现文件浏览和后台管理

官方文档：https://filebrowser.xyz/

### 安装

```sh
curl -fsSL https://filebrowser.xyz/get.sh | bash
filebrowser -r /path/to/your/files
```

### filebrowser配置

参考：https://filebrowser.xyz/cli/filebrowser

filebrowser支持不使用配置直接运行

**指定配置文件**

配置文件的名字必须是`.filebrowser`，扩展名可以是json、toml、yaml、yml四种任意一个

配置文件的路径必须是当前目录、$HOME目录或者/database.db三者之一

### toml配置 物理机部署使用
```toml
# docker filebrowser config file
#log = "/var/log/filebrowser/filebrowser.log"
database = "/etc/filebrowser/filebrowser.db"
# 默认绑定地址是127.0.0.1 只能本机访问 如果外部网络访问 设置为0,0,0,0
address ="0.0.0.0"
port = 9000
root = "/var/filebrowser/mysite"
baseurl = "/manager
```

### json配置 docker使用

[官方docker镜像](https://filebrowser.xyz/installation#docker)的 Dockerfile里filebrowser的配置文件是json类型，docker启动挂载的配置文件也必须是json类型

address必须是0.0.0.0 默认是localhost

```json
{
  "port": 9001,
  "baseURL": "/manager",
  "address": "0.0.0.0",
  "log": "stdout",
  "database": "/database.db",
  "root": "/srv"
}
```

### web配置

#### 配置事件命令

参考：https://filebrowser.xyz/configuration/command-runner

filebrowser启动后可通过web页面修改密码、管理用户权限和指定某个事件后运行命令

Command runner里可以指定以下四个事件发生时执行的命令（不包括Save事件，文件修改后保存执行的是Updload事件）

Copy  
Rename  
Upload  
Delete  
~~Save~~  

如果要使用变量，需设置一下配置

**Global Settings -- Execute on shell**：配置里指定要使用的shell`bash -c`

命令中可以使用filebrowser内置的以下环境变量
```sh
FILE        改动文件的绝对路径
SCOPE       当前用户的用户目录路径
TRIGGER     事件名
USERNAME    当前用户的用户名
DESTINATION 目标位置的绝对路径，只在copy和rename时有效
```

修改文件后执行git推送
```sh
git pull
git add $FILE
git commit -m"add or modify post"
git push
```

默认命令是阻塞执行，如果需要非阻塞运行，在命令前面添加`&`
```sh
&git pull
&git add $FILE
&git commit -m"add or modify post"
&git push
```

**注意：**

filebrowser命令执行时的当前目录是程序启动的目录

如果在docker里运行，工作目录是`/`，需要在[官方Dockerfile](https://github.com/filebrowser/filebrowser/blob/master/Dockerfile)里添加`WORKDIR /path/to/workdir`指定工作目录

为了方便查看修改文件，我直接在文件目录后台运行的filebrowser
```sh
(filebrowser -c /home/ljc/websiteconf/filebrowser.toml > /var/log/filebrowser/filebrowser.log 2>&1 &)
```


### 系统服务

systemd 模式

```sh
[Unit]
Description=File Browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser

[Install]
WantedBy=multi-user.target
```

如果不想使用默认配置文件路径，在`ExecStart=/usr/local/bin/filebrowser`后面通过命令选项指定配置

## docker部署

### caddy+hugo

下载caddy+hugo镜像
```sh
docker pull windzhu0514/caddy-hugo
```

或者从Dockerfile编译
```sh
FROM alpine
MAINTAINER ljc <windzhu0514@163.com>

RUN apk update && \
    apk add git curl bash && \
    curl https://getcaddy.com | bash -s personal http.git && \
    apk add hugo && \
    # hugo not create the log dir,caddy not create access.log dir
    mkdir /var/log/hugo && \
    mkdir /var/log/caddy && \
    apk del curl bash wget

ADD ./Caddyfile /etc/caddy/Caddyfile

EXPOSE 9000

ENTRYPOINT ["caddy","-conf","/etc/caddy/Caddyfile"]
```
启动服务
```sh
sudo docker run -d -p 9000:9000 --name alpine-website-d  windzhu0514/caddy-hugo:0.0.3
```

浏览器输入https://ip:9000访问网站，如果提示`404 Site [ip:port] is not served on this interface`
容器里caddy监听外网无法访问 修改Caddyfile站点地址为`:9000`

### filebrowser

容器中的目录可以不必和例子相同，但是配置文件的路径必须是当前目录、$HOME目录或者/database.db三者之一（参考[.filebrowser ](https://filebrowser.xyz/cli/filebrowser)）

启动filebrowser
```sh
sudo docker run -d --restart=always --name filebrowser \
-v /var/filebrowser/mysite:/srv \
-v /etc/filebrowser/filebrowser.db:/database.db \
-v /etc/filebrowser/.filebrowser.json:/.filebrowser.json \
-p 9001:9001  filebrowser/filebrowser
```

## 代理网站

### 为什么要代理

域名指向中国大陆境内服务器且开通Web服务时需要备案。域名指向中国大陆境外服务器（例如中国香港等大陆境外）不需要备案。首次备案时间需要一周到一个月才能完成，如果更换了服务器，需要修改备案信息。如果手里有境外服务器，域名绑定到境外服务器服务器，如果境外服务器性能较低，可以把网站部署在境内服务器，由境外服务器跳转到境内服务器。

### 代理配置
境外服务器的代理依然使用强大的caddy，配置如下
```sh
ljc.space {
    log /var/log/caddy/access.log {
        rotate_size 50  # 50M以后轮转
    }
    errors /var/log/caddy/errors.log {
        rotate_size 50  # 50M以后轮转
    }
    proxy / https://windzhu0514.github.io
    proxy /elf 国内ip:9200 {
        without /elf
    }

    proxy /elf/ws 国内ip:9200 {
        without /elf
        websocket
    }
}

www.ljc.space {
    redir https://ljc.space{uri}
}
```

### 代理服务开机启动

代理服务启动脚本修改自官方systemd启动脚本：https://github.com/caddyserver/caddy/tree/master/dist/init/linux-systemd

修改的内容：
```shell
修改
StartLimitIntervalSec=14400
StartLimitBurst=10
为
StartLimitInterval=14400
StartLimitBurst=10
并由[Unit]下移到[Service]下

修改
; User and group the process will run as.
User=www-data
Group=www-data
为
; User and group the process will run as.
User=root
Group=root

修改
ReadWritePaths=/etc/ssl/caddy
ReadWriteDirectories=/etc/ssl/caddy
为
;ReadWritePaths=/etc/ssl/caddy
ReadWriteDirectories=/etc/ssl/caddy
```

代理服务开机启动脚本

```shell
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=on-abnormal

; Do not allow the process to be restarted in a tight loop. If the
; process fails to start, something critical needs to be fixed.
StartLimitInterval=14400
StartLimitBurst=10

; User and group the process will run as.
User=root
Group=root

; Letsencrypt-issued certificates will be written to this directory.
Environment=CADDYPATH=/etc/ssl/caddy

; Always set "-root" to something safe in case it gets forgotten in the Caddyfile.
ExecStart=/usr/local/bin/caddy -log stdout -log-timestamps=false -agree=true -conf=/etc/caddy/Caddyfile -root=/var/tmp
ExecReload=/bin/kill -USR1 $MAINPID

; Use graceful shutdown with a reasonable timeout
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

; Limit the number of file descriptors; see `man systemd.exec` for more limit settings.
LimitNOFILE=1048576
; Unmodified caddy is not expected to use more than that.
LimitNPROC=512

; Use private /tmp and /var/tmp, which are discarded after caddy stops.
PrivateTmp=true
; Use a minimal /dev (May bring additional security if switched to 'true', but it may not work on Raspberry Pi's or other devices, so it has been disabled in this dist.)
PrivateDevices=false
; Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
ProtectHome=true
; Make /usr, /boot, /etc and possibly some more folders read-only.
ProtectSystem=full
; 鈥?except /etc/ssl/caddy, because we want Letsencrypt-certificates there.
;   This merely retains r/w access rights, it does not add any new. Must still be writable on the host!
;ReadWritePaths=/etc/ssl/caddy
ReadWriteDirectories=/etc/ssl/caddy

; The following additional security directives only work with systemd v229 or later.
; They further restrict privileges that can be gained by caddy. Uncomment if you like.
; Note that you may have to add capabilities required by any plugins in use.
;CapabilityBoundingSet=CAP_NET_BIND_SERVICE
;AmbientCapabilities=CAP_NET_BIND_SERVICE
;NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```