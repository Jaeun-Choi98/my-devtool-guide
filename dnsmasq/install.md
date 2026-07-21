# dnsmasq 설치 가이드

## 배경 지식: /etc/resolv.conf와 systemd-resolved

DNS 질의 흐름

1. 앱이 /etc/resolv.conf(→ stub-resolv.conf)를 참조해서 127.0.0.53:53으로 질의를 보냄
2. 127.0.0.53:53은 별도 프로세스가 아니라 systemd-resolved 자신이 열어놓은 stub 리스너임. 즉 "다른 데몬에게 위임"하는 게 아니라, 같은 프로세스 내부에서 요청을 받아 바로 처리함
3. systemd-resolved는 /etc/systemd/resolved.conf 설정과 각 네트워크 인터페이스가 받은 DNS 정보(DHCP, networkd/NetworkManager 등)를 바탕으로 실제 업스트림 DNS 서버에 질의를 날림

/run/systemd/resolve/stub-resolv.conf: nameserver 127.0.0.53만 담음. 모든 질의가 로컬 stub을 거치게 해서 캐싱/DNSSEC 검증 등을 적용받게 하는 용도. /etc/resolv.conf가 기본으로 이걸 가리킴
/run/systemd/resolve/resolv.conf: 모든 인터페이스의 실제 업스트림 DNS 서버 목록을 합쳐놓은 raw 목록. stub을 안 쓰고 싶은 프로그램이 직접 참조하는 용도(uplink/static 모드)
-> 파일 두 개의 역할 (둘 다 systemd-resolved가 만드는 출력물이지 입력이 아님)

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
