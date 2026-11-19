# DB 덤프 (Export / Import) 가이드

## MySQL / MariaDB

### 1. Export (mysqldump)

```bash
# 하나 이상의 테이블
mysqldump -u root -p test_db test_tb > /workspace/test.sql

# 하나 이상의 데이터베이스
mysqldump -u root -p --databases test_db > /workspace/test.sql

# 전체 데이터베이스
mysqldump -u root -p --all-databases > /workspace/all.sql
```

**실무 예시:**

```bash
mysqldump -u username -p --single-transaction --routines --triggers database_name | gzip > backup.sql.gz
```

**주요 옵션** ([공식 문서](https://dev.mysql.com/doc/refman/8.4/en/mysqldump.html#mysqldump-performance) 참고):

| 옵션 | 설명 |
|------|------|
| `--no-data` | 스키마만 백업 |
| `--no-create-info` | 데이터만 백업 |
| `--routines` | 프로시저, 함수 포함 |
| `--triggers` | 트리거 포함 |
| `--single-transaction` | 일관된 백업을 위해 트랜잭션으로 묶어서 백업 |

**간단히 개별 테이블 액셀 추출**
```bash
mysql -u root -p mydb --batch \
  -e "SELECT * FROM your_table" \
  | sed 's/\t/,/g' \
  > /tmp/output.csv
```

### 2. Import

```bash
mysql -u root -p < /workspace/test.sql
```


### 3. binlog를 활용한 복구

사고 발생 직전까지의 기록을 `mysqlbinlog` 유틸리티를 사용해 SQL문으로 변환한 뒤 적용합니다.

* **특정 파일 전체 적용:**
  ```bash
  mysqlbinlog /var/lib/mysql/mysql-bin.0000XX | mysql -u[사용자] -p
  ```
* **특정 시간대 지정 복구 (Point-in-Time Recovery):** 실수하기 직전 시간(`--stop-datetime`)까지만 로그를 추출해 적용합니다.
  ```bash
  mysqlbinlog --stop-datetime="2026-08-11 14:00:00" /var/lib/mysql/mysql-bin.0000XX | mysql -u[사용자] -p
  ```
* **특정 위치(Position) 지정 복구:**
  ```bash
  mysqlbinlog --stop-position=12345 /var/lib/mysql/mysql-bin.0000XX | mysql -u[사용자] -p
  ```
* **실수로 지운 데이터만 역추적하여 복구할 때 (Flashback):** 
  ```bash
  mysqlbinlog --flashback /var/lib/mysql/mysql-bin.0000XX > rollback.sql
  mysql -u[사용자] -p < rollback.sql
  ```
  
---

## Oracle

### 1. 디렉토리 오브젝트 생성 및 권한 부여

```sql
-- 방법 1: DBA가 직접 오브젝트 생성 후 권한 부여
CREATE DIRECTORY EXPDUMP_DIR AS '/dump';                       -- DBA 권한 필요
GRANT READ, WRITE ON DIRECTORY EXPDUMP_DIR TO scott;           -- DBA 권한 필요

-- 방법 2: 사용자에게 디렉토리 생성 권한 부여
GRANT CREATE ANY DIRECTORY TO scott;                           -- DBA 권한 필요
-- scott 계정으로 접속 후:
CREATE DIRECTORY EXPDUMP_DIR AS '/dump';

-- full 옵션 사용 시 추가 권한
GRANT EXP_FULL_DATABASE, IMP_FULL_DATABASE TO scott;
```

### 2. expdp / impdp (Data Pump)

```bash
# Export
expdp 계정ID/비번@TNS명 [schemas|tables|full]=계정명 \
    directory=디렉토리명 dumpfile=파일명.dmp logfile=파일명.log \
    [network_link=DB_LINK명] [version=버전]

# Import
impdp 계정ID/비번@TNS명 [schemas|tables|full]=계정명 \
    directory=디렉토리명 dumpfile=파일명.dmp logfile=파일명.log \
    [network_link=DB_LINK명] [version=버전]
```

### 3. exp / imp (전통적인 유틸리티, 디렉토리 오브젝트 불필요)

```bash
exp userid=username/password@database file=backup.dmp log=backup.log
imp userid=username/password@database file=backup.dmp log=import.log
```

### 4. imp/exp vs impdp/expdp 차이

| 항목 | imp/exp | impdp/expdp |
|------|---------|-------------|
| 지원 버전 | 모든 버전 | 10g 이상 |
| 실행 위치 | 클라이언트 측 (네트워크를 통해 전송) | 서버 측 (더 빠른 성능) |
| 처리 방식 | 단일 프로세스 | 병렬 처리 지원 |
| 파일 관리 | 로컬 파일시스템에 직접 생성 | 디렉터리 객체를 통해 관리 |
| 중단/재시작 | 미지원 | 지원 |
| 메타데이터 | 제한적 | 더 많은 객체 타입 지원 |
