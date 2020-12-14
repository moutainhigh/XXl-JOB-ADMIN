# 边框心理环境搭建
### 依赖环境
| 名称          | 版本                |注意事项             |
| ------------- | ------------------- | ------------------- |
| MySQL         | 5.7                 | 1.配置容器与宿主机时间同步2.不区分大小写                 |
| Redis         | 5 |                  |
| RabbitMQ      | 3.7.15 |               |
| MinIO         |                     |                 |
| Nginx         | 1.10 |                  |
| JDK           | 8                   |              |
### 搭建步骤
> Docker环境部署

1.dokcer环境搭建
~~~
安装yum-utils：
yum install -y yum-utils device-mapper-persistent-data lvm2

为yum源添加docker仓库位置：
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

安装docker：
yum install docker-ce

启动docker：
systemctl start docker
~~~
2.安装MySQL

~~~
#下载镜像
docker pull mysql:5.7
~~~
~~~
# 创建容器
docker run -p 3306:3306 --name mysql \
-v /mydata/mysql/log:/var/log/mysql \
-v /mydata/mysql/data:/var/lib/mysql \
-v /mydata/mysql/conf:/etc/mysql \
-v /etc/localtime:/etc/localtime \
-e MYSQL_ROOT_PASSWORD=root  \
-d mysql:5.7 --lower_case_table_names=1
~~~
```
# 进入运行MySQL的docker容器：
docker exec -it mysql /bin/bash

使用MySQL命令打开客户端：
mysql -uroot -proot --default-character-set=utf8
```



3.安装Redis

```
#下载镜像
docker pull redis:5
```

```
# 创建容器
docker run -p 6379:6379 --name redis \
-v /mydata/redis/data:/data \
-d redis:5 redis-server --appendonly yes
```

```
进入Redis容器使用redis-cli命令进行连接：
docker exec -it redis redis-cli

查询所有数据
keys *
```



4.安装RabbitMQ  

```
#下载镜像
docker pull rabbitmq:3.7.15
```

```
#使用如下命令启动RabbitMQ服务：
docker run -p 5672:5672 -p 15672:15672 --name rabbitmq \
-d rabbitmq:3.7.15
```
```
#docker cp 47ee1070001d:/etc/rabbitmq/ /mydata/rabbitmq/conf
#docker cp 47ee1070001d:/var/lib/rabbitmq/ /mydata/rabbitmq/data
#docker cp 47ee1070001d:/var/log/rabbitmq/ /mydata/rabbitmq/logs
#docker cp 47ee1070001d:/opt/rabbitmq/plugins/ /mydata/rabbitmq/plugins
docker run  -p 5672:5672 -p 15672:15672 --name rabbitmq \
-v /mydata/rabbitmq/conf:/etc/rabbitmq \
-v /mydata/rabbitmq/data:/var/lib/rabbitmq \
-v /mydata/rabbitmq/plugins:/opt/rabbitmq/plugins \
-v /mydata/rabbitmq/logs:/var/log/rabbitmq \
-d rabbitmq:3.7.15
```
```
#进入容器并开启管理功能：
docker exec -it rabbitmq /bin/bash
rabbitmq-plugins enable rabbitmq_management
```

```
#开启防火墙：
firewall-cmd --zone=public --add-port=15672/tcp --permanent
firewall-cmd --reload
```

```
#访问地址查看是否安装成功：http://ip:15672
```

```
#根据需要安装rabbitmq延迟插件：

插件下载地址
https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/tag/v3.8.0

然后拷贝到docker里面去
docker cp rabbitmq_delayed_message_exchange-3.8.0.ez 6a56b1871ee3:/opt/rabbitmq/plugins

然后 rabbitmq-plugins enable rabbitmq_delayed_message_exchange 即可 注意不要带上版本和.ez
使用 rabbitmq-plugins list 命令查看已安装插件
```



5.安装MinIO

~~~
#下载镜像
docker pull minio/minio
#创建容器
docker run -p 9000:9000 --name minio \
-d --restart=always \
-e "MINIO_ACCESS_KEY=minio" \
-e "MINIO_SECRET_KEY=minioadmin" \
-v /mydata/minio/data:/data \
-v /mydata/minio/config:/root/.minio \
minio/minio server /data
~~~
6.安装Nginx

```
#下载镜像
docker pull nginx:1.10
```

```
#先运行一次容器（为了拷贝配置文件）：
docker run -p 80:80 --name nginx \
-v /mydata/nginx/html:/usr/share/nginx/html \
-v /mydata/nginx/logs:/var/log/nginx  \
-d nginx:1.10
```

```
#将容器内的配置文件拷贝到指定目录：
docker container cp nginx:/etc/nginx /mydata/nginx/
```

```
#修改文件名称：
cd mydata/nginx
mv nginx conf
```

```
#终止并删除容器：
docker stop nginx
docker rm nginx
```

```
#使用如下命令启动Nginx服务：
docker run -p 80:80 -p 3366:3366 --name nginx \
-v /mydata/nginx/html:/usr/share/nginx/html \
-v /mydata/nginx/logs:/var/log/nginx  \
-v /mydata/nginx/conf:/etc/nginx \
-d nginx:1.10
```



7.运行项目

```
用vim编辑器修改docker.service文件
vi /usr/lib/systemd/system/docker.service
需要修改的部分
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
修改成
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock
重启docker服务
systemctl stop docker
systemctl start docker
开启防火墙的Docker构建端口
firewall-cmd --zone=public --add-port=2375/tcp --permanent
firewall-cmd --reload

*注意
docker 服务启动的时候，docker服务会向iptables注册一个链，以便让docker服务管理的containner所暴露的端口之间进行通信
命令iptables -L可以查看iptables 链
如果你删除了iptables中的docker链，或者iptables的规则被丢失了（例如重启firewalld），docker就会报如上错误
只需要重启docker服务即可



docker run -p 8086:8086 \
--name project-admin \
--link mysql:db \
--link redis:redis \
--link rabbitmq:rabbit \
-v /etc/localtime:/etc/localtime \
-v /mydata/app/BorderPsychology:/var/logs/BorderPsychology \
-v /mydata/cert:/home \
-d project-admin:1.0-SNAPSHOT
```
8.MySQL数据库备份
```
#下载镜像
docker pull databack/mysql-backup
#运行容器（每晚2点执行）
docker run  \
--name mysql-backup \
--restart=always \
-e DB_DUMP_CRON="00 02 * * *" \
-e DB_DUMP_TARGET=/home \
-e DB_SERVER=172.27.17.241 \
-e DB_USER=root \
-e DB_PASS=root \
-e DB_PORT=3306 \
-e DB_NAMES=borderpsychology \
-v /mydata/mysqlback:/home \
-v /etc/localtime:/etc/localtime \
-d databack/mysql-backup:latest
```
9.安装Jenkins
```
#不带项目名
docker run -p 8080:8080 -p 50000:5000 --name jenkins \
-u root \
-v /mydata/jenkins_home:/var/jenkins_home \
-d jenkins/jenkins:lts
#带项目名
docker run -p 8080:8080 -p 50000:5000 --name jenkins \
-u root \
-v /mydata/jenkins_home:/var/jenkins_home \
-d jenkins/jenkins:lts\
--prefix="/jenkins"
```

