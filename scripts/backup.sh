#!/bin/bash

# 서비스 백업 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 사용법 출력
usage() {
    echo "사용법: $0 <서비스명> [옵션]"
    echo ""
    echo "옵션:"
    echo "  -f, --file <파일명>    특정 docker-compose 파일 지정"
    echo "  -o, --output <경로>    백업 파일 저장 경로 (기본: ./backups)"
    echo "  -d, --database-only    데이터베이스만 백업"
    echo "  -F, --files-only       파일만 백업"
    echo "  -h, --help             도움말 출력"
    echo ""
    echo "예제:"
    echo "  $0 wordpress"
    echo "  $0 nextcloud -f dc-pg.yml"
    echo "  $0 drupal -o /path/to/backups"
    echo "  $0 joomla --database-only"
    echo ""
    echo "지원 서비스:"
    echo "  - wordpress, joomla, drupal"
    echo "  - mediawiki, nextcloud, phabricator"
    echo ""
    exit 1
}

# --help 체크
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
fi

# 인자 확인
if [ $# -lt 1 ]; then
    usage
fi

SERVICE=$1
shift

# 옵션 파싱
COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="$PROJECT_ROOT/backups"
DB_ONLY=false
FILES_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -o|--output)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -d|--database-only)
            DB_ONLY=true
            shift
            ;;
        -F|--files-only)
            FILES_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}알 수 없는 옵션: $1${NC}"
            usage
            ;;
    esac
done

SERVICE_DIR="$PROJECT_ROOT/$SERVICE"

# 서비스 디렉토리 확인
if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}❌ 오류: '$SERVICE' 서비스를 찾을 수 없습니다.${NC}"
    exit 1
fi

# docker-compose 파일 확인
if [ ! -f "$SERVICE_DIR/$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ 오류: '$SERVICE_DIR/$COMPOSE_FILE' 파일을 찾을 수 없습니다.${NC}"
    exit 1
fi

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR/$SERVICE"

# 타임스탬프
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$SERVICE/${SERVICE}_${TIMESTAMP}"

echo -e "${BLUE}=========================================="
echo "  💾 서비스 백업: $SERVICE"
echo "==========================================${NC}"
echo ""
echo "서비스: $SERVICE"
echo "설정 파일: $COMPOSE_FILE"
echo "백업 경로: $BACKUP_PATH"
echo ""

# docker-compose 명령 확인
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo -e "${RED}❌ 오류: docker-compose 또는 docker compose를 찾을 수 없습니다.${NC}"
    exit 1
fi

cd "$SERVICE_DIR"

# 서비스별 백업 로직
backup_database() {
    local db_type=$1
    local container=$2
    local db_name=$3
    local db_user=$4
    local backup_file="${BACKUP_PATH}_database.sql"

    echo -e "${YELLOW}⏳ 데이터베이스 백업 중...${NC}"

    case $db_type in
        mariadb|mysql)
            $COMPOSE_CMD -f "$COMPOSE_FILE" exec -T $container mysqldump -u $db_user $db_name > "$backup_file"
            ;;
        postgres)
            $COMPOSE_CMD -f "$COMPOSE_FILE" exec -T $container pg_dump -U $db_user $db_name > "$backup_file"
            ;;
        *)
            echo -e "${RED}❌ 지원하지 않는 데이터베이스 타입: $db_type${NC}"
            return 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}✅ 데이터베이스 백업 완료: $backup_file ($size)${NC}"
    else
        echo -e "${RED}❌ 데이터베이스 백업 실패${NC}"
        return 1
    fi
}

backup_files() {
    local container=$1
    local path=$2
    local backup_file="${BACKUP_PATH}_files.tar.gz"

    echo -e "${YELLOW}⏳ 파일 백업 중...${NC}"

    $COMPOSE_CMD -f "$COMPOSE_FILE" exec -T $container tar czf - $path > "$backup_file" 2>/dev/null

    if [ $? -eq 0 ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}✅ 파일 백업 완료: $backup_file ($size)${NC}"
    else
        echo -e "${RED}❌ 파일 백업 실패${NC}"
        return 1
    fi
}

# 서비스별 백업 수행
case $SERVICE in
    wordpress)
        if [ "$FILES_ONLY" = false ]; then
            backup_database "mariadb" "db" "bitnami_wordpress" "bn_wordpress"
        fi
        if [ "$DB_ONLY" = false ]; then
            backup_files "wordpress" "/bitnami/wordpress"
        fi
        ;;

    joomla)
        if [ "$FILES_ONLY" = false ]; then
            backup_database "mariadb" "db" "bitnami_joomla" "bn_joomla"
        fi
        if [ "$DB_ONLY" = false ]; then
            backup_files "joomla" "/bitnami/joomla"
        fi
        ;;

    drupal)
        if [ "$FILES_ONLY" = false ]; then
            backup_database "mariadb" "db" "bitnami_drupal" "bn_drupal"
        fi
        if [ "$DB_ONLY" = false ]; then
            backup_files "drupal" "/bitnami/drupal"
        fi
        ;;

    mediawiki)
        if [ "$FILES_ONLY" = false ]; then
            backup_database "mariadb" "db" "bitnami_mediawiki" "bn_mediawiki"
        fi
        if [ "$DB_ONLY" = false ]; then
            backup_files "mediawiki" "/bitnami"
        fi
        ;;

    nextcloud)
        # PostgreSQL 또는 MariaDB 확인
        if [[ "$COMPOSE_FILE" == *"pg"* ]]; then
            if [ "$FILES_ONLY" = false ]; then
                backup_database "postgres" "db" "nextcloud" "nextcloud"
            fi
        else
            if [ "$FILES_ONLY" = false ]; then
                backup_database "mariadb" "mariadb" "nextcloud_db" "nextcloud"
            fi
        fi
        if [ "$DB_ONLY" = false ]; then
            backup_files "nextcloud" "/var/www/html/data"
            backup_files "nextcloud" "/var/www/html/config"
        fi
        ;;

    phabricator)
        if [ "$FILES_ONLY" = false ]; then
            backup_database "mariadb" "db" "bitnami_phabricator" "root"
        fi
        if [ "$DB_ONLY" = false ]; then
            backup_files "phabricator" "/bitnami"
        fi
        ;;

    *)
        echo -e "${RED}❌ 지원하지 않는 서비스: $SERVICE${NC}"
        echo ""
        echo "지원 서비스: wordpress, joomla, drupal, mediawiki, nextcloud, phabricator"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}=========================================="
echo "  ✅ 백업 완료!"
echo "==========================================${NC}"
echo ""
echo "백업 위치: $BACKUP_PATH*"
echo ""
echo "복원 방법:"
echo "  ./scripts/restore.sh $SERVICE -b $BACKUP_PATH"
echo ""
