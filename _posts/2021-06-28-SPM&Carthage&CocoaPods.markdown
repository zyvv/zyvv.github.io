---
title: 'SPM Carthage CocoaPods'
layout: post
tags: 
      - iOS
      - Swift

---


### 创建 CocoaPods:
```ogdl
pod spec create PodspecName

git tag
git push

pod spec lint PodspecName.podspec --verbose --allow-warnings

// pod trunk register email "username"

pod trunk push PodspecName.podspec --verbose --allow-warnings
```

### 创建 Carthage:

1. Create Framework
2. Share Build Schemes
3. Remove `iphonesimulator` in `Supported Platforms`
4. Build
```
carthage build --no-skip-current
```

### 创建 Swift Package Manager
1. Xcode: New -> Swift Package...

or

```
swift package init    
```