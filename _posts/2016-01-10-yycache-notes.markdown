---
layout:     post
title:      "YYCache笔记"
stick:      
tags:
    - iOS
    - 笔记
    - 源码
---

上午去香山溜达了一圈，回来睡了一觉，直接就到5点了。好吧，我要开始写笔记了。。

源码地址：[ibireme/YYCache](https://github.com/ibireme/YYCache)

### YYMemoryCache

* 支持同步和异步访问，但是并没有开放异步访问block回调的接口。
* 支持在主线程进行释放，默认是关闭的。（只有操作UIView/CALayer这些必须在主线程释放的对象时使用）
* 支持异步释放，默认开启。
* 根据当前Cache的配置进行移除。	

至于如何移除，可以看下面一段代码：

```objc
if (holder.count) {
    dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : YYMemoryCacheGetReleaseQueue();
    dispatch_async(queue, ^{
        [holder count]; // release in queue
	});	
}
```	

> holder 持有了待释放的对象，这些对象应该根据配置在不同线程进行释放(release)。此处 holder 被 block 持有，然后在另外的 queue 中释放。[holder count] 只是为了让 holder 被 block 捕获，保证编译器不会优化掉这个操作，所以随便调用了一个方法。

真是小妙招啊~学到了~


   * [LRU淘汰算法(近期最少使用算法)](https://en.wikipedia.org/wiki/Cache_algorithms#LRU)
   
   顾名思义...就是最近最少使用的最先淘汰。淘汰的规则有缓存的（最后使用）时间、大小和个数。
   具体是用双向链表和 NSDictionary实现的这个算法。双向链表？...
   
> 双向链表也叫双链表，是链表的一种，它的每个数据结点中都有两个指针，分别指向直接后继和直接前驱。所以，从双向链表中的任意一个结点开始，都可以很方便地访问它的前驱结点和后继结点。

拿`- (void)bringNodeToHead:(_YYLinkedMapNode *)node`这个函数来说一下吧...
这个方法是实现把一个`_YYLinkedMap`（每个_YYLinkedMapNode含有 key-value对，直接后继Node，直接前驱Node，内存花销（_cost）,存活时间（_time））配置成`_head`（头）：

```objc
- (void)bringNodeToHead:(_YYLinkedMapNode *)node {

    if (_head == node) return; // 如果_head==node，嗯。。如我所愿，直接返回。
    if (_tail == node) { // 如果_tail(尾) == node，那我们首先把_tail改成node的上一个。
    _tail = node->_prev; // _tail =  node.prev(上一个)。
    _tail->_next = nil; //_tail.next(下一个) = nil。 现在_tail 又变成真的尾巴了啦~
    } else { // 如果node在中间。
	
        // 配置node.next
        node->_next->_prev = node->_prev; // node.next(nodenext)的上一个(nodenext.prev) = node.prev。
        // 配置node.prev
        node->_prev->_next = node->_next; // node.prev(nodeprev)的下一个(nodeprev.next) = node.next。
    } 
	
    // 配置node
    node->_next = _head;
    node->_prev = nil;
		    
    // 更新_head
    _head->_prev = node;
    _head = node;
}
```
看晕了没...反正开始自己看的时候是晕了...

画个图应该容易理解一点。

![](http://7xpyhz.com1.z0.glb.clouddn.com/01.png_w600hfree)
![](http://7xpyhz.com1.z0.glb.clouddn.com/02.png_w600hfree)





### YYDiskCache

* 支持异步回调。
* 同时支持了文件和SQLite。
* 可以自定义解归档方式。
	
第三点我还没搞明白。代码里大概是这么实现的：

在调用`setObject: forKey:`的时候，会检查有没有实现`^customArchiveBlock`，如果有，将自定义的`value`作为value存入缓存，否则将归档之后的`object`作为value存入缓存。解档与之类似。

问题在于，当我实现了这个block，并且返回了自定义的`value`，那`objcet`除了作为block的参数，还有什么用呢？如果我只实现了自定义归档，没有实现自定义解档，会出现什么问题呢？

嗯...比较乱...


		
#### YYKVStorage

这个类其实就是YYDiskCache的具体实现，YYDiskCache通过加锁实现线程安全，然后通过创建YYKVStorage实例完成具体功能。

主要说一下`- (BOOL)saveItemWithKey:(NSString *)key
                  value:(NSData *)value
               filename:(NSString *)filename
           extendedData:(NSData *)extendedData`这个方法。
           

```objc
// 如果type == YYKVStorageTypeFile，那么，item.filename 不能为空。
// 如果type == YYKVStorageTypeSQLite, item.filename 将被忽略。
// 如果type == YYKVStorageTypeMixed, 并且item.filename不为空，那么item.value将被保存为file文件系统，否则保存为sqlite。


- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename extendedData:(NSData *)extendedData {
    if (key.length == 0 || value.length == 0) return NO;
    if (_type == YYKVStorageTypeFile && filename.length == 0) {
        return NO;
    }
    
    if (filename.length) { // filename 不为空
        if (![self _fileWriteWithName:filename data:value]) { // 1.先将value写入文件。
            return NO;
        }
        if (![self _dbSaveWithKey:key value:value fileName:filename extendedData:extendedData]) { // 2.文件信息存入。（value的size，time等等）
            [self _fileDeleteWithName:filename]; // 3. 如果失败，把第一步写入成功的value文件删除。
            return NO;
        }
        return YES;
    } else { // filename 为空
        if (_type != YYKVStorageTypeSQLite) {
            // 如果filename为空，而且type != YYKVStorageTypeSQLite的时候，查询sqlite中是否有这个key的filename，如果有，删除。
            NSString *filename = [self _dbGetFilenameWithKey:key];
            if (filename) {
                [self _fileDeleteWithName:filename];
            }
        }
        // 删除filename之后，存入sqlite （当file那么==nil的时候，才会存value的信息（bytes和length））。
        return [self _dbSaveWithKey:key value:value fileName:nil extendedData:extendedData];
    }
}


// 注意这两句： 
   
if (fileName.length == 0) {
    sqlite3_bind_blob(stmt, 4, value.bytes, (int)value.length, 0);
} else {
    sqlite3_bind_blob(stmt, 4, NULL, 0, 0);
}
    
    
// 也就是说：（当file那么==nil的时候，才会存value的信息（bytes和length））
```


##### Tips：

* 内联函数：

>
 内联函数有些类似于宏。内联函数的代码会被直接嵌入在它被调用的地方，调用几次就嵌入几次，没有使用call指令。这样省去了函数调用时的一些额外开销，比如保存和恢复函数返回地址等，可以加快速度。不过调用次数多的话，会使可执行文件变大，这样会降低速度。相比起宏来说，内核开发者一般更喜欢使用内联函数。因为内联函数没有长度限制，格式限制。编译器还可以检查函数调用方式，以防止其被误用。
`static inline`的内联函数，一般情况下不会产生函数本身的代码，而是全部被嵌入在被调用的地方。如果不加`static`，则表示该函数有可能会被其他编译单元所调用，所以一定会产生函数本身的代码。所以加了`static`，一般可令可执行文件变小。内核里一般见不到只用`inline`的情况，而都是使用`static inline`。



* 锁：

> Spin locks are a simple, fast, thread-safe synchronization primitive that is suitable in situations
where contention is expected to be low. The spinlock operations use memory barriers to synchronize
access to shared memory protected by the lock. Preemption is possible while the lock is held.

> OSSpinLock 自旋锁，性能最高的锁。原理很简单，就是一直 do while 忙等。它的缺点是当等待时会消耗大量 CPU 资源，所以它不适用于较长时间的任务。对于内存缓存的存取来说，它非常合适。)

> dispatch_semaphore 是信号量，但当信号总量设为 1 时也可以当作锁来。在没有等待情况出现时，它的性能比 pthread_mutex 还要高，但一旦有等待情况出现时，性能就会下降许多。相对于 OSSpinLock 来说，它的优势在于等待时不会消耗 CPU 资源。对磁盘缓存来说，它比较合适。

so...因为DiskCache 锁占用时间可能会比较长，如果用 SpinLock 会在锁存在竞争时占用大量 CPU 资源。所以在DiskCache用的是dispatch_semaphore_signal(1)来实现锁。

> 1月18号更新：
 OSSpinLock已经不再安全，YY大神的这篇[博客文章](http://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)有详解。。
 
