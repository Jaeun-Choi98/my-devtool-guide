# 네트워크 설정 가이드 (Ubuntu Netplan)

## 네트워크 상태 확인

```bash
# 네트워크 하드웨어 장비 인식
sudo lshw -c "network" / sudo lshw -class network

# 10초간 포트 LED 깜빡이기 (어떤 포트인지 육안 확인)
ethtool -p eno1 10

# 네트워크 연결 상태 확인 (state UP 확인)
ip addr show

# 연결된 게이트웨이 정보 확인 (default via [게이트웨이])
ip route show

# DNS 확인
resolvectl status

# 인터페이스 UP/DOWN
sudo ip link set eno1 up
sudo ip link set eno1 down

```

## 동적/고정 IP 설정 (systemd-networkd 서버용) 

```bash
sudo vim /etc/netplan/*.yaml
```

```yaml
network:
 # renderer: networkd  # Ubuntu Server 기본값, 생략 가능
  ethernets:
    eno1:
      dhcp4: true
      # 고정 IP 설정 시:
      # addresses: [10.1.0.100/23]
      # routes:
      #   - to: 0.0.0.0/0
      #     via: 10.1.1.254
      # nameservers:
      #   addresses: [168.126.63.1, 168.126.63.2]
    enp3s0:
      # dhcp4: true
      addresses: [192.168.2.107/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.2.254
      nameservers:
        addresses: [168.126.63.1, 168.126.63.2]
    ens3f0:
      dhcp4: true
    ens3f1:
      dhcp4: true
  version: 2
```

```bash
sudo netplan generate   # 백엔드 설정 파일 생성만
sudo netplan apply      # 즉시 적용
```

## 동적/고정 IP 설정 (NetworkManager 데스크탑용) 


```bash
sudo vim /etc/NetworkManager/system-connections/연결이름.nmconnection
```

```
[connection]
# 아무이름
id=mynmconnection
# uuid 생성
# uuidgen
# 출력 예: a1b2c3d4-e5f6-7890-abcd-ef1234567890
uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# wifi로 설정 시에 [wifi], [wifi-security] 섹터를 읽음
type=ethernet  
autoconnect=true

[ethernet]
interface-name=enp3s0

[ipv4]
method=manual
address1=192.168.2.107/24,192.168.2.254   # IP/prefix,gateway
dns=168.126.63.1;168.126.63.2;

# DHCP 시:
# method=auto

[ipv6]
method=disabled

[proxy]

# connection 섹터에서 type을 wifi로 사용 시에 아래 섹터 사용
[wifi]
[wifi-security]
# 연결하면 자동으로 .nmconnection 파일 생성됨
nmcli dev wifi connect "MyWifiName" password "mypassword"
```

```bash
# 파일 권한 설정 (필수)
sudo chmod 600 /etc/NetworkManager/system-connections/연결이름.nmconnection

# 적용
sudo nmcli con reload
sudo nmcli con up "연결이름"
```
