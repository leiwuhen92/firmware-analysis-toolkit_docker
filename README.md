# firmware-analysis-toolkit_docker

## 构建镜像
docker build -t simulation:1.0 .

## 挂载固件运行
docker run -it --rm --privileged -p 8066:80 -v /dev:/dev -v /home/firmware_run/input:/root/input simulation:1.0 ./fat.py  /root/input/"WNAP320 Firmware Version 2.0.3.zip"


🚩 **固件仿真运行报错** 🚩
	https://github.com/attify/firmware-analysis-toolkit/issues/62
	https://www.coder.work/article/2603490  postgresql - postgres createuser 使用来自终端的密码
	https://www.oomake.com/question/6336022  为什么你不能使用“service postgres start”在docker中启动postgres？
	https://github.com/firmadyne/firmadyne/issues/170    解决:docker运行容器添加--privileged -v /dev:/dev
	https://github.com/firmadyne/firmadyne/issues/149  已在 Docker 容器中安装了 firmadyne，并且能够获取网络 IP，但 Netgear 的网页仍然不可见

## postgres
service postgresql start
psql -U firmadyne -h127.0.0.1 -p5432 -dfirmware

## 外网访问
## 1、einetd端口转发工具
	在docker容器内添加端口映射
	```shell
	root@a8e4d33280d9:/# vi /etc/rinetd.conf
	0.0.0.0 80 192.168.0.100 80

	root@a8e4d33280d9:/# pkill rinetd   		     # 关闭进程
	root@a8e4d33280d9:/# rinetd -c /etc/rinetd.conf  # 启动转发
	
	web访问地址：http://宿主机hostip:8066    # admin/password
	```
	