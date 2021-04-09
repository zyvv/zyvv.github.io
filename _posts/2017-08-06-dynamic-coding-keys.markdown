---
title: 'Dynamic Coding Keys'
layout: post
tags:
        - ZiMuZu
        - iOS
        - Swift
---

人人影视字幕组的`每日更新`接口返回的json里有个key是用当天的日期字符串表示的。

例如今天（8月6日）的更新列表数据的key是`2017-08-06`：

```json
{
    status: 1,
    info: "",
    data: {
        2017-08-06: [ 
            {
                id: "35120",
                cnname: "疑是疑非",
                enname: "Doubt",
                poster: "http://tu.zmzjstu.com/ftp/2017/0214/1466530223001c6e506287b090f1db3d.jpg",
                season: "1",
                episode: "10",
                play_time: "2017-08-06",
                poster_a: "http://tu.zmzjstu.com/ftp/2017/0214/a_1466530223001c6e506287b090f1db3d.jpg",
                poster_b: "http://tu.zmzjstu.com/ftp/2017/0214/b_1466530223001c6e506287b090f1db3d.jpg",
                poster_m: "http://tu.zmzjstu.com/ftp/2017/0214/m_1466530223001c6e506287b090f1db3d.jpg",
                poster_s: "http://tu.zmzjstu.com/ftp/2017/0214/s_1466530223001c6e506287b090f1db3d.jpg"
            }
        ]
    }
}
```
我们当然不能定义`let 2017-08-06: [TV]`这样的属性。通常遇到需要重命名的key，会通过遵循`CodingKey`协议来处理：
```swift
struct Schedule: Decodable {
    
    var todayTVs: [TV] = []
    
    enum CodingKeys: String, CodingKey {
        case todayTVs = "2017-08-06"
    }
}
```

但是当这个key每天都不一样，就无法只通过定义rawValue无法动态变更的枚举来处理了。


怎么办呢？

在`Decoder`中，有一个方法可以用来解码动态key：
```swift
/// Returns the data stored in this decoder as represented in a container
/// keyed by the given key type.
///
/// - parameter type: The key type to use for the container.
/// - returns: A keyed decoding container view into this decoder.
/// - throws: `DecodingError.typeMismatch` if the encountered stored value is
func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey
```
这个方法返回值是存储了我们输入的自定义key的解码容器，而自定义key需要遵循`CodingKey`协议。
查看`CodingKey`:
```swift
protocol CodingKey : CustomDebugStringConvertible, CustomStringConvertible {

    var stringValue: String { get }
    init?(stringValue: String)

    var intValue: Int? { get }
    init?(intValue: Int)
}
```
可知`CodingKey`支持自定义`Int`和`String`类型。因为`2017-08-06`是字符串，所以我们只需要完成`String`的初始化:
```swift
struct DateKey: CodingKey {

    var stringValue: String
    init(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int? { return nil }
    init?(intValue: Int) { return nil }
}
```
然后将`DateKey`实例传入`Decoder`的 Container（解码容器）就可以了。完整代码如下：


```swift
struct ResponseModel: Decodable {
    
    let data: Schedule
    let info: String
    let status: Int
}

struct TV: Decodable {
    
    let id: String
    let cnname: String
    let poster: String
}

struct Schedule: Decodable {
    
    let todayTVs: [TV]
}

extension Schedule {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: DateKey.self)
        self.todayTVs = try container.decode([TV].self, forKey: .dateKey)
    }

    struct DateKey : CodingKey {
        
        var stringValue: String
        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let dateKey = DateKey(stringValue: today())
        
        private static func today() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "zh-CN")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: Date())
        }
    }
}
```


* [Ultimate Guide to JSON Parsing with Swift 4](http://benscheirman.com/2017/06/ultimate-guide-to-json-parsing-with-swift-4/)




