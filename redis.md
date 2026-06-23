# Redis 설치 가이드

## Ubuntu 네이티브 설치

### 설치 (latest)

```bash
sudo apt-get install lsb-release curl gpg
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
sudo chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/redis.list
sudo apt-get update
sudo apt-get install redis
```

### 특정 버전 설치

```bash
apt policy redis
# e.g.
sudo apt-get install redis=6:7.4.2-1rl1~jammy1
```

### 실행

```bash
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

### CLI 테스트

```bash
redis-cli -h 127.0.0.1 -p 6379
```

### 환경 설정

```bash
sudo vi /etc/redis/redis.conf
```

```ini
bind 0.0.0.0 -::1
requirepass 1234
```

```bash
sudo systemctl restart redis-server
```

---

## Docker 사용

### 기본 실행

```bash
sudo docker run -d \
  --name redis \
  -p 6379:6379 \
  redis:latest redis-server --bind 0.0.0.0
```

### CLI 테스트

```bash
docker exec -it redis redis-cli
127.0.0.1:6379> config get requirepass
127.0.0.1:6379> config set requirepass <passwd>
```

### 설정 파일 적용

**방법 1: Dockerfile 사용**

```dockerfile
FROM redis
COPY redis.conf /usr/local/etc/redis/redis.conf
CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
```

```bash
sudo docker build -t myredis:latest ./
sudo docker run -d --name myredis -p 6379:6379 myredis:latest
```

**방법 2: run 옵션 사용**

```bash
docker run -v /myredis/conf:/usr/local/etc/redis \
  --name myredis \
  redis redis-server /usr/local/etc/redis/redis.conf
```
