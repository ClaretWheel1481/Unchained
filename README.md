# Unchained
内网穿透Client - Flutter Version

## 使用方法
1. 防火墙开放需要连接及通行的端口
2. 前往[Rathole]("https://github.com/rapiz1/rathole")下载并在服务端根据README运行Rathole服务端
3. 下载并运行Unchained
4. 在Unchained中输入Rathole服务端的[server]下的**bind.addr**和Token，以及需要转发的端口地址
5. 点击开始穿透，显示Control channel established则表示穿透成功，此时连接服务端的[server.services.*]下的**bind_addr**即可。

## 致谢
[Rathole]("https://github.com/rapiz1/rathole")

## 截图
![Screenshot](/public/screenshot.png)