# RabbitMQ 설치 가이드 (Ubuntu)

## 설치

### 1. 의존성 추가

```bash
sudo apt-get install curl gnupg apt-transport-https -y
```

### 2. 레포지터리 인증키 추가

```bash
curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
  | sudo gpg --dearmor | sudo tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null
```

### 3. 레포지터리 소스 리스트 추가

> 배포판에 따라 내용이 다를 수 있음. [RabbitMQ 공식 다운로드](https://www.rabbitmq.com/docs/install-debian)에서 확인

아래는 **Ubuntu 24.04 (noble)** 기준:

```bash
sudo tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Modern Erlang/OTP releases
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb1.rabbitmq.com/rabbitmq-erlang/ubuntu/noble noble main
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb2.rabbitmq.com/rabbitmq-erlang/ubuntu/noble noble main

## Latest RabbitMQ releases
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb1.rabbitmq.com/rabbitmq-server/ubuntu/noble noble main
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb2.rabbitmq.com/rabbitmq-server/ubuntu/noble noble main
EOF
```

### 4. Erlang 패키지 설치

```bash
sudo apt-get update -y
sudo apt-get install -y erlang-base \
    erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
    erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
    erlang-runtime-tools erlang-snmp erlang-ssl \
    erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl
```

### 5. RabbitMQ 설치

```bash
sudo apt-get install rabbitmq-server -y --fix-missing
```

---

## 설정 (Config)

기본 설치 시 기본 설정이 제공됨. 튜닝이 필요한 경우:

| 항목 | 경로/설명 |
|------|-----------|
| Home directory | `/var/lib/rabbitmq` |
| Config files | `/etc/rabbitmq/rabbitmq.conf`, `/etc/rabbitmq/advanced.config` |
| `rabbitmq.conf` | 새로운 스타일 형식 (대부분의 설정에 권장) |
| `advanced.config` | Erlang term 형식, 고급 설정용 |

**설정 예시:** [rabbitmq.conf.example](https://github.com/rabbitmq/rabbitmq-server/blob/main/deps/rabbit/docs/rabbitmq.conf.example)

```ini
# 포트 변경 예시
listeners.tcp.default = 5673
```

---

## 인증 및 권한 (Authentication, Authorization)

기본 사용자: `guest/guest` (localhost에서만 접속 가능)

### 유저 관리

```bash
# 유저 추가
rabbitmqctl add_user 'username' 'password'

# 특수문자(!, &, $, # 등)가 포함된 비밀번호는 echo로 전달
echo '2a55f70a841f18b97c3a7db939b7adc9e34a0f1b' | rabbitmqctl add_user 'username'

# 유저 목록 확인
rabbitmqctl list_users

# 유저 삭제
rabbitmqctl delete_user 'username'
```

### 권한 관리

```bash
# 권한 부여 (configure / write / read)
rabbitmqctl set_permissions -p "/" "username" ".*" ".*" ".*"

# 특정 vhost에 권한 부여
rabbitmqctl set_permissions -p "custom-vhost" "username" ".*" ".*" ".*"

# 권한 삭제
rabbitmqctl clear_permissions -p "custom-vhost" "username"
```

### VHost 관리

```bash
rabbitmqctl list_vhosts           # vhost 목록 확인
rabbitmqctl add_vhost "custom-vhost"    # 새 vhost 생성
rabbitmqctl delete_vhost "custom-vhost" # vhost 삭제
```

---

## 시스템 제한 설정 (Open Files)

```bash
# 현재 open files 확인 (기본: 1024, 공식 권장: 65536)
ulimit -n
```

### open files 변경

```bash
sudo vi /etc/systemd/system/rabbitmq-server.service.d/limits.conf
```

```ini
[Service]
LimitNOFILE=64000
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart rabbitmq-server

# 변경 확인
rabbitmq-diagnostics status
```
