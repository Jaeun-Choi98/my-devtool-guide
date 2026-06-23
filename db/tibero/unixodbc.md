# unixODBC 설치 및 설정 가이드

## 1. 설치 전 준비 (Requirement)

### 1.1. 의존 패키지 설치

```bash
sudo apt install -y build-essential unixodbc-dev
# unixodbc-dev: 애플리케이션에서 ODBC 연결을 위한 개발 패키지
```

## 2. unixODBC 설치 (수동 설치 권장)

### 2.1. 다운로드

```bash
wget http://www.unixodbc.org/unixODBC-2.3.12.tar.gz
```

### 2.2. 압축 풀기

```bash
gunzip unixODBC-2.3.12.tar.gz
tar xvf unixODBC-2.3.12.tar
```

### 2.3. 빌드 및 설치

```bash
cd unixODBC-2.3.12
./configure --prefix=/home/juchoi/unixodbc
make
make install
```

### 2.4. 환경 변수 설정

```bash
sudo vim ~/.profile
```

```bash
export UNIXODBC_HOME=/home/juchoi/unixodbc
export LD_LIBRARY_PATH=$UNIXODBC_HOME/lib:$LD_LIBRARY_PATH
export PATH=$UNIXODBC_HOME/bin:$PATH
export ODBCINI=$UNIXODBC_HOME/etc/odbc.ini
export ODBCSYSINI=$UNIXODBC_HOME/etc
```

### 2.5. ODBC 드라이버 설정 (odbcinst.ini)

```bash
sudo vim $UNIXODBC_HOME/etc/odbcinst.ini
```

```ini
[ODBC]
Trace=yes
TraceFile=/home/juchoi/unixodbc/log/traceFile.log

[Tibero 7 ODBC driver]
Description = Tibero ODBC driver for Tibero 7
Driver = /home/juchoi/tibero7/client/lib/libtbodbc.so
DriverManagerEncoding=UTF-16
```

```bash
mkdir -p /home/juchoi/unixodbc/log
touch /home/juchoi/unixodbc/log/traceFile.log
```

### 2.6. DSN 설정 (odbc.ini)

```bash
sudo vim $UNIXODBC_HOME/etc/odbc.ini
```

```ini
[tbodbc]
Driver = Tibero 7 ODBC driver
SERVER = 10.1.0.120
PORT = 8629
DATABASE = tibero
USER = TB_TEST
PASSWORD = TB_TEST
```

### 2.7. isql 실행

```bash
isql tbodbc
```

### 2.8. 설정 확인

```bash
# 현재 설정 정보 확인
odbcinst -j

# odbcinst.ini에 정의된 드라이버 정보 확인
odbcinst -q -d

# odbc.ini에 정의된 Data Source 정보 확인
odbcinst -q -s
```
