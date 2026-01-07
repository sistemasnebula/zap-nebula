#!/bin/bash

# Script para iniciar stack de logging (Loki + Grafana)
# Uso: ./start-logging.sh [start|stop|restart|status|logs]

set -e

COMPOSE_FILE="docker-compose.logging.yml"

case "$1" in
    start)
        echo "🚀 Iniciando stack de logging..."
        docker-compose -f "$COMPOSE_FILE" up -d
        echo ""
        echo "✅ Stack iniciada!"
        echo ""
        echo "📊 Acesse:"
        echo "   - Grafana: http://localhost:3001 (admin/admin)"
        echo "   - Loki: http://localhost:3100"
        echo ""
        echo "📝 Para ver logs:"
        echo "   docker-compose -f $COMPOSE_FILE logs -f"
        ;;
    stop)
        echo "🛑 Parando stack de logging..."
        docker-compose -f "$COMPOSE_FILE" down
        echo "✅ Stack parada!"
        ;;
    restart)
        echo "🔄 Reiniciando stack de logging..."
        docker-compose -f "$COMPOSE_FILE" restart
        echo "✅ Stack reiniciada!"
        ;;
    status)
        echo "📊 Status da stack de logging:"
        echo ""
        docker-compose -f "$COMPOSE_FILE" ps
        echo ""
        echo "📈 Containers WhatsApp monitorados:"
        docker ps --filter "label=app=whatsapp-api" --format "table {{.Names}}\t{{.Status}}" | head -20
        ;;
    logs)
        docker-compose -f "$COMPOSE_FILE" logs -f "${2:-}"
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs} [serviço]"
        echo ""
        echo "Comandos:"
        echo "  start    - Inicia stack de logging"
        echo "  stop     - Para stack de logging"
        echo "  restart  - Reinicia stack de logging"
        echo "  status   - Mostra status da stack"
        echo "  logs     - Mostra logs (opcional: loki|grafana|promtail)"
        echo ""
        echo "Exemplos:"
        echo "  $0 start"
        echo "  $0 logs grafana"
        exit 1
        ;;
esac

