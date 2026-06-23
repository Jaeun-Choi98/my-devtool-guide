# Docker 설치 가이드

## Ubuntu

```bash
# 1. apt 업데이트
sudo apt update

# 2. 필수 패키지 설치
sudo apt install ca-certificates curl

# 3. Docker GPG 키 추가
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 4. Docker 리포지토리 추가
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

# 5. Docker 설치
sudo apt install docker-ce docker-ce-cli containerd.io
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
