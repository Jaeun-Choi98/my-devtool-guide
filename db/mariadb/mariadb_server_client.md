# MariaDB 설치 및 설정 가이드

> [MariaDB 공식 다운로드 페이지](https://mariadb.org/download/?t=repo-config)에서 OS 버전에 맞는 리파지토리를 추가 후 다운로드

**환경:** Ubuntu 20.04, MariaDB 11.4

---

## 1. Repository 추가

```bash
sudo apt -y install apt-transport-https curl
sudo mkdir -p /etc/apt/keyrings
sudo curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
```

## 2. MariaDB 소스 설정

`/etc/apt/sources.list.d/mariadb.sources` 파일에 아래 내용 작성:

```ini
# MariaDB 11.4 repository list
# https://mariadb.org/download/
X-Repolib-Name: MariaDB
Types: deb
URIs: https://tw1.mirror.blendbyte.net/mariadb/repo/11.4/ubuntu
Suites: focal
Components: main main/debug
Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp
```

```bash
sudo apt update
```

## 3. MariaDB 설치

```bash
sudo apt -y install mariadb-server
```

## 4. mariadb-secure-installation 설정

```bash
sudo mariadb-secure-installation
```

| 설정 항목 | 권장 값 | 설명 |
|-----------|---------|------|
| Enter current password for root | (엔터) | 현재 root 비밀번호 (없으면 엔터) |
| Switch to unix_socket authentication | **n** | root 계정을 통해 접속 |
| Change the root password? | **y** | root 비밀번호 변경 |
| Remove anonymous users? | **y** | 익명 사용자 제거 (운영 환경 필수) |
| Disallow root login remotely? | **y** | root는 localhost에서만 접속 허용 |
| Remove test database? | **y** | test DB 제거 (운영 환경 전에 필수) |
| Reload privilege tables now? | **y** | 변경사항 저장 |

> `select host, user from mysql.user;`로 확인하면 user명이 없는 익명 사용자를 확인할 수 있다.

## 5. MariaDB 환경 설정

```bash
sudo systemctl stop mariadb.service
sudo vim /etc/mysql/my.cnf
```

```ini
[client-server]
socket = /run/mysqld/mysqld.sock

!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mariadb.conf.d/

[client]
default-character-set=utf8mb4

[mariadbd]
# 모든 호스트에서 접속을 허용
bind-address = 0.0.0.0
# 운영 환경에서는 아래 설정 권장
# bind-address = 127.0.0.1

character-set-server    = utf8mb4
character-set-collations= utf8mb4=utf8mb4_general_ci

innodb_buffer_pool_size = 4G
innodb_buffer_pool_chunk_size = 4M

lower_case_table_names = 1

event_scheduler = ON

datadir=/home/juchoi/mariadb/mysql

[mysqldump]
default-character-set = utf8mb4
```

### 5.1. 기본 데이터 디렉토리 변경

```bash
sudo systemctl stop mariadb
mkdir -p /home/juchoi/mariadb/mysql
sudo rsync -av /var/lib/mysql/ /home/juchoi/mariadb/mysql
sudo chown -R mysql:mysql /home/juchoi/mariadb/mysql

# systemd 서비스 파일 수정
sudo vim /usr/lib/systemd/system/mariadb.service
# ProtectHome=true → ProtectHome=false 변경
# /home이 아닌 디렉토리를 사용하는 경우: ProtectSystem=false 도 변경
```

### 5.2. MariaDB 실행

```bash
sudo systemctl daemon-reload
sudo systemctl start mariadb.service
```

## 6. 설정 확인 방법

```sql
-- MariaDB 버전 정보
SELECT VERSION();

-- 문자셋 및 Collation 확인
SHOW VARIABLES LIKE 'character%';

-- InnoDB Buffer 설정 크기 확인
SELECT @@innodb_buffer_pool_size;
SELECT @@innodb_buffer_pool_chunk_size;
SELECT @@innodb_buffer_pool_instances;

-- InnoDB Buffer 현재 상태 확인
SHOW STATUS LIKE 'Innodb_buffer%';
```

**추가 확인:**

```sql
-- 특정 데이터베이스의 문자셋/Collation 확인
SELECT * FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '데이터베이스이름';

-- 특정 테이블 컬럼의 Collation 확인
SELECT COLUMN_NAME, COLLATION_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = '데이터베이스이름' AND TABLE_NAME = '테이블이름';
```

---

## 환경 설정 설명

### 1. 문자셋(charset) / 문자 정렬(collation)

**문자셋:** utf-8, utf-16, euc-kr 등이 있으며, `utf8mb4`를 권장. 국제 표준으로 대부분의 경우 적합.

**문자 정렬 옵션:**

| 접미사 | 의미 |
|--------|------|
| `bin` | binary 값으로 비교 |
| `ci` | case insensitive, 대소문자 구분 없음 |
| `ai` | accent insensitive, 악센트 무시 |
| `general` | 일반 목적 비교 규칙 |
| `unicode` | Unicode 표준 |
| `0900` | Unicode 9.0.0 기준 (MySQL 8.0 도입) |
| `uca1400` | Unicode 14.0.0 기준 (MariaDB 11.x 도입) |

> MariaDB 11.x의 기본 collation은 `uca1400_ai_ci`이다. MySQL 8.0의 기본값인 `utf8mb4_0900_ai_ci`와는 다르므로 혼동하지 않도록 주의.

### 2. InnoDB Buffer Pool

메인 메모리 내에서 데이터와 인덱스를 캐시하는 영역. 자주 접근되는 데이터를 메모리에서 바로 가져올 수 있어 전체 성능을 향상시킨다.

| 설정 | 설명 | 권장 |
|------|------|------|
| `innodb_buffer_pool_size` | 실제 할당 크기 | 물리 메모리의 50~80% |
| `innodb_buffer_pool_instances` | 버퍼 풀을 여러 파트로 분할 | `pool_size / chunk_size`가 1000 미만 유지 |
| `innodb_buffer_pool_chunk_size` | 파트당 할당 크기 | 10.8.1 이상은 autosize(0)가 기본, `pool_size / 64`로 자동 조정 |

**Buffer 상태 확인:**

```sql
SHOW STATUS LIKE 'Innodb_buffer%';
-- innodb_buffer_pool_bytes_data: 사용된 크기
-- innodb_buffer_pool_pages_data: 사용된 페이지
--   pages_data * 16KiB * 1024 == bytes_data
-- 사용률: bytes_data / pool_size * 100
```
