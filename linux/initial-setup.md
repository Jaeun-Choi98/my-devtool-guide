# Ubuntu 20.04 Server 초기 설정 가이드

**환경:** Ubuntu 20.04-server amd64

---

## 1. 계정 생성

```bash
su root                          # 루트 계정으로 전환
adduser username                 # 사용자 계정 생성
adduser username sudo            # sudo 그룹에 추가
```

## 2. Vim 설치 및 설정

```bash
sudo apt update
sudo apt install vim
vi ~/.vimrc
```

```vim
set number
set ai
set si
set cindent
set shiftwidth=4
set tabstop=4
set ignorecase
set hlsearch
set expandtab
set background=dark
set nocompatible
set fileencodings=utf-8,euc-kr
set bs=indent,eol,start
set history=1000
set ruler
set nobackup
set title
set showmatch
set nowrap
set wmnu
```

## 3. Samba 설치 및 설정

```bash
sudo apt install samba
sudo smbpasswd -a username
sudo vi /etc/samba/smb.conf
```

```ini
[username]
comment = user account
path = /home/username
valid users = username
writable = yes
create mask = 0644
directory mask = 0755
```

```bash
sudo systemctl restart smbd
```

## 4. net-tools 설치

```bash
sudo apt install net-tools
```

## 5. FTP (vsftpd) 설치 및 설정

```bash
sudo apt install vsftpd
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.orig
sudo vi /etc/vsftpd.conf
```

```ini
listen=YES                          # IPv4 단독 실행 모드
listen_ipv6=NO                      # IPv6 비활성화
anonymous_enable=NO                 # 익명 사용자 접속 차단
local_enable=YES                    # 시스템 계정 사용자 접속 허용
write_enable=YES                    # 파일 업로드 및 수정 허용
local_umask=022                     # 기본 권한 (파일 644, 디렉토리 755)
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
chroot_local_user=YES               # 홈 디렉토리 밖 접근 제한
allow_writeable_chroot=YES          # chroot된 디렉토리에 쓰기 허용
use_localtime=YES
xferlog_enable=YES                  # 전송 로그 활성화
# xferlog_file=/var/log/vsftpd.log  # 전송 로그 위치 (기본값)
dirmessage_enable=YES
ftpd_banner=Welcome to My FTP Server!

# 아래는 설정 필요x 
pasv_enable=YES
pasv_min_port=60020
pasv_max_port=60030

ssl_enable=NO
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
```

**접속:** 파일 탐색기에서 `ftp://[사용자ID@]서버_IP[:포트]`
**접속 시 에러 로그 확인:** sudo tail -f /var/log/vsftpd.log

## 6. 메시지 큐 파라미터 설정

```bash
sudo sysctl -a | grep kernel.msg           # 확인
sudo sysctl -w kernel.msgmax=65536         # 최대 메시지 크기
sudo sysctl -w kernel.msgmnb=1048576       # 메시지 큐 크기
sudo sysctl -w kernel.msgmni=16384         # 최대 메시지 큐 개수
sudo sysctl -p                             # 적용
```

**영구 적용** (`/etc/sysctl.conf`):

```ini
kernel.msgmax=65536
kernel.msgmnb=1048576
kernel.msgmni=16384
```

## 7. 파일 핸들 수 설정

```bash
sysctl -a | grep fs.file-max               # 시스템 전체 최대 확인
sudo sysctl -w fs.file-max=9223372036854775807
ulimit -a | grep open                      # 현재 사용자 제한 확인
```

**사용자별 설정** (`/etc/security/limits.conf`):

```
user1    soft    nofile    2048
user1    hard    nofile    2048
```

> 변경사항 적용을 위해 시스템 재시작 필요

## 8. 네트워크 유틸리티 설치

### 8.1. NTP (시간 동기화)

```bash
sudo apt install ntp
sudo vim /etc/ntp.conf
# server [ntp server]    # 동기화할 NTP 서버 설정
```

> 시간이 일치하지 않으면 `/etc/localtime` 심볼릭 링크를 확인

**systemd-timesyncd를 사용하는 경우:**

```bash
timedatectl                         # 시간 동기화 상태 확인
timedatectl timesync-status         # NTP 서버 주기 확인

sudo vim /etc/systemd/timesyncd.conf
```

```ini
[Time]
NTP=time.bora.net time.nuri.net time2.kriss.re.kr
FallbackNTP=ntp.ubuntu.com
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
```

```bash
timedatectl list-timezones                  # 사용 가능한 Timezone 확인
sudo timedatectl set-timezone Asia/Seoul    # Timezone 변경
```

### 8.2. traceroute

```bash
sudo apt install traceroute
```

### 8.3. tcpdump

```bash
sudo apt install tcpdump
```
