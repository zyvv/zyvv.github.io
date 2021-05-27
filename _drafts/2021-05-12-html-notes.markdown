---
title: 'HTML笔记'
layout: post
tags: 
    - 笔记
    - HTML
---

VSCode快捷键：
!+tap 快速生成HTML模板

块级元素：默认情况下，块级元素会新起一行。
https://developer.mozilla.org/zh-CN/docs/Web/HTML/Block-level_elements
行内元素
https://developer.mozilla.org/zh-CN/docs/Web/HTML/Inline_elements

分组选择器
,
div, span 
同时匹配<span> 元素和 <div> 元素。

后代组合器
空格

div span
匹配所有位于任意 <div> 元素之内的 <span> 元素。

直接子代组合器
>
ul > li 
匹配直接嵌套<ul> 元素内的所有 <li> 元素。

一般兄弟组合器
~
p ~ span
匹配同一父元素下，<p> 元素后的所有 <span> 元素。

紧邻兄弟组合器
+
h2 + p 会匹配所有紧邻在 <h2> 元素后的 <p> 元素。
