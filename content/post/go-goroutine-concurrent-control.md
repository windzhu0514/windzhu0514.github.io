---
title: "goroutine并发控制"
date: 2018-12-07T10:05:37+08:00
draft: false
tags: ["go", "goroutine", "并发"]
categories: ["golang"]
---

## 通信

#### 共享内存

```go
func  Test() {
	ordersInfoApp  :=  make([]orderInfoApp, 0, totalCount)
	var  mux sync.Mutex
	wg  := sync.WaitGroup{}

	for  i  :=  0; i <=  10; i++ {
		wg.Add(1)
		go  func(pageIndex int) {
			// do somethine
			var  ordersInfo orderInfoApp
			mux.Lock()
			ordersInfoApp  =  append(ordersInfoApp, ordersInfo)
			mux.Unlock()

			wg.Done()
		}(i)
	}

	wg.Wait()
}
```

一般在简单的数据传递下使用

#### channel

```go
func  Test() {
	ordersInfoApp  :=  make([]orderInfoApp, 0, totalCount)
	choi  :=  make(chan orderInfoApp, 10)
	wg  := sync.WaitGroup{}

	for  i  :=  0; i <=  10; i++ {
		wg.Add(1)
		go  func(pageIndex int) {
			// do somethine
			var  ordersInfo orderInfoApp
			choi <- ordersInfo

			wg.Done()
		}(i)
	}

	go  func() {
		wg.Wait()
		close(choi)
	}()

	for  v  :=  range choi {
		ordersInfoApp  =  append(ordersInfoApp, v)
	}
}
```

相对复杂的数据流动情况

## 同步和控制

goroutine 退出只能由本身控制，不能从外部强制结束该 goroutine
两种例外情况：main 函数结束或者程序崩溃结束运行

#### 共享变量控制结束

```go
func  main() {
	running  :=  true
	f  :=  func() {
		for running {
			fmt.Println("i am running")
			time.Sleep(1  * time.Second)
		}
		fmt.Println("exit")
	}
	go  f()
	go  f()
	go  f()
	time.Sleep(2  * time.Second)
	running  =  false
	time.Sleep(3  * time.Second)
	fmt.Println("main exit")
}
```

**优点**：
实现简单，不抽象，方便，一个变量即可简单控制子 goroutine 的进行。
**缺点**:
结构只能是多读一写，不能适应结构复杂的设计，如果有多写，会出现数据同步问题，需要加锁或者使用 sync.atomic
不适合用于同级的子 go 程间的通信，全局变量传递的信息太少
因为是单向通知,主进程无法等待所有子 goroutine 退出
这种方法只适用于非常简单的逻辑且并发量不太大的场景

#### sync.Waitgroup 等待结束

```go
func  main() {
	var  wg sync.WaitGroup
	for  i  :=  0; i <  3; i++ {
		wg.Add(1)
		go  func() {
			defer wg.Done()
			// do something
		}()
	}

	wg.Wait()
}
```

#### channel 控制结束

```go
// 可扩展到多个work
func  main() {
	chClose  :=  make(chan  struct{})
	go  func() {
		for {
			select {
				case  <-chClose:
					return
				default:
			}

		// do something
		}
	}()

	//chClose<-struct{}
	close(chClose)
}
```

注意 channel 的阻塞情况，避免出现死锁。
通常 channel 只能由发送者关闭

- 向无缓冲的 channel 写入数据会导致该 goroutine 阻塞，直到其他 goroutine 从这个 channel 中读取数据

- 从无缓冲的 channel 读出数据，如果 channel 中无数据，会导致该 goroutine 阻塞，直到其他 goroutine 向这个 channel 中写入数据

- 向带缓冲的且缓冲已满的 channel 写入数据会导致该 goroutine 阻塞，直到其他 goroutine 从这个 channel 中读取数据

- 向带缓冲的且缓冲未满的 channel 写入数据不会导致该 goroutine 阻塞

- 从带缓冲的 channel 读出数据，如果 channel 中无数据，会导致该 goroutine 阻塞，直到其他 goroutine 向这个 channel 中写入数据

- 从带缓冲的 channel 读出数据，如果 channel 中有数据，该 goroutine 不会阻塞

  ```go
  // 读完结束
  for {
  	select {
  	case  <-ch:
  		default:
  		goto finish
  	}
  }
  finish:
  ```

- 如果多个 case 同时就绪时，select 会随机地选择一个执行

- case 标签里向 channel 发送或接收数据，case 后面的语句在发送接收成功后才会执行
- nil channel（读、写、读写）的 case 标签会被跳过

#### limitwaitgroup

```go
type  limitwaitgroup  struct {
	sem chan  struct{}
	wg sync.WaitGroup
}

func  New(n int) *limitwaitgroup {
	return  &limitwaitgroup{
		sem: make(chan  struct{}, n),
	}
}

func  (l *limitwaitgroup) Add() {
	l.sem <-  struct{}{}
	l.wg.Add(1)
}

func  (l *limitwaitgroup) Done() {
	<-l.sem
	l.wg.Done()
}

func  (l *limitwaitgroup) Wait() {
	l.wg.Wait()
}

// 例子
wg  := limitwaitgroup.New(6)
for  i  :=  0; i <=  10; i++ {
	wg.Add()
	go  func(index int){
		defer wg.Done()
		// do something
	}(i)
}
wg.Wait()
```

#### context

上下文 go 1.7 作为第一个参数在 goroutine 里传递

Context 的接口定义

```go
type  Context  interface {
	Deadline() (deadline time.Time, ok bool)
	Done() <-chan  struct{}
	Err() error
	Value(key interface{}) interface{}
}
```

`Deadline`获取设置的截止时间(WithDeadline、WithTimeout)， 第一个返回值代表截止时间，第二个返回值代表是否设置了截止时间，false 时表示没有设置截止时间

`Done`方法返回一个关闭的只读的 chan，类型为`struct{}`，在 goroutine 中，如果该方法返回的 chan 可以读取，则意味着 parent context 已经发起了取消请求，我们通过`Done`方法收到这个信号后，就应该做清理操作，然后退出 goroutine，释放资源。

`Err`context 没有被结束，返回 nil；已被结束，返回结束的原因（被取消、超时）。

`Value`方法通过一个 Key 获取该 Context 上绑定的值，访问这个值是线程安全的。key 一般定义当前包的一个新的未导出类型的变量（最好不要使用内置类型），避免和其他 goroutine 的 key 冲突。

- Context 衍生

```go
func  WithCancel(parent Context) (ctx Context, cancel CancelFunc)
func  WithDeadline(parent Context, deadline time.Time) (Context, CancelFunc)
func  WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc)
func  WithValue(parent Context, key, val interface{}) Context
```

这四个`With`函数，接收的都有一个 partent 参数，就是父 Context，我们要基于这个父 Context 创建出子 Context 的意思，这种方式可以理解为子 Context 对父 Context 的继承，也可以理解为基于父 Context 的衍生。

通过这些函数，就创建了一颗 Context 树，树的每个节点都可以有任意多个子节点，节点层级可以有任意多个。

`WithCancel`函数，传递一个父 Context 作为参数，返回子 Context，以及一个取消函数用来取消 Context。 `WithDeadline`函数，和`WithCancel`差不多，它会多传递一个截止时间参数，意味着到了这个时间点，会自动取消 Context，也可以不等到这个时候，可以提前通过取消函数进行取消。

`WithTimeout`和`WithDeadline`基本上一样，这个表示是超时自动取消，设置多少时间后自动取消 Context。

`WithValue`函数和取消 Context 无关，生成一个绑定了一个键值对数据的 Context，这个绑定的数据可以通过`Context.Value`方法访问到

- 例子

WithCancel

```go
func  main() {
	ctx, cancel  := context.WithCancel(context.Background())
	go  watch(ctx, "goroutine 1")
	go  watch(ctx, "goroutine 2")
	go  watch(ctx, "goroutine 3")
	time.Sleep(10  * time.Second)
	fmt.Println("开始结束goroutine")
	cancel()
	time.Sleep(5  * time.Second)
	fmt.Println(ctx.Err())
}
func  watch(ctx context.Context, name string) {
  for {
      select {
      case  <-ctx.Done():
          fmt.Println(name, "over")
          return
      default:
          fmt.Println(name, "running")
          time.Sleep(2  * time.Second)
      }
  }
}

// output:
goroutine 1 running
goroutine 2 running
goroutine 3 running
goroutine 1 running
goroutine 2 running
goroutine 3 running
goroutine 1 running
goroutine 2 running
goroutine 3 running
goroutine 2 running
goroutine 3 running
goroutine 1 running
goroutine 3 running
goroutine 2 running
goroutine 1 running
开始结束goroutine
goroutine 1 over
goroutine 2 over
goroutine 3 over
context canceled
```

WithDeadline

```go
func  main() {
	ctx, cancel  := context.WithDeadline(context.Background(), time.Now().Add(5*time.Second))
	go  watch(ctx, "goroutine 1")
	go  watch(ctx, "goroutine 2")
	go  watch(ctx, "goroutine 3")
	_  = cancel
	time.Sleep(8  * time.Second)
	fmt.Println(ctx.Err())
}

func  watch(ctx context.Context, name string) {
  for {
      select {
      case  <-ctx.Done():
          fmt.Println(name, "over")
          return
      default:
          fmt.Println(name, "running")
          time.Sleep(2  * time.Second)
      }
  }
}

// output:
goroutine 3 running
goroutine 2 running
goroutine 1 running
goroutine 3 running
goroutine 1 running
goroutine 2 running
goroutine 1 running
goroutine 3 running
goroutine 2 running
goroutine 3 over
goroutine 1 over
goroutine 2 over
context deadline exceeded
```

WithTimeout

```go
func  main() {
	ctx, cancel  := context.WithTimeout(context.Background(), 5*time.Second)
	go  watch(ctx, "goroutine 1")
	go  watch(ctx, "goroutine 2")
	go  watch(ctx, "goroutine 3")
	_  = cancel
	time.Sleep(8  * time.Second)
	fmt.Println(ctx.Err())
}

func  watch(ctx context.Context, name string) {
  for {
      select {
      case  <-ctx.Done():
          fmt.Println(name, "over")
          return
      default:
          fmt.Println(name, "running")
          time.Sleep(2  * time.Second)
      }
  }
}

// output:
goroutine 3 running
goroutine 1 running
goroutine 2 running
goroutine 3 running
goroutine 2 running
goroutine 1 running
goroutine 2 running
goroutine 1 running
goroutine 3 running
goroutine 2 over
goroutine 3 over
goroutine 1 over
context deadline exceeded
```

WithValue

```go
type  key  int  // 未导出的包私有类型
var  kkk key =  0

func  main() {
	ctx, cancel  := context.WithCancel(context.Background())
	// WithValue是没有取消函数的
	ctx  = context.WithValue(ctx, kkk, "100W")

	go  watch(ctx, "goroutine 1")
	go  watch(ctx, "goroutine 2")
	go  watch(ctx, "goroutine 3")

	time.Sleep(8  * time.Second)

	fmt.Println("开始结束goroutine")
	cancel()

	time.Sleep(3  * time.Second)
	fmt.Println(ctx.Err())
}

func  watch(ctx context.Context, name string) {
  for {
      select {
      case  <-ctx.Done():
          fmt.Println(name, "over")
          return
      default:
          fmt.Println(name, "running", "爸爸给我了", ctx.Value(kkk).(string))
          time.Sleep(2  * time.Second)
      }
  }
}
// output:
goroutine 1 running 爸爸给我了 100W
goroutine 2 running 爸爸给我了 100W
goroutine 3 running 爸爸给我了 100W
goroutine 2 running 爸爸给我了 100W
goroutine 1 running 爸爸给我了 100W
goroutine 3 running 爸爸给我了 100W
goroutine 1 running 爸爸给我了 100W
goroutine 2 running 爸爸给我了 100W
goroutine 3 running 爸爸给我了 100W
goroutine 1 running 爸爸给我了 100W
goroutine 3 running 爸爸给我了 100W
goroutine 2 running 爸爸给我了 100W
开始结束goroutine
goroutine 2 over
goroutine 3 over
goroutine 1 running 爸爸给我了 100W
goroutine 1 over
context canceled
```

控制多个 goroutine

```go
func  main() {
	http.HandleFunc("/", func(W http.ResponseWriter, r *http.Request) {
	fmt.Println("收到请求")

	ctx, cancel  := context.WithCancel(context.Background())
	go  worker(ctx, 2)
	go  worker(ctx, 3)

	time.Sleep(time.Second *  10)
	cancel()
	fmt.Println(ctx.Err())
	})
	http.ListenAndServe(":9290", nil)
}
func  worker(ctx context.Context, speed int) {
	reader  :=  func(n int) {
		for {
			select {
				case  <-ctx.Done():
				return
				default:
				break
			}
			fmt.Println("reader:", n)
			time.Sleep(time.Duration(n) * time.Second)
		}
	}

	go  reader(2)
	go  reader(1)

	for {
		select {
			case  <-ctx.Done():
			return
			default:
			break
		}
		fmt.Println("worker:", speed)
		time.Sleep(time.Duration(speed) * time.Second)
	}
}

// output:
收到请求
worker: 2
reader: 1
worker: 3
reader: 1
reader: 2
reader: 2
reader: 1
reader: 1
reader: 1
reader: 2
worker: 2
reader: 2
reader: 1
reader: 1
reader: 1
worker: 3
reader: 1
worker: 2
reader: 2
reader: 1
reader: 2
reader: 1
context canceled
```

- 使用规则
  使用 Context 的程序应遵循以下这些规则来保持跨包接口的一致和方便静态分析工具(go vet)来检查上下文传播是否有潜在问题。

  - 不要将 Context 存储在结构类型中，而是显式的传递给每个需要的函数； Context 应该作为函数的第一个参数传递，通常命名为 ctx：

    ```go
        func  DoSomething(ctx context.Context, arg Arg) error {
        // ... use ctx ...
    }
    ```

  - 即使函数可以接受 nil 值，也不要传递 nil Context。如果不确定要使用哪个 Context，请传递 context.TODO。

  - 使用 context 的 Value 相关方法只应该用于在程序和接口中传递和请求相关的元数据，不要用它来传递一些可选的参数

  - 相同的 Context 可以传递给在不同 goroutine 中运行的函数; Context 对于多个 goroutine 同时使用是安全的。
