# WordPress

WordPress는 세계에서 가장 인기 있는 콘텐츠 관리 시스템(CMS)이자 블로그 플랫폼입니다. 전 세계 웹사이트의 40% 이상이 WordPress로 구동됩니다.

## 개요

- **공식 사이트**: https://wordpress.org
- **Docker Hub**:
  - 공식: https://hub.docker.com/_/wordpress
  - Bitnami: https://hub.docker.com/r/bitnami/wordpress
- **기본 포트**: 8080
- **데이터베이스**: MariaDB 10

## 빠른 시작

### 기본 실행 방법

```bash
# 서비스 시작
cd wordpress
docker-compose up -d

# 브라우저에서 접속
# http://localhost:8080
```

### 헬퍼 스크립트 사용

```bash
# 프로젝트 루트에서
./scripts/start.sh wordpress

# 중지
./scripts/stop.sh wordpress

# 볼륨까지 삭제
./scripts/stop.sh wordpress -v

# 백업 (데이터베이스 + 파일)
./scripts/backup.sh wordpress

# 복원
./scripts/restore.sh wordpress -b /path/to/backup
```

## 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| MARIADB_HOST | db | 데이터베이스 호스트 |
| MARIADB_PORT_NUMBER | 3306 | 데이터베이스 포트 |
| WORDPRESS_DATABASE_USER | bn_wordpress | DB 사용자 |
| WORDPRESS_DATABASE_NAME | bitnami_wordpress | DB 이름 |
| ALLOW_EMPTY_PASSWORD | yes | 빈 비밀번호 허용 (개발용) |

## 볼륨

### Bitnami 이미지 (현재 사용 중)

- `db_data`: MariaDB 데이터베이스 데이터 (`/bitnami/mariadb`)
- `web_data`: WordPress 애플리케이션 데이터 (`/bitnami/wordpress`)

**프로덕션 환경에서 권장하는 세부 볼륨**:
```
/bitnami/wordpress/wp-content/plugins    # 플러그인
/bitnami/wordpress/wp-content/themes     # 테마
/bitnami/wordpress/wp-content/uploads    # 업로드 파일
/bitnami/wordpress/wp-config.php         # 설정 파일
```

### 공식 이미지

```
/var/www/html/wp-content                 # 컨텐츠 디렉토리
```

## 포트

| 포트 | 서비스 | 설명 |
|------|--------|------|
| 8080 | WordPress | 웹 인터페이스 |
| 3306 | MariaDB | 데이터베이스 (외부 노출) |

⚠️ **주의**: 여러 서비스를 동시 실행 시 포트 충돌 가능. `.env` 파일이나 `docker-compose.yml`에서 포트 변경 필요.

## 기본 접속 정보

- **URL**: http://localhost:8080
- **관리자 페이지**: http://localhost:8080/wp-admin
- **초기 설정**: 첫 접속 시 설치 마법사 실행

**기본 계정** (Bitnami 이미지):
- **사용자명**: user
- **비밀번호**: bitnami

## 사용 예제

### 백업

```bash
# 데이터베이스 백업
docker-compose exec db mysqldump -u bn_wordpress bitnami_wordpress > backup.sql

# 파일 백업
docker-compose exec wordpress tar czf /tmp/wp-content.tar.gz /bitnami/wordpress/wp-content
docker cp wordpress_wordpress_1:/tmp/wp-content.tar.gz ./wp-content-backup.tar.gz
```

### 복원

```bash
# 데이터베이스 복원
docker-compose exec -T db mysql -u bn_wordpress bitnami_wordpress < backup.sql

# 파일 복원
docker cp ./wp-content-backup.tar.gz wordpress_wordpress_1:/tmp/
docker-compose exec wordpress tar xzf /tmp/wp-content.tar.gz -C /
```

### 로그 확인

```bash
# 전체 로그
docker-compose logs -f

# WordPress만
docker-compose logs -f wordpress

# 최근 100줄
docker-compose logs --tail=100 wordpress
```

## 커스터마이징

### 포트 변경

`.env` 파일 생성:
```bash
WORDPRESS_PORT=8081
MARIADB_PORT=3307
```

`docker-compose.yml` 수정:
```yaml
services:
  wordpress:
    ports:
      - "${WORDPRESS_PORT:-8080}:8080"
```

### 보안 강화 (프로덕션)

`docker-compose.yml`에서:
```yaml
environment:
  - MARIADB_PASSWORD=secure_password_here
  - WORDPRESS_PASSWORD=admin_password_here
  # ALLOW_EMPTY_PASSWORD 제거
```

### PHP 메모리 제한 증가

```yaml
wordpress:
  environment:
    - PHP_MEMORY_LIMIT=512M
```

## 알려진 이슈

### 1. 초기화 스크립트 충돌

**문제**: Bitnami 이미지는 컨테이너 재시작 시 초기화 스크립트가 실행될 수 있음

**해결**:
- 볼륨을 올바르게 마운트하여 데이터 유지
- 백업 후 복원 시 초기화 스크립트 비활성화 옵션 사용

### 2. 퍼미션 문제

**문제**: 플러그인/테마 업로드 시 권한 오류

**해결**:
```bash
docker-compose exec wordpress chown -R www-data:www-data /bitnami/wordpress/wp-content
```

### 3. HTTPS 리다이렉트

**문제**: 프록시 뒤에서 무한 리다이렉트 발생

**해결**: `wp-config.php`에 추가:
```php
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
```

## 대안 설정

### 공식 WordPress 이미지 사용

`docker-compose.yml`의 주석 처리된 부분을 참조하세요.

장점:
- 더 가벼운 이미지
- 공식 지원

단점:
- 초기 설정이 더 복잡
- 환경 변수 옵션이 제한적

## 참고 링크

- **공식 문서**: https://wordpress.org/support/
- **Bitnami WordPress**: https://github.com/bitnami/bitnami-docker-wordpress
- **공식 Docker 이미지**: https://github.com/docker-library/wordpress
- **WordPress Codex**: https://codex.wordpress.org/

## 프로덕션 체크리스트

프로덕션 환경 배포 전 확인사항:

- [ ] 모든 기본 비밀번호 변경
- [ ] `ALLOW_EMPTY_PASSWORD` 제거
- [ ] HTTPS 설정 (리버스 프록시)
- [ ] 정기 백업 스크립트 설정
- [ ] 볼륨 범위를 필요한 디렉토리로 축소
- [ ] PHP 메모리 및 업로드 제한 설정
- [ ] 데이터베이스 포트 외부 노출 제거
- [ ] 보안 플러그인 설치 (Wordfence 등)
- [ ] 자동 업데이트 설정

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
