# Oracle Instant Client 설치 가이드 (Ubuntu)

## 1. Oracle Instant Client 다운로드

[Oracle Instant Client 다운로드 페이지](https://www.oracle.com/kr/database/technologies/instant-client/linux-x86-64-downloads.html)에서 zip 파일 다운로드

```
instantclient-basic-linux.x64-19.26
instantclient-sqlplus-linux.x64-19.26       # sqlplus가 이미 있다면 불필요
instantclient-sdk-linux.x64-19.26
```

## 2. 압축 해제

```bash
mkdir /oracle/instant-client
sudo unzip instantclient-basic-linux.x64-19.26 -d /oracle/instant-client
unzip instantclient-sqlplus-linux.x64-19.26 -d /oracle/instant-client
unzip instantclient-sdk-linux.x64-19.26 -d /oracle/instant-client
# 압축 해제하면 instantclient_19_26 폴더가 생성됨
```

## 3. 환경 변수 설정

```bash
sudo vim ~/.bashrc
```

```bash
export ORA_CLIENT_HOME=/oracle/instant-client/instantclient_19_26
export LD_LIBRARY_PATH=$ORA_CLIENT_HOME:$LD_LIBRARY_PATH
export PATH=$ORA_CLIENT_HOME:$PATH
export TNS_ADMIN=$ORA_CLIENT_HOME/network/admin   # tnsnames.ora 위치를 명시적으로 지정할 경우
```

## 4. tnsnames.ora 설정

```bash
sudo vim /oracle/instant-client/instantclient_19_26/network/admin/tnsnames.ora
```

```
[ServiceName] =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = [ip])(PORT = [port]))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = [service_name])
      (SID = [sid])
    )
  )
```

## 5. sqlplus 실행

```bash
# sqlplus 실행에 필요한 의존 라이브러리 설치 (libaio.so.1)
sudo apt install libaio1

# 접속
sqlplus user/passwd@ServiceName
```
