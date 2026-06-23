# dnsmasq 설치 가이드

## 배경 지식: /etc/resolv.conf와 systemd-resolved

- 응용프로그램은 보통 `/etc/resolv.conf`을 통해 DNS 질의를 요청한다.
- `/etc/resolv.conf` 파일이 `/run/systemd/resolve/stub-resolv.conf`에 심볼릭 링크되어 있고, 내부에 `127.0.0.53`으로 명시되어 있다.
- `systemd-resolved`는 stub DNS 서버 기능과 DNS resolve 기능을 가지고 있다.
- stub DNS 서버(`127.0.0.53`)는 들어온 질의를 `systemd-resolved` 데몬에게 위임한다.
- `systemd-resolved`는 실제 DNS resolve 기능을 수행하며, `/run/systemd/resolve/resolv.conf`을 반영하여 처리한다.
- `systemd-resolved`의 설정을 수정하려면 `/etc/systemd/resolved.conf`를 수정한다.

---

## dnsmasq 구축

### 1. systemd-resolved 비활성화

systemd-resolved를 비활성화하여 기본 DNS 처리를 중지하고, dnsmasq가 직접 DNS 처리를 수행하도록 설정한다.

```bash
sudo systemctl disable --now systemd-resolved
sudo systemctl stop systemd-resolved
sudo ls -lh /etc/resolv.conf            # 기존 resolv.conf 확인
sudo rm -rf /etc/resolv.conf            # 기존 resolv.conf 삭제
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf   # 외부 DNS(Google DNS) 설정
```

### 2. dnsmasq 설치

```bash
sudo apt update
sudo apt install dnsmasq
sudo systemctl status dnsmasq
```

> **서버 리부트 시 resolv.conf 초기화 문제 해결:**
> - Ubuntu: `/etc/NetworkManager/NetworkManager.conf`에서 `[main]` 섹션에 `dns=none` 설정
> - CentOS: `/etc/sysconfig/network-scripts/ifcfg-[네트워크인터페이스]`에서 `NM_CONTROLLED=no` 설정

### 3. dnsmasq 설정

```bash
sudo cp /etc/dnsmasq.conf{,.bak}    # 설정 파일 백업
sudo vim /etc/dnsmasq.conf
```

```ini
# DNS 서비스 포트 (기본 53번)
port=53
# 도메인 이름이 없으면 DNS 요청을 무시
domain-needed
# 사설 IP를 외부 DNS로부터 받아오는 것을 무시
bogus-priv
# DNSSEC 활성화 (DNS 위조 방지, trust-anchors 파일 필수)
conf-file=/usr/share/dnsmasq/trust-anchors.conf
dnssec
# DNS 서버 순서를 엄격히 따름
strict-order
# 호스트 이름에 도메인 자동 추가
expand-hosts
# 로컬 도메인 이름 설정
domain=example.com
# DNS 질의 요청을 처리할 IP
listen-address=127.0.0.1,(192.168.1.100)
# DNS 질의 로그 활성화
log-queries
# DNS 로그 파일 경로
log-facility=/var/log/dnsmasq.log
# /etc/resolv.conf 무시하고 server= 로 지정한 DNS만 사용
no-resolv
# 외부 DNS 설정
server=8.8.8.8
```

```bash
sudo systemctl restart dnsmasq
```

### 4. 호스트 설정

```bash
sudo vim /etc/hosts
```

```
192.168.1.10 server1.example.com
192.168.1.20 server2.example.com
192.168.1.30 app.example.com
```

```bash
sudo systemctl restart dnsmasq
```

### 5. dnsmasq 테스트

```bash
# 설정 파일 문법 검사
dnsmasq --test

# 재시작 및 포트 확인
systemctl restart dnsmasq
netstat -alnp | grep -i :53
```

### 6. DNS 호스트 테스트

```bash
dig A erp.mypridomain.com
tail -f /var/log/dnsmasq.log    # DNS 로그 실시간 확인
```
