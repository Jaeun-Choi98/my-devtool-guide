# Tibero Client 설치 가이드 (Linux)

## 1. 설치 전 준비사항 (Requirement)

### 1.1. Tibero Client 설치 파일 준비

[Technet](https://technet.tmax.co.kr/ko/front/main/main.do)에서 tar.gz 파일 다운로드 (로그인 필요)

## 2. 수동 모드 설치

### 2.1. 압축 풀기

> `/` 폴더에 압축을 풀면 `gen_tip.sh`에서 오류가 발생하므로 주의

```bash
ls ~
# tibero7-bin-FS02_PS03-linux64_3.10-291585-20250409174611.tar.gz

gunzip tibero7-bin-FS02_PS03-linux64_3.10-291585-20250409174611.tar.gz
sudo tar -xvf tibero7-bin-FS02_PS03-linux64_3.10-291585-20250409174611.tar -C ~/
```

### 2.2. 환경 변수 설정

```bash
sudo vim ~/.profile
```

```bash
export TB_HOME=$HOME/tibero7
export TB_SID=tibero
export PATH=$TB_HOME/bin:$TB_HOME/client/bin:$PATH
export LD_LIBRARY_PATH=$TB_HOME/client/lib:$LD_LIBRARY_PATH
# Go 앱 연결 시 필요
export TBCLI_WCHAR_TYPE=ucs2
```

### 2.3. gen_tip.sh 실행

```bash
cd $TB_HOME/config
sh gen_tip.sh
```

---

> 아래부터는 unixODBC를 사용하지 않는 경우에만 필요

### 2.4. tbdsn.tbr 설정

```bash
vim $TB_HOME/client/config/tbdsn.tbr
```

```
tibero=(
    (INSTANCE=(HOST=10.1.0.120)
        (PORT=8629)
        (DB_NAME=tibero)
    )
)
```

### 2.5. tbsql 실행을 위한 의존 패키지 설치

```bash
sudo apt -y install libncurses5 libaio1
```

### 2.6. tbsql 접속

```bash
tbsql [유저아이디]/[패스워드]@[tbdsn에서 설정한 별칭]
```

---

## 연결 흐름 참고

리눅스는 ODBC Manager가 기본 제공되지 않으므로, unixODBC를 별도로 설치하고 설정해야 한다.

```
Go App / isql → ODBC → tbodbc → Tibero DB
```
