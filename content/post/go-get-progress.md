---
title: "go get添加进度"
date: 2018-11-30T14:50:56+08:00
draft: false
tags: ["go", "git"]
categories: ["golang"]
---

go get 比较大的包时会很慢, 可能几分钟或更长, 让人误以为卡死了.
修改 go 源码包，让 go get 显示进度。

1. **修改 git clone 命令, 添加 --progress 选项, 使其输出进度**
   找到如下代码, createdCmd 字段值修改为 clone --progress {repo} {dir}
   其它命令 hg, svn...添加进度方法类似

```go
// vcsGit describes how to use Git.
var vcsGit = &vcsCmd{
	name: "Git",
	cmd:  "git",
	createCmd:   "clone {repo} {dir}", // 此处修改为 clone --progress {repo} {dir}
	downloadCmd: "pull --ff-only"
}
```

2.  修改 cmd.Run()执行的地方, 将输出定位到标准输出流上
    找到 run1()方法, 在 cmd.Stderr = &buf 下添加两行, 如:

        var buf bytes.Buffer
        cmd.Stdout = &buf
        cmd.Stderr = &buf
        cmd.Stdout = os.Stdout // 重定向标准输出
        cmd.Stderr = os.Stderr // 重定向标准输出
        err = cmd.Run()

3.执行 golang 源码 src 下的 all.bash 重新编译 golang, 编译要些时间, 编译完后使用 go get 会显示拉取进度
