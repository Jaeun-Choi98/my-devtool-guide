# Tibero Client 설치 가이드 (Windows)

## Tibero Client Instant

### 1. 설치 파일 다운로드

TmaxNet에서 client_installer 다운 후 압축 해제

> client_installer를 제공하지 않는 경우 `tibero_client_install_guide` 참고

### 2. 환경 변수 설정

`setPath` 배치 파일을 실행하면 시스템 PATH에 자동 추가됨:
- `[설치된 폴더]/bin`
- `[설치된 폴더]/client/bin`

### 3. ODBC 드라이버 설치

`[설치된 폴더]/bin/tbodbc_driver_installer_7_xx` 실행

### 4. ODBC Manager 설정

**ODBC 데이터 원본** → **사용자 DSN**에서 Tibero ODBC Driver 추가

> 유닉스/리눅스는 ODBC Manager가 없으므로 별도 설치 필요 (unixODBC)

---

## Tibero Studio

### 1. 설치 전 준비

JRE 1.8 버전 필요

> 데스크톱 앱용 JRE를 다운 받아야 함. 설치 후 시스템 PATH에 추가되는 경로:
> `C:\Program Files (x86)\Common Files\Oracle\Java\java8path`

### 2. 설치

TmaxNet에서 Tibero Studio 다운 받아서 압축 해제
