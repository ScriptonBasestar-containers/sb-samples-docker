#!/bin/bash

# 서비스 복원 스크립트

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
    echo "  -f, --file <파일명>      특정 docker-compose 파일 지정"
    echo "  -b, --backup <경로>      백업 파일 경로 (확장자 제외)"
    echo "  -d, --database-only      데이터베이스만 복원"
    echo "  -F, --files-only         파일만 복원"
    echo "  -h, --help               도움말 출력"
    echo ""
    echo "예제:"
    echo "  $0 wordpress -b ./backups/wordpress/wordpress_20240117_120000"
    echo "  $0 nextcloud -f dc-pg.yml -b ./backups/nextcloud/nextcloud_20240117_120000"
    echo "  $0 drupal --database-only -b ./backups/drupal/drupal_20240117_120000"
    echo ""
    echo "주의:"
    echo "  - 복원 전 현재 데이터가 덮어씌워집니다!"
    echo "  - 복원 전 현재 상태를 백업하는 것을 권장합니다."
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
BACKUP_PATH=""
DB_ONLY=false
FILES_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -b|--backup)
            BACKUP_PATH="$2"
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

# 백업 경로 확인
if [ -z "$BACKUP_PATH" ]; then
    echo -e "${RED}❌ 오류: 백업 파일 경로를 지정해야 합니다. (-b 옵션)${NC}"
    usage
fi

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

echo -e "${BLUE}=========================================="
echo "  🔄 서비스 복원: $SERVICE"
echo "==========================================${NC}"
echo ""
echo "서비스: $SERVICE"
echo "설정 파일: $COMPOSE_FILE"
echo "백업 경로: $BACKUP_PATH"
echo ""
echo -e "${RED}⚠️  경고: 복원하면 현재 데이터가 덮어씌워집니다!${NC}"
echo ""
read -p "계속하시겠습니까? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy]([Ee][Ss])?$ ]]; then
    echo "복원이 취소되었습니다."
    exit 0
fi
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

# 서비스별 복원 로직
restore_database() {
    local db_type=$1
    local container=$2
    local db_name=$3
    local db_user=$4
    local backup_file="${BACKUP_PATH}_database.sql"

    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}❌ 데이터베이스 백업 파일을 찾을 수 없습니다: $backup_file${NC}"
        return 1
    fi

    echo -e "${YELLOW}⏳ 데이터베이스 복원 중...${NC}"

    case $db_type in
        mariadb|mysql)
            cat "$backup_file" | $COMPOSE_CMD -f "$COMPOSE_FILE" exec -T $container mysql -u $db_user $db_name
            ;;
        postgres)
            cat "$backup_file" | $COMPOSE_CMD -f "$COMPOSE_FILE" exec -T $container psql -U $db_user $db_name
            ;;
        *)
            echo -e "${RED}❌ 지원하지 않는 데이터베이스 타입: $db_type${NC}"
            return 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 데이터베이스 복원 완료${NC}"
    else
        echo -e "${RED}❌ 데이터베이스 복원 실패${NC}"
        return 1
    fi
}

restore_files() {
    local container=$1
    local path=$2
    local backup_file="${BACKUP_PATH}_files.tar.gz"

    if [ ! -f "$backup_file" ]; then
        echo -e "${YELLOW}⚠️  파일 백업을 찾을 수 없습니다: $backup_file${NC}"
        echo -e "${YELLOW}   파일 복원을 건너뜁니다.${NC}"
        return 0
    fi

    echo -e "${YELLOW}⏳ 파일 복원 중...${NC}"

    # 백업 파일을 컨테이너로 복사
    cat "$backup_file" | $COMPOSE_CMD -f "$COMPOSE_FILE" exec -T $container tar xzf - -C /

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 파일 복원 완료${NC}"
    else
        echo -e "${RED}❌ 파일 복원 실패${NC}"
        return 1
    fi
}

# 서비스별 복원 수행
case $SERVICE in
    wordpress)
        if [ "$FILES_ONLY" = false ]; then
            restore_database "mariadb" "db" "bitnami_wordpress" "bn_wordpress"
        fi
        if [ "$DB_ONLY" = false ]; then
            restore_files "wordpress" "/bitnami/wordpress"
        fi
        ;;

    joomla)
        if [ "$FILES_ONLY" = false ]; then
            restore_database "mariadb" "db" "bitnami_joomla" "bn_joomla"
        fi
        if [ "$DB_ONLY" = false ]; then
            restore_files "joomla" "/bitnami/joomla"
        fi
        ;;

    drupal)
        if [ "$FILES_ONLY" = false ]; then
            restore_database "mariadb" "db" "bitnami_drupal" "bn_drupal"
        fi
        if [ "$DB_ONLY" = false ]; then
            restore_files "drupal" "/bitnami/drupal"
        fi
        ;;

    mediawiki)
        if [ "$FILES_ONLY" = false ]; then
            restore_database "mariadb" "db" "bitnami_mediawiki" "bn_mediawiki"
        fi
        if [ "$DB_ONLY" = false ]; then
            restore_files "mediawiki" "/bitnami"
        fi
        ;;

    nextcloud)
        # PostgreSQL 또는 MariaDB 확인
        if [[ "$COMPOSE_FILE" == *"pg"* ]]; then
            if [ "$FILES_ONLY" = false ]; then
                restore_database "postgres" "db" "nextcloud" "nextcloud"
            fi
        else
            if [ "$FILES_ONLY" = false ]; then
                restore_database "mariadb" "mariadb" "nextcloud_db" "nextcloud"
            fi
        fi
        if [ "$DB_ONLY" = false ]; then
            restore_files "nextcloud" "/var/www/html"
        fi
        ;;

    phabricator)
        if [ "$FILES_ONLY" = false ]; then
            restore_database "mariadb" "db" "bitnami_phabricator" "root"
        fi
        if [ "$DB_ONLY" = false ]; then
            restore_files "phabricator" "/bitnami"
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
echo "  ✅ 복원 완료!"
echo "==========================================${NC}"
echo ""
echo "복원된 백업: $BACKUP_PATH"
echo ""
echo "서비스를 다시 시작하세요:"
echo "  $COMPOSE_CMD -f $COMPOSE_FILE restart"
echo ""
