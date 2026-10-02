# 网络工具箱（安卓版）

ipip.net 免费替代客户端 · Flutter 实现 · GitHub Actions 免费编译

## 功能
- 我的 IP：ip-api.com / ipwho.is / ip.sb / Cloudflare 四源交叉
- IP 查询：批量归属地（国家/省份/城市/ISP/ASN）
- Ping：系统 ping 命令实时输出
- 路由追踪：Android 无 traceroute，用 DoH 解析目标全部 A 记录 + 逐 IP 归属地替代
- 端口扫描：并发 TCP 探测，常用服务识别
- DoH 解析：A/AAAA/CNAME/MX/NS/TXT/HTTPS(ECH/SVCB)/SOA，端点可自定义（填自己的 cloudflare-gateway 可查 ECH 记录）

## 构建
推送 main 分支自动触发 GitHub Actions 编译，APK 在 Actions 产物中。
