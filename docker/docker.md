# Docker 설치 가이드

## Ubuntu

```bash
# 1. apt 업데이트
sudo apt update

# 2. 필수 패키지 설치
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

# 3. Docker GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 4. Docker 리포지토리 추가
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update

# 5. Docker 설치
sudo apt install docker-ce
```

## RHEL / CentOS

```bash
# 1. yum-utils 설치
yum install -y yum-utils

# 2. Docker 리포지토리 추가
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 3. Docker 설치
yum install -y docker-ce
```
