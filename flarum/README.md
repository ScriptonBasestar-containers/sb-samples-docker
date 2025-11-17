# Flarum

Flarum은 차세대 포럼 소프트웨어입니다. 빠르고, 아름답고, 사용하기 쉬운 토론 플랫폼으로 설계되었습니다.

## 개요

- **공식 사이트**: https://flarum.org
- **GitHub**: https://github.com/flarum/flarum
- **Docker Hub**:
  - Mondedie: https://hub.docker.com/r/mondedie/flarum
  - GitHub: https://github.com/mondediefr/docker-flarum
- **기본 포트**: 8888
- **데이터베이스**: MariaDB 10

## 빠른 시작

```bash
# 서비스 시작
cd flarum
docker-compose up -d

# 브라우저에서 접속
# http://localhost:8888
```

### 헬퍼 스크립트 사용

```bash
./scripts/start.sh flarum
./scripts/stop.sh flarum
./scripts/backup.sh flarum
```

## 환경 변수

### Flarum 설정

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| FORUM_URL | http://localhost:8888 | 포럼 URL |
| DEBUG | false | 디버그 모드 |
| FLARUM_ADMIN_USER | admin | 관리자 사용자명 |
| FLARUM_ADMIN_PASS | password | 관리자 비밀번호 (최소 8자) |
| FLARUM_ADMIN_MAIL | admin@test.co.kr | 관리자 이메일 |
| FLARUM_TITLE | Test flarum | 포럼 제목 |

### 데이터베이스 설정

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| DB_HOST | db | 데이터베이스 호스트 |
| DB_NAME | bitnami_db | DB 이름 |
| DB_USER | bn_user | DB 사용자 |
| DB_PASS | password | DB 비밀번호 |
| DB_PREF | flarum_ | 테이블 접두사 |
| DB_PORT | 3306 | DB 포트 |

## 볼륨

- `db_data`: MariaDB 데이터베이스 데이터
- `flarum-assets`: 컴파일된 자산 파일 (`/flarum/app/public/assets`)
- `flarum-extensions`: 확장 기능 (`/flarum/app/extensions`)
- `flarum-nginx`: Nginx 설정 (`/etc/nginx/conf.d`)

**중요 경로**:
```
/flarum/app/public/assets    # CSS, JS 등 컴파일된 자산
/flarum/app/extensions        # 설치된 확장 기능
/etc/nginx/conf.d            # Nginx 웹서버 설정
```

## 기본 접속 정보

- **URL**: http://localhost:8888
- **관리자 ID**: admin (설치 시 지정)
- **관리자 비밀번호**: password (최소 8자, 변경 필요!)

## 사용 예제

### 백업

```bash
# 데이터베이스 백업
docker-compose exec db mysqldump -u bn_user -ppassword bitnami_db > backup.sql

# 확장 기능 백업
docker-compose exec mondedie-flarum tar czf /tmp/extensions-backup.tar.gz /flarum/app/extensions
docker cp flarum_mondedie-flarum_1:/tmp/extensions-backup.tar.gz ./flarum-extensions.tar.gz

# 또는 자동화 스크립트 사용 (현재 미지원)
# ./scripts/backup.sh flarum
```

### 복원

```bash
# 데이터베이스 복원
docker-compose exec -T db mysql -u bn_user -ppassword bitnami_db < backup.sql

# 확장 기능 복원
docker cp ./flarum-extensions.tar.gz flarum_mondedie-flarum_1:/tmp/
docker-compose exec mondedie-flarum tar xzf /tmp/extensions-backup.tar.gz -C /
```

### 로그 확인

```bash
# 전체 로그
docker-compose logs -f

# Flarum만
docker-compose logs -f mondedie-flarum

# Nginx 로그
docker-compose exec mondedie-flarum tail -f /var/log/nginx/access.log
docker-compose exec mondedie-flarum tail -f /var/log/nginx/error.log
```

## Flarum 관리

### 확장 기능 설치

Flarum의 강력함은 확장 기능에 있습니다:

```bash
# 컨테이너 접속
docker-compose exec mondedie-flarum sh

# Composer로 확장 설치 (예: 태그 기능)
cd /flarum/app
composer require flarum/tags

# 확장 활성화 (웹 관리 페이지에서)
# http://localhost:8888/admin
```

### 인기 확장 기능

**공식 확장**:
- **flarum/tags**: 태그 시스템
- **flarum/mentions**: 사용자 멘션
- **flarum/likes**: 좋아요 기능
- **flarum/lock**: 토론 잠금
- **flarum/sticky**: 공지 고정

**커뮤니티 확장**:
- **fof/best-answer**: 베스트 답변
- **fof/formatting**: 고급 서식
- **fof/upload**: 파일 업로드
- **fof/polls**: 투표 기능

### 캐시 및 자산 재컴파일

```bash
# 캐시 클리어
docker-compose exec mondedie-flarum php /flarum/app/flarum cache:clear

# 자산 재컴파일 (확장 설치 후)
docker-compose exec mondedie-flarum php /flarum/app/flarum assets:publish
```

### 유지보수 모드

```bash
# 유지보수 모드 활성화
docker-compose exec mondedie-flarum php /flarum/app/flarum down

# 유지보수 모드 비활성화
docker-compose exec mondedie-flarum php /flarum/app/flarum up
```

## 커스터마이징

### 포트 변경

`.env` 파일 생성:
```bash
FLARUM_PORT=8889
```

`docker-compose.yml` 수정:
```yaml
services:
  mondedie-flarum:
    ports:
      - "${FLARUM_PORT:-8888}:8888"
    environment:
      - FORUM_URL=http://localhost:${FLARUM_PORT:-8888}
```

### 보안 강화 (프로덕션)

`docker-compose.yml`에서:
```yaml
environment:
  - MARIADB_ROOT_PASSWORD=very_secure_root_password
  - MARIADB_PASSWORD=secure_db_password
  - FLARUM_ADMIN_PASS=secure_admin_password_minimum_8_chars
  - DEBUG=false
  - FORUM_URL=https://yourdomain.com
```

### SMTP 이메일 설정

Flarum 관리 페이지에서 설정:
1. Admin > Email 메뉴
2. SMTP 서버 정보 입력
3. 테스트 이메일 발송

## 알려진 이슈

### 1. 자산 컴파일 실패

**문제**: 확장 설치 후 자산이 로드되지 않음

**해결**:
```bash
docker-compose exec mondedie-flarum php /flarum/app/flarum cache:clear
docker-compose exec mondedie-flarum php /flarum/app/flarum assets:publish
docker-compose restart mondedie-flarum
```

### 2. 데이터베이스 연결 오류

**문제**: "Connection refused" 오류

**해결**: DB 컨테이너가 완전히 시작될 때까지 대기
```bash
docker-compose restart mondedie-flarum
```

### 3. Nginx 502 Bad Gateway

**문제**: PHP-FPM 연결 실패

**해결**:
```bash
docker-compose exec mondedie-flarum sv restart php-fpm
```

### 4. 확장 충돌

**문제**: 특정 확장 설치 후 사이트 오류

**해결**: 문제 확장 제거
```bash
docker-compose exec mondedie-flarum composer remove vendor/extension-name
docker-compose exec mondedie-flarum php /flarum/app/flarum cache:clear
```

## 성능 최적화

### 1. OPcache 활성화

이미 mondedie 이미지에 포함되어 있습니다.

### 2. Redis 캐시 (권장)

추가 Redis 서비스 설정:
```yaml
redis:
  image: redis:alpine
  ports:
    - 6379:6379
```

Flarum 설정에서 Redis 캐시 드라이버 활성화

### 3. CDN 사용

정적 자산을 CDN으로 제공하여 성능 향상

## Flarum CLI 명령어

```bash
# 컨테이너 내부에서 실행
docker-compose exec mondedie-flarum sh

# 사용 가능한 명령어 확인
php /flarum/app/flarum list

# 관리자 생성
php /flarum/app/flarum admin:create

# 설정 캐시
php /flarum/app/flarum cache:clear

# 데이터베이스 마이그레이션
php /flarum/app/flarum migrate

# 스케줄러 (cron 설정 필요)
php /flarum/app/flarum schedule:run
```

## 대안 이미지

### Uninett 이미지

```yaml
flarum:
  image: uninettno/flarum-docker-uh
  volumes:
    - /bitnami
```

장점:
- Bitnami 기반으로 익숙한 구조

단점:
- 업데이트 빈도가 낮음
- 커뮤니티 지원 적음

## 참고 링크

- **공식 문서**: https://docs.flarum.org/
- **확장 검색**: https://discuss.flarum.org/t/extensions
- **Flarum Community**: https://discuss.flarum.org/
- **Extiverse**: https://extiverse.com/ (확장 마켓플레이스)
- **GitHub**: https://github.com/flarum/flarum

## 프로덕션 체크리스트

- [ ] 모든 기본 비밀번호 변경
- [ ] 관리자 비밀번호 8자 이상
- [ ] HTTPS 설정 (리버스 프록시)
- [ ] FORUM_URL을 실제 도메인으로 변경
- [ ] DEBUG 모드 비활성화
- [ ] SMTP 이메일 서버 설정
- [ ] 정기 백업 스크립트 설정
- [ ] Redis 캐시 설정
- [ ] 데이터베이스 포트 외부 노출 제거
- [ ] 스팸 방지 확장 설치
- [ ] 로그 로테이션 설정
- [ ] CDN 설정 고려

## 업그레이드

### Flarum 버전 업데이트

```bash
# 1. 백업
docker-compose exec db mysqldump -u bn_user -ppassword bitnami_db > backup.sql

# 2. 컨테이너 내부 접속
docker-compose exec mondedie-flarum sh

# 3. Composer로 업데이트
cd /flarum/app
composer update --prefer-dist --no-dev -a --with-all-dependencies

# 4. 데이터베이스 마이그레이션
php flarum migrate

# 5. 캐시 클리어
php flarum cache:clear

# 6. 자산 재컴파일
php flarum assets:publish
```

### 이미지 업데이트

```bash
# 최신 이미지 가져오기
docker-compose pull

# 컨테이너 재시작
docker-compose up -d
```

## 트러블슈팅

### 데이터베이스 마이그레이션 실패

```bash
# 마이그레이션 상태 확인
docker-compose exec mondedie-flarum php /flarum/app/flarum migrate:status

# 강제 재시도
docker-compose exec mondedie-flarum php /flarum/app/flarum migrate:reset
docker-compose exec mondedie-flarum php /flarum/app/flarum migrate
```

### 권한 문제

```bash
# 소유권 재설정
docker-compose exec mondedie-flarum chown -R flarum:flarum /flarum/app
```

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
