---
title: "Go Rate限流器代码分析"
date: 2020-08-30T23:49:05+08:00
draft: false
tags: ["go", "golang", "rate", "限流器", "令牌桶"]
categories: ["golang"]
toc: false
---

## 源码分析

```go
// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package rate 基于令牌桶算法实现了一个速率限制器。
// Package rate provides a rate limiter.
package rate

import (
	"context"
	"fmt"
	"math"
	"sync"
	"time"
)

//  Limit 定义事件发生的最大速率，代表每秒事件发生的次数。0表示事件不会发生

// Limit defines the maximum frequency of some events.
// Limit is represented as number of events per second.
// A zero Limit allows no events.
type Limit float64

// Inf 代表没有速率限制，始终允许事件发生
// Inf is the infinite rate limit; it allows all events (even if burst is zero).
const Inf = Limit(math.MaxFloat64)

// Every 把事件发生的最小时间间隔转换为Limit变量
// 比如interval=5s，表示5s一次，每秒的速率为1/5=0.2
// Every converts a minimum time interval between events to a Limit.
func Every(interval time.Duration) Limit {
	if interval <= 0 {
		return Inf
	}
	return 1 / Limit(interval.Seconds())
}

// Limiter 控制事件发生的频率。实现了一个大小为b，初始为满，每秒填充r个令牌的令牌桶。
// 在随便一个很大的时间间隔内，Limiter限制令牌的产生速率为每秒r个令牌，同时发生的事件数量为b个。
// 如果r==Inf（预定的的值，代表无限制的速率），Limiter忽略同时发生的事件数量b的值。
// 零值的Limiter是一个有效Limiter，但是会拒绝任何事件的发生。使用NewLimiter创建非零值的Limiter
// Limiter有三个主要的方法，Allow、Reserve、Wait。大多数调用都应该使用Wait。
// 这三个方法每次都只消费一个令牌。他们的不同之处在于当令牌桶里没有令牌时不同行为：
// 如果令牌桶里没有令牌，Allow返回false
// 如果令牌桶里没有令牌,Reserve返回

// A Limiter controls how frequently events are allowed to happen.
// It implements a "token bucket" of size b, initially full and refilled
// at rate r tokens per second.
// Informally, in any large enough time interval, the Limiter limits the
// rate to r tokens per second, with a maximum burst size of b events.
// As a special case, if r == Inf (the infinite rate), b is ignored.
// See https://en.wikipedia.org/wiki/Token_bucket for more about token buckets.
//
// The zero value is a valid Limiter, but it will reject all events.
// Use NewLimiter to create non-zero Limiters.
//
// Limiter has three main methods, Allow, Reserve, and Wait.
// Most callers should use Wait.
//
// Each of the three methods consumes a single token.
// They differ in their behavior when no token is available.
// If no token is available, Allow returns false.
// If no token is available, Reserve returns a reservation for a future token
// and the amount of time the caller must wait before using it.
// If no token is available, Wait blocks until one can be obtained
// or its associated context.Context is canceled.
//
// The methods AllowN, ReserveN, and WaitN consume n tokens.
type Limiter struct {
	mu     sync.Mutex
	limit  Limit   // 放入桶中的token的产生速率
	burst  int     // 同一时刻支持的最大突发事件的数量，也是令牌桶的最大容量
	tokens float64 // token的数量 使用float64类型是因为指定时间内产生的令牌数量可能不是整数个
	// last字段是tokens字段最后一次更新的时间
	// last is the last time the limiter's tokens field was updated
	last time.Time
	// lastEvent 上一个事件发生的时间
	// lastEvent is the latest time of a rate-limited event (past or future)
	lastEvent time.Time
}

// Limit returns the maximum overall event rate.
func (lim *Limiter) Limit() Limit {
	lim.mu.Lock()
	defer lim.mu.Unlock()
	return lim.limit
}

// Burst returns the maximum burst size. Burst is the maximum number of tokens
// that can be consumed in a single call to Allow, Reserve, or Wait, so higher
// Burst values allow more events to happen at once.
// A zero Burst allows no events, unless limit == Inf.
func (lim *Limiter) Burst() int {
	lim.mu.Lock()
	defer lim.mu.Unlock()
	return lim.burst
}

//
// NewLimiter returns a new Limiter that allows events up to rate r and permits
// bursts of at most b tokens.
func NewLimiter(r Limit, b int) *Limiter {
	return &Limiter{
		limit: r,
		burst: b,
	}
}

// Allow 判断是否允许发生一个事件
// Allow is shorthand for AllowN(time.Now(), 1).
func (lim *Limiter) Allow() bool {
	return lim.AllowN(time.Now(), 1)
}

// AllowN reports whether n events may happen at time now.
// Use this method if you intend to drop / skip events that exceed the rate limit.
// Otherwise use Reserve or Wait.
func (lim *Limiter) AllowN(now time.Time, n int) bool {
	return lim.reserveN(now, n, 0).ok
}

// Reservation 保存在一定时间延迟后Limiter允许执行的事件信息。
// Reservation可以被取消，取消后Limiter可以执行剩下的事件。

// A Reservation holds information about events that are permitted by a Limiter to happen after a delay.
// A Reservation may be canceled, which may enable the Limiter to permit additional events.
type Reservation struct {
	ok        bool      // 令牌桶是否可以提供需要的令牌数量
	lim       *Limiter  // Limiter本省
	tokens    int       // 预定的令牌数量
	timeToAct time.Time // 令牌桶可以提供满足需要的令牌数量的时间
	// 预订时的限制速率，后续可以改变
	// This is the Limit at reservation time, it can change later.
	limit Limit
}

// OK returns whether the limiter can provide the requested number of tokens
// within the maximum wait time.  If OK is false, Delay returns InfDuration, and
// Cancel does nothing.
func (r *Reservation) OK() bool {
	return r.ok
}

// Delay is shorthand for DelayFrom(time.Now()).
func (r *Reservation) Delay() time.Duration {
	return r.DelayFrom(time.Now())
}

// InfDuration is the duration returned by Delay when a Reservation is not OK.
const InfDuration = time.Duration(1<<63 - 1)

// DelayFrom 返回满足预定条件前预定持有者必须要等待的时间。
// 0表示立刻可以满足。InfDuration表示限流器在最大的等待时间内无法满足此次预订的令牌数量。
// DelayFrom returns the duration for which the reservation holder must wait
// before taking the reserved action.  Zero duration means act immediately.
// InfDuration means the limiter cannot grant the tokens requested in this
// Reservation within the maximum wait time.
func (r *Reservation) DelayFrom(now time.Time) time.Duration {
	if !r.ok {
		return InfDuration
	}
	delay := r.timeToAct.Sub(now)
	if delay < 0 {
		return 0
	}
	return delay
}

// Cancel is shorthand for CancelAt(time.Now()).
func (r *Reservation) Cancel() {
	r.CancelAt(time.Now())
	return
}

// CancelAt 表示预订持有者将不会继续保留预订的令牌，并且尽可能的弥补此次预订对速率限制的影响，
// 因为一些预订的令牌可能已经被使用。
// CancelAt indicates that the reservation holder will not perform the reserved action
// and reverses the effects of this Reservation on the rate limit as much as possible,
// considering that other reservations may have already been made.
func (r *Reservation) CancelAt(now time.Time) {
	if !r.ok { // 预订失败的不需用操作
		return
	}

	r.lim.mu.Lock()
	defer r.lim.mu.Unlock()

	// 速率无限制、令牌数量为0、已过预定等待时间的无需操作
	if r.lim.limit == Inf || r.tokens == 0 || r.timeToAct.Before(now) {
		return
	}

	// 先计算取消后last和tokens的值

	// 计算需要恢复的令牌
	// r.lim.lastEvent的值是返回Reservation对象时的值
	// r.timeToAct是此次满足预定条件时事件发生的时间
	// lastEvent始终是大于等于（也就是等于或晚于）timeToAct
	// r.lim.lastEvent-r.timeToAct表示从前一个事件发生的时间到此次预订成功后事件发生的时间之间的差值，然后计算在这个
	// 时间段产生了多少令牌，即已经消耗掉的令牌数量，这些令牌不需要恢复

	// calculate tokens to restore
	// The duration between lim.lastEvent and r.timeToAct tells us how many tokens were reserved
	// after r was obtained. These tokens should not be restored.
	restoreTokens := float64(r.tokens) - r.limit.tokensFromDuration(r.lim.lastEvent.Sub(r.timeToAct))
	if restoreTokens <= 0 {
		return
	}

	// 计算lim上一次修改令牌数量后到现在应该产生的令牌的数量
	// advance time to now
	now, _, tokens := r.lim.advance(now)
	// calculate new number of tokens
	tokens += restoreTokens                            // 当前的令牌数量
	if burst := float64(r.lim.burst); tokens > burst { // 限制不超过最大令牌数量
		tokens = burst
	}

	// update state
	r.lim.last = now
	r.lim.tokens = tokens

	// 计算取消后lastEvent的值
	// 相等说明预约成功后没有任何事件发生，即没到预约事件发生的时间
	// 把reserveN函数里修改的lastEvent还原为reserveN调用前的上一个事件发生的时间，
	// 即上次调用reserveN函数并且预订成功时lastEvent的值，此次预订成功时事件发生的
	// 时间减去该值就是产生此次预订的令牌数量所消耗的时间。所以前一个事件的时间=此次预订成功事件发生的时间-产生此次预订的令牌数量的时间
	// reserveN函数timeToAct的计算反操作
	if r.timeToAct == r.lim.lastEvent {
		prevEvent := r.timeToAct.Add(r.limit.durationFromTokens(float64(-r.tokens)))
		if !prevEvent.Before(now) {
			r.lim.lastEvent = prevEvent
		}
	}

	return
}

// Reserve is shorthand for ReserveN(time.Now(), 1).
func (lim *Limiter) Reserve() *Reservation {
	return lim.ReserveN(time.Now(), 1)
}

// ReserveN returns a Reservation that indicates how long the caller must wait before n events happen.
// The Limiter takes this Reservation into account when allowing future events.
// The returned Reservation’s OK() method returns false if n exceeds the Limiter's burst size.
// Usage example:
//   r := lim.ReserveN(time.Now(), 1)
//   if !r.OK() {
//     // Not allowed to act! Did you remember to set lim.burst to be > 0 ?
//     return
//   }
//   time.Sleep(r.Delay())
//   Act()
// Use this method if you wish to wait and slow down in accordance with the rate limit without dropping events.
// If you need to respect a deadline or cancel the delay, use Wait instead.
// To drop or skip events exceeding rate limit, use Allow instead.
func (lim *Limiter) ReserveN(now time.Time, n int) *Reservation {
	r := lim.reserveN(now, n, InfDuration)
	return &r
}

// Wait is shorthand for WaitN(ctx, 1).
func (lim *Limiter) Wait(ctx context.Context) (err error) {
	return lim.WaitN(ctx, 1)
}

// WaitN blocks until lim permits n events to happen.
// It returns an error if n exceeds the Limiter's burst size, the Context is
// canceled, or the expected wait time exceeds the Context's Deadline.
// The burst limit is ignored if the rate limit is Inf.
func (lim *Limiter) WaitN(ctx context.Context, n int) (err error) {
	lim.mu.Lock()
	burst := lim.burst
	limit := lim.limit
	lim.mu.Unlock()

	// 等待的令牌数量为什么不可以超过最大令牌数量？
	// 限流器是不阻塞的，只计算当前是否可满足需要的令牌数量，如果超过最大值，必定要等待一段时间
	if n > burst && limit != Inf {
		return fmt.Errorf("rate: Wait(n=%d) exceeds limiter's burst %d", n, burst)
	}
	// Check if ctx is already cancelled
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	// 等待时间不能超过context的截止时间
	// Determine wait limit
	now := time.Now()
	waitLimit := InfDuration
	if deadline, ok := ctx.Deadline(); ok {
		waitLimit = deadline.Sub(now)
	}

	// 预定指定数量的令牌
	// Reserve
	r := lim.reserveN(now, n, waitLimit)
	if !r.ok {
		return fmt.Errorf("rate: Wait(n=%d) would exceed context deadline", n)
	}
	// Wait if necessary
	delay := r.DelayFrom(now)
	if delay == 0 {
		return nil
	}
	t := time.NewTimer(delay)
	defer t.Stop()
	select {
	case <-t.C:
		// We can proceed.
		return nil
	case <-ctx.Done():
		// 如果在满足预订条件前，context取消了，就取消此次预订。
		// Context was canceled before we could proceed.  Cancel the
		// reservation, which may permit other events to proceed sooner.
		r.Cancel()
		return ctx.Err()
	}
}

// SetLimit is shorthand for SetLimitAt(time.Now(), newLimit).
func (lim *Limiter) SetLimit(newLimit Limit) {
	lim.SetLimitAt(time.Now(), newLimit)
}

// SetLimitAt 修改Limit的速率值。在SetLimitAt调用前使用Reserve或者Wait预定的并且还未发生的Reservation可能不会使用到新的速率和新的桶大小。

// SetLimitAt sets a new Limit for the limiter. The new Limit, and Burst, may be violated
// or underutilized by those which reserved (using Reserve or Wait) but did not yet act
// before SetLimitAt was called.
func (lim *Limiter) SetLimitAt(now time.Time, newLimit Limit) {
	lim.mu.Lock()
	defer lim.mu.Unlock()

	now, _, tokens := lim.advance(now)

	lim.last = now
	lim.tokens = tokens
	lim.limit = newLimit
}

// SetBurst is shorthand for SetBurstAt(time.Now(), newBurst).
func (lim *Limiter) SetBurst(newBurst int) {
	lim.SetBurstAt(time.Now(), newBurst)
}

// SetBurstAt 设置Limiter的值，也就是令牌桶的大小

// SetBurstAt sets a new burst size for the limiter.
func (lim *Limiter) SetBurstAt(now time.Time, newBurst int) {
	lim.mu.Lock()
	defer lim.mu.Unlock()

	// 修改的同时更新一下当前时间桶内的令牌数量
	now, _, tokens := lim.advance(now)

	lim.last = now
	lim.tokens = tokens
	lim.burst = newBurst
}

// reserveN是AllowN, ReserveN和WaitN方法的辅助方法
// maxFutureReserve 指定最大的等待时间
// reserveN返回Reservation类型的值而不是指针，这样其他函数调用时不会在堆上分配内存（一个指针变量大小的内存）

// reserveN is a helper method for AllowN, ReserveN, and WaitN.
// maxFutureReserve specifies the maximum reservation wait duration allowed.
// reserveN returns Reservation, not *Reservation, to avoid allocation in AllowN and WaitN.
func (lim *Limiter) reserveN(now time.Time, n int, maxFutureReserve time.Duration) Reservation {
	lim.mu.Lock()

	// 如果速率无限制，返回true，要多少有多少
	if lim.limit == Inf {
		lim.mu.Unlock()
		return Reservation{
			ok:        true,
			lim:       lim,
			tokens:    n,
			timeToAct: now,
		}
	}

	// 计算从上一次令牌变化到当前时间令牌的数量
	now, last, tokens := lim.advance(now)

	// 计算满足预订请求后还剩余的令牌数量
	// Calculate the remaining number of tokens resulting from the request.
	tokens -= float64(n)

	// 计算预订指定的令牌数量需要等待的时间，如果tokens大于0，表示不用等待。
	// 如果tokens小于0，则需要等待产生tokens个令牌的时间
	// Calculate the wait duration
	var waitDuration time.Duration
	if tokens < 0 {
		waitDuration = lim.limit.durationFromTokens(-tokens)
	}

	// 如果需要的令牌数量大于令牌桶的最大容量，必定是不能一次满足的
	// 如果等待时间大于最大等待时间，说明在最大等待时间内无法满足需要的令牌数量
	// Decide result
	ok := n <= lim.burst && waitDuration <= maxFutureReserve

	// Prepare reservation
	r := Reservation{
		ok:    ok,
		lim:   lim,
		limit: lim.limit,
	}
	if ok { // 如果可以提供需要的令牌数量
		r.tokens = n                        // 记录预订的令牌数量
		r.timeToAct = now.Add(waitDuration) // timetoaction 记录满足所有需要的令牌数量时的时间，也即是满足后事件发生的时间
	}

	// Update state
	if ok {
		lim.last = now              // 桶内令牌数量的改变时间
		lim.tokens = tokens         // 当前桶内的令牌数量
		lim.lastEvent = r.timeToAct // 满足预订需求后事件发生的时间
	} else {
		lim.last = last // 如果预订满足不了，则只记录最后一次token数量变化的时间
	}

	lim.mu.Unlock()
	return r
}

// advance 计算并返回在经过的时间内lim的变化结果值（token数量的变化、更新时间）
// lim保持不变，调用advance函数时lim需要持有锁

// advance calculates and returns an updated state for lim resulting from the passage of time.
// lim is not changed.
// advance requires that lim.mu is held.
func (lim *Limiter) advance(now time.Time) (newNow time.Time, newLast time.Time, newTokens float64) {
	// 如果计算的时间早于最后一次令牌修改的时间
	last := lim.last
	if now.Before(last) {
		last = now
	}

	// 计算剩下的token产生所需要的最大时间
	// 当last是一个很久之前的时间时，避免使下面的delta变量溢出
	// Avoid making delta overflow below when last is very old.
	maxElapsed := lim.limit.durationFromTokens(float64(lim.burst) - lim.tokens)
	elapsed := now.Sub(last) // 时间段
	if elapsed > maxElapsed {
		elapsed = maxElapsed
	}

	// 计算在elapsed时间段内产生的token数量
	// Calculate the new number of tokens, due to time that passed.
	delta := lim.limit.tokensFromDuration(elapsed)
	tokens := lim.tokens + delta
	if burst := float64(lim.burst); tokens > burst { // token数量最大不超过burst
		tokens = burst
	}

	return now, last, tokens
}

// durationFromTokens 是个单位转换函数，计算以每秒limit个token的速率产生tokens个token的时间。
// tokens支持负值

// durationFromTokens is a unit conversion function from the number of tokens to the duration
// of time it takes to accumulate them at a rate of limit tokens per second.
func (limit Limit) durationFromTokens(tokens float64) time.Duration {
	seconds := tokens / float64(limit)
	return time.Nanosecond * time.Duration(1e9*seconds)
}

// tokensFromDuration 是个单位转换函数，计算在指定的时间隔间内以每秒limit个token的速率产生的token数量。

// tokensFromDuration is a unit conversion function from a time duration to the number of tokens
// which could be accumulated during that duration at a rate of limit tokens per second.
func (limit Limit) tokensFromDuration(d time.Duration) float64 {
	// Split the integer and fractional parts ourself to minimize rounding errors.
	// See golang.org/issues/34861.
	sec := float64(d/time.Second) * float64(limit)
	nsec := float64(d%time.Second) * float64(limit)
	return sec + nsec/1e9
}

```

## 参考资料

[Golang 限流器 time/rate 实现剖析](https://zhuanlan.zhihu.com/p/90206074)
[Golang 限流器 time/rate 使用介绍](https://zhuanlan.zhihu.com/p/89820414)
[不得不了解系列之限流](https://blog.luojilab.com/2019/12/16/zeroteam/You_have_to_know_the_rate_limit_of_the_series/)
[How to handle API rate limits: Do your integrations work at scale?](https://techbeacon.com/app-dev-testing/how-handle-api-rate-limits-do-your-integrations-work-scale)
[Golang rate 无法延迟重排的 BUG](http://xiaorui.cc/archives/5930)
