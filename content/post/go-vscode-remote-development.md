---
title: "VSCode Remote Development-go开发环境搭建"
date: 2019-08-19T18:54:39+08:00
tags: ["go", "ssh"]
categories: ["golang"]
---

## 安装vscode

刚学习go的时候一直使用的vscode开发，轻巧方便。但随着工程代码量增加，本地下载的包越来越多，代码提示和自动补全功能变得越来越慢，就转向了goland神IDE，打开一个工程占用1.5G内存，吓得我赶紧又加了8G内存！！！

正式版的vscode已支持VSCode Remote Development，附上vscode下载地址：[Visual Studio Code下载地址](https://code.visualstudio.com/download)

安装完成，安装[GO](https://marketplace.visualstudio.com/items?itemName=ms-vscode.Go)扩展和[Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)扩展，Remote Development扩展包含了[Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)、[Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)和[Remote - WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)三个扩展，分别用于通过ssh远程连接、连接docker容器和连接[ Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/about)。

## 本机安装ssh客户端

如果安装过git，就不需要再进行安装

具体安装说明参照：[Installing a supported SSH client](https://code.visualstudio.com/docs/remote/troubleshooting#_installing-a-supported-ssh-client)

## Remote - SSH

Remote - SSH已支持系统版本： x86_64 Debian 8+, Ubuntu 16.04+, CentOS / RHEL 7+

正在实验中的支持系统版本：ARMv7l (or ARMv8 in 32-bit mode) Raspbian Stretch/9+ (32-bit) ，这些系统暂时只[Visual Studio Code Insiders](https://code.visualstudio.com/insiders/)提供支持。

具体使用说明参照：[Remote Development using SSH](https://code.visualstudio.com/docs/remote/ssh)

## 使用SSH key认证连接

1. `ctrl+shift+p`或者`菜单-查看-命令面板`，打开命令面板，运行`Remote-SSH: Connect to Host`命令
2. 在弹出的窗口下拉列表里选择`Configure SSH Hosts...`，回车
3. 在列表里选择要使用的SSH配置文件路径，回车
4. 在打开的文件里添加远程机器人的配置
5. 保存后重新运行`Remote-SSH: Connect to Host`命令
6. 在下拉列表里选择远程机器，回车
7. 等待远程机器安装`VS Code Server`，窗口左下角会显示`远程打开中`
8. 连接成功后，打开vscode的资源管理器，点击`打开文件夹`，在弹出的窗口中选择要打开的目录，打开后该目录下的内容会自动同步到文件列表里，欢快的操作吧

配置内容：
```
    Host example-remote-linux-machine-with-identity-file
        User your-user-name-on-host
        HostName another-host-fqdn-or-ip-goes-here
        IdentityFile ~/.ssh/id_rsa-remote-ssh
```

## 使用用户和密码连接

1. `ctrl+shift+p`或者`菜单-查看-命令面板`，打开命令面板，运行`Remote-SSH: Connect to Host`命令
2. 在弹出的窗口中输入用户名@远程机器IP地址：`username@remoteip`，回车
3. 在新打开的窗口的命令面板位置填入远程机器的ssh密码，回车
4. 等待远程机器安装`VS Code Server`，窗口左下角会显示`远程打开中`
5. 连接成功后，打开vscode的资源管理器，点击`打开文件夹`，在弹出的窗口中选择要打开的目录，打开后该目录下的内容会自动同步到文件列表里，欢快的操作吧

也可以把用户名和远程机器配置在SSH配置文件里，连接时选择要连接的Host，回车输入密码就可以了
```sh
Host example-remote-linux-machine
    User your-user-name-here
    HostName host-fqdn-or-ip-goes-here
```

## 安装扩展到远程机器

给远程机器安装的扩展，需要先安装到本地，然后在扩展列表里点击`Install in SSH:xxx`，安装到远程机器

## 安装go tool到远程机器

1. `ctrl+shift+p`或者`菜单-查看-命令面板`，打开命令面板，运行`Go:Install/Update Tools`命令
2. 在弹出的下拉列表里选择要安装的go tools
3. 点击`确定`开始安装
4. 安装完成后，欢快的操作吧

如果远程服务没有go程序，安装的go tools会先下载到本地，再传送到远程机器，部分go tools需要翻墙安装，只需设置本地代理即可。

## 问题及解决方法

- 连接远程终端时出现一下错误

```shell
Received install output: 16dc5c4c-c0ba-4e71-ae2b-9f44cbe3258d##25##
Server download failed
Downloading VS Code Server failed. Please try again later.
```
远端机器无法下载VS Code Server，可能网速太慢（大概有100多M）或者网络不通
vscode github issues：https://github.com/microsoft/vscode-remote-release/issues/78

解决方法：

1 复制其他可用机器上的.vscode-server文件夹到用户目录下

2 设置代理参照一下链接：
https://github.com/Microsoft/vscode-remote-release/issues/78#issuecomment-491229576

## 参考资料

[VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)