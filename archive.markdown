---
title: 列表
layout: page
---

<ul class="listing">
{% for post in site.posts %}
  {% capture y %}{{post.date | date:"%Y"}}{% endcapture %}
  {% if year != y %}
    {% assign year = y %}
    <span class="year-seperator">
     <span class="fa fa-quote-left"></span>
     <span class="artist-list"> <li class="listing-seperator">{{ y }}</li></span>
    </span>
  {% endif %}
  <li class="listing-item">
    <time datetime="{{ post.date | date:"%m-%d" }}">{{ post.date | date:"%m-%d" }}</time>
    <a href="{{ post.url }}" title="{{ post.title }}">{{ post.title }}</a>
  </li>
{% endfor %}
</ul>
