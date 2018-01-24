# BaiduDirectLink
简单的一个小APP，分析百度网盘的API，获取列表和直接下载链接

## 使用
1. 使用App登陆百度云
2. 使用右上角的首页，获取下载目录
3. 点击需要下载的文件，等待链接生成
4. 在弹出的框里选择分享方式
5. 在电脑浏览器登陆百度云，然后使用之前手机生成的链接下载文件。


![alt text](https://github.com/sosoyososo/BaiduDirectLink/blob/master/screenShoot.png?raw=true)

依赖使用Carthage，其中KCBlockUIKit可以在 https://github.com/sosoyososo/KCBlockUIKit 找到，其余的都是github上常见的
![alt text](https://github.com/sosoyososo/BaiduDirectLink/blob/master/dependency.png?raw=true)


## TODO
1. 文件名包含特殊字符(比如&)的时候无法下载
2. webView无法返回
