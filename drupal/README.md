# Drupal

Drupal은 강력하고 확장 가능한 엔터프라이즈급 오픈소스 콘텐츠 관리 시스템(CMS)입니다. 복잡한 웹사이트와 애플리케이션 구축에 적합합니다.

## 개요

- **공식 사이트**: https://www.drupal.org
- **Docker Hub**:
  - 공식: https://hub.docker.com/_/drupal
  - Bitnami: https://hub.docker.com/r/bitnami/drupal
- **기본 포트**: 8080
- **데이터베이스**: MariaDB 10

## 빠른 시작

### 기본 실행 방법

```bash
# 서비스 시작
cd drupal
docker-compose up -d

# 브라우저에서 접속
# http://localhost:8080
```

### 헬퍼 스크립트 사용

```bash
# 프로젝트 루트에서
./scripts/start.sh drupal

# 중지
./scripts/stop.sh drupal

# 볼륨까지 삭제
./scripts/stop.sh drupal -v
```

## 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| MARIADB_HOST | db | 데이터베이스 호스트 |
| MARIADB_PORT_NUMBER | 3306 | 데이터베이스 포트 |
| DRUPAL_DATABASE_USER | bn_drupal | DB 사용자 |
| DRUPAL_DATABASE_NAME | bitnami_drupal | DB 이름 |
| ALLOW_EMPTY_PASSWORD | yes | 빈 비밀번호 허용 (개발용) |

## 볼륨

### Bitnami 이미지 (현재 사용 중)

- `db_data`: MariaDB 데이터베이스 데이터 (`/bitnami/mariadb`)
- `web_data`: Drupal 애플리케이션 데이터 (`/bitnami`)

**프로덕션 환경에서 권장하는 세부 볼륨**:
```
/bitnami/drupal/modules          # 모듈 (contrib + custom)
/bitnami/drupal/themes           # 테마
/bitnami/drupal/sites            # 사이트 설정 및 파일
/bitnami/drupal/sites/default/files  # 업로드 파일
```

### 공식 이미지

```
/var/www/html/modules            # 모듈
/var/www/html/profiles           # 프로파일
/var/www/html/themes             # 테마
/var/www/html/sites              # 사이트 설정 및 파일
```

## 포트

| 포트 | 서비스 | 설명 |
|------|--------|------|
| 8080 | Drupal | 웹 인터페이스 |
| 3306 | MariaDB | 데이터베이스 (외부 노출) |

⚠️ **주의**: 여러 서비스를 동시 실행 시 포트 충돌 가능. `.env` 파일이나 `docker-compose.yml`에서 포트 변경 필요.

## 기본 접속 정보

- **URL**: http://localhost:8080
- **초기 설정**: 첫 접속 시 설치 마법사 실행

**설치 후 기본 계정**:
- **사용자명**: admin (설치 시 지정)
- **비밀번호**: (설치 시 지정)

## 사용 예제

### 백업

```bash
# 데이터베이스 백업
docker-compose exec db mysqldump -u bn_drupal bitnami_drupal > backup.sql

# 파일 백업
docker-compose exec drupal tar czf /tmp/drupal-files.tar.gz /bitnami/drupal/sites/default/files
docker cp drupal_drupal_1:/tmp/drupal-files.tar.gz ./drupal-files-backup.tar.gz

# 전체 백업 (코드 + DB)
docker-compose exec drupal tar czf /tmp/drupal-full.tar.gz /bitnami/drupal
docker cp drupal_drupal_1:/tmp/drupal-full.tar.gz ./drupal-full-backup.tar.gz
```

### 복원

```bash
# 데이터베이스 복원
docker-compose exec -T db mysql -u bn_drupal bitnami_drupal < backup.sql

# 파일 복원
docker cp ./drupal-files-backup.tar.gz drupal_drupal_1:/tmp/
docker-compose exec drupal tar xzf /tmp/drupal-files-backup.tar.gz -C /
```

### Drush 사용

```bash
# 컨테이너 내부에서 Drush 실행
docker-compose exec drupal drush status

# 캐시 클리어
docker-compose exec drupal drush cache-rebuild

# 모듈 활성화
docker-compose exec drupal drush en module_name -y

# 사이트 업데이트
docker-compose exec drupal drush updatedb

# 설정 내보내기
docker-compose exec drupal drush config-export
```

### 로그 확인

```bash
# 전체 로그
docker-compose logs -f

# Drupal만
docker-compose logs -f drupal

# 최근 100줄
docker-compose logs --tail=100 drupal

# Drupal watchdog 로그
docker-compose exec drupal drush watchdog-show
```

## 커스터마이징

### 포트 변경

`.env` 파일 생성:
```bash
DRUPAL_PORT=8082
MARIADB_PORT=3307
```

`docker-compose.yml` 수정:
```yaml
services:
  drupal:
    ports:
      - "${DRUPAL_PORT:-8080}:80"
```

### 보안 강화 (프로덕션)

`docker-compose.yml`에서:
```yaml
environment:
  - MARIADB_PASSWORD=secure_password_here
  - DRUPAL_PASSWORD=admin_password_here
  # ALLOW_EMPTY_PASSWORD 제거
```

### PHP 설정 커스터마이징

```yaml
drupal:
  environment:
    - PHP_MEMORY_LIMIT=512M
    - PHP_UPLOAD_MAX_FILESIZE=128M
    - PHP_POST_MAX_SIZE=128M
    - PHP_MAX_EXECUTION_TIME=300
```

### Composer 사용

```bash
# 컨테이너 내부 접속
docker-compose exec drupal bash

# Composer로 모듈 설치
cd /bitnami/drupal
composer require drupal/admin_toolbar
composer require drupal/pathauto
composer require drupal/metatag

# Drush로 활성화
drush en admin_toolbar pathauto metatag -y
```

## 알려진 이슈

### 1. 퍼미션 문제

**문제**: 파일 업로드 시 권한 오류

**해결**:
```bash
docker-compose exec drupal chown -R www-data:www-data /bitnami/drupal/sites/default/files
docker-compose exec drupal chmod -R 755 /bitnami/drupal/sites/default/files
```

### 2. Trusted Host 설정

**문제**: "The provided host name is not valid" 경고

**해결**: `settings.php` 수정
```bash
docker-compose exec drupal bash
vi /bitnami/drupal/sites/default/settings.php

# 추가:
$settings['trusted_host_patterns'] = [
  '^localhost$',
  '^127\.0\.0\.1$',
];
```

### 3. 캐시 문제

**문제**: 변경사항이 즉시 반영되지 않음

**해결**:
```bash
# Drush로 캐시 클리어
docker-compose exec drupal drush cache-rebuild

# 또는 관리자 페이지
# Configuration > Development > Performance > Clear all caches
```

### 4. 모듈 업데이트 오류

**문제**: Composer 메모리 부족

**해결**:
```bash
# PHP 메모리 제한 일시적으로 증가
docker-compose exec drupal php -d memory_limit=2G /usr/local/bin/composer update
```

## Drupal 관리 팁

### 필수 모듈 추천

**관리 및 개발**:
- **Admin Toolbar**: 향상된 관리 메뉴
- **Devel**: 개발 도구
- **Configuration Split**: 환경별 설정 관리

**SEO 및 성능**:
- **Pathauto**: URL 자동 생성
- **Metatag**: 메타태그 관리
- **Redis**: 캐시 성능 향상

**컨텐츠 관리**:
- **Paragraphs**: 유연한 컨텐츠 구조
- **Media**: 미디어 관리
- **Webform**: 폼 빌더

### 성능 최적화

1. **캐시 설정**:
   - Configuration > Performance
   - Cache pages for anonymous users
   - Aggregate CSS/JS files

2. **Redis 캐시 백엔드** (권장):
```yaml
# docker-compose.yml에 Redis 추가
redis:
  image: redis:alpine
  ports:
    - 6379:6379
```

3. **Twig 디버깅 비활성화** (프로덕션):
```php
# sites/default/settings.php
$settings['cache']['bins']['render'] = 'cache.backend.chainedfast';
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.chainedfast';
```

### Drupal 8/9/10 특징

- **Configuration Management**: YAML 기반 설정 관리
- **Composer**: 의존성 관리
- **Drush**: 강력한 CLI 도구
- **Symfony Components**: 현대적인 PHP 프레임워크

## 대안 설정

### 공식 Drupal 이미지 사용

```yaml
drupal:
  image: drupal:10-apache
  volumes:
    - drupal_modules:/var/www/html/modules
    - drupal_themes:/var/www/html/themes
    - drupal_sites:/var/www/html/sites
```

장점:
- 공식 이미지
- 최신 Drupal 버전

단점:
- Drush 수동 설치 필요
- 환경 변수 옵션 제한적

## 참고 링크

- **공식 문서**: https://www.drupal.org/docs
- **Bitnami Drupal**: https://github.com/bitnami/bitnami-docker-drupal
- **공식 Docker 이미지**: https://github.com/docker-library/drupal
- **Drupal Modules**: https://www.drupal.org/project/project_module
- **Drush 문서**: https://www.drush.org/

## 프로덕션 체크리스트

프로덕션 환경 배포 전 확인사항:

- [ ] 모든 기본 비밀번호 변경
- [ ] `ALLOW_EMPTY_PASSWORD` 제거
- [ ] HTTPS 설정 (리버스 프록시)
- [ ] Trusted Host 설정
- [ ] 정기 백업 스크립트 설정
- [ ] 볼륨 범위를 필요한 디렉토리로 축소
- [ ] PHP 메모리 및 업로드 제한 설정
- [ ] 데이터베이스 포트 외부 노출 제거
- [ ] Twig 디버깅 비활성화
- [ ] 성능 캐시 활성화
- [ ] Redis 캐시 백엔드 설정
- [ ] Cron 작업 설정
- [ ] 에러 로깅 설정
- [ ] 보안 업데이트 자동 알림 설정

## 버전 업그레이드

### Drupal 마이너 버전 업데이트

```bash
# 1. 백업
docker-compose exec drupal drush sql-dump > backup.sql

# 2. Composer로 업데이트
docker-compose exec drupal composer update drupal/core-recommended --with-dependencies

# 3. 데이터베이스 업데이트
docker-compose exec drupal drush updatedb

# 4. 캐시 클리어
docker-compose exec drupal drush cache-rebuild
```

### Drupal 메이저 버전 업그레이드 (예: 9 → 10)

```bash
# 1. 전체 백업
# 2. 테스트 환경에서 먼저 테스트
# 3. 공식 업그레이드 가이드 참조
# https://www.drupal.org/docs/upgrading-drupal
```

## 트러블슈팅

### Composer "killed" 오류

메모리 부족 시:
```bash
docker-compose exec drupal sh -c "COMPOSER_MEMORY_LIMIT=-1 composer update"
```

### 파일 시스템 경로 오류

```bash
# sites/default/files 경로 확인
docker-compose exec drupal drush status --field=files

# 경로 수정 필요시
# Configuration > Media > File system
```

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
