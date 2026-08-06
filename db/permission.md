# DB 권한 관리 가이드

## MySQL / MariaDB — 호스트 기반 접근 제어

### 접속 방법

```bash
# 로컬 접속
mysql -u root -p

# 원격 접속
mysql -h 192.168.1.100 -P 3306 -u myuser -p mydb
```

### 1. 계정 생성

```sql
-- 기본 계정 생성
CREATE USER '사용자명'@'호스트' IDENTIFIED BY '비밀번호';

-- 예시
CREATE USER 'testuser'@'localhost' IDENTIFIED BY '123456';
CREATE USER 'webuser'@'%' IDENTIFIED BY 'webpass123';              -- 모든 호스트에서 접근 가능
CREATE USER 'dbadmin'@'192.168.1.%' IDENTIFIED BY 'adminpass';     -- 특정 IP 대역만 허용
```

### 2. 권한 부여

```sql
-- 전체 권한 부여
GRANT ALL PRIVILEGES ON *.* TO '사용자명'@'호스트';

-- 특정 데이터베이스에 대한 권한
GRANT ALL PRIVILEGES ON 데이터베이스명.* TO '사용자명'@'호스트';

-- 특정 테이블에 대한 권한
GRANT SELECT, INSERT, UPDATE, DELETE ON 데이터베이스명.테이블명 TO '사용자명'@'호스트';

-- 읽기 전용 권한
GRANT SELECT ON 데이터베이스명.* TO '사용자명'@'호스트';

-- 권한 적용
FLUSH PRIVILEGES;
```

### 3. 권한 확인 및 관리

```sql
-- 사용자 목록 확인
SELECT User, Host FROM mysql.user;

-- 특정 사용자 권한 확인
SHOW GRANTS FOR '사용자명'@'호스트';

-- 권한 제거
REVOKE 권한 ON 데이터베이스명.* FROM '사용자명'@'호스트';

-- 계정 삭제
DROP USER '사용자명'@'호스트';
```

---

## Oracle — 롤 기반 접근 제어

### 접속 방법

```bash
# Easy Connect 방식
sqlplus scott/tiger@localhost:1521/XE
sqlplus hr/hr@192.168.1.100:1521/ORCL

# TNS 별칭 사용
sqlplus scott/tiger@MYDB

# 로컬 접속
sqlplus sys as sysdba
```

### 1. 계정 생성

```sql
-- 기본 계정 생성
CREATE USER 사용자명 IDENTIFIED BY 비밀번호;

-- 예시
CREATE USER testuser IDENTIFIED BY oracle123;

-- 계정 생성 시 추가 옵션
CREATE USER webuser IDENTIFIED BY webpass123
    DEFAULT TABLESPACE users        -- 기본 저장 공간
    TEMPORARY TABLESPACE temp       -- 임시 저장 공간 (정렬, 조인 등의 임시 작업)
    QUOTA 100M ON users;            -- 용량 (UNLIMITED: 제한 없음)
```

### 2. 권한 부여

```sql
-- 데이터베이스 연결 권한
GRANT CREATE SESSION TO 사용자명;

-- 기본적인 객체 생성 권한
GRANT CREATE TABLE TO 사용자명;
GRANT CREATE VIEW TO 사용자명;
GRANT CREATE PROCEDURE TO 사용자명;
GRANT CREATE SEQUENCE TO 사용자명;
GRANT SELECT ON 소유자.테이블 TO 사용자명;
-- 모든 테이블 조회가 필요한 경우 (시스템 권한):
-- GRANT SELECT ANY TABLE TO 사용자명;

-- 또는 CONNECT, RESOURCE 롤 부여 (일반적으로 많이 사용)
GRANT CONNECT, RESOURCE TO 사용자명;
-- DBA 옵션: 모든 테이블 조회, 수정, 삭제 가능 + 테이블 스페이스 관리 권한
```

### 3. 롤(Role) 활용

```sql
-- 사용자 정의 롤 생성
CREATE ROLE app_user_role;

-- 롤에 권한 부여
GRANT CREATE SESSION TO app_user_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON hr.employees TO app_user_role;

-- 사용자에게 롤 부여
GRANT app_user_role TO 사용자명;
```

```sql
CREATE USER 사용자명
IDENTIFIED BY 사용자명
DEFAULT TABLESPACE 테이블스페이스
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON 테이블스페이스;

CREATE ROLE 역할명;

GRANT 
    CREATE SESSION,
    ALTER SESSION,
    CREATE TABLE,
    CREATE SYNONYM,
    CREATE VIEW,
    CREATE SEQUENCE,
    CREATE DATABASE LINK,
    CREATE PROCEDURE,
    CREATE TRIGGER,
    CREATE TYPE,
    CREATE OPERATOR,
    CREATE INDEXTYPE
TO 역할명;

GRANT 역할명 TO 사용자명;

--유효기간 조회
select username, account_status, lock_date, expiry_date
  from dba_users;

--유효기간 해제
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
```

### 4. 권한 확인

```sql
-- 사용자 목록 확인
SELECT username FROM dba_users;

-- 테이블 기준
SELECT * FROM dba_tab_privs WHERE grantee = 'TESTUSER';     -- TABLE 권한
SELECT * FROM dba_sys_privs WHERE grantee = 'TESTUSER';     -- ANY TABLE 권한
SELECT * FROM dba_role_privs WHERE grantee = 'TESTUSER';

-- 사용자 기준
SELECT * FROM user_tab_privs;
SELECT * FROM user_sys_privs WHERE privilege LIKE '%ANY TABLE%';

-- 권한 제거
REVOKE 권한 FROM 사용자명;

-- 계정 삭제
DROP USER 사용자명 CASCADE;  -- CASCADE: 사용자 소유 객체도 함께 삭제
```

---

## 테이블 스페이스 관리 (Oracle)

### 생성 문법

```sql
CREATE TABLESPACE 테이블스페이스명
    DATAFILE '파일경로/파일명.dbf'
    SIZE 초기크기
    [AUTOEXTEND ON|OFF]
    [NEXT 확장크기]
    [MAXSIZE 최대크기|UNLIMITED];
```

### 일반 테이블 스페이스 생성 예시 ( 임시 테이블 스페이스로 사용해도 됨 )

```sql
-- dev_data 테이블스페이스 생성
CREATE TABLESPACE dev_data
    DATAFILE '/u01/app/oracle/oradata/orcl/dev_data01.dbf'
    SIZE 500M
    AUTOEXTEND ON
    NEXT 50M
    MAXSIZE 2G;

-- dev_index 테이블스페이스 생성
CREATE TABLESPACE dev_index
    DATAFILE '/u01/app/oracle/oradata/orcl/dev_index01.dbf'
    SIZE 200M
    AUTOEXTEND ON
    NEXT 20M
    MAXSIZE 1G;
```

### 임시 테이블 스페이스 생성

```sql
CREATE TEMPORARY TABLESPACE dev_temp
    TEMPFILE '/u01/app/oracle/oradata/orcl/dev_temp01.dbf'
    SIZE 100M
    AUTOEXTEND ON
    NEXT 10M
    MAXSIZE 500M;
```

### 테이블 스페이스 확인

```sql
-- 존재하는 테이블스페이스 확인
SELECT tablespace_name, status FROM dba_tablespaces;

-- 데이터파일 정보 확인
SELECT tablespace_name, file_name, bytes/1024/1024 AS size_mb
FROM dba_data_files;
```
