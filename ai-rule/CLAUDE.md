# 공통 개발 규칙

모든 프로젝트에 공통으로 적용되는 규칙이다. 프로젝트 폴더의 규칙 파일이 이 파일과 충돌하면 프로젝트 규칙을 따른다.

## 0. 최우선 제약: 폐쇄망

모든 산출물은 **인터넷이 차단된 폐쇄망**에서 동작해야 한다.

- 외부 CDN 사용 금지: Google Fonts, unpkg, jsdelivr, cdnjs, 외부 아이콘 폰트, 외부 이미지 URL 모두 해당
- 폰트, 아이콘, 이미지 등 모든 에셋은 로컬 파일로 포함하고 빌드 결과물에 번들링한다
- 런타임에 외부 네트워크를 호출하는 코드 금지 (분석 도구, 에러 리포팅 SaaS, 원격 설정 등)
- 작업 후 빌드 결과물(`index.html`, CSS, JS)에 `http://` 또는 `https://`로 시작하는 외부 리소스 참조가 없는지 확인한다

## 1. 작업 원칙

- 추측하지 않는다. 요구사항이 애매하면 가정을 명시하고 질문한다
- 요청받은 것만 만든다. 요청 범위 밖의 파일, 스타일, 코드는 수정하지 않는다
- 관련 없는 문제를 발견하면 고치지 말고 보고만 한다
- 기존 코드 스타일과 패턴을 따른다. 새 패턴을 도입하기 전에 먼저 확인받는다
- 단순하게 짠다. 요청하지 않은 추상화, 설정 옵션, 미래 대비 코드를 만들지 않는다

## 2. 백엔드 (Go + Gin)

### 폴더 구조

`github.com/Jaeun-Choi98/app-folder-template`의 `go/gin` 구조를 따른다. 새 파일은 반드시 해당 계층에 둔다.

```
cmd/server/            # 진입점 main.go, env.ini, build/(SPA 결과물)
internal/
├── app/               # 시작/종료 순서
├── config/            # env.ini 로더
├── container/         # 의존성 조립 (수동 DI)
├── event/             # EventBus 접근자, 이벤트 타입
├── service/           # 비즈니스 로직 (api-service, tcp-service)
├── transport/
│   ├── http-rest/     # controller, middleware, request, response
│   └── tcp/
├── db/                # db-handler(maria, oracle), entity
├── infra/cache/       # 인메모리 캐시
├── worker/            # 백그라운드 작업
└── logger/
```

- 계층을 건너뛰지 않는다: controller → service → db/infra
- 서버는 `cmd/server/`에서 실행한다 (`env.ini`, `log/`가 상대 경로)

### 프로세스 수명 주기

`cmd/server/main.go`와 `internal/app/app.go`에 구현된 수명 주기를 그대로 사용한다. 별도의 시작/종료 로직을 새로 만들지 않는다.

- 흐름: `config` 로드 → `logger.Init` → `container.NewContainer` → `app.NewApplication(cancel).Start()` → 종료 원인 대기 → `container.DelContainer`
- 배포 모드: `TEST`는 한 번 실행 후 종료, `PRODUCT`는 비정상 종료 시 자동 재시작. 이 분기를 유지한다
- 새 고루틴(서버, 워커, 모니터링)은 `app.Start()`에 등록한다. 장시간 도는 작업은 `safeGo`로 감싸 panic이 `ErrPanic`으로 상위에 전달되게 한다
- 종료 시 정리는 `app`의 `stop`/`shutdown` 경로에 추가한다. 시그널(SIGINT/SIGTERM) 처리를 다른 곳에서 중복 등록하지 않는다
- 새 컴포넌트는 `container`에서 생성·조립하고 `container.GetXxx()`로 접근한다

### 설정 파일

- 설정은 `example.env.ini`를 기준으로 한다. 실행 위치(`cmd/server/`)에 `env.ini`로 복사해 값을 채워 사용한다
- 새 설정 키를 추가하면 `example.env.ini`와 `internal/config/config.go`를 함께 수정한다
- 하드코딩 대신 설정 키를 사용한다 (IP, 포트, 경로, 타임아웃 등)
- 실제 값이 들어간 `env.ini`, 인증서, 키 파일은 커밋하지 않는다

### 공용 모듈

`github.com/Jaeun-Choi98/modules`에 있는 기능은 새로 구현하지 않고 이 모듈을 사용한다.

| 필요한 기능 | 사용할 패키지 |
| --- | --- |
| 내부 이벤트 Pub/Sub | `eventbus` |
| 실시간 서버 푸시 | `sse` |
| TCP / UDP / 시리얼 통신 | `tcpnet`, `udpnet`, `serialport` |
| Redis 저장소 | `orm/redisorm` |
| 로그 | `logger` |
| 쉘/SSH 실행 | `shell`, `sshclient` |
| 범용 유틸 | `utils` |

- 모듈에 없는 기능이 필요하면 구현 전에 알린다
- 폐쇄망 빌드를 위해 Go 의존성은 vendoring 또는 내부 프록시 기준으로 관리한다. 새 외부 Go 모듈 추가 전 확인받는다

### API 규칙
- 에러는 `ctx.Error(httperr...)`로 넘겨 에러 미들웨어가 처리하게 한다
- 실시간 데이터는 폴링보다 SSE(`/sse/connect`, `sse` 모듈)를 우선한다
- 인증은 기존 JWT 쿠키 방식을 따른다

## 3. 프론트엔드 (TypeScript + React SPA)

### 기본

- TypeScript strict 모드. `any` 사용 금지 (불가피하면 이유를 주석으로 남김)
- 함수형 컴포넌트와 Hooks만 사용
- 빌드 결과물은 Go 서버의 `cmd/server/build/`에 배치되어 `SpaHandlerRoot`로 서빙된다
- 클라이언트 라우팅 경로는 백엔드 API 경로와 겹치지 않게 한다

### 라이브러리

- **새 라이브러리 추가는 최소화한다.** 추가가 필요하면 먼저 이유와 대안(직접 구현 시 코드량)을 제시하고 확인받는다
- 기본 원칙: React + TypeScript + 브라우저 기본 API로 해결 가능하면 라이브러리를 쓰지 않는다
  - HTTP: `fetch` 래퍼 하나로 처리 (axios 추가 금지)
  - 상태관리: `useState`, `useReducer`, Context로 시작
  - 스타일: CSS Modules 또는 일반 CSS + CSS 변수 (CSS-in-JS, UI 키트 추가 금지)
  - 날짜: `Intl.DateTimeFormat` 또는 작은 유틸 함수
  - SSE: 브라우저 `EventSource`
- 추가하는 라이브러리는 npm 패키지로 설치해 번들에 포함한다 (CDN 금지)

### 폴더 구조 (기본값, 프로젝트에 기존 구조가 있으면 그것을 따름)

```
src/
├── api/          # fetch 래퍼, API 호출 함수, 응답 타입
├── components/   # 재사용 컴포넌트
├── pages/        # 라우트 단위 화면
├── hooks/        # 커스텀 훅 (useSSE 등)
├── styles/       # tokens.css, global.css
├── types/        # 공용 타입
└── utils/        # 포맷터 등
```

### API 연동

- 백엔드 `BaseResponse` 형식에 맞춘 공용 응답 타입과 fetch 래퍼를 `src/api/`에 하나만 둔다
- `result` 코드가 성공이 아니면 공통 에러 처리로 넘긴다
- 백엔드 응답 JSON의 실제 필드명을 확인하고 타입을 작성한다 (추측 금지)
- 401 응답 시 로그인 화면으로 이동하는 처리를 공통 래퍼에서 한다

## 4. 디자인: 미니멀

### 원칙

- 장식보다 정보. 요소를 추가하기 전에 빼도 되는지 먼저 생각한다
- 여백과 정렬로 구분하고, 테두리·배경색·그림자는 꼭 필요할 때만 쓴다
- 한 화면에 강조색(primary)은 주요 동작 하나에만 쓴다

### 금지

- 그라데이션, 글래스모피즘, 네온/글로우 효과
- 이모지를 아이콘 대신 사용
- 과한 그림자, 과한 둥근 모서리(8px 초과)
- 의미 없는 애니메이션 (전환 효과는 150ms 이하의 opacity/transform만)
- 모든 것을 카드로 감싸는 레이아웃

### 디자인 토큰

- 색상, 간격, 폰트 크기는 `src/styles/tokens.css`의 CSS 변수만 사용한다. 컴포넌트에 색상값 하드코딩 금지
- 테마 기본값은 **라이트 모드**. 다크 모드는 요청이 있을 때만 `[data-theme="dark"]`로 토큰을 덮어써서 추가한다

```css
:root {
  /* 색상: 무채색 중심 + 강조색 1개 */
  --color-bg: #ffffff;
  --color-surface: #f7f7f8;
  --color-border: #e4e4e7;
  --color-text: #18181b;
  --color-text-muted: #71717a;
  --color-primary: #2563eb;
  --color-success: #16a34a;
  --color-warning: #d97706;
  --color-danger: #dc2626;

  /* 간격: 4px 단위 */
  --space-1: 4px;  --space-2: 8px;  --space-3: 12px;
  --space-4: 16px; --space-6: 24px; --space-8: 32px;

  /* 타이포 */
  --font-sans: "Pretendard", system-ui, -apple-system, "Malgun Gothic", sans-serif;
  --text-xs: 12px; --text-sm: 13px; --text-md: 14px;
  --text-lg: 16px; --text-xl: 20px; --text-2xl: 24px;

  --radius: 6px;
  --shadow: 0 1px 2px rgb(0 0 0 / 0.06);
}
```

- 폰트 파일(Pretendard 등)을 쓰면 `woff2`를 프로젝트에 포함하고 `@font-face`로 로컬 로드한다. 없으면 시스템 폰트를 쓴다
- 아이콘은 로컬 SVG 컴포넌트로 만든다 (아이콘 폰트, 외부 아이콘 CDN 금지)

## 5. UI 품질 기준

- 데이터를 보여주는 모든 화면은 **로딩 / 빈 데이터 / 에러** 상태를 구현한다
- 긴 텍스트는 말줄임 처리하고 전체 내용은 `title` 등으로 확인 가능하게 한다
- 날짜 표기: `YYYY-MM-DD HH:mm:ss` (24시간제), 숫자는 천 단위 콤마
- 폼: `label` 연결, 필수값 표시, 제출 중 버튼 비활성화, 서버 에러 메시지 표시
- 키보드로 주요 동작이 가능해야 한다 (Tab 이동, Enter 제출, Esc로 모달 닫기)
- 텍스트와 배경의 명도 대비를 충분히 확보한다

## 6. 문구

- UI 언어는 한국어
- 버튼은 동사형 간결체: "저장", "삭제", "조회"
- 안내 메시지는 존댓말: "저장되었습니다", "데이터가 없습니다"
- 삭제 등 되돌릴 수 없는 동작은 확인 절차를 거친다

## 7. 완료 조건

작업 완료를 보고하기 전에 확인한다.

- [ ] `go build`, `go vet`, 프론트 `tsc --noEmit`과 빌드가 오류 없이 통과
- [ ] 브라우저 콘솔 에러 없음
- [ ] 빌드 결과물에 외부 URL 참조 없음
- [ ] 로딩 / 빈 데이터 / 에러 상태 동작 확인
- [ ] 새로 추가한 라이브러리가 있으면 이유와 함께 보고

보고 형식: 변경한 파일 목록과 변경 요약, 확인하지 못한 부분이 있으면 명시.
