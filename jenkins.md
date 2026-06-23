# Jenkins 설치 및 설정 가이드 (Ubuntu)

## 설치

### 1. Java 설치

```bash
apt-get update
apt-get install -y openjdk-17-jdk
```

### 2. Jenkins 공식 GPG 키 추가

```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
```

### 3. Jenkins 저장소 추가

```bash
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
```

### 4. Jenkins 설치

```bash
sudo apt-get update
sudo apt-get install -y jenkins
```

### 5. 서비스 시작 및 활성화

```bash
systemctl start jenkins
systemctl enable jenkins
```

### 방화벽 설정 (필요시)

```bash
ufw allow 8080/tcp
```

### 초기 비밀번호 확인

```bash
cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 포트 변경

```bash
sudo vi /usr/lib/systemd/system/jenkins.service
# Environment="JENKINS_PORT=80**"
```

---

## 유용한 명령어

| 명령어 | 설명 |
|--------|------|
| `sudo systemctl status jenkins` | 서비스 상태 확인 |
| `sudo systemctl restart jenkins` | 서비스 재시작 |
| `sudo journalctl -u jenkins -f` | 로그 확인 |
| `/etc/default/jenkins` | 설정 파일 |
| `/var/lib/jenkins` | 작업 디렉토리 |

---

## GitLab 트리거 설정

### 1. GitLab Access Token 발행

- repo에 대한 access token이 아닌 **user access token** 발행

### 2. Jenkins 설정

#### 2.1. Credential 생성

두 개의 자격증명을 만드는 것을 권장:
- **Username with Password**: 파이프라인 스크립트에서 repo를 pull할 때 사용
- **GitLab API Token**: GitLab API 연결 및 트리거 설정에 사용

#### 2.2. 시스템 설정

GitLab 항목에서:
- Connection Name (임의)
- GitLab Host URL (`https://gitlab.com`)
- GitLab API Credential 입력

#### 2.3. Job 설정

- GitLab Connection 설정 (시스템 설정에서 입력한 Connection Name 선택)
- 트리거 기본 설정 후 **Advanced**에서 **Secret Token 생성** → GitLab repo webhook에서 사용

### 3. GitLab 설정 (SSL 미사용)

- GitLab webhook URL과 Secret Token 입력
- webhook URL: `http://example.com/job/my-job`이라면 `http://example.com/project/my-job`으로 입력
- **Enable SSL** 항목 체크 해제
