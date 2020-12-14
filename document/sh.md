# 边框心理后台
## Jenkins自动部署【脚本】:
```
#!/usr/bin/env bash
app_name='project-admin'
docker stop ${app_name}
echo '----stop container----'
docker rm ${app_name}
echo '----rm container----'
docker rmi `docker images | grep none | awk '{print $3}'`
echo '----rm none images----'
docker run -p 8086:8086 \
--name ${app_name} \
--link mysql:db \
--link redis:redis \
--link rabbitmq:rabbit \
-v /etc/localtime:/etc/localtime \
-v /mydata/app/BorderPsychology:/var/logs/BorderPsychology \
-v /mydata/cert:/home \
-d ${app_name}:1.0-SNAPSHOT
echo '----start container----'
```
## Dockerfile构建镜像并发布【脚本】:
```
Dockerfile文件:
# 该镜像需要依赖的基础镜像
FROM java:8
# 将当前目录下的jar包复制到docker容器的/目录下
ADD project-admin-1.0-SNAPSHOT.jar /project-admin-1.0-SNAPSHOT.jar
# 运行过程中创建一个project-admin-1.0-SNAPSHOT.jar文件
RUN bash -c 'touch /project-admin-1.0-SNAPSHOT.jar'
# 声明服务运行在8086端口
EXPOSE 8086
# 指定docker容器启动时运行jar包
ENTRYPOINT ["java", "-jar","-Duser.timezone=GMT+8","-Dspring.profiles.active=prod","/project-admin-1.0-SNAPSHOT.jar"]
# 指定维护者的名字
MAINTAINER dx
```
```
构建镜像并发布:
#!/usr/bin/env bash
app_name='project-admin'
app_version='1.0-SNAPSHOT'
docker build -t ${app_name}:${app_version} .
echo '----build image success----'
docker stop ${app_name}
echo '----stop container----'
docker rm ${app_name}
echo '----rm container----'
docker rmi `docker images | grep none | awk '{print $3}'`
echo '----rm none images----'
docker run -p 8086:8086 \
--name ${app_name} \
--link mysql:db \
--link redis:redis \
--link rabbitmq:rabbit \
-v /etc/localtime:/etc/localtime \
-v /mydata/app/BorderPsychology:/var/logs/BorderPsychology \
-v /mydata/cert:/home \
-d ${app_name}:${app_version}
echo '----start container----'
```