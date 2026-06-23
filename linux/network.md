# 네트워크 설정 가이드 (Ubuntu Netplan)

## 네트워크 상태 확인

```bash
# 네트워크 연결 상태 확인 (state UP 확인)
ip addr show

# 연결된 게이트웨이 정보 확인 (default via [게이트웨이])
ip route show
```

## 동적/고정 IP 설정

```bash
sudo vim /etc/netplan/*.yaml
```

```yaml
network:
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
