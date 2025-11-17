# Phabricator

Phabricator는 강력한 오픈소스 소프트웨어 개발 협업 플랫폼입니다. 코드 리뷰, 저장소 호스팅, 버그 추적, 프로젝트 관리 등을 통합 제공합니다.

## 개요

- **공식 사이트**: https://www.phacility.com/phabricator/
- **Docker Hub**: https://hub.docker.com/r/bitnami/phabricator
- **GitHub**: https://github.com/bitnami/bitnami-docker-phabricator
- **기본 포트**: 8080
- **데이터베이스**: MariaDB 10 (다중 스키마 사용)

## ⚠️ 중요 사항

### 다중 데이터베이스 스키마

Phabricator는 **수십 개의 MySQL 스키마를 생성**합니다. 각 애플리케이션(Differential, Maniphest, Diffusion 등)마다 별도의 데이터베이스를 사용하므로:

- 전용 MariaDB 인스턴스 사용 권장
- 다른 애플리케이션과 DB 공유 지양
- 충분한 디스크 공간 확보 필요

### Bitnami 이미지 이슈

1. **스키마 접두사 문제**: Bitnami 이미지는 `bitnami_` 접두사를 자동으로 추가하는데, 이를 제거하려면 수동 설정 필요
2. **HTTPS 강제 리다이렉트**: 기본적으로 HTTPS로 리다이렉트되므로 HTTP 사용 시 설정 수정 필요
3. **초기화 스크립트**: `entry1.sh`를 통한 추가 설정 필요

## 빠른 시작

```bash
# 서비스 시작
cd phabricator
docker-compose up -d

# 초기 설정 대기 (2-5분 소요)
docker-compose logs -f phabricator

# 브라우저에서 접속
# http://localhost:8080
```

### 헬퍼 스크립트 사용

```bash
./scripts/start.sh phabricator
./scripts/stop.sh phabricator
./scripts/backup.sh phabricator
```

## 환경 변수

### 데이터베이스 설정

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| MARIADB_HOST | db | 데이터베이스 호스트 |
| MARIADB_PORT_NUMBER | 3306 | 데이터베이스 포트 |
| MARIADB_USER | root | DB 사용자 (root 권장) |
| MARIADB_PASSWORD | password | DB 비밀번호 |
| MARIADB_ROOT_PASSWORD | password | DB 루트 비밀번호 |

### Phabricator 설정

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| PHABRICATOR_HOST | 127.0.0.1 | 서버 호스트 |
| PHABRICATOR_USERNAME | user | 관리자 사용자명 |
| PHABRICATOR_PASSWORD | bitnami1 | 관리자 비밀번호 |
| PHABRICATOR_EMAIL | user@example.com | 관리자 이메일 |
| PHABRICATOR_FIRSTNAME | FirstName | 이름 |
| PHABRICATOR_LASTNAME | LastName | 성 |
| PHP_MEMORY_LIMIT | 256M | PHP 메모리 제한 |

### 고급 설정

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| PHABRICATOR_USE_LFS | yes | Git LFS 사용 여부 |
| PHABRICATOR_SSH_PORT_NUMBER | 22 | SSH 포트 |
| PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY | no | Git SSH 저장소 활성화 |

## 볼륨

- `db_data`: MariaDB 데이터베이스 데이터
- `web_data`: Phabricator 애플리케이션 데이터 (`/bitnami`)

**중요 경로**:
```
/bitnami/phabricator/conf/local/local.json  # 로컬 설정 파일
/bitnami/phabricator/repo                   # Git 저장소
/bitnami/phabricator/data                   # 파일 저장소
/opt/bitnami/phabricator/tmp/phd/log        # PHD 데몬 로그
```

## 기본 접속 정보

- **URL**: http://localhost:8080
- **관리자 ID**: user
- **관리자 비밀번호**: bitnami1 (보안을 위해 즉시 변경!)

## 사용 예제

### 백업

```bash
# 데이터베이스 백업 (모든 스키마)
docker-compose exec db sh -c 'mysqldump -u root -ppassword --all-databases' > backup-all.sql

# 또는 Phabricator 데이터베이스만
docker-compose exec db sh -c 'mysqldump -u root -ppassword --databases $(mysql -u root -ppassword -e "SHOW DATABASES" | grep phabricator)' > backup-phabricator.sql

# 저장소 및 파일 백업
docker-compose exec phabricator tar czf /tmp/phabricator-data.tar.gz /bitnami/phabricator/repo /bitnami/phabricator/data
docker cp phabricator_phabricator_1:/tmp/phabricator-data.tar.gz ./phabricator-backup.tar.gz

# 또는 자동화 스크립트 사용
./scripts/backup.sh phabricator
```

### 복원

```bash
# 데이터베이스 복원
docker-compose exec -T db mysql -u root -ppassword < backup-all.sql

# 파일 복원
docker cp ./phabricator-backup.tar.gz phabricator_phabricator_1:/tmp/
docker-compose exec phabricator tar xzf /tmp/phabricator-data.tar.gz -C /
```

### 로그 확인

```bash
# Docker 로그
docker-compose logs -f phabricator

# PHD 데몬 로그
docker-compose exec phabricator tail -f /opt/bitnami/phabricator/tmp/phd/log/daemons.log

# Apache 로그
docker-compose exec phabricator tail -f /opt/bitnami/apache/logs/access_log
docker-compose exec phabricator tail -f /opt/bitnami/apache/logs/error_log
```

## Phabricator 관리

### CLI 도구 (bin/)

Phabricator는 강력한 CLI 도구를 제공합니다:

```bash
# 컨테이너 접속
docker-compose exec phabricator bash

# 설정 확인
/opt/bitnami/phabricator/bin/config get phabricator.base-uri

# 설정 변경
/opt/bitnami/phabricator/bin/config set phabricator.base-uri "https://yourdomain.com"

# 데이터베이스 업그레이드
/opt/bitnami/phabricator/bin/storage upgrade

# PHD 데몬 상태 확인
/opt/bitnami/phabricator/bin/phd status

# PHD 데몬 재시작
/opt/bitnami/phabricator/bin/phd restart

# 사용자 관리
/opt/bitnami/phabricator/bin/accountadmin
```

### 저장소 설정

Phabricator는 Git, SVN, Mercurial 저장소를 호스팅할 수 있습니다:

```bash
# Diffusion 앱에서 저장소 생성
# Web UI: http://localhost:8080/diffusion/

# 저장소 정보 확인
/opt/bitnami/phabricator/bin/repository list

# 저장소 인덱싱
/opt/bitnami/phabricator/bin/repository update <callsign>
```

### 이메일 설정

```bash
# SMTP 설정
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config set phpmailer.smtp-host smtp.gmail.com
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config set phpmailer.smtp-port 587
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config set phpmailer.smtp-protocol TLS
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config set phpmailer.smtp-user your-email@gmail.com
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config set phpmailer.smtp-password your-password

# 테스트 이메일 발송
docker-compose exec phabricator /opt/bitnami/phabricator/bin/mail list-outbound
```

## 커스터마이징

### Bitnami 접두사 제거

`/opt/bitnami/phabricator/conf/local/local.json` 파일 수정:

```json
{
  "storage.default-namespace": "",
  "mysql.user": "root",
  "mysql.pass": "password",
  "mysql.port": "3306",
  "mysql.host": "db"
}
```

또는 `entry1.sh` 스크립트 사용 (이미 포함됨):
```bash
# docker-compose.yml의 volumes 섹션
volumes:
  - ./entry1.sh:/post-init.d/entry1.sh
```

### HTTP 사용 (HTTPS 리다이렉트 비활성화)

`entry1.sh`에서:
```bash
#!/bin/bash
/opt/bitnami/phabricator/bin/config set phabricator.base-uri "http://localhost:8080"
```

### 포트 변경

`.env` 파일:
```bash
PHABRICATOR_PORT=8081
```

`docker-compose.yml`:
```yaml
ports:
  - "${PHABRICATOR_PORT:-8080}:80"
```

## 알려진 이슈

### 1. Bitnami 스키마 접두사

**문제**: 모든 데이터베이스에 `bitnami_` 접두사 추가됨

**해결**: `entry1.sh` 스크립트로 `storage.default-namespace` 제거
```bash
/opt/bitnami/phabricator/bin/config set storage.default-namespace ""
```

### 2. HTTPS 강제 리다이렉트

**문제**: HTTP 접속 시 HTTPS로 자동 리다이렉트

**해결**: Base URI를 HTTP로 설정
```bash
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config set phabricator.base-uri "http://localhost:8080"
```

### 3. PHD 데몬 중지

**문제**: 백그라운드 작업이 실행되지 않음

**해결**: PHD 데몬 재시작
```bash
docker-compose exec phabricator /opt/bitnami/phabricator/bin/phd restart
```

### 4. 데이터베이스 연결 오류

**문제**: "Can't connect to MySQL server" 오류

**해결**:
```bash
# DB 컨테이너 상태 확인
docker-compose ps db

# DB 재시작
docker-compose restart db phabricator
```

### 5. 파일 업로드 크기 제한

**문제**: 대용량 파일 업로드 실패

**해결**:
```bash
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config set storage.mysql-engine.max-size 0
```

## Phabricator 애플리케이션

### 주요 앱

- **Differential**: 코드 리뷰
- **Diffusion**: Git/SVN/Mercurial 저장소 호스팅
- **Maniphest**: 이슈 및 태스크 관리
- **Phriction**: 위키
- **Ponder**: Q&A 플랫폼
- **Projects**: 프로젝트 관리
- **Herald**: 자동화 규칙
- **Harbormaster**: CI/CD

### 앱 활성화/비활성화

```bash
# 사용 가능한 앱 목록
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config get phabricator.show-beta-applications

# 웹 UI에서: Config > Applications
```

## 성능 최적화

### 1. OPcache 설정

이미 Bitnami 이미지에 포함되어 있습니다.

### 2. APCu 캐시

```bash
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config set phabricator.cache-namespace "phabricator-cache"
```

### 3. 검색 인덱스

```bash
# 검색 인덱스 재구축
docker-compose exec phabricator /opt/bitnami/phabricator/bin/search index --all
```

### 4. 저장소 미러링

대용량 저장소는 미러링 설정으로 성능 향상

## 보안 설정

### 1. 비밀번호 변경

```bash
# 관리자 비밀번호 변경
docker-compose exec phabricator /opt/bitnami/phabricator/bin/auth recover <username>
```

### 2. 2FA 활성화

웹 UI: Settings > Multi-Factor Auth

### 3. API 토큰 관리

웹 UI: Settings > Conduit API Tokens

## 참고 링크

- **공식 문서**: https://secure.phabricator.com/book/phabricator/
- **Bitnami Phabricator**: https://github.com/bitnami/bitnami-docker-phabricator
- **User Guide**: https://secure.phabricator.com/book/phabricator/article/
- **Configuration Guide**: https://secure.phabricator.com/book/phabricator/article/configuration_guide/

## 프로덕션 체크리스트

- [ ] 모든 기본 비밀번호 변경
- [ ] HTTPS 설정 (리버스 프록시)
- [ ] phabricator.base-uri 설정
- [ ] SMTP 이메일 서버 설정
- [ ] 정기 백업 스크립트 설정 (모든 DB 스키마 포함)
- [ ] PHD 데몬 상태 모니터링
- [ ] 데이터베이스 포트 외부 노출 제거
- [ ] 파일 저장소 백업 설정
- [ ] 2단계 인증 활성화
- [ ] API 접근 제어 설정
- [ ] 로그 로테이션 설정
- [ ] Bitnami 스키마 접두사 제거 확인

## 업그레이드

### Phabricator 버전 업그레이드

```bash
# 1. 전체 백업
./scripts/backup.sh phabricator

# 2. 최신 이미지 가져오기
docker-compose pull

# 3. 컨테이너 재시작
docker-compose up -d

# 4. 데이터베이스 스키마 업그레이드
docker-compose exec phabricator /opt/bitnami/phabricator/bin/storage upgrade --force

# 5. PHD 데몬 재시작
docker-compose exec phabricator /opt/bitnami/phabricator/bin/phd restart
```

## 트러블슈팅

### 데이터베이스 스키마 복구

```bash
# 스키마 상태 확인
docker-compose exec phabricator /opt/bitnami/phabricator/bin/storage status

# 누락된 스키마 생성
docker-compose exec phabricator /opt/bitnami/phabricator/bin/storage upgrade
```

### PHD 데몬 디버깅

```bash
# PHD 로그 확인
docker-compose exec phabricator tail -f /opt/bitnami/phabricator/tmp/phd/log/daemons.log

# PHD 재시작
docker-compose exec phabricator /opt/bitnami/phabricator/bin/phd stop
docker-compose exec phabricator /opt/bitnami/phabricator/bin/phd start
```

### 설정 초기화

```bash
# 설정 파일 확인
docker-compose exec phabricator cat /opt/bitnami/phabricator/conf/local/local.json

# 설정 삭제 (주의!)
docker-compose exec phabricator /opt/bitnami/phabricator/bin/config delete <key>
```

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
