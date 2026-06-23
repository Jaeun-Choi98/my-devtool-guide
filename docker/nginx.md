# Docker Nginx 파일 서버 가이드

## 방법 1: Docker 컨테이너 옵션 사용

```bash
docker run -d \
  --name fileserver \
  -p 8080:80 \
  -v /path/to/your/files:/usr/share/nginx/html:ro \
  -v /path/to/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx:alpine
```

## 방법 2: Dockerfile (권장)

### 프로젝트 구조

```
fileserver/
├── Dockerfile
├── nginx.conf
└── files/
    └── resource/
        └── TimeSpaceDiagram/
            └── latest.yml
```

### Dockerfile

```dockerfile
FROM nginx:alpine

# 커스텀 Nginx 설정 복사
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 파일 복사 (선택사항 - 볼륨 마운트도 가능)
# COPY files/ /usr/share/nginx/html/

EXPOSE 80
```

### nginx.conf

```nginx
server {
    listen 80;
    server_name _;

    # 파일 브라우징 활성화
    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;

    location / {
        root /usr/share/nginx/html;
        # CORS 설정 (필요시)
        add_header Access-Control-Allow-Origin *;
    }

    # 또는 /update 경로 사용
    location /update/ {
        alias /usr/share/nginx/html/;
    }
}
```

### 빌드 및 실행

```bash
# 이미지 빌드
docker build -t my-fileserver .

# 실행 (볼륨 마운트)
docker run -d \
  --name fileserver \
  -p 8080:80 \
  -v $(pwd)/files:/usr/share/nginx/html:ro \
  my-fileserver

# 접속 테스트
curl http://localhost:8080/resource/TimeSpaceDiagram/latest.yml
```
