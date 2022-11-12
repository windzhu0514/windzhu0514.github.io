---
title: "git多账户共存"
date: 2019-01-12T22:48:32+08:00
tags: ["git"]
categories: ["git"]
---

## 问题

很多开发者都会遇到在自己的电脑上使用不止一个 git 帐号的情况。一般一个是自己的 github 帐号，另一个则是公司的 git 帐号，比如 gitlab、bitbucket 等。如果采用 https 方式获取仓库，多个 git 帐号间不会有冲突，但在每次 pull、push 的时候都要输入帐号密码，十分麻烦。而且当代码库十分庞大时，如果仍然采用 https 方式，在 git pull 时可能出现超时不响应的情况，此时只能采用 ssh 方式。ssh 在配置完 ssh key 后使用起来很方便，但是 git 帐号间可能出现冲突，这时候该如何解决呢？

配置 ssh key 的方式此处不再赘述，假设在 .ssh 文件夹下有 id_rsa、id_rsa.pub、gitlab_id_rsa、gitlab_id_rsa.pub，分别对应个人 github 帐号私钥公钥以及公司 git 帐号私钥公钥。如果不进行设置，使用 github 账号时没有问题，但是使用公司账号时，由于默认情况下私钥存放在 id_rsa 文件中，因此 git 仍会尝试用 id_rsa 中而不是 gitlab_id_rsa 中的私钥去与服务器上添加的公钥进行比对，自然而然会报错。通常这种情况下 git 会让你输入密码，就算输入正确密码也会报错：Permission denied。

## 解决方法

ssh 的 config 文件：该文件的主要作用是指明各个 git 帐号对应的 User 以及 IdentityFile 的文件位置。Window 系统中，该配置信息存放在名为 config 的文件中，位置在 USERPROFILE/.ssh/目录下，而在 Linux/Unix 系统中配置信息则保存在 ssh_config 文件中，至于位置不同系统有所区别。可以使用以下命令查看文件位置，第二行打印了配置文件的位置。

```bash
$ ssh -vT git@xxxx.com
OpenSSH_7.9p1, OpenSSL 1.1.1a  20 Nov 2018
debug1: Reading configuration data /c/Users/ljc01/.ssh/config
debug1: Reading configuration data /etc/ssh/ssh_config
debug1: Connecting to xxxx.com [52.84.49.177] port 22.
```

以 windows 为例，新建 config 文件，在文件里添加的以下字段

```bash
Host github.com
 hostname github.com
 User <username>
 IdentityFile ~/.ssh/github_rsa

Host git.xxx.com
 hostname git.xxx.com
 User <username>
 IdentityFile ~/.ssh/gitlab_rsa
```

配置完毕后，先取消全局用户名以及邮箱配置，再在各个项目 repo 中应用该项目的用户名以及邮箱：

```bash
1.取消global
git config --global --unset user.name
git config --global --unset user.email

2.设置每个项目repo的自己的用户名以及邮箱
git config user.email "xxxx@xx.com"
git config user.name "xxxx"
```

如此，各个 git 帐号间就可以“井水不犯河水”了。
