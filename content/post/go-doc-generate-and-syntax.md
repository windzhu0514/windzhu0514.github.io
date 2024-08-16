---
title: "golang源码生成文档及注释语法"
date: 2024-08-16T11:17:50+08:00
draft: false
tags: ["go", "doc"]
categories: ["golang"]
toc: true
---

> go version: 1.22.6

## godoc

**已弃用**：`godoc` 无法选择要显示的包版本，由 golang.org/x/pkgsite/cmd/pkgsite 替代。

`godoc` 提取 Go 代码里的注释生成网页的形式的 Go 程序文档

默认情况下，`godoc` 通过 `$GOROOT` 和 `$GOPATH`（如果设置了两个环境变量）查找包。
可以通过使用 `-goroot` 标志指定查找路径。

`-index` 标志开启自动定时更新索引，索引会在启动时创建一次。

索引信息包含标识符和全文搜索信息（可通过正则表达式搜索）。 可以使用 `-maxresults` 标志设置显示的全文搜索结果的最大数量；如果设置为 0，则不显示全文结果，并且只创建标识符索引，不创建全文搜索索引。

默认情况下，godoc 使用系统的 GOOS/GOARCH。 可以通过 URL 参数 `GOOS` 和 `GOARCH` 设置目标系统网页上的输出。

通过 URL 参数 `m` 可以控制网页的显示模式，参数值是逗号分割的标志名：

```bash
all 显示所有标识符的文档，而不只是导出的标识符
methods 显示所有的嵌入方法，而不只是未导出的匿名字段的方法
src 显示原始源代码而不是生成的文档
flat 显示全路径的不缩进的目录列表
```

> 这些标记在go官方文档上不生效

`m=flat` 未添加和添加后的区别

![image-20240815172843359](https://raw.githubusercontent.com/windzhu0514/imagehost/master/images/1723713878532.jpg)![image-20240815172843359](https://raw.githubusercontent.com/windzhu0514/imagehost/master/images/image-20240815172843359.png)

默认情况下，godoc 使用操作系统的文件系统提供文件服务。 另外也可以通过 `-zip` 标志提供 `.zip` 文件提供文件服务，其中包含要使用的文件系统。 `.zip` 文件中存储的文件路径必须使用正斜杠（'`/`'）作为路径分隔符；并且它们必须没有根路径。 `$GOROOT`（或 `-goroot`）必须设置为包含 `Go root` 目录的 .zip 文件目录路径。 例如，对于通过以下命令创建的 `.zip` 文件：

```bash
zip -r go.zip $HOME/go
```

可以按以下方式运行 godoc：

```bash
godoc -http=:6060 -zip=go.zip -goroot=$HOME/go
```

godoc 使用 `go/doc` 包把注释转换为 HTML 或文本；详细规则请参阅 [ToHTML](https://golang.org/pkg/go/doc/#ToHTML)
godoc 还显示可由测试包运行的示例代码；有关约定请参阅 [hdr-Examples](https://golang.org/pkg/testing/#hdr-Examples)

### 安装命令

```bash
go install golang.org/x/tools/cmd/godoc@latest
```

### 命令参数说明

```bash
$ godoc -h      
usage: godoc -http=localhost:6060 
  -goroot string
        Go root directory (default "/usr/local/go") 
		// go安装目录
  -http string
        HTTP service address (default "localhost:6060") 
		// HTTP服务地址 :6060
  -index
        enable search index 
		// 启用全文搜索索引，支持搜索
  -index_files string
        glob pattern specifying index files; if not empty, the index is read from these files in sorted order
		// glob模式指定索引信息保存的位置，索引建立后会写入这些文件；如果不为空，启动时按文件名增序读取索引信息
  -index_interval duration
        interval of indexing; 0 for default (5m), negative to only index once at startup
		// 索引更新间隔。不设置默认为5分钟，负值表示只在启动时更新。
  -index_throttle float
        index throttle value; 0.0 = no time allocated, 1.0 = full throttle (default 0.75)
		// 控制索引建立的速度；范围为[0,1]，默认为0.75；避免占用过高的CPU
  -links
        link identifiers to their declarations (default true)
		// 为标识符（变量、结构体、基础数据类型、函数接收器、函数参数和返回值）生成跳转到声明的链接
  -maxresults int
        maximum number of full text search results shown (default 10000) 
		// 展示的全文搜索结果最大数量
  -notes string
        regular expression matching note markers to show (default "BUG")
		// 匹配注释标记的正则表达式，MARKER(uid)
  -play
        enable playground 
		// 启用playground，向https://play.golang.org服务发送代码
  -templates string
        load templates/JS/CSS from disk in this directory
		// 指定templates/JS/CSS加载的目录，默认使用打包到程序里的文件
  -timestamps
        show timestamps with directory listings 
		// 显示目录的索引更新时间
		// Last update: 2024-08-06 15:57:05.065391466 +0800 CST m=+0.105469304
  -url string
        print HTML for named URL
		// 在控制台打印该地址返回的网页内容然后退出程序
  -v    verbose mode // 输出详细日志
  -write_index
        write index to a file; the file name must be specified with -index_files
		// 把索引信息写入文件；由index_files指定写入的文件名
  -zip string
        zip file providing the file system to serve; disabled if empty
		// 使用zip文件文件系统，为空则使用默认文件系统
```

## pkgsite

pkgsite 提取 Go 代码里的注释生成网页的形式的 Go 程序文档

不指定参数的情况，`pkgsite` 展示相对于当前目录的主模块的文档，也就是 `go list -m` 命令返回的模块。通常也是父级目录中离当前目录最近的 `go.mod` 文件中定义的模块名。

使用 `go.work` 定义工作空间情况下，`pkgsite` 生成工作空间下多个模块的文档。以下两种命令形式都可以生成定义在 `repos/cue/go.mod` 文件中的模块的文档：

```bash
# 单模块形式
cd repos/cue && pkgsite
# 多模块形式
go work init repos/cue repos/other && pkgsite
```

默认情况，`pkgsite` 生成模块的所有依赖包的文档。可通过 `-list=false` 参数禁用。

`pkgsite` 可以直接从本地的模块缓存目录（/home/ljc/go/pkg/mod/）查找模块和生成文档，默认使用环境变量里配置的GOPROXY。等同于以下命令：

```bash
pkgsite -cache -proxy
```

使用 `-cache` 或 `-proxy`，`kgsite `时不会在当前目录中查找模块。但是可以在参数里指定本地模块的路径：

```bash
pkgsite -cache -proxy ~/repos/cue some/other/module
```

同时也会生成标准库的文档，`pkgsite` 从 https://go.googlesource.com/go 下载 go 最新版本的源码到临时目录，然后生成标准库的文档。这个过程会有点慢，可以通过`gorepo` 参数指定本地已安装的go标准库路径。

### 安装命令

```bash
go install golang.org/x/pkgsite/cmd/pkgsite@latest
```

### 命令参数说明

```bash
$ pkgsite -h                
usage: pkgsite [flags] [PATHS ...]
    where each PATHS is a single path or a comma-separated list
	# PATHS 是单个路径或逗号分隔的路径列表。代表要生成文档的模块路径
    (default is current directory if neither -cache nor -proxy is provided)
	# 如果-cache和-proxy都不设置，默认是当前目录
  -cache
        fetch from the module cache
		# 从本地模块缓存中加载模块
  -cachedir go env GOMODCACHE
        module cache directory (defaults to go env GOMODCACHE)
		# 模块缓存目录
  -dev
        enable developer mode (reload templates on each page load, serve non-minified JS/CSS, etc.)
		# 开发者模式，用于网站开发调试。页面每次加载时都重新加载母版文件，返回未压缩的JS/CSS文件
  -gopath_mode
        assume that local modules' Paths are relative to GOPATH/src
 		# 在GOPATH/src目录下查找模块
  -gorepo string
        path to Go repo on local filesystem
		# 本地go仓库目录，通常可以用本地go安装目录，$GOROOT
  -http string
        HTTP service address to listen for incoming requests on (default "localhost:8080")
		# 文档服务的http服务监听地址
  -list
        for each path, serve all modules in build list (default true)
		# 生成编译列表里的所有包的文档（编译列表：go build时编译的所有包及模块和模块的依赖包）
  -open
        open a browser window to the server's address
		# 自动在浏览器中打开文档页面
  -proxy
        fetch from GOPROXY if not found locally
		# 从GOPROXY环境变量设置的go包代理（https://goproxy.cn/、https://goproxy.io/）拉取包，不再从本地查找
  -static string
        path to folder containing static files served (default "static")
		# 自定义静态文件路径
```

### 启动命令

```bash
cd ~/WorkspaceGo/GS-util/gocore
pkgsite -http :6060
```

## 注释规则

### 注释语法

Go 文档注释以简单的语法编写，支持段落、标题、链接、列表和预格式化代码块。为了使源文件中的注释保持轻量级和可读性，不支持字体更改或原始 HTML 等复杂功能。 可以将语法视为 Markdown 语法的简化子集。

标准格式化程序 `gofmt` 以规范的格式重新格式化文档注释。 `gofmt` 的目标是提高源代码中注释的可读性和控制注释的书写方式，会调整展示格式以使特定注释的语义更清晰，如：将1+2 * 3重新格式化为1 + 2*3 。

`gofmt` 删除文档注释中的前部和尾部空白行。如果文档注释中的所有行都以相同的空格和制表符开头，则 `gofmt` 会自动删除该前缀。

类型、变量、常量、函数，包都可以通过在声明的前面写注释的方法生成文档（中间不要有空行）。

#### **段落**

多个相邻的注释行，生成文档时被视为一个段落（忽略行尾的换行符），Gofmt 保留段落文本中的换行符，如果想要生成多个段落，使用**空注释**行来分割段落。

单行注释方式的空行分割

```go
// Package io provides basic interfaces to I/O primitives.
// Its primary job is to wrap existing implementations of such primitives,
// such as those in package os, into shared public interfaces that
// abstract the functionality, plus some other related primitives.
//
// Because these interfaces and primitives wrap lower-level operations with
// various implementations, unless otherwise informed clients should not
// assume they are safe for parallel execution.
package io
```

多行注释方式的空行分割

```go
/*
Package fmt implements formatted I/O with functions analogous
to C's printf and scanf.  The format 'verbs' are derived from C's but
are simpler.

# Printing

The verbs:

General:

	%v	the value in a default format
		when printing structs, the plus flag (%+v) adds field names
	%#v	a Go-syntax representation of the value
	%T	a Go-syntax representation of the type of the value
	%%	a literal percent sign; consumes no value

Boolean:

	%t	the word true or false
*/
package fmt
```

#### **标题**

标题是以# (U+0023)开头，然后空格加标题文本的行。该行必须不能缩进，并用空行与相邻段落文本分开。

标题语法在 Go 1.19 中添加。在 Go 1.19 之前，标题是通过满足某些条件的单行段落隐式标识的，最明显的是句尾没有任何终止标点符号（逗号句号分号）。

#### **链接**

##### **网页链接**

网页链接注释是一段格式为 `[Text]: URL`，没有缩进的注释行组成，多行之间没有空行。

识别为 URL 的注释文本在网页中显示为链接。

每个注释块内的链接定义都是独立，不会影响其他注释块。

同一个注释块内其他的注释文本中可以用 `[Text]` 格式来使用定义的链接。在网页源码中表示为：`<a href=“URL”>Text</a>`；被使用的链接注释和未被使用的链接注释会被 `gofmt` 分开，如 `archive/zip` 包的注释：

```go
/*
Package zip provides support for reading and writing ZIP archives.

See the [ZIP specification] for details.

This package does not support disk spanning.

A note about ZIP64:

To be backwards compatible the FileHeader has both 32 and 64 bit Size
fields. The 64 bit fields will always contain the correct value and
for normal archives both fields will be the same. For files requiring
the ZIP64 format the 32 bit fields will be 0xffffffff and the 64 bit
fields must be used instead.

[ZIP specification]: https://www.pkware.com/appnote

[ZIP2 specification]: https://www.pkware.com/appnote
[ZIP3 specification]: https://www.pkware.com/appnote
*/
package zip

import (
    "io/fs"
    "path"
    "time"
)
```

文档展示效果

  ![image-20240815174559174](https://raw.githubusercontent.com/windzhu0514/imagehost/master/images/image-20240815174559174.png)

##### **文档链接**

仅包含方括号的链接用来定义文档链接。

`[Name1]` 或 `[Name1.Name2]` 格式用于引用当前文档里的标识符

```go
// Package path implements utility routines for manipulating slash-separated
// paths.
//
// The path package should only be used for paths separated by forward
// slashes, such as the paths in URLs. This package does not deal with
// Windows paths with drive letters or backslashes; to manipulate
// operating system paths, use the [path/filepath] package.
package path
```

文档页面显示样式

 ![image-20240815174656164](https://raw.githubusercontent.com/windzhu0514/imagehost/master/images/image-20240815174656164.png)

`[pkg]`、`[pkg.Name1]` 或者 `[pkg.Name1.Name2]` 格式用于引用其他包中的标识符。

当引用其他包时，`pkg` 可以是完整的包导入路径，也可以是重命名后的包的别名。

例如，如果当前包导入 `encoding/json`，则可以使用 `[json.Decoder]` 来代替 `[encoding/json.Decoder]` 来链接到 `encoding/json` 的文档。

只有当 `pkg` 是域名或者是标准库里的包名时，才被识别为完整路径导入。例如， `[os.File]` 和 `[example.com/sys.File]` 是文档链接，但 `[os/sys.File]` 不是，因为标准库中没有 `os/sys` 包。

为了和map、泛型和数组类型定义进行区分，文档链接的前后必须有标点符号、空格、制表符或行开头和结尾。例如：`map[ast.Expr]TypeAndValue` 不会被识别为文档链接。

符号链接的括号内文本可以包含可选的星号（`*`）前缀，用于创建引用指针类型的符号链接，例如: `[*bytes.Buffer]`。

#### **列表**

列表是一段缩进行或空行，以第一个有无序列表标记或有序列表标记开头的缩进行为开始。

无序列表标记是星号、加号、破折号或 Unicode 项目符号（`*、+、-、•；U+002A、U+002B、U+002D、U+2022`），后跟空格或制表符，然后是文本。在无序符号列表中，以无序列表标记开头的每一行都作为一个列表项。

```go
package url

// PublicSuffixList provides the public suffix of a domain. For example:
//   - the public suffix of "example.com" is "com",
//   - the public suffix of "foo1.foo2.foo3.co.uk" is "co.uk", and
//   - the public suffix of "bar.pvt.k12.ma.us" is "pvt.k12.ma.us".
//
// Implementations of PublicSuffixList must be safe for concurrent use by
// multiple goroutines.
//
// An implementation that always returns "" is valid and may be useful for
// testing but it is not secure: it means that the HTTP server for foo.com can
// set a cookie for bar.com.
//
// A public suffix list implementation is in the package
// golang.org/x/net/publicsuffix.
type PublicSuffixList interface {
    ...
}
```

有序列表标记是十进制数字后跟句点或右括号，然后是空格或制表符，然后是文本。

```go
package path

// Clean returns the shortest path name equivalent to path
// by purely lexical processing. It applies the following rules
// iteratively until no further processing can be done:
//
//  1. Replace multiple slashes with a single slash.
//  2. Eliminate each . path name element (the current directory).
//  3. Eliminate each inner .. path name element (the parent directory)
//     along with the non-.. element that precedes it.
//  4. Eliminate .. elements that begin a rooted path:
//     that is, replace "/.." by "/" at the beginning of a path.
//
// The returned path ends in a slash only if it is the root "/".
//
// If the result of this process is an empty string, Clean
// returns the string ".".
//
// See also Rob Pike, “[Lexical File Names in Plan 9].”
//
// [Lexical File Names in Plan 9]: https://9p.io/sys/doc/lexnames.html
func Clean(path string) string {
    ...
}
```

列表项中只能包含段落，不能包含代码块或嵌套列表。

`gofmt` 格式化无序列表时，使用短横线（`-`）作为列表符号标记，在短横线之前使用两个空格的缩进，连续的换行使用四个空格的缩进。格式化有序列表时，在数字前加一个空格，在数字后使用句点（`.`），连续的换行使用四个空格的缩进。不强制要求列表前必须有空行，如果有空行会保留。列表后面会强制插入一个空行。

#### **代码块**

代码块是注释中一段连续的缩进行或空行。生成文档时渲染为预格式化文本（网页中的 `<pre>` 块）。例如：

```
package sort

// Search uses binary search...
//
// As a more whimsical example, this program guesses your number:
//
//  func GuessingGame() {
//      var s string
//      fmt.Printf("Pick an integer from 0 to 100.\n")
//      answer := sort.Search(100, func(i int) bool {
//          fmt.Printf("Is your number <= %d? ", i)
//          fmt.Scanf("%s", &s)
//          return s != "" && s[0] == 'y'
//      })
//      fmt.Printf("Your number is %d.\n", answer)
//  }
func Search(n int, f func(int) bool) int {
    ...
}
```

除了代码之外，代码块还可以包含预先格式化的文本

```
package path

// Match reports whether name matches the shell pattern.
// The pattern syntax is:
//
//  pattern:
//      { term }
//  term:
//      '*'         matches any sequence of non-/ characters
//      '?'         matches any single non-/ character
//      '[' [ '^' ] { character-range } ']'
//                  character class (must be non-empty)
//      c           matches character c (c != '*', '?', '\\', '[')
//      '\\' c      matches character c
//
//  character-range:
//      c           matches character c (c != '\\', '-', ']')
//      '\\' c      matches character c
//      lo '-' hi   matches character c for lo <= c <= hi
//
// Match requires pattern to match all of name, not just a substring.
// The only possible returned error is [ErrBadPattern], when pattern
// is malformed.
func Match(pattern, name string) (matched bool, err error) {
    ...
}
```

网页文档效果如下：

![image-20240815194144224](https://raw.githubusercontent.com/windzhu0514/imagehost/master/images/image-20240815194144224.png)

`gofmt` 使用单个制表符缩进代码块中的所有行，替换和非空行共有的任何其他缩进，并且在每个代码块前后插入一个空行，将代码块与周围的段落文本区分开。

### **包注释**

包注释以 `Package xxx`  格式开头，`xxx` 是要注释的包的包名。

每个包都应该有一个介绍该包的包注释。

```go
// Package sort provides primitives for sorting slices and user-defined
// collections.
package sort
```

包注释文本比较长时可以单独的放在命名未为 `doc.go` 文件中，文件中仅包含包注释和包声明语句，如：[sort package - sort - Go Packages](https://pkg.go.dev/sort)

包注释通常写在包的主文件里，不用每个文件都写。如果多个文件有包注释，它们将被连接起来形成整个包的注释。

包注释的第一句话会出现在文档里包列表页面，如：[Standard library - Go Packages](https://pkg.go.dev/std)

生成文档时会忽略和包注释不相邻的其他顶级注释（包级别的注释），以 `BUG(who)` 开头的除外。`BUG(who)` 开头的注释可以出现在源码里的任何位置，都会显示在文档页面 `Bugs` 区域。如：[net package - net - Go Packages](https://pkg.go.dev/net@go1.22.6#pkg-note-BUG)

### **命令包注释**

命令的包的注释和普通包注释类似，但它描述的是程序的行为而不是包中的标识符的含义。第一个句注释通常以程序本身的名称开头（位于句子的开头所以首字母大写）。例如，以下是 `gofmt` 程序注释的删减版：

```go
/*
Gofmt formats Go programs.
It uses tabs for indentation and blanks for alignment.
Alignment assumes that an editor is using a fixed-width font.

Without an explicit path, it processes the standard input. Given a file,
it operates on that file; given a directory, it operates on all .go files in
that directory, recursively. (Files starting with a period are ignored.)
By default, gofmt prints the reformatted sources to standard output.

Usage:

    gofmt [flags] [path ...]

The flags are:

    -d
        Do not print reformatted sources to standard output.
        If a file's formatting is different than gofmt's, print diffs
        to standard output.
    -w
        Do not print reformatted sources to standard output.
        If a file's formatting is different from gofmt's, overwrite it
        with gofmt's version. If an error occurred during overwriting,
        the original file is restored from an automatic backup.

When gofmt reads from standard input, it accepts either a full Go program
or a program fragment. A program fragment must be a syntactically
valid declaration list, statement list, or expression. When formatting
such a fragment, gofmt preserves leading indentation as well as leading
and trailing spaces, so that individual sections of a Go program can be
formatted by piping them through gofmt.
*/
package main
```

注释的开头三行是使用[语义换行](https://rhodesmill.org/brandon/2012/one-sentence-per-line/)模式编写，每个新句子或长短语单独占一行，随着后期代码的改动和新注释的添加，不同行的差异会更容易区分。后面的段落没有遵循这个约定。不论哪种方式， `go doc` 和 `pkgsite` 在生成文档时都会重新进行排版。例如：

```go
$ go doc gofmt
Gofmt formats Go programs. It uses tabs for indentation and blanks for
alignment. Alignment assumes that an editor is using a fixed-width font.

Without an explicit path, it processes the standard input. Given a file, it
operates on that file; given a directory, it operates on all .go files in that
directory, recursively. (Files starting with a period are ignored.) By default,
gofmt prints the reformatted sources to standard output.

Usage:

    gofmt [flags] [path ...]

The flags are:

    -d
        Do not print reformatted sources to standard output.
        If a file's formatting is different than gofmt's, print diffs
        to standard output.
...
```

### **标识符注释**

注释开头的单词以被注释的标识符的名称开头（包注释除外）

#### **类型注释**

类型的文档注释应该解释该类型的每个实例代表或提供什么功能。例如：

```go
package regexp

// Regexp is the representation of a compiled regular expression.
// A Regexp is safe for concurrent use by multiple goroutines,
// except for configuration methods, such as Longest.
type Regexp struct {
    ...
}
```

默认情况下假设类型都不支持并发操作，如果支持，最好在注释里说明:

```go
package regexp

// Regexp is the representation of a compiled regular expression.
// A Regexp is safe for concurrent use by multiple goroutines,
// except for configuration methods, such as Longest.
type Regexp struct {
    ...
}
```

类型还应该尽量使零值具有有用的含义。如果零值的含义不明显，最好在注释里说明：

```go
package bytes

// A Buffer is a variable-sized buffer of bytes with Read and Write methods.
// The zero value for Buffer is an empty buffer ready to use.
type Buffer struct {
    ...
}
```

具有导出字段的类型，文档注释或每个字段的注释应该解释每个导出字段的含义。例如：

```go
// 类型的注释详细描述类型的功能
package io

// A LimitedReader reads from R but limits the amount of
// data returned to just N bytes. Each call to Read
// updates N to reflect the new amount remaining.
// Read returns EOF when N <= 0.
type LimitedReader struct {
    R   Reader // underlying reader
    N   int64  // max bytes remaining
}

// 类型的部分注释在每个字段的注释中
package comment

// A Printer is a doc comment printer.
// The fields in the struct can be filled in before calling
// any of the printing methods
// in order to customize the details of the printing process.
type Printer struct {
    // HeadingLevel is the nesting level used for
    // HTML and Markdown headings.
    // If HeadingLevel is zero, it defaults to level 3,
    // meaning to use <h3> and ###.
    HeadingLevel int
    ...
}
```

#### **函数和方法注释**

函数的注释应该解释该函数的作用、入参和返参的含义。命名参数可以直接在注释中引用，无需任何特殊语法（不用加上反引号）。 

```go
package strconv

// Quote returns a double-quoted Go string literal representing s.
// The returned string uses Go escape sequences (\t, \n, \xFF, \u0100)
// for control characters and non-printable characters as defined by IsPrint.
func Quote(s string) string {
    ...
}

package os

// Exit causes the current program to exit with the given status code.
// Conventionally, code zero indicates success, non-zero an error.
// The program terminates immediately; deferred functions are not run.
//
// For portability, the status code should be in the range [0, 125].
func Exit(code int) {
    ...
}
```

返回布尔值的函数注释通常是 `reports whether` 格式：

```go
package strings

// HasPrefix reports whether the string s begins with prefix.
func HasPrefix(s, prefix string) bool
```

给函数添加命名返回值，并在注释里进行引用，可以使注释更加清晰和容易理解，即使命名返回值在函数中未使用到。

```go
package io

// Copy copies from src to dst until either EOF is reached
// on src or an error occurs. It returns the total number of bytes
// written and the first error encountered while copying, if any.
//
// A successful Copy returns err == nil, not err == EOF.
// Because Copy is defined to read from src until EOF, it does
// not treat an EOF from Read as an error to be reported.
func Copy(dst Writer, src Reader) (n int64, err error) {
    ...
}
```

默认情况下假设函数和方法都不支持并发操作，如果支持，最好在注释里说明:

```
package sql

// Close returns the connection to the connection pool.
// All operations after a Close will return with ErrConnDone.
// Close is safe to call concurrently with other operations and will
// block until all other operations finish. It may be useful to first
// cancel any used context and then call Close directly after.
func (c *Conn) Close() error {
    ...
}
```

给函数或方法添加 Locked 后缀表示该函数或方法是并发安全的或者调用该函数或方法时需要加锁。

```go
// prepareOnConnLocked prepares the query in Stmt s on dc and adds it to the list of
// open connStmt on the statement. It assumes the caller is holding the lock on dc.
func (s *Stmt) prepareOnConnLocked(ctx context.Context, dc *driverConn) (*driverStmt, error) {
    si, err := dc.prepareLocked(ctx, s.cg, s.query)
    if err != nil {
        return nil, err
    }
    cs := connStmt{dc, si}
    s.mu.Lock()
    s.css = append(s.css, cs)
    s.mu.Unlock()
    return cs.ds, nil
}

// lasterrOrErrLocked returns either lasterr or the provided err.
// rs.closemu must be read-locked.
func (rs *Rows) lasterrOrErrLocked(err error) error {
    if rs.lasterr != nil && rs.lasterr != io.EOF {
        return rs.lasterr
    }
    return err
}
```

函数或方法的特殊情况需要在注释里说明

```go
package math

// Sqrt returns the square root of x.
//
// Special cases are:
//
//  Sqrt(+Inf) = +Inf
//  Sqrt(±0) = ±0
//  Sqrt(x < 0) = NaN
//  Sqrt(NaN) = NaN
func Sqrt(x float64) float64 {
```

函数或方法的注释通常不需要解释内部的详细实现，详细实现的注释应该在函数或方法体内。而且将来改变内部实现时不用修改函数或方法的文档。

#### **常量注释**

Go 语法允许对声明进行分组，通过一段注释就可以描述一组相关的常量，也可以单独注释不同的常量。

```go
package scanner // import "text/scanner"

// The result of Scan is one of these tokens or a Unicode character.
const (
    EOF = -(iota + 1)
    Ident
    Int
    Float
    Char
    ...
)


package unicode // import "unicode"

const (
    MaxRune         = '\U0010FFFF' // maximum valid Unicode code point.
    ReplacementChar = '\uFFFD'     // represents invalid code points.
    MaxASCII        = '\u007F'     // maximum ASCII value.
    MaxLatin1       = '\u00FF'     // maximum Latin-1 value.
)
```

未分组的常量需要添加以常量名开头的注释

```go
package unicode

// Version is the Unicode edition from which the tables are derived.
const Version = "13.0.0"
```

类型常量的声明通常放在类型常量的类型定义之后，这种情况一般省略类型常量或类型常量组的注释，直接使用常量类型的注释。

```go
package syntax

// An Op is a single regular expression operator.
type Op uint8

const (
    OpNoMatch        Op = 1 + iota // matches no strings
    OpEmptyMatch                   // matches empty string
    OpLiteral                      // matches Runes sequence
    OpCharClass                    // matches Runes interpreted as range pair list
    OpAnyCharNotNL                 // matches any character except newline
    ...
)
```

**变量注释**

变量注释和常量注释格式相同，以下是组变量和单个变量的注释格式：

```go
package fs

// Generic file system errors.
// Errors returned by file systems can be tested against these errors
// using errors.Is.
var (
    ErrInvalid    = errInvalid()    // "invalid argument"
    ErrPermission = errPermission() // "permission denied"
    ErrExist      = errExist()      // "file already exists"
    ErrNotExist   = errNotExist()   // "file does not exist"
    ErrClosed     = errClosed()     // "file already closed"
)

package unicode

// Scripts is the set of Unicode script tables.
var Scripts = map[string]*RangeTable{
    "Adlam":                  Adlam,
    "Ahom":                   Ahom,
    "Anatolian_Hieroglyphs":  Anatolian_Hieroglyphs,
    "Arabic":                 Arabic,
    "Armenian":               Armenian,
    ...
}
```

### 注释标记

### Bug标记

`BUG(r)`：该标记记录一个确认的BUG信息，`r` 是可以提供更多相关信息的人的用户名

通常格式为：

```
// BUG(rsc): FieldByName and related functions consider struct field names to be equal
// BUG(rsc,mikio): On DragonFly BSD and OpenBSD, listening on the
```

文档生成时的匹配标记的正则表达式：

```
// 匹配所有MARKER(uid)格式的注释，再过滤BUG开头的
var (
	noteMarker    = `([A-Z][A-Z]+)\(([^)]+)\):?`                // MARKER(uid), MARKER at least 2 chars, uid at least 1 char
	noteMarkerRx  = lazyregexp.New(`^[ \t]*` + noteMarker)      // MARKER(uid) at text start
	noteCommentRx = lazyregexp.New(`^/[/*][ \t]*` + noteMarker) // MARKER(uid) at comment start
)
```

必须以 `BUG(xxx)` 格式开头 ，冒号 `:` 及其之后的格式没要求

### Deprecated标记

`Deprecated:` 该标记记录结构体成员字段、函数、类型或者包已被弃用，但是保留下来保持向后兼容。

通常格式为：

```
// Title treats s as UTF-8-encoded bytes and returns a copy with all Unicode letters that begin
// words mapped to their title case.
//
// Deprecated: The rule Title uses for word boundaries does not handle Unicode
// punctuation properly. Use golang.org/x/text/cases instead.
func Title(s []byte) []byte {
	// Use a closure here to remember state.
	// Hackish but effective. Depends on Map scanning in order and calling
	// the closure once per rune.
	prev := ' '
	return Map(
		func(r rune) rune {
			if isSeparator(prev) {
				prev = r
				return unicode.ToTitle(r)
			}
			prev = r
			return r
		},
		s)
}
```

文档生成时的匹配标记的正则表达式：

```
var deprecatedRx = regexp.MustCompile(`(^|\n\s*\n)\s*Deprecated:`)
```

## Example函数

`Example` 函数的注释会和注释的标识符的文档显示在一起，包级别的 `Example` 函数会显示在包注释后面。如 [tar package - archive/tar - Go Packages](https://pkg.go.dev/archive/tar@go1.22.6)

`Example` 函数必须定义在后缀为 `_test.go` 文件中，函数名以 `Example` 开头，并且不需要任何参数。

godoc 通过实例函数的函数名命名约定将示例函数与包级标识符相关联。

类型或者方法的示例函数会和该类型或方法的文档显示在一起。

```
func ExampleFoo()     // Foo函数或者Foo类型的示例
func ExampleBar_Qux() // Bar类型的Qux方法的示例 
func Example()        // 包级别的示例
```

可以通过在函数名后面添加后缀的方式为指定的标识符提供多个示例，后缀以 `_` 开头后面跟小写字母组成的字符串。

```
func ExampleString()
func ExampleString_second()
func ExampleString_third()
func ExampleBar_Qux_one()
func ExampleBar_Qux_two() 
```

## 隐藏README文件

`git` 托管网站通常会把 `README` 文件作为仓库的文档展示。`godoc` 或 `pkgsite` 生成文档时，把 `README` 文件放在包文档页面的顶部。如果不希望展示 `README` 文件，可以把 `README` 文件放在子目录下，如 `docs//README.md`。

# go doc

与 `godoc` 命令不同，该命令用于在命令行上查看源码的文档

```
go doc 				// 输出当前目录下的包文档
go doc fmt 			// 查看fmt包的文档
go doc fmt Printf 	// 查看fmt包里的Printf函数的文档
godoc os File  		// 查看os包里File结构的文档
go doc fmt Printf Println // 查看包内多个标识符
```

# 参考资料

> [Godoc: documenting Go code - The Go Programming Language](https://go.dev/blog/godoc)
> [Go Doc Comments - The Go Programming Language (golang.org)](https://tip.golang.org/doc/comment)
> [godoc command - golang.org/x/tools/cmd/godoc - Go Packages](https://pkg.go.dev/golang.org/x/tools/cmd/godoc)
> [Testable Examples in Go - The Go Programming Language](https://go.dev/blog/examples)
> [pkgsite command - golang.org/x/pkgsite/cmd/pkgsite - Go Packages](https://pkg.go.dev/golang.org/x/pkgsite/cmd/pkgsite)
> [如何查看历史版本的Go文档？嘘！答案我只告诉你！ | Tony Bai](https://tonybai.com/2020/12/15/how-to-see-the-manual-of-go-history-version/)
> [聊聊godoc、go doc与pkgsite | Tony Bai](https://tonybai.com/2023/03/20/godoc-vs-go-doc-vs-pkgsite/)