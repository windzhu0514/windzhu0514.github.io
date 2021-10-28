---
title: "听说你想把windows当作linux用？"
date: 2021-10-28T13:52:45+08:00
tags: ["windows","wsl","linux","ssh","openssh","开发环境"]
categories: ["开发环境"]
---

## 需求
如果你有一台闲置的PC，而且安装了win10或win11，又想把这台PC当做linux服务用，比如做开发机、跑服务。

## 安装前提

1. 从应用商店安装应用，需要使用微软账号进行登录，提前注册号微软账号。
2. 系统必须是windows10或windows11
3. 公司内部网络会限制系统的更新和从应用商店安装应用，联系IT部门开通对应权限。
4. 安装过程计算机需要重启，安装前保存好重要文件

## 安装和启用wsl

wsl2和wsl1区别详见 [比较 WSL 1 和 WSL 2](https://docs.microsoft.com/zh-cn/windows/wsl/compare-versions)

### 开启硬件虚拟化支持

计算机必须支持虚拟化才能安装wsl，不同的主板进入BIOS设置的方式不同，具体参照该主板操作文档。在菜单中找到虚拟化相关设置，开启虚拟化支持。Intel的一般是`Intel Virtual Technology`，简称`IVT`，开启后，在`任务管理器`-`性能`-`CPU`中可以看到虚拟化`已启用`。

### 新版本系统安装wsl

如果系统运行 Windows 10 版本 2004 及更高版本（内部版本 19041 及更高版本）或 Windows 11，可使用新版的[简易安装方法](https://docs.microsoft.com/zh-cn/windows/wsl/install)，自动启用所需的可选组件，下载最新的 Linux 内核，将 WSL 2 设置为默认值，并默认安装 Linux 发行版 Ubuntu。

### 旧版系统安装wsl

旧版系统安装可参照[该文档](https://docs.microsoft.com/zh-cn/windows/wsl/install-manual)进行手动安装

### 使用系统设置启用虚拟机平台和适用于 Linux 的 Windows 子系统功能

- win10

打开`设置` - `应用和功能`，右上角位置`程序和功能` - `启用或关闭Windows功能` - 勾选`适用于Linux的Windows子系统`和`虚拟机平台`，如下图所示

- win11

打开`设置` - `应用`，最下面`更多windows功能` -  勾选`适用于Linux的Windows子系统`和`虚拟机平台`，如下图所示

![](https://cdn.jsdelivr.net/gh/windzhu0514/imagehost@master/images/1635336876812适用于Linux的Windows子系统.png)
![](https://cdn.jsdelivr.net/gh/windzhu0514/imagehost@master/images/1635336917450%E8%99%9A%E6%8B%9F%E6%9C%BA%E5%B9%B3%E5%8F%B0.png)

## wsl安装启用ssh服务

以下命令假设wsl使用`ubuntu`linux发行版
1. 更新wsl的包库` apt update -y && apt upgrade -y`
2. 安装`openssh-server`
```sh
# 搜索openssh-server
$ apt search openssh-server
Sorting... Done
Full Text Search... Done
openssh-server/focal-updates,now 1:8.2p1-4ubuntu0.3 amd64 [installed]
  secure shell (SSH) server, for secure access from remote machines
# 安装 openssh-server
$ sudo apt install openssh-server 
```
3. ssh服务配置调整

配置文件路径为`/etc/ssh/sshd_config`，使用root权限打开文件进行对应修改，`sudo vim /etc/ssh/sshd_config`，如果使用配置默认值，直接进行第4步操作。

4. 启动ssh服务
```sh
# 查看sshd服务状态
sudo service ssh status
# 启动sshd服务
sudo service ssh start
# 停止sshd服务
sudo service ssh sttop
# 重新启动sshd服务
sudo service ssh restart
```
5. 设置wsl ssh服务开机启动

wsl启动时，ssh服务默认不会自动开启，可以手动开启或配置为开机启动。

- 添加wsl用户名为sudo用户，并设置不需要密码
  1. `sudo visudo`打开`/etc/sudoers`文件
  2. 添加以下修改
  ```sh
  root    ALL=(ALL:ALL) ALL
  在上面一行下面添加
  {wsl-username} ALL=(ALL:ALL) NOPASSWD:ALL
  ```
- 在windows系统新建文件`wsl-ssh-start.bat`
- 写入以下命令`wsl sudo service ssh start`
- Win+R打开`运行`，输入`shell:startup`打开启动文件夹，复制文件`wsl-ssh-start.bat`到该文件夹。

## 添加端口映射
wsl的ip在windows系统每次重启后会发生改变，可以在每次重启后使用脚本获取wsl的ip并添加端口映射

1. 新建文件`batch-add-portproxy.ps1`添加以下代码
```sh
# 添加wsl端口转发
$wsl_ip = (wsl hostname -I).trim()
Write-Host "WSL Machine IP: ""$wsl_ip"""
netsh interface portproxy add v4tov4 listenport={对外端口} connectport={wsl-ssh-port} connectaddress=$wsl_ip
```
2. 添加开机启动任务
打开`任务计划程序`，左边列表里选择`任务计划程序库`，右键`创建基本任务`，填写任务名，下一步后选择`计算机启动时`,下一步选择`启动程序`，下一步选择脚本路径，下一步完成。

## 防火墙开放ssh服务的对外端口

windows防火墙默认关闭任何对外端口，局域网访问需要开放端口。
防火墙开放端口：`设置`-`更新和安全`-`Windows安全中心`-`防火墙和网络保护`-`高级设置`-`入站规则`-`新建规则`-`端口`-`下一页`-选择`TCP`和`特定本地端口`，后面填写ssh服务的对外端口-`下一页`-`允许连接`-继续下一页-最后一页填写名称

## 局域网机器ssh连接wsl

```sh
ssh -p {对外端口} wsl-username@windows-ip
```

## 配置ssh公钥登录

公钥登录可参照[Windows OpenSSH 密钥管理](https://docs.microsoft.com/zh-cn/windows-server/administration/openssh/openssh_keymanagement)

## 错误和问题

### wsl使用windows代理

windows cmd运行`ipconfig`，找到本地IP地址，在wsl里设置代理
```sh
export ALL_PROXY="http://{windows-ip}:{代理端口}"
```

### windows安装和启动ssh服务
windows ssh安装和启用参照微软官方文档 [ OpenSSH 入门](https://docs.microsoft.com/zh-cn/windows-server/administration/openssh/openssh_install_firstuse)


在 Windows 中，ssh服务的名称也是`sshd`， 默认从`%ProgramData%\ssh\sshd_config` 中读取配置数据，该文件相当于linux下sshd服务的配置文件·/etc/ssh/sshd_config`。可以修改文件配置ssh服务的端口，认证方式等。

### 使用公钥访问windows ssh服务（非wsl）出现Permission denied 

```sh
$ ssh pc-win-ssh
ljc43026@10.181.24.27: Permission denied (publickey,keyboard-interactive).
```

**问题原因：** windows用户是管理员用户

如果用户是[管理员用户](https://docs.microsoft.com/zh-cn/windows-server/administration/openssh/openssh_keymanagement#administrative-user)，客户端的公钥应该添加到`administrators_authorized_keys`，该文件路径为`%ProgramData%\ssh\administrators_authorized_keys`，并且此文件上的 ACL 需要配置为仅允许访问管理员和系统，设置方法参见[修复administrators_authorized_keys文件权限](https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH#administrators_authorized_keys)。

## 参考资料：
> - [适用于 Linux 的 Windows 子系统文档](https://docs.microsoft.com/zh-cn/windows/wsl/)
> - [解决访问windows ssh服务出现Permission denied](https://github.com/PowerShell/Win32-OpenSSH/issues/1617#issuecomment-637910492)
> - [修复 administrators_authorized_keys  文件的权限](https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH#administrators_authorized_keys)
> - [How to automatically start ssh server on boot on Windows Subsystem for Linux](https://gist.github.com/dentechy/de2be62b55cfd234681921d5a8b6be11)