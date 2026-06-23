# Docker Jenkins 실행 가이드

## 1. Jenkins 컨테이너 실행

```bash
sudo docker run -d \
  --name jenkins \
  --restart=unless-stopped \
  --network jenkins-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v $JENKINS_HOME:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

## 2. 초기 비밀번호 확인

```bash
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
