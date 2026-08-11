# Oracle RAC 기동 단계와 저장소 구조 (0~4장)

> 핵심 요약
>
> - **진단 기록물(로그)** → 누가 만들었든 → **로컬 파일시스템** → `adrci`로 관리
> - **복구 데이터(리두)** → 누가 만들었든 → **ASM / FRA** → `RMAN`으로 관리
> - 도구는 **만든 주체가 아니라 파일의 종류**로 갈린다.

---

## 0. 용어 정리

혼동하기 쉬운 용어를 먼저 확정한다.

| 용어 | 정체 |
|---|---|
| **ASM** | 기술·계층의 이름 (개념) |
| **ASM 인스턴스** | 실제 돌아가는 프로세스 집합 (`asm_pmon_+ASM1` + SGA) |
| **ASM 디스크그룹** | 관리 대상 저장 공간 (`+DATA`, `+FRA`, `+OCR`) |
| **ADR** | 진단 정보 저장소(디렉터리 구조)의 이름 |
| **adrci** | ADR을 조회·정리하는 **도구** |
| **FRA** | 복구 파일 보관 **정책** (위치 + 크기 한도) |
| `+FRA` | 디스크그룹 **이름** (관례일 뿐, `+RECO` 등 무엇이든 가능) |

- "ASM이 마운트한다" → 정확히는 **"ASM 인스턴스가 디스크그룹을 마운트한다"**
- **`+FRA`(디스크그룹 이름) ≠ FRA(기능)**
- 인스턴스 = **SGA(공유 메모리)** + **백그라운드 프로세스(실행 주체)**
  - "SGA 프로세스"라는 것은 없다.

---

## 1. 기동 6단계 개요

```
서버 전원 ON
  │
  ├─[1] Clusterware 기동      ┐
  ├─[2] ASM 인스턴스 NOMOUNT   ├─ 부팅 시 1회, 이후 상시 유지
  ├─[3] ASM 인스턴스 MOUNT     ┘  (인프라 계층)
  │
  ├─[4] DB 인스턴스 NOMOUNT    ┐
  ├─[5] DB 인스턴스 MOUNT      ├─ shutdown / startup 시 반복되는 구간
  └─[6] DB 인스턴스 OPEN       ┘
```

**`SHUTDOWN IMMEDIATE`는 DB 인스턴스만 내린다.** 1~3은 살아 있으므로 재기동 시 4번부터 시작한다.

```bash
ps -ef | grep ora_    # 없음      ← DB 내려감
ps -ef | grep asm_    # 떠 있음   ← ASM 유지
crsctl stat res -t    # ora.asm ONLINE / ora.orcl.db OFFLINE
```

---

## 2. 단계별 상세

### [1] Clusterware 기동

| 항목 | 내용 |
|---|---|
| 시점 | 서버 부팅 시 systemd가 `ohasd` 실행 |
| 정체 | **순수 데몬** (SGA 없음, SID 없음) |
| 읽는 것 | **OLR** (`$GRID_HOME/cdata/<호스트명>.olr`) — 로컬 파일 |
| 남기는 것 | CRS 로그 → `$ORACLE_BASE(grid)/diag/crs/<host>/crs/trace/` |
| 관리 도구 | `adrci` |

**뜨는 데몬:** `ohasd.bin`, `ocssd.bin`, `crsd.bin`, `evmd.bin`, `gpnpd`, `mdnsd`

**기동 연쇄:**
```
systemd → ohasd
   ↓ OLR 읽음 (로컬 파일)              ← 하위 스택
gpnpd, mdnsd, gipcd, cssdagent 기동
   ↓ GPnP 프로파일로 디스크 스캔
ocssd 기동 (Voting Disk 읽고 클러스터 멤버십 확정)
   ↓
[2][3] ASM 기동 및 디스크그룹 마운트
   ↓ OCR 읽음 (ASM 내부!)              ← 상위 스택
crsd 기동 → 자원 정의·의존관계 참조
   ↓
리스너, VIP, SCAN, DB 인스턴스 기동
```

> **OLR과 OCR이 나뉘는 이유**
> 하위 스택은 ASM 기동 전이라 **로컬의 OLR**만 읽을 수 있고,
> 상위 스택(crsd)은 ASM 마운트 이후라 **ASM 안의 OCR**을 읽는다.

**CRS 로그는 크기 기준 자동 회전(rotation)이 있어** 세대 초과분이 자동 삭제된다. 무한 증가하지 않는다.

---

### [2] ASM 인스턴스 — NOMOUNT

| 항목 | 내용 |
|---|---|
| 정체 | **데몬이 아니라 인스턴스** (SGA 1~2GB + 백그라운드 프로세스) |
| 상태 | `STARTED` (NOMOUNT) |
| 읽는 것 | GPnP 프로파일(로컬) → 디스크 스캔 → **디스크 헤더**에서 spfile 위치 → spfile 로드 |
| 남기는 것 | ASM alert log, trace → `$ORACLE_BASE(grid)/diag/asm/+asm/+ASM1/` |
| 관리 도구 | `adrci` |

**ASM 고유 프로세스**

| 프로세스 | 역할 |
|---|---|
| **RBAL** | 리밸런싱 조정 |
| **ARBn / ARBA** | 실제 익스텐트 이동 수행 |
| **GMON** | 디스크그룹 멤버십 관리 |
| **Onnn** | DB 인스턴스와의 통신 슬레이브 |

> **부트스트랩 순환 문제**
>
> ASM spfile은 `+OCR` 디스크그룹 안에 있는데, spfile을 읽어야 ASM이 뜨고 ASM이 떠야 마운트가 된다. 닭과 달걀 문제를 Oracle은 이렇게 푼다.
>
> 1. GPnP 프로파일(로컬)에 ASM 디스크 검색 경로가 기록됨
> 2. 그 경로의 디스크를 스캔해 **디스크 헤더**를 읽음
> 3. 헤더 안에 ASM spfile의 물리적 위치가 기록되어 있음 (마운트 없이 읽을 수 있는 특수 영역)
> 4. spfile을 읽어 ASM 인스턴스 기동
> 5. 그제야 디스크그룹 마운트

**ASM 진단 로그가 반드시 로컬 파일시스템인 이유:** ASM 기동에 실패했을 때 그 원인을 ASM에 적을 수는 없다.

---

### [3] ASM 인스턴스 — MOUNT (디스크그룹 마운트)

| 항목 | 내용 |
|---|---|
| 상태 | `MOUNTED` — **ASM에는 OPEN 상태가 없다** (열 데이터파일이 없으므로) |
| 하는 일 | 흩어진 물리 디스크를 논리적 저장 공간으로 조립 |
| 남기는 것 | 마운트 로그 → `diag/asm/+asm/+ASM1/` (2단계와 동일 위치) |

**3계층 구조**
```
[물리 디스크]  /dev/sdb, /dev/sdc, /dev/sdd  (LUN)
      ↓ ASM에 등록
[ASM 디스크]   DATA_0000, DATA_0001, DATA_0002
      ↓ 묶어서
[디스크그룹]   +DATA        ← 이 단위로 마운트
```

**마운트 시 실제로 일어나는 일**

1. 각 디스크의 **헤더를 읽음** — "너는 어느 디스크그룹의 몇 번 디스크냐"
2. 구성원이 다 모였는지 확인 (하나라도 없으면 마운트 실패)
3. 흩어진 조각을 **논리적으로 하나로 조립**
4. **익스텐트 맵을 ASM SGA에 로드** ← 핵심
5. DB가 파일 위치를 물어볼 수 있는 상태가 됨

4번이 있어야 6단계에서 DB가 "이 파일 어디 있냐"를 물어볼 수 있다.

**주요 디스크그룹**

| 디스크그룹 | 통상 용도 |
|---|---|
| `+DATA` | 데이터파일, 온라인 리두 로그, 컨트롤 파일, spfile |
| `+FRA` / `+RECO` | 아카이브 로그, RMAN 백업, 플래시백 로그 |
| `+OCR` / `+GRID` | OCR, Voting Disk |

**이중화 정책(redundancy):** `EXTERNAL`(미러 없음, 스토리지 RAID 사용) / `NORMAL`(2중) / `HIGH`(3중)

**2·3단계를 분리해서 봐야 하는 이유**

```sql
SELECT name, state FROM v$asm_diskgroup;
```
| NAME | STATE |
|---|---|
| DATA | MOUNTED |
| FRA | **DISMOUNTED** ← ASM은 정상인데 이 디스크그룹만 안 올라옴 |

이 상태면 DB는 뜨지만 아카이브를 못 써서 hang이 걸린다. **디스크 공간과 무관**하게 발생하며 `df`로는 잡히지 않는다.

```bash
asmcmd lsdg            # State 컬럼 확인
asmcmd mount FRA       # 개별 마운트
```
```sql
ALTER DISKGROUP ALL MOUNT;
```

RAC에서는 디스크그룹 하나하나가 CRS 자원(`ora.DATA.dg`, `ora.FRA.dg`)으로 등록되어 `crsctl stat res -t`에 개별 상태로 보인다.

---

### [4] DB 인스턴스 — NOMOUNT

**여기서부터가 `shutdown immediate` → `startup`으로 반복되는 구간이다.**

| 항목 | 내용 |
|---|---|
| 읽는 것 | **spfile — ASM에서** (`+DATA/ORCL/spfileORCL.ora`) |
| 남기는 것 | DB alert log, trace → `$ORACLE_BASE(oracle)/diag/rdbms/orcl/ORCL/` |
| 관리 도구 | `adrci` |

ASM이 안 떠 있으면 **spfile조차 못 읽어 NOMOUNT도 실패**한다.

**이 단계에서 백그라운드 프로세스가 거의 전부 뜬다.** MOUNT/OPEN으로 넘어가도 프로세스가 추가되지 않는다. 바뀌는 것은 "무엇을 열었는가"뿐이다.

| 프로세스 | 역할 |
|---|---|
| **PMON** (18c+ CLMN) | 죽은 세션 정리, 자원 회수 |
| **SMON** | 인스턴스 복구, 임시 세그먼트 정리 |
| **DBWn** | Buffer Cache의 변경 블록 → 데이터파일 |
| **LGWR** | Redo Log Buffer → 온라인 리두 로그 |
| **CKPT** | 체크포인트, 컨트롤 파일·데이터파일 헤더 갱신 |
| **MMON / MMNL** | AWR 스냅샷, 자동 통계, **ADR purge** |
| **RECO** | 분산 트랜잭션 복구 |
| **LREG** | 리스너에 인스턴스·서비스 등록 |
| **ARCn** | ARCHIVELOG 모드일 때 아카이브 생성 |
| **ASMB** | ASM 인스턴스와 상시 통신 (**죽으면 DB 종료**) |

**RAC 추가 프로세스**

| 프로세스 | 역할 |
|---|---|
| **LMS** | 노드 간 블록 전송 (Cache Fusion, 성능 핵심) |
| **LMD** | 글로벌 락 요청 관리 |
| **LMON** | 노드 장애 감지, 재구성(reconfiguration) |
| **LCK0** | 비블록 자원 락 |
| **DIAG** | 진단 정보 수집 → ADR에 기록 |

> RAC에서 진단 파일이 단일 인스턴스보다 훨씬 많이 쌓이는 이유가 LMON·DIAG다. 노드 간 통신 이슈마다 대량의 trace를 남긴다.

**SGA 구성**

| 영역 | 역할 |
|---|---|
| Buffer Cache | 데이터 블록 캐시 (보통 가장 큼) |
| Shared Pool | SQL 파싱 결과, 실행계획, 딕셔너리 캐시 |
| Redo Log Buffer | 리두 레코드 임시 버퍼 → LGWR가 디스크로 |
| Large Pool | RMAN 백업, 병렬 처리용 |
| Java / Streams Pool | 해당 기능 사용 시 |

**중요:** DB 진단 로그는 `oracle` 유저의 `$ORACLE_BASE`에 쌓인다. grid와 `$ORACLE_BASE`가 분리되어 있으므로 **`/grid` 용량과 무관**하다.

| | 유저 | ORACLE_HOME | ORACLE_BASE |
|---|---|---|---|
| GI + ASM | `grid` | `/grid/19.0.0/grid` | `/grid/app/grid` |
| DB | `oracle` | `/u01/.../dbhome_1` | `/u01/app/oracle` |

---

### [5] DB 인스턴스 — MOUNT

| 항목 | 내용 |
|---|---|
| 읽는 것 | **컨트롤 파일 — ASM에서** (`+DATA/ORCL/CONTROLFILE/`) |
| 프로세스 | 추가 없음 |
| 남기는 것 | — |

**컨트롤 파일에 들어있는 것:** 데이터파일 목록, 리두 로그 위치, **로그 모드(ARCHIVELOG 여부)**, RMAN 백업 이력

**이 단계에서만 가능한 작업**
```sql
ALTER DATABASE ARCHIVELOG;        -- 로그 모드 변경
ALTER DATABASE RENAME FILE ...;
RECOVER DATABASE;
```

**왜 MOUNT에서만 되는가:** 로그 모드는 컨트롤 파일에 기록되는 값이다. NOMOUNT에서는 컨트롤 파일을 아직 안 읽었고, OPEN에서는 사용자가 데이터파일에 쓰고 있어 리두 처리 방식을 중간에 바꾸면 정합성이 깨진다. **컨트롤 파일은 읽었지만 아무도 데이터를 안 건드리는 유일한 구간**이 MOUNT다.

```sql
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
```

---

### [6] DB 인스턴스 — OPEN

| 항목 | 내용 |
|---|---|
| 읽는 것 | 데이터파일, 온라인 리두 로그 — ASM에서 |
| 남기는 것 | **리두 로그, 아카이브 로그** |
| 위치 | `+DATA` (리두) / `+FRA` 또는 `db_recovery_file_dest` (아카이브) |
| 관리 도구 | **RMAN** |

**IO 구조 확립 — ASM은 IO 경로에 없다**
```
DB 인스턴스 ──[① 파일 위치 문의]──▶ ASM 인스턴스
             ◀─[② 익스텐트 맵 응답]──   (파일 열 때 1회)

DB 인스턴스 ──[③ 실제 읽기/쓰기]──▶ 디스크   (ASM 안 거침)
```
DB는 익스텐트 맵을 자기 SGA에 캐싱한 뒤 디스크에 직접 IO한다. 그래서 ASM 인스턴스는 병목이 되지 않으며, 파일 열기·닫기·확장·리밸런싱 같은 **메타데이터 작업만** 관여한다.

**커밋 시 흐름**
```
UPDATE 실행
  ↓ 서버 프로세스가 Buffer Cache에서 블록 변경
  ↓ 변경 내역을 Redo Log Buffer에 기록
COMMIT
  ↓ LGWR가 리두를 디스크에 flush   ← 여기서 "커밋 완료" 응답
  ↓ (나중에) DBWn이 데이터파일에 반영
  ↓ (리두 그룹 전환 시) ARCn이 아카이브 로그 생성
```

**커밋 시점에 데이터파일은 건드리지 않는다(WAL).** 이것이 리두 로그가 존재하는 근본 이유이고, DBWn과 LGWR이 분리된 이유다.

---

## 3. 단계 요약표

| 단계 | 주체 | 상태 | 읽는 것 | 남기는 것 | 위치 | 도구 |
|---|---|---|---|---|---|---|
| 1 | CRS 데몬 | — | OLR (로컬) | CRS 로그 | `/grid` diag | adrci |
| 2 | **ASM 인스턴스** | NOMOUNT | GPnP + 디스크 헤더 | ASM alert/trace | `/grid` diag | adrci |
| 3 | **ASM 인스턴스** | MOUNTED | 디스크그룹 메타데이터 | 마운트 로그 | `/grid` diag | adrci |
| 4 | DB 인스턴스 | NOMOUNT | spfile (ASM) | DB alert/trace | oracle diag | adrci |
| 5 | DB 인스턴스 | MOUNTED | 컨트롤 파일 (ASM) | — | — | — |
| 6 | DB 인스턴스 | OPEN | 데이터파일 (ASM) | **리두·아카이브** | **ASM / FRA** | **RMAN** |

> **한 문장 요약**
> 1~5단계는 **진단 기록만** 남기고 전부 로컬 파일시스템에 쌓인다(adrci 관리).
> **복구 데이터를 만드는 것은 6단계 DB OPEN 이후뿐이고**, 그것만 ASM/FRA에 쌓인다(RMAN 관리).

**ASM 인스턴스 vs DB 인스턴스 — 구조는 동일**

| | ASM 인스턴스 | DB 인스턴스 |
|---|---|---|
| NOMOUNT | [2] SGA + 프로세스 생성 | [4] SGA + 프로세스 생성 |
| MOUNT | [3] **디스크그룹** 마운트 | [5] **컨트롤 파일** 읽어 DB 연결 |
| OPEN | **없음** (데이터파일 없음) | [6] 데이터파일 열림 |

**Clusterware / ASM / DB 비교**

| | 정체 | SGA | 접속 방식 | 실행 유저 |
|---|---|---|---|---|
| Clusterware | 순수 **데몬** | 없음 | `crsctl`, `srvctl` | root / grid |
| ASM | **인스턴스** | 있음 (작음) | `sqlplus / as sysasm` | grid |
| DB | **인스턴스** | 있음 (큼) | `sqlplus / as sysdba` | oracle |

**장애 파급 — 아래에서 위로만 전파**

| 죽는 것 | 결과 |
|---|---|
| DB 인스턴스 | ASM·CRS 정상, 해당 DB만 중단 |
| **ASM 인스턴스** | **그 노드의 모든 DB 동반 종료** (ASMB 끊김) |
| Clusterware | 노드 전체 재기동 또는 축출(eviction) |

---

## 4. 저장소 계층 전체 그림

```
ASM 디스크그룹 (공유 스토리지)              ← Oracle이 읽는 것
├── +DATA  : 데이터파일, 리두 로그, 컨트롤 파일, spfile
├── +FRA   : 아카이브 로그, RMAN 백업        ← RMAN으로 정리
└── +OCR   : OCR, Voting Disk

로컬 파일시스템 (/grid, /u01 등)            ← 사람이 읽는 것
├── GI 소프트웨어, OLR, OCR 백업
├── ADR 진단 파일 (trace, alert, incident)  ← adrci로 정리
└── adump 감사 파일                          ← find -delete로 정리
```

**한 줄 요약: ASM은 Oracle이 읽는 것, 로컬 파일시스템은 사람이 읽는 것을 담는다.**

### ADR에 들어가지 않는 것 / 들어가는 것

**ASM에 저장 가능 여부**

| 대상 | ASM 저장 | 이유 |
|---|---|---|
| 데이터파일, 리두 로그 | ✅ | Oracle 블록 구조 |
| 아카이브 로그, RMAN 백업셋 | ✅ | 〃 |
| OCR, Voting Disk | ✅ | Clusterware가 ASM 접근 가능 |
| **ADR (trace, alert, adump)** | ❌ | 텍스트 파일 + **기동 순서상 불가** |
| OLR | ❌ | ASM 기동 전에 필요 |

### ADR 구조

```
$ORACLE_BASE/diag/
├── rdbms/orcl/ORCL/          ← DB용 ADR 홈 (oracle 유저)
│   ├── alert/                XML 형식 alert log
│   ├── trace/                텍스트 alert log + trace 파일
│   ├── incident/             ORA-600 등 심각 오류 덤프
│   ├── cdump/                코어 덤프
│   └── hm/                   Health Monitor 결과
├── asm/+asm/+ASM1/           ← ASM용   (grid 유저)
├── tnslsnr/<host>/listener/  ← 리스너용 (grid 유저)
└── crs/<host>/crs/           ← CRS용   (grid 유저, 12c+)
```

**ADR 홈이 여러 개**라는 점이 중요하다. purge 정책도 홈별로 따로 관리된다.
