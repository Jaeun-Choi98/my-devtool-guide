# Oracle 서버 설치 가이드 (Ubuntu)

## 방법 1: Oracle XE 11g (간편 설치)

### 1. Oracle XE 11g 다운로드

### 2. 압축 풀기

```bash
sudo apt install unzip   # 없으면 설치
unzip oracle-xe-11.2.0-1.0.x86_64.rpm.zip
```

### 3. RPM → DEB 변환

```bash
sudo apt install -y alien libaio1 unixodbc
sudo alien --scripts -d oracle-xe-11.2.0-1.0.x86_64.rpm
```

### 4. DEB 파일 설치

```bash
sudo dpkg --install oracle-xe_11.2.0-2_amd64.deb
```

### 5. 환경 설정

```bash
# netstat 명령어가 필요하므로 설치
sudo apt install net-tools

# 환경 설정 (포트 설정 및 system 암호 설정)
sudo /etc/init.d/oracle-xe configure
```

### 6. 환경 변수 추가

`~/.profile`에 추가:

```bash
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export ORACLE_SID=XE
# American_America.AL32UTF8 대신 Korean_Korea.AL32UTF8로 명시적 설정 권장
export NLS_LANG=Korean_Korea.AL32UTF8
export ORACLE_BASE=/u01/app/oracle
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH
```

```bash
source ~/.profile
```

### 7. Oracle 구동

```bash
sudo service oracle-xe start
```

### 8. sqlplus 접속

```bash
sqlplus system
```

```sql
CREATE USER [유저명] IDENTIFIED BY [passwd];
GRANT CONNECT, RESOURCE, DBA TO [유저명];
COMMIT;
```

---

## 방법 2: Oracle 11gR2 (전체 설치)

### 1. 기본 시스템 준비

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install alien libaio1 unixodbc sysstat ksh libcap2 -y
```

| 패키지 | 용도 |
|--------|------|
| `alien` | RPM → DEB 변환 |
| `libaio1` | Oracle I/O 의존성 |
| `unixodbc`, `sysstat`, `ksh` | 필수 유틸리티 |
| `libcap2` | 권한 관리용 라이브러리 |

### 2. 커널 파라미터 조정

`/etc/sysctl.conf`에 추가:

```ini
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmax = 536870912
kernel.shmall = 2097152
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
```

```bash
sudo sysctl -p
```

### 3. 리소스 제한 설정

`/etc/security/limits.conf`에 추가:

```
oracle   soft   nproc    2047
oracle   hard   nproc    16384
oracle   soft   nofile   1024
oracle   hard   nofile   65536
oracle   soft   stack    10240
```

`/etc/pam.d/common-session` 마지막 줄에 추가:

```
session required pam_limits.so
```

### 4. Oracle 유저 생성

```bash
sudo groupadd oinstall
sudo groupadd dba
sudo useradd -m -g oinstall -G dba oracle
sudo passwd oracle

# 홈 디렉토리 준비
sudo mkdir -p /u01/app/oracle
sudo chown -R oracle:oinstall /u01
sudo chmod -R 775 /u01
```

### 5. 설치 파일 준비

```bash
# 보통 설치 파일은 2개 (1of2, 2of2)
unzip linux_11gR2_database_1of2.zip
unzip linux_11gR2_database_2of2.zip
```

### 6. 설치 스크립트 수정 (OS 체크 무시)

Ubuntu에서는 OS 버전 체크에서 실패하므로 수정 필요:

```bash
vi database/install/oraparam.ini
# [Certified Versions] 항목에 추가:
# Linux=Ubuntu-20.04
```

### 7. 설치 시작

```bash
# oracle 계정으로 로그인
sudo su - oracle

# GUI 설치화면
cd /path/to/database/
./runInstaller
```

**설치 옵션:**
- Software only 설치 가능 (DBCA로 나중에 DB 생성)
- 또는 바로 Database까지 생성

**설치 후 root로 실행:**

```bash
sudo /u01/app/oraInventory/orainstRoot.sh
sudo /u01/app/oracle/product/11.2.0/dbhome_1/root.sh
```

### 8. Listener / DB 생성

```bash
netca    # 리스너 설정
dbca     # 데이터베이스 생성
```

### 9. 환경 변수 설정

`~/.profile`에 추가:

```bash
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=ORCL
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
```
