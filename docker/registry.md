# 사설 Docker Registry 구축 가이드 (SSL 인증서 사용)

## 1. 자체 서명 인증서(SSC) 만들기

```bash
mkdir certs

# 개인키 생성 및 Root 인증서(CA) 생성
openssl genrsa -out ./certs/ca.key 2048
openssl req -x509 -new -key ./certs/ca.key -days 10000 -out ./certs/ca.crt

# 루트 인증서로 새로운 인증서 발급
openssl genrsa -out ./certs/domain.key 2048
openssl req -new -key ./certs/domain.key -subj /CN=10.1.0.118 -out ./certs/domain.csr
echo subjectAltName = IP:10.1.0.118 > extfile.cnf
openssl x509 -req -in ./certs/domain.csr \
  -CA ./certs/ca.crt \
  -CAkey ./certs/ca.key \
  -CAcreateserial -out ./certs/domain.crt \
  -days 90000 -extfile extfile.cnf
```

## 2. 접속 제한 추가

```bash
sudo docker run --entrypoint htpasswd httpd:2 -Bbn juchoi 1234 \
  > /home/theroad/juchoi/docker-config/auth/passwords
```

## 3. Docker Registry 컨테이너 실행

```bash
sudo docker run -d -p 443:443 --restart=always --name registry \
  -v /home/theroad/juchoi/docker-config/auth:/auth \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/passwords \
  -v /home/theroad/juchoi/docker-config/certs:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:3
```

## 4. CA 인증서 등록 (Ubuntu)

```bash
sudo cp certs/ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
sudo systemctl restart docker
```

## 5. 테스트

```bash
curl -u juchoi:1234 https://10.1.0.118:443/v2/_catalog
sudo docker login 10.1.0.118:443
```

## 6. 이미지 Push

```bash
# 1. 이미지 태그 만들기
sudo docker tag <my-image>:<tag> <host_ip>:443/<my-image-name>:<tag>

# 2. 이미지 Push
sudo docker push <host_ip>:443/<my-image-name>:<tag>
```
