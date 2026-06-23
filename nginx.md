# Nginx 파일 서버 설치 가이드 (Ubuntu)

## 1. Nginx 설치

```bash
sudo apt update
sudo apt install nginx -y
```

## 2. 파일 서버 디렉토리 생성

```bash
sudo mkdir -p /var/www/files
sudo chown -R www-data:www-data /var/www/files
sudo chmod -R 755 /var/www/files
```

## 3. Nginx 설정 파일 생성

```bash
sudo nano /etc/nginx/sites-available/fileserver
```

**기본 파일 서버 설정:**

```nginx
server {
    listen 80;
    server_name _;  # 또는 your-domain.com

    # 파일 브라우징 활성화
    autoindex on;
    autoindex_exact_size off;   # 파일 크기를 KB, MB로 표시
    autoindex_localtime on;     # 로컬 시간으로 표시

    location / {
        root /var/www/files;
    }
}
```

**특정 경로 매핑 (예: /update/*):**

```nginx
server {
    listen 80;
    server_name _;

    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;

    location /update/ {
        alias /var/www/files/;
        # /update/resource/test.yml → /var/www/files/resource/test.yml
    }

    # 다운로드 속도 제한 (선택사항)
    # limit_rate 1m;  # 1MB/s
}
```

## 4. 설정 활성화

```bash
# 심볼릭 링크 생성
sudo ln -s /etc/nginx/sites-available/fileserver /etc/nginx/sites-enabled/

# 기본 설정 비활성화 (선택사항)
sudo rm /etc/nginx/sites-enabled/default

# 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

## 5. 방화벽 설정

```bash
sudo ufw allow 'Nginx Full'
# 또는
sudo ufw allow 80/tcp
```

## 6. 파일 업로드 (테스트)

```bash
sudo mkdir -p /var/www/files/resource/TimeSpaceDiagram
echo "test content" | sudo tee /var/www/files/resource/TimeSpaceDiagram/latest.yml
sudo chown -R www-data:www-data /var/www/files
```

## 7. 접속 테스트

```bash
# 브라우저: http://your-server-ip/
curl http://localhost/resource/TimeSpaceDiagram/latest.yml
```

---

## 추가 옵션

### Basic Auth 인증

```bash
sudo apt install apache2-utils -y
sudo htpasswd -c /etc/nginx/.htpasswd username
```

```nginx
location / {
    root /var/www/files;
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

### HTTPS 설정 (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

### 로그 확인

```bash
sudo tail -f /var/log/nginx/access.log    # 액세스 로그
sudo tail -f /var/log/nginx/error.log     # 에러 로그
```
