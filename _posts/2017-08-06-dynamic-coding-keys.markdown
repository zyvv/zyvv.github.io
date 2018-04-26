---
title: 'Dynamic Coding Keys'
layout: post
tags:
        - ZiMuZu
        - iOS
        - Swift
---

人人影视字幕组的`每日更新`接口返回的json里有个key是用当日的日期字符串表示的。

例如今天（8月6号）的更新列表数据的key是`2017-08-06`：

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

这个key每天都不一样，无法用常量值表示，也不可能在`CodingKey`枚举里指定一个可变的原始值。


怎么办呢？


我们需要为这个数据创建一个动态实现的`CodingKey`，代码如下：

```swift
// 顶层
struct TVSchedule: Codable {
    let data: TVScheduleData
    let info: String
    let status: Int
}

// data的Decoder
struct TVScheduleData: Codable {
    struct ScheduleDateKey : CodingKey {
        var stringValue: String
        init?(stringValue: String) {
        self.stringValue = stringValue
    }
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let todayTVs = ScheduleDateKey(stringValue: today())!
    }

        var todayTVs: [TV] = []

        init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ScheduleDateKey.self)
        do {
            let todayTVs = try container.decode([TV].self, forKey: .todayTVs)
            self.todayTVs = todayTVs
        } catch {
            print(error)
        }
    }
        // 未实现
        func encode(to encoder: Encoder) throws {
        }
}

func today() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "zh-CN")
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: Date())
}

```


* [Ultimate Guide to JSON Parsing with Swift 4](http://benscheirman.com/2017/06/ultimate-guide-to-json-parsing-with-swift-4/)




