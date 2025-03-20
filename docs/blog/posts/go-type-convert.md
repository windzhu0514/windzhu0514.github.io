---
title: "golang类型转换"
date: 2019-03-07T17:45:27+08:00
draft: false
tags: ["go", "golang", "类型转换"]
categories: ["golang"]
---

## int --> string

转换函数：

[fmt.Sprintf](https://golang.google.cn/pkg/fmt/#Sprintf "fmt.Sprintf")：格式化范围 math.MinInt64 -> math.MaxInt64

[strconv.Itoa](https://golang.google.cn/pkg/strconv/#Itoa "strconv.Itoa")：格式化范围 math.MinInt64 -> math.MaxInt64

[strconv.FormatInt](https://golang.google.cn/pkg/strconv/#FormatInt "strconv.FormatInt")：格式化范围 math.MinInt64 -> math.MaxInt64

[strconv.FormatUint](https://golang.google.cn/pkg/strconv/#FormatUint "strconv.FormatUint")：格式化范围 0 -> math.MaxUint64

<!-- more -->

```go
fmt.Sprintf("%d", math.MinInt64)
// "-9223372036854775808"
fmt.Sprintf("%d", math.MaxInt64)
// "9223372036854775807"
fmt.Sprintf("%d", math.MaxUint64)
// constant 18446744073709551615 overflows int

strconv.Itoa(math.MinInt64)
// "-9223372036854775808"
strconv.Itoa(math.MaxInt64)
// "9223372036854775807"
strconv.Itoa(math.MaxUint64)
// constant 18446744073709551615 overflows int

strconv.FormatInt(math.MinInt64, 10)
// "-9223372036854775808"
strconv.FormatInt(math.MaxInt64, 10)
// "9223372036854775807"
strconv.FormatInt(math.MaxUint64, 10)
// constant 18446744073709551615 overflows int64

strconv.FormatUint(math.MaxUint64, 10)
// "18446744073709551615"
```

## string --> int

转换函数：

[fmt.Sscanf](https://golang.google.cn/pkg/fmt/#Sscanf "fmt.Sscanf")：格式化范围 math.MinInt64 -> math.MaxUint64

[strconv.ParseInt](https://golang.google.cn/pkg/strconv/#ParseInt "strconv.ParseInt")：格式化范围 math.MinInt64 -> math.MaxInt64

[strconv.ParseUint](https://golang.google.cn/pkg/strconv/#ParseUint "strconv.ParseUint")：格式化范围 0 -> math.MaxUint64

```go
var n int
fmt.Sscanf("2147483647", "%d", &n)
// 2147483647

var n32 int32
fmt.Sscanf("2147483647", "%d", &n32)
// 2147483647

var n64 int64
fmt.Sscanf("-9223372036854775808", "%d", &n64)
// -9223372036854775808

var n64_2 int64
fmt.Sscanf("9223372036854775807", "%d", &n64_2)
// 9223372036854775807

var un64 uint64
fmt.Sscanf("18446744073709551615", "%d", &un64)
// 18446744073709551615

//  bitSize 0, 8, 16, 32, 和 64分别对应int, int8, int16, int32, 和 int64
// math.MaxUint64 18446744073709551615
// math.MaxInt64 9223372036854775807
strconv.ParseInt("9223372036854775807", 10, 64)
// 9223372036854775807
strconv.ParseUint("18446744073709551615", 10, 64)
// 18446744073709551615
```

## float64 --> string

float32 类型的浮点数可以提供大约 6 个十进制数的精度，而 float64 则可以提供约 15 个十进制数的精度；通常应该优先使用 float64 类型，因为 float32 类型的累计计算误差很容易扩散，并且 float32 能精确表示的正整数并不是很大（译注：因为 float32 的有效 bit 位只有 23 个，其它的 bit 位用于指数和符号；当整数大于 23bit 能表达的范围时，float32 的表示将出现误差）《The Go Programming Language》

golang 浮点数舍入方式是按照[IEEE 754](https://zh.wikipedia.org/wiki/IEEE_754 "IEEE 754")进行的（区别于四舍五入）

转换函数：[strconv.FormatFloat](https://golang.google.cn/pkg/strconv/#FormatFloat "strconv.FormatFloat")、[fmt.Sprintf](https://golang.google.cn/pkg/fmt/#Sprintf "fmt.Sprintf")

```go
var discoutAmount = 49.285
var discoutTaxAmount = 296.85
strconv.FormatFloat(discoutAmount+discoutTaxAmount, 'f', 2, 64)
// 346.13
fmt.Sprintf("%.2f", discoutAmount+discoutTaxAmount)
// 346.13
strconv.FormatFloat(1.45, 'f', 1, 64)
// 1.4
strconv.FormatFloat(1.445, 'f', 2, 64)
// 1.45
```

float64 四舍五入转 2 位小数字符串

```java
// java 小数四舍五入
double  discoutAmount  =  252.945;
double  discoutTaxAmount  =  41.989999999999995;
// BigDecimal.ROUND_HALF_UP 四舍五入
double  price  =  new  BigDecimal(discoutAmount + discoutTaxAmount).setScale(2, BigDecimal.ROUND_HALF_UP).doubleValue();
System.out.println(price);
// output:
294.94
```

```go
// go 四舍五入 转3位小数 *1000）/1000 依次类推
var discoutAmount = 252.945
var discoutTaxAmount = 41.989999999999995
price := math.Round((discoutAmount+discoutTaxAmount)*100) / 100
fmt.Println(strconv.FormatFloat(price, 'f', 2, 64))
// 294.94
```

## string --> float64

转换函数：[fmt.Sscanf](https://golang.google.cn/pkg/fmt/#Sscanf "fmt.Sscanf") [strconv.ParseFloat](https://golang.google.cn/pkg/strconv/#ParseFloat "strconv.ParseFloat")

strconv.ParseFloat：如果字符串合乎语法规则，函数会返回最为接近 s 表示值的一个浮点数（使用 IEEE754 规范舍入）。bitSize 指定了期望的接收类型，32 是 float32（返回值的赋值给 float32 时可以不改变精确度），64 是 float64；

```go
var f32 float32
fmt.Sscanf("41.989999999999995", "%f", &f32)
// 41.99
var f64 float64
fmt.Sscanf("41.989999999999995", "%f", &f64)
// 41.989999999999995

strconv.ParseFloat("41.989999999999995", 64)
// 41.989999999999995
strconv.ParseFloat("41.989999999999995", 32)
// 41.9900016784668
```

**备注：**

- strconv 包的函数不需要格式化，比 fmt 包的函数更加高效。
