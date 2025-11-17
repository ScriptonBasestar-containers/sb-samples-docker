#!/bin/bash

# 서비스 시작 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 사용법 출력
usage() {
    echo "사용법: $0 <서비스명> [옵션]"
    echo ""
    echo "옵션:"
    echo "  -f, --file <파일명>  특정 docker-compose 파일 지정"
    echo "  -d, --detach         백그라운드로 실행 (기본값)"
    echo "  -l, --logs           로그 출력 모드로 실행"
    echo "  -h, --help           도움말 출력"
    echo ""
    echo "예제:"
    echo "  $0 wordpress"
    echo "  $0 nextcloud -f dc-pg.yml"
    echo "  $0 redis -f dc-bitnami-single.yml"
    echo ""
    echo "사용 가능한 서비스 목록을 보려면:"
    echo "  ./scripts/list.sh"
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
DETACH_MODE="-d"
SHOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -d|--detach)
            DETACH_MODE="-d"
            shift
            ;;
        -l|--logs)
            SHOW_LOGS=true
            DETACH_MODE=""
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
    echo ""
    echo "사용 가능한 서비스 목록:"
    ./scripts/list.sh
    exit 1
fi

# docker-compose 파일 확인
if [ ! -f "$SERVICE_DIR/$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ 오류: '$SERVICE_DIR/$COMPOSE_FILE' 파일을 찾을 수 없습니다.${NC}"
    echo ""
    echo "사용 가능한 파일:"
    ls -1 "$SERVICE_DIR"/*.yml 2>/dev/null || echo "  (docker-compose 파일 없음)"
    exit 1
fi

echo -e "${GREEN}=========================================="
echo "  🚀 서비스 시작: $SERVICE"
echo "==========================================${NC}"
echo ""
echo "디렉토리: $SERVICE_DIR"
echo "설정 파일: $COMPOSE_FILE"
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

# 서비스 시작
cd "$SERVICE_DIR"

echo -e "${YELLOW}⏳ 서비스를 시작하고 있습니다...${NC}"
echo ""

if $SHOW_LOGS; then
    $COMPOSE_CMD -f "$COMPOSE_FILE" up
else
    $COMPOSE_CMD -f "$COMPOSE_FILE" up $DETACH_MODE

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ 서비스가 성공적으로 시작되었습니다!${NC}"
        echo ""
        echo "상태 확인:"
        $COMPOSE_CMD -f "$COMPOSE_FILE" ps
        echo ""
        echo "로그 확인:"
        echo "  cd $SERVICE && $COMPOSE_CMD -f $COMPOSE_FILE logs -f"
        echo ""
        echo "서비스 중지:"
        echo "  ./scripts/stop.sh $SERVICE"
    else
        echo -e "${RED}❌ 서비스 시작 중 오류가 발생했습니다.${NC}"
        exit 1
    fi
fi
