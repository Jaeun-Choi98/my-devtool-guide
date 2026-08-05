## 도커 파일 빌드

```
docker build --platform linux/amd64 -t my-linux-amd64 .
```

## 빌드 후 확인

```
docker images | grep my-linux-amd64
docker run --rm --platform linux/amd64 my-linux-amd64 uname -m
```

x86_64 나오면 정상.

## 컨테이너 실행

```
# vsftd
docker run -d --platform linux/amd64 \
  -p 2222:22 \
  -p 21:21 -p 21100-21110:21100-21110 \
  --name linux-amd64-dev \
  my-linux-amd64 tail -f /dev/null

docker run -d --platform linux/amd64 \
  -p 2222:22 \
  --name linux-amd64-dev \
  my-linux-amd64 tail -f /dev/null

# docker run -d --platform linux/amd64 --name linux-amd64-dev my-linux-amd64 tail -f /dev/null
docker exec -it linux-amd64-dev bash
```
