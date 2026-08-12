# 스케줄러 사용법 정리 (schtasks & crontab)

윈도우의 **schtasks**와 Linux의 **crontab**은 각각 정해진 시각·주기에 작업을 자동 실행하는 스케줄러 도구입니다.
이 문서는 두 도구의 사용법을 함께 정리합니다.

---

# 1부. Windows — schtasks

`schtasks`는 윈도우의 **작업 스케줄러(Task Scheduler)**를 명령줄에서 다루는 도구입니다.

## 1-1. 기본 구조

```
schtasks /명령 [옵션들]
```

| 명령 | 역할 |
|---|---|
| `/Create` | 새 작업 등록 |
| `/Query` | 등록된 작업 조회 |
| `/Change` | 기존 작업 수정 |
| `/Run` | 작업 즉시 실행 |
| `/End` | 실행 중인 작업 중지 |
| `/Delete` | 작업 삭제 |

## 1-2. 작업 만들기 (`/Create`)

| 옵션 | 의미 |
|---|---|
| `/TN` (task name) | 작업 이름 |
| `/TR` (task run) | 실행할 프로그램/스크립트 경로 |
| `/SC` (schedule) | 실행 주기 |
| `/ST` (start time) | 시작 시각 (HH:MM, 24시간제) |
| `/SD` (start date) | 시작 날짜 |
| `/MO` (modifier) | 주기 간격 (예: 2일마다, 3시간마다) |
| `/D` (day) | 요일(MON, TUE…) 또는 일자(1~31) |
| `/RU` (run as user) | 실행 계정 (`SYSTEM` 지정 시 로그온 없이 실행) |

**`/SC` 실행 주기 종류**
`MINUTE`, `HOURLY`, `DAILY`, `WEEKLY`, `MONTHLY`, `ONCE`,
`ONSTART`(부팅 시), `ONLOGON`(로그온 시), `ONIDLE`(유휴 시)

### 예시

```
# 매일 오전 9시에 배치 파일 실행
schtasks /Create /TN "일일백업" /TR "C:\scripts\backup.bat" /SC DAILY /ST 09:00

# 매주 월·수·금 오후 6시 실행
schtasks /Create /TN "주간작업" /TR "C:\scripts\report.exe" /SC WEEKLY /D MON,WED,FRI /ST 18:00

# 3시간마다 실행
schtasks /Create /TN "모니터링" /TR "powershell -File C:\scripts\check.ps1" /SC HOURLY /MO 3

# 매월 1일 새벽 2시에 SYSTEM 권한으로 실행
schtasks /Create /TN "월정산" /TR "C:\scripts\monthly.bat" /SC MONTHLY /D 1 /ST 02:00 /RU SYSTEM
```

## 1-3. 조회 · 수정 · 실행 · 삭제

```
# 조회
schtasks /Query                              # 전체 목록
schtasks /Query /TN "일일백업" /V /FO LIST      # 특정 작업 상세

# 수정
schtasks /Change /TN "일일백업" /ST 10:00        # 시작 시각 변경
schtasks /Change /TN "일일백업" /DISABLE         # 비활성화
schtasks /Change /TN "일일백업" /ENABLE          # 활성화

# 실행 · 중지 · 삭제
schtasks /Run    /TN "일일백업"                  # 지금 즉시 실행
schtasks /End    /TN "일일백업"                  # 실행 중인 것 중지
schtasks /Delete /TN "일일백업" /F              # 삭제 (/F는 확인 생략)
```

## 1-4. 알아두면 좋은 점

- 관리자 권한이 필요한 작업(SYSTEM 계정 등)은 **관리자 권한 명령 프롬프트**에서 실행합니다.
- 경로에 공백이 있으면 안쪽에도 따옴표: `/TR "\"C:\Program Files\app.exe\""`
- `schtasks /Create /?` 로 전체 옵션 도움말을 볼 수 있습니다.

---

# 2부. Linux — crontab

`crontab`(cron table)은 Linux/유닉스에서 정해진 시각·주기에 명령을 자동 실행하는 스케줄러입니다.
사용자별로 크론 작업 목록(crontab)을 관리합니다.

## 2-1. 기본 명령

| 명령 | 역할 |
|---|---|
| `crontab -e` | 내 크론 목록 편집 (없으면 새로 생성) |
| `crontab -l` | 내 크론 목록 조회 |
| `crontab -r` | 내 크론 목록 전체 삭제 |
| `crontab -i` | 삭제 시 확인 프롬프트 표시 |
| `crontab -u 사용자 -e` | 특정 사용자의 크론 편집 (root 권한 필요) |

## 2-2. 크론 표현식 (핵심)

각 줄은 **5개의 시간 필드 + 실행할 명령**으로 구성됩니다.

```
┌───────────── 분   (0-59)
│ ┌─────────── 시   (0-23)
│ │ ┌───────── 일   (1-31)
│ │ │ ┌─────── 월   (1-12)
│ │ │ │ ┌───── 요일 (0-7, 0과 7은 일요일)
│ │ │ │ │
* * * * *  실행할_명령
```

### 특수 기호

| 기호 | 의미 | 예시 |
|---|---|---|
| `*` | 모든 값 | 매 분/매 시 |
| `,` | 나열 | `1,15,30` → 1분, 15분, 30분 |
| `-` | 범위 | `1-5` → 월~금 |
| `/` | 간격 | `*/10` → 10분마다 |

## 2-3. 예시

```cron
# 매일 오전 9시 정각에 백업 스크립트 실행
0 9 * * * /home/user/backup.sh

# 매주 월·수·금 오후 6시에 실행
0 18 * * 1,3,5 /home/user/report.sh

# 10분마다 실행
*/10 * * * * /home/user/check.sh

# 매월 1일 새벽 2시에 실행
0 2 1 * * /home/user/monthly.sh

# 평일(월~금) 오전 8시 30분에 실행
30 8 * * 1-5 /home/user/notify.sh

# 매시 정각마다 실행
0 * * * * /home/user/hourly.sh
```

## 2-4. 특수 문자열 (단축 표기)

크론 표현식 대신 아래 키워드를 쓸 수도 있습니다.

| 키워드 | 의미 |
|---|---|
| `@reboot` | 부팅 시 1회 |
| `@yearly` / `@annually` | 매년 1월 1일 0시 (`0 0 1 1 *`) |
| `@monthly` | 매월 1일 0시 (`0 0 1 * *`) |
| `@weekly` | 매주 일요일 0시 (`0 0 * * 0`) |
| `@daily` / `@midnight` | 매일 0시 (`0 0 * * *`) |
| `@hourly` | 매시 정각 (`0 * * * *`) |

```cron
@daily  /home/user/daily.sh
@reboot /home/user/startup.sh
```

## 2-5. 알아두면 좋은 점

- 크론은 **최소 환경 변수**로 실행되므로, 스크립트 안에서는 명령·파일 경로를 **절대경로**로 쓰는 것이 안전합니다.
- 실행 결과나 오류는 기본적으로 메일로 전송됩니다. 로그로 남기려면 리다이렉트를 씁니다.
  ```cron
  0 9 * * * /home/user/backup.sh >> /home/user/backup.log 2>&1
  ```
- 특정 작업만 조용히 실행하려면 출력을 버립니다: `> /dev/null 2>&1`
- 크론 데몬(`cron` 또는 `crond`)이 실행 중이어야 동작합니다.
  ```
  systemctl status cron      # (데비안/우분투 계열)
  systemctl status crond     # (RHEL/CentOS 계열)
  ```

---

# 3부. schtasks ↔ crontab 대응표

| 항목 | Windows (schtasks) | Linux (crontab) |
|---|---|---|
| 도구 이름 | 작업 스케줄러 / `schtasks` | cron / `crontab` |
| 작업 편집 | `schtasks /Create …` | `crontab -e` |
| 작업 조회 | `schtasks /Query` | `crontab -l` |
| 작업 삭제 | `schtasks /Delete /TN …` | `crontab -r` (전체) 또는 해당 줄 삭제 |
| 즉시 실행 | `schtasks /Run /TN …` | (별도 없음, 명령 직접 실행) |
| 매일 9시 | `/SC DAILY /ST 09:00` | `0 9 * * *` |
| 10분마다 | `/SC MINUTE /MO 10` | `*/10 * * * *` |
| 부팅 시 | `/SC ONSTART` | `@reboot` |
| 요일 지정 | `/D MON,WED,FRI` | `* * * * 1,3,5` |
