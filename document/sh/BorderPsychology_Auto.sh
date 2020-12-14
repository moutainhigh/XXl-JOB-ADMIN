#Jenkins自动部署
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
#/mydata/sh/BorderPsychology.sh