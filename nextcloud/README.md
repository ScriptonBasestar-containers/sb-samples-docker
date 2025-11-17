# Nextcloud

Nextcloud는 오픈소스 파일 동기화 및 공유 솔루션입니다. 개인 클라우드 스토리지를 구축하여 파일, 캘린더, 연락처, 메일 등을 관리할 수 있습니다.

## 개요

- **공식 사이트**: https://nextcloud.com
- **Docker Hub**:
  - 공식: https://hub.docker.com/_/nextcloud
  - Linuxserver: https://hub.docker.com/r/linuxserver/nextcloud
- **기본 포트**: 8080
- **데이터베이스**: MariaDB 또는 PostgreSQL
- **캐시**: Redis (권장)

## 빠른 시작

### 기본 실행 방법 (PostgreSQL 권장)

```bash
# PostgreSQL 버전 사용 (권장)
cd nextcloud
docker-compose -f dc-pg.yml up -d

# 브라우저에서 접속
# http://localhost:8080
```

### MySQL/MariaDB 버전 사용

```bash
# MySQL 버전 (transaction isolation 이슈 있음)
docker-compose -f dc-my.yml up -d
```

⚠️ **주의**: MySQL/MariaDB 사용 시 transaction isolation 이슈가 있어 PostgreSQL 사용을 권장합니다.

### 헬퍼 스크립트 사용

```bash
# 프로젝트 루트에서
./scripts/start.sh nextcloud -f dc-pg.yml

# 중지
./scripts/stop.sh nextcloud -f dc-pg.yml

# 볼륨까지 삭제
./scripts/stop.sh nextcloud -f dc-pg.yml -v

# 백업 (데이터베이스 + 파일)
./scripts/backup.sh nextcloud -f dc-pg.yml

# 복원
./scripts/restore.sh nextcloud -f dc-pg.yml -b /path/to/backup
```

## 환경 변수

### PostgreSQL 버전 (dc-pg.yml)

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| POSTGRES_DB | nextcloud | 데이터베이스 이름 |
| POSTGRES_USER | nextcloud | DB 사용자 |
| POSTGRES_PASSWORD | password | DB 비밀번호 |
| NEXTCLOUD_ADMIN_USER | admin | 관리자 계정 |
| NEXTCLOUD_ADMIN_PASSWORD | password | 관리자 비밀번호 |
| REDIS_HOST | redis5 | Redis 호스트 |
| REDIS_HOST_PASSWORD | password | Redis 비밀번호 |

### MySQL/MariaDB 버전 (dc-my.yml)

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| MYSQL_DATABASE | nextcloud_db | 데이터베이스 이름 |
| MYSQL_USER | nextcloud | DB 사용자 |
| MYSQL_PASSWORD | password | DB 비밀번호 |
| MYSQL_ROOT_PASSWORD | password | DB 루트 비밀번호 |

## 볼륨

### 공식 이미지 (현재 사용 중)

- `db_data`: 데이터베이스 데이터
- `nextcloud-data`: 사용자 파일 데이터 (`/var/www/html/data`)
- `nextcloud-config`: Nextcloud 설정 (`/var/www/html/config`)
- `nextcloud-custom_apps`: 커스텀 앱 (`/var/www/html/custom_apps`)
- `nextcloud-apps`: 앱 (`/var/www/html/apps`)
- `nextcloud-themes`: 테마 (`/var/www/html/themes`)

**프로덕션 환경에서 중요한 볼륨**:
```
/var/www/html/data          # 사용자 파일 (가장 중요!)
/var/www/html/config        # 설정 파일
/var/www/html/custom_apps   # 커스텀 앱
```

### Linuxserver 이미지

```
/data                       # 사용자 데이터
/config                     # 설정
```

## 포트

| 포트 | 서비스 | 설명 |
|------|--------|------|
| 8080 | Nextcloud | 웹 인터페이스 |
| 5432 | PostgreSQL | 데이터베이스 (dc-pg.yml) |
| 3306 | MariaDB | 데이터베이스 (dc-my.yml) |
| 6379 | Redis | 캐시 (내부 사용) |

⚠️ **주의**: 여러 서비스를 동시 실행 시 포트 충돌 가능. `.env` 파일이나 docker-compose 파일에서 포트 변경 필요.

## 기본 접속 정보

- **URL**: http://localhost:8080
- **관리자 ID**: admin (설정 파일에서 지정)
- **관리자 비밀번호**: password (보안을 위해 변경 필요!)

## 사용 예제

### 백업

```bash
# PostgreSQL 데이터베이스 백업
docker-compose -f dc-pg.yml exec db pg_dump -U nextcloud nextcloud > backup.sql

# MySQL 데이터베이스 백업
docker-compose -f dc-my.yml exec mariadb mysqldump -u nextcloud -ppassword nextcloud_db > backup.sql

# 사용자 파일 백업
docker-compose -f dc-pg.yml exec nextcloud tar czf /tmp/data-backup.tar.gz /var/www/html/data
docker cp nextcloud_nextcloud_1:/tmp/data-backup.tar.gz ./nextcloud-data-backup.tar.gz

# 설정 백업
docker-compose -f dc-pg.yml exec nextcloud tar czf /tmp/config-backup.tar.gz /var/www/html/config
docker cp nextcloud_nextcloud_1:/tmp/config-backup.tar.gz ./nextcloud-config-backup.tar.gz
```

### 복원

```bash
# PostgreSQL 데이터베이스 복원
docker-compose -f dc-pg.yml exec -T db psql -U nextcloud nextcloud < backup.sql

# MySQL 데이터베이스 복원
docker-compose -f dc-my.yml exec -T mariadb mysql -u nextcloud -ppassword nextcloud_db < backup.sql

# 파일 복원
docker cp ./nextcloud-data-backup.tar.gz nextcloud_nextcloud_1:/tmp/
docker-compose -f dc-pg.yml exec nextcloud tar xzf /tmp/data-backup.tar.gz -C /
```

### OCC 명령어 사용

Nextcloud OCC는 강력한 CLI 도구입니다:

```bash
# 상태 확인
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ status

# 유지보수 모드
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ maintenance:mode --on
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ maintenance:mode --off

# 파일 스캔
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ files:scan --all

# 앱 목록
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ app:list

# 앱 활성화
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ app:enable calendar

# 사용자 생성
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ user:add --display-name="John Doe" john

# 캐시 클리어
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ maintenance:repair
```

### 로그 확인

```bash
# Docker 로그
docker-compose -f dc-pg.yml logs -f nextcloud

# Nextcloud 로그
docker-compose -f dc-pg.yml exec nextcloud tail -f /var/www/html/data/nextcloud.log
```

## 커스터마이징

### 포트 변경

`.env` 파일 생성:
```bash
NEXTCLOUD_PORT=8087
POSTGRES_PORT=5433
REDIS_PORT=6380
```

`dc-pg.yml` 수정:
```yaml
services:
  nextcloud:
    ports:
      - "${NEXTCLOUD_PORT:-8080}:80"
```

### 보안 강화 (프로덕션)

`dc-pg.yml`에서:
```yaml
environment:
  - POSTGRES_PASSWORD=your_very_secure_password
  - NEXTCLOUD_ADMIN_PASSWORD=admin_secure_password
  - REDIS_HOST_PASSWORD=redis_secure_password
```

### PHP 메모리 및 업로드 제한

```yaml
nextcloud:
  environment:
    - PHP_MEMORY_LIMIT=512M
    - PHP_UPLOAD_LIMIT=16G
```

또는 `config/config.php` 수정:
```php
'upload_max_filesize' => '16G',
'post_max_size' => '16G',
'memory_limit' => '512M',
```

### Trusted Domains 설정

```bash
# 도메인 추가
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ config:system:set trusted_domains 1 --value=yourdomain.com

# 확인
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ config:system:get trusted_domains
```

## 알려진 이슈

### 1. MySQL/MariaDB Transaction Isolation

**문제**: MySQL/MariaDB 사용 시 "General error: 1665 Cannot execute statement: impossible to write to binary log" 오류

**해결**: PostgreSQL 사용 권장 또는 MySQL 설정 수정
```yaml
mariadb:
  command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
```

### 2. 파일 업로드 크기 제한

**문제**: 대용량 파일 업로드 실패

**해결**:
```bash
# .htaccess 수정 또는 PHP 설정 변경
docker-compose -f dc-pg.yml exec nextcloud bash
vi /var/www/html/.user.ini

# 추가:
upload_max_filesize=16G
post_max_size=16G
```

### 3. Redis 연결 실패

**문제**: "Redis server went away" 오류

**해결**: `config/config.php`에서 Redis 설정 확인
```php
'memcache.distributed' => '\OC\Memcache\Redis',
'memcache.locking' => '\OC\Memcache\Redis',
'redis' => [
  'host' => 'redis5',
  'port' => 6379,
  'password' => 'password',
],
```

### 4. 퍼미션 문제

**문제**: "Data directory is not writable" 오류

**해결**:
```bash
docker-compose -f dc-pg.yml exec nextcloud chown -R www-data:www-data /var/www/html/data
docker-compose -f dc-pg.yml exec nextcloud chmod -R 750 /var/www/html/data
```

## Nextcloud 앱 추천

### 필수 앱

- **Calendar**: 캘린더 및 일정 관리
- **Contacts**: 연락처 관리
- **Tasks**: 할 일 목록
- **Notes**: 노트 작성
- **Talk**: 화상 회의 (별도 서버 권장)

### 생산성 앱

- **Deck**: 칸반 보드
- **Forms**: 설문조사
- **Polls**: 투표
- **Mail**: 이메일 클라이언트

### 미디어 앱

- **Photos**: 사진 관리
- **Music**: 음악 플레이어
- **Video Player**: 비디오 플레이어

### 보안 앱

- **Two-Factor TOTP**: 2단계 인증
- **Brute-force settings**: 무차별 대입 공격 방어
- **End-to-End Encryption**: 종단간 암호화

## 성능 최적화

### 1. Redis 캐시 활성화 (이미 설정됨)

Redis를 사용하면 성능이 크게 향상됩니다.

### 2. Cron 작업 설정

```bash
# Cron 모드로 변경 (기본은 AJAX)
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ background:cron

# Crontab 추가
docker-compose -f dc-pg.yml exec nextcloud crontab -u www-data -e
# 추가: */5 * * * * php -f /var/www/html/cron.php
```

### 3. 프리뷰 생성 최적화

`config/config.php`:
```php
'preview_max_x' => 2048,
'preview_max_y' => 2048,
'jpeg_quality' => 60,
'enable_previews' => true,
```

### 4. 데이터베이스 인덱스 추가

```bash
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ db:add-missing-indices
```

## 대안 설정

### Linuxserver 이미지 사용

```yaml
nextcloud:
  image: linuxserver/nextcloud
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=Asia/Seoul
  volumes:
    - /path/to/data:/data
    - /path/to/config:/config
```

장점:
- 간단한 볼륨 구조
- LinuxServer.io 커뮤니티 지원

단점:
- 공식 이미지 아님
- OCC 명령어 경로 다름

## 참고 링크

- **공식 문서**: https://docs.nextcloud.com/
- **공식 Docker 이미지**: https://github.com/nextcloud/docker
- **Nextcloud Apps**: https://apps.nextcloud.com/
- **Nextcloud Community**: https://help.nextcloud.com/
- **Admin Manual**: https://docs.nextcloud.com/server/latest/admin_manual/

## 프로덕션 체크리스트

프로덕션 환경 배포 전 확인사항:

- [ ] PostgreSQL 사용 (MySQL 대신)
- [ ] 모든 기본 비밀번호 변경
- [ ] HTTPS 설정 (리버스 프록시 필수)
- [ ] Trusted Domains 설정
- [ ] Redis 캐시 활성화 확인
- [ ] Cron 작업 설정
- [ ] 정기 백업 스크립트 설정
- [ ] 데이터 디렉토리 백업
- [ ] 업로드 크기 제한 설정
- [ ] 2단계 인증 활성화
- [ ] 보안 및 설정 경고 확인 (관리자 페이지)
- [ ] 이메일 서버 설정
- [ ] 외부 스토리지 설정 (선택사항)
- [ ] 데이터베이스 인덱스 추가
- [ ] 로그 로테이션 설정

## 버전 업그레이드

### 마이너 버전 업데이트

```bash
# 1. 백업
# 2. 유지보수 모드 활성화
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ maintenance:mode --on

# 3. 이미지 업데이트
docker-compose -f dc-pg.yml pull nextcloud
docker-compose -f dc-pg.yml up -d nextcloud

# 4. 업그레이드 실행
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ upgrade

# 5. 유지보수 모드 비활성화
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ maintenance:mode --off

# 6. 캐시 클리어
docker-compose -f dc-pg.yml exec -u www-data nextcloud php occ maintenance:repair
```

### 메이저 버전 업그레이드

메이저 버전 업그레이드는 단계별로 진행해야 합니다 (예: 25 → 26 → 27):
```bash
# 1. 전체 백업
# 2. 테스트 환경에서 먼저 테스트
# 3. 공식 업그레이드 가이드 참조
# https://docs.nextcloud.com/server/latest/admin_manual/maintenance/upgrade.html
```

## 데스크톱 및 모바일 클라이언트

- **Windows/Mac/Linux**: https://nextcloud.com/install/#install-clients
- **Android**: Google Play Store
- **iOS**: App Store

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
