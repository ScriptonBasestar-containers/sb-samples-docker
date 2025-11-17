# Joomla

Joomla는 강력하고 유연한 오픈소스 콘텐츠 관리 시스템(CMS)입니다. 수백만 개의 웹사이트와 강력한 온라인 애플리케이션 구축에 사용됩니다.

## 개요

- **공식 사이트**: https://www.joomla.org
- **Docker Hub**:
  - 공식: https://hub.docker.com/_/joomla
  - Bitnami: https://hub.docker.com/r/bitnami/joomla
- **기본 포트**: 8080
- **데이터베이스**: MariaDB 10

## 빠른 시작

### 기본 실행 방법

```bash
# 서비스 시작
cd joomla
docker-compose up -d

# 브라우저에서 접속
# http://localhost:8080
```

### 헬퍼 스크립트 사용

```bash
# 프로젝트 루트에서
./scripts/start.sh joomla

# 중지
./scripts/stop.sh joomla

# 볼륨까지 삭제
./scripts/stop.sh joomla -v

# 백업 (데이터베이스 + 파일)
./scripts/backup.sh joomla

# 복원
./scripts/restore.sh joomla -b /path/to/backup
```

## 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| MARIADB_HOST | db | 데이터베이스 호스트 |
| MARIADB_PORT_NUMBER | 3306 | 데이터베이스 포트 |
| JOOMLA_DATABASE_USER | bn_joomla | DB 사용자 |
| JOOMLA_DATABASE_NAME | bitnami_joomla | DB 이름 |
| ALLOW_EMPTY_PASSWORD | yes | 빈 비밀번호 허용 (개발용) |

## 볼륨

### Bitnami 이미지 (현재 사용 중)

- `db_data`: MariaDB 데이터베이스 데이터 (`/bitnami/mariadb`)
- `web_data`: Joomla 애플리케이션 데이터 (`/bitnami`)

**프로덕션 환경에서 권장하는 세부 볼륨**:
```
/bitnami/joomla/administrator    # 관리자 디렉토리
/bitnami/joomla/components       # 컴포넌트
/bitnami/joomla/modules          # 모듈
/bitnami/joomla/plugins          # 플러그인
/bitnami/joomla/templates        # 템플릿
/bitnami/joomla/images           # 이미지 업로드
/bitnami/joomla/configuration.php # 설정 파일
```

### 공식 이미지

```
/var/www/html                    # Joomla 루트 디렉토리
```

## 포트

| 포트 | 서비스 | 설명 |
|------|--------|------|
| 8080 | Joomla | 웹 인터페이스 |
| 3306 | MariaDB | 데이터베이스 (외부 노출) |

⚠️ **주의**: 여러 서비스를 동시 실행 시 포트 충돌 가능. `.env` 파일이나 `docker-compose.yml`에서 포트 변경 필요.

## 기본 접속 정보

- **URL**: http://localhost:8080
- **관리자 페이지**: http://localhost:8080/administrator
- **초기 설정**: 첫 접속 시 설치 마법사 실행

**기본 계정** (Bitnami 이미지):
- **사용자명**: user
- **비밀번호**: bitnami

## 사용 예제

### 백업

```bash
# 데이터베이스 백업
docker-compose exec db mysqldump -u bn_joomla bitnami_joomla > backup.sql

# 파일 백업
docker-compose exec joomla tar czf /tmp/joomla-files.tar.gz /bitnami/joomla
docker cp joomla_joomla_1:/tmp/joomla-files.tar.gz ./joomla-backup.tar.gz
```

### 복원

```bash
# 데이터베이스 복원
docker-compose exec -T db mysql -u bn_joomla bitnami_joomla < backup.sql

# 파일 복원
docker cp ./joomla-backup.tar.gz joomla_joomla_1:/tmp/
docker-compose exec joomla tar xzf /tmp/joomla-files.tar.gz -C /
```

### 로그 확인

```bash
# 전체 로그
docker-compose logs -f

# Joomla만
docker-compose logs -f joomla

# 최근 100줄
docker-compose logs --tail=100 joomla
```

### 확장 설치

```bash
# 컨테이너 내부 접속
docker-compose exec joomla bash

# 확장 다운로드 (예: Akeeba Backup)
cd /bitnami/joomla/tmp
wget https://example.com/extension.zip
```

## 커스터마이징

### 포트 변경

`.env` 파일 생성:
```bash
JOOMLA_PORT=8081
MARIADB_PORT=3307
```

`docker-compose.yml` 수정:
```yaml
services:
  joomla:
    ports:
      - "${JOOMLA_PORT:-8080}:80"
```

### 보안 강화 (프로덕션)

`docker-compose.yml`에서:
```yaml
environment:
  - MARIADB_PASSWORD=secure_password_here
  - JOOMLA_PASSWORD=admin_password_here
  # ALLOW_EMPTY_PASSWORD 제거
```

### PHP 설정 커스터마이징

```yaml
joomla:
  environment:
    - PHP_MEMORY_LIMIT=512M
    - PHP_UPLOAD_MAX_FILESIZE=64M
    - PHP_POST_MAX_SIZE=64M
```

### MySQL 대신 MariaDB 사용

현재 설정이 MariaDB를 사용하고 있습니다. MySQL로 변경하려면:

```yaml
db:
  image: bitnami/mysql:8.0
  volumes:
    - db_data:/bitnami/mysql
  environment:
    - MYSQL_USER=bn_joomla
    - MYSQL_DATABASE=bitnami_joomla
```

## 알려진 이슈

### 1. 초기 설치 시 타임아웃

**문제**: 대용량 사이트 복원 시 PHP 타임아웃 발생

**해결**:
```yaml
joomla:
  environment:
    - PHP_MAX_EXECUTION_TIME=300
    - PHP_MAX_INPUT_TIME=300
```

### 2. 퍼미션 문제

**문제**: 확장 설치나 미디어 업로드 시 권한 오류

**해결**:
```bash
docker-compose exec joomla chown -R daemon:daemon /bitnami/joomla
# 또는
docker-compose exec joomla chmod -R 755 /bitnami/joomla
```

### 3. .htaccess 리다이렉트 문제

**문제**: SEF URL 활성화 후 404 오류

**해결**: Apache mod_rewrite 활성화 확인
```bash
docker-compose exec joomla a2enmod rewrite
docker-compose restart joomla
```

### 4. 캐시 문제

**문제**: 업데이트 후 변경사항이 반영되지 않음

**해결**:
```bash
# Joomla 관리자에서: System > Clear Cache
# 또는 직접 삭제
docker-compose exec joomla rm -rf /bitnami/joomla/cache/*
```

## Joomla 관리 팁

### 확장 관리

- **컴포넌트**: 주요 기능 (게시판, 갤러리 등)
- **모듈**: 사이드바, 헤더 등에 표시되는 작은 블록
- **플러그인**: 시스템 기능 확장
- **템플릿**: 사이트 디자인

### 권장 확장

- **Akeeba Backup**: 백업 및 복원
- **Admin Tools**: 보안 강화
- **JCE Editor**: 향상된 에디터
- **K2**: 확장된 컨텐츠 관리

### 성능 최적화

1. **캐시 활성화**: System > Global Configuration > System > Cache
2. **Gzip 압축**: System > Global Configuration > Server > Gzip Compression
3. **정적 파일 캐싱**: .htaccess에 브라우저 캐싱 규칙 추가

## 대안 설정

### 공식 Joomla 이미지 사용

`docker-compose.yml` 수정:
```yaml
joomla:
  image: joomla:latest
  volumes:
    - joomla_data:/var/www/html
```

장점:
- 공식 이미지
- 더 자주 업데이트

단점:
- 수동 설정 필요
- 환경 변수 옵션 제한적

## 참고 링크

- **공식 문서**: https://docs.joomla.org/
- **Bitnami Joomla**: https://github.com/bitnami/bitnami-docker-joomla
- **공식 Docker 이미지**: https://github.com/joomla/docker-joomla
- **Joomla Extensions**: https://extensions.joomla.org/
- **Joomla Forums**: https://forum.joomla.org/

## 프로덕션 체크리스트

프로덕션 환경 배포 전 확인사항:

- [ ] 모든 기본 비밀번호 변경
- [ ] `ALLOW_EMPTY_PASSWORD` 제거
- [ ] HTTPS 설정 (리버스 프록시)
- [ ] 정기 백업 스크립트 설정 (Akeeba 등)
- [ ] 볼륨 범위를 필요한 디렉토리로 축소
- [ ] PHP 메모리 및 업로드 제한 설정
- [ ] 데이터베이스 포트 외부 노출 제거
- [ ] 2단계 인증 활성화
- [ ] 불필요한 확장 제거
- [ ] Joomla 및 확장 최신 버전 유지
- [ ] 관리자 URL 변경 고려
- [ ] 로그 모니터링 설정

## 버전 업그레이드

### Joomla 메이저 버전 업그레이드

```bash
# 1. 전체 백업
./scripts/stop.sh joomla
docker-compose exec joomla tar czf /tmp/full-backup.tar.gz /bitnami/joomla
docker-compose exec db mysqldump -u bn_joomla bitnami_joomla > db-backup.sql

# 2. 테스트 환경에서 먼저 테스트

# 3. Joomla 관리자에서 업데이트
# Components > Joomla Update

# 4. 확장 호환성 확인
```

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
