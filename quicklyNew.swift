#!/usr/bin/env swift

import Foundation

func main() {
    let fileManager = FileManager.default
    print("输入标题：")
    var blogName = readLine()
    print("输入链接标题(英文)：")
    guard let linkName = readLine() else { fatalError("标题不能为空") }
    print("输入tags(空格隔开)：")
    let tags = readLine()?.components(separatedBy: " ") ?? []
    if blogName == nil { blogName = linkName }
    let currentPath = fileManager.currentDirectoryPath
    let blogPath = "\(currentPath)/_posts/\(formatDateString())-\(linkName).markdown"
    let blogURL = URL(fileURLWithPath: blogPath)
    print("本地URL:\(blogPath)")
    if fileManager.fileExists(atPath: blogPath) {
        print("此博文已存在, 是否打开？y/n")
        if readLine()?.lowercased() == "y" {
            openBlog(blogURL)
        } else {
            main()
        }
        return
    }
    do {
        let templateString = template(blogName!, tags: tags)
        print(templateString)
        try templateString.write(to: blogURL, atomically: false, encoding: .utf8)
        openBlog(blogURL)
    } catch {
        fatalError(error.localizedDescription)
    }
}

func formatDateString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
}

func template(_ titleName: String, tags: [String]) -> String {
    """
    ---
    title: '\(titleName)'
    layout: post
    tags: \(tags.reduce("\n") { $0 + "      - \($1)\n" })
    ---\n\n\n
    """
}

func openBlog(_ path: URL) {
    print("正在启动VSCode...")
    let process = Process()
    process.launchPath = "/usr/bin/open"
    process.arguments = ["-n", "/Applications/Visual Studio Code.app", "--args", path.path]
    process.launch()
    process.waitUntilExit()
}

main()
