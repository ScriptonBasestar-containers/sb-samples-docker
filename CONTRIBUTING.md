# 기여 가이드라인 (Contributing)

sb-samples-websolution 프로젝트에 기여해 주셔서 감사합니다! 이 문서는 프로젝트에 기여하는 방법을 안내합니다.

## 목차

- [기여 방법](#기여-방법)
- [새 서비스 추가](#새-서비스-추가)
- [코드 스타일 및 규칙](#코드-스타일-및-규칙)
- [Pull Request 절차](#pull-request-절차)
- [이슈 보고](#이슈-보고)

## 기여 방법

다음과 같은 방법으로 기여할 수 있습니다:

1. **새로운 웹 서비스 추가**: Docker Compose 설정 추가
2. **기존 설정 개선**: 볼륨 경로, 환경 변수 최적화
3. **문서화 개선**: README, 주석, 사용 예제
4. **버그 수정**: 설정 오류, 스크립트 버그
5. **유틸리티 스크립트**: 백업, 복원, 헬스체크 등

## 새 서비스 추가

새로운 웹 애플리케이션이나 서비스를 추가하려면:

### 1. 디렉토리 구조 생성

```bash
# 서비스 이름으로 디렉토리 생성 (소문자, 하이픈 사용)
mkdir service-name
cd service-name
```

### 2. docker-compose.yml 작성

기본 템플릿:

```yaml
version: '3.7'

services:
  # 데이터베이스 (필요시)
  db:
    image: bitnami/mariadb:10
    ports:
      - 3306:3306
    volumes:
      - db_data:/bitnami/mariadb
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_USER=bn_servicename
      - MARIADB_DATABASE=bitnami_servicename

  # 메인 애플리케이션
  servicename:
    image: vendor/servicename
    ports:
      - 8080:80
    volumes:
      - web_data:/bitnami
    depends_on:
      - db
    environment:
      - MARIADB_HOST=db
      - MARIADB_PORT_NUMBER=3306

volumes:
  db_data:
    driver: local
  web_data:
    driver: local
```

### 3. README.md 작성

서비스 디렉토리에 README.md를 추가하세요. 표준 형식:

```markdown
# [서비스명]

[서비스에 대한 간단한 설명]

## 개요

- **공식 사이트**: [URL]
- **Docker Hub**: [URL]
- **기본 포트**: 8080
- **데이터베이스**: MariaDB 10

## 빠른 시작

\`\`\`bash
# 서비스 시작
docker-compose up -d

# 브라우저에서 접속
http://localhost:8080
\`\`\`

## 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| MARIADB_HOST | db | 데이터베이스 호스트 |
| SERVICE_PORT | 8080 | 웹 포트 |

## 볼륨

- `web_data`: 애플리케이션 데이터
- `db_data`: 데이터베이스 데이터

## 기본 접속 정보

- **URL**: http://localhost:8080
- **관리자 ID**: admin
- **관리자 비밀번호**: (초기 설정 시 생성)

## 알려진 이슈

- [이슈 설명]

## 참고 링크

- [공식 문서]
- [Docker 이미지 문서]
\`\`\`

### 4. 루트 README 업데이트

`/README.md` 파일을 업데이트하여:
- 서비스 목록 테이블에 추가
- 포트 맵 테이블에 추가

### 5. .env.example 업데이트

루트의 `.env.example` 파일에 새 서비스의 환경 변수를 추가하세요:

```bash
# [서비스명]
SERVICENAME_PORT=8090
SERVICENAME_DB_PASSWORD=password
```

### 6. 테스트

```bash
# 서비스 시작 테스트
cd service-name
docker-compose up -d

# 컨테이너 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs

# 웹 접속 테스트
curl http://localhost:8080

# 정리
docker-compose down -v
```

## 코드 스타일 및 규칙

### Docker Compose 파일

- **버전**: `3.7` 사용
- **네이밍**:
  - 서비스명: snake_case (예: `wordpress`, `redis_master`)
  - 볼륨명: snake_case (예: `db_data`, `web_data`)
- **포트**: 기본적으로 8080 사용 (충돌 시 다른 포트)
- **환경 변수**: 대문자, 언더스코어 구분 (예: `MARIADB_HOST`)
- **주석**: 설정이 복잡하거나 중요한 부분에 주석 추가

### 디렉토리 구조

```
service-name/
├── docker-compose.yml        # 기본 설정
├── README.md                  # 서비스별 문서
├── dc-alternative.yml         # 대안 설정 (선택사항)
└── config/                    # 추가 설정 파일 (선택사항)
    └── ...
```

### 볼륨 설정

- **개발 모드**: 넓은 범위 볼륨 허용 (예: `/bitnami`)
- **README에 명시**: 프로덕션 환경에서는 좁은 범위로 조정 필요
- **중요 데이터**: 반드시 볼륨 마운트 (DB 데이터, 업로드 파일 등)

### 보안

- **개발 편의성**: `ALLOW_EMPTY_PASSWORD=yes` 허용
- **경고 추가**: README에 프로덕션 환경 보안 경고 명시
- **기본 비밀번호**: 간단한 기본값 사용 (예: `password`)
- **.env 사용 권장**: 민감한 정보는 .env 파일로 관리

## Pull Request 절차

### 1. Fork 및 Clone

```bash
# 저장소 Fork (GitHub에서)
# 로컬에 Clone
git clone https://github.com/your-username/sb-samples-docker.git
cd sb-samples-docker
```

### 2. 브랜치 생성

```bash
# 기능별 브랜치 생성
git checkout -b add-service-name
# 또는
git checkout -b fix-wordpress-config
```

### 3. 변경 사항 커밋

```bash
git add .
git commit -m "feat: Add [service-name] docker-compose configuration"
```

**커밋 메시지 규칙**:
- `feat:` - 새 기능 추가
- `fix:` - 버그 수정
- `docs:` - 문서 수정
- `refactor:` - 코드 리팩토링
- `test:` - 테스트 추가/수정
- `chore:` - 빌드, 설정 등

### 4. Push 및 PR 생성

```bash
git push origin add-service-name
```

GitHub에서 Pull Request를 생성하고 다음을 포함하세요:
- **제목**: 간결하고 명확한 설명
- **설명**:
  - 무엇을 변경했는지
  - 왜 변경했는지
  - 어떻게 테스트했는지
- **스크린샷**: UI 변경이 있다면 추가

### 5. 리뷰 및 수정

- 리뷰어의 피드백에 응답
- 필요한 수정사항 반영
- CI/CD 통과 확인

## 이슈 보고

버그나 개선 사항을 발견하면 GitHub Issues에 보고해 주세요.

### 버그 리포트 템플릿

```markdown
## 버그 설명
[버그에 대한 명확한 설명]

## 재현 방법
1. '...'로 이동
2. '...'를 클릭
3. '...'까지 스크롤
4. 오류 발생

## 예상 동작
[예상했던 동작 설명]

## 실제 동작
[실제로 발생한 동작]

## 환경
- OS: [예: Ubuntu 22.04]
- Docker 버전: [예: 24.0.5]
- Docker Compose 버전: [예: 2.20.2]
- 서비스: [예: wordpress]

## 추가 정보
[스크린샷, 로그 등]
```

### 기능 요청 템플릿

```markdown
## 기능 설명
[원하는 기능에 대한 명확한 설명]

## 동기
[왜 이 기능이 필요한지]

## 제안하는 해결책
[어떻게 구현할 수 있을지]

## 대안
[고려한 다른 대안들]
```

## 질문이나 도움이 필요하신가요?

- GitHub Issues에 질문을 올려주세요
- 기존 Issues와 Pull Requests를 먼저 확인해 보세요

## 라이선스

기여하신 코드는 프로젝트와 동일한 [MIT License](LICENSE)가 적용됩니다.

---

**감사합니다!** 여러분의 기여가 프로젝트를 더 좋게 만듭니다. 🎉
