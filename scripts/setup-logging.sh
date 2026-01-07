#!/bin/bash

# Script para configurar sistema de logging (Loki + Grafana)
# Uso: ./setup-logging.sh [install|start|stop|status]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOGGING_DIR="$PROJECT_ROOT/logging-stack"

install() {
    echo "📦 Instalando stack de logging (Loki + Grafana)..."
    
    mkdir -p "$LOGGING_DIR"
    cd "$LOGGING_DIR"
    
    # Criar docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - loki-data:/loki
    networks:
      - logging
    restart: unless-stopped

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./promtail-config.yml:/etc/promtail/config.yml:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - logging
    depends_on:
      - loki
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - logging
    depends_on:
      - loki
    restart: unless-stopped

volumes:
  loki-data:
  grafana-data:

networks:
  logging:
    driver: bridge
EOF

    # Criar promtail-config.yml
    cat > promtail-config.yml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
        filters:
          - name: label
            values: ["app=whatsapp-api"]
    
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container_name'
      
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'stream'
      
      - source_labels: ['__meta_docker_container_label_loja']
        target_label: 'loja'
      
      - source_labels: ['__meta_docker_container_label_loja_id']
        target_label: 'loja_id'
      
      - source_labels: ['__meta_docker_container_label_app']
        target_label: 'app'
    
    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            attrs: attrs
      
      - labels:
          stream:
          container_name:
          loja:
          loja_id:
          app:
      
      - output:
          source: output
EOF

    echo "✅ Arquivos de configuração criados em: $LOGGING_DIR"
    echo ""
    echo "📝 Próximos passos:"
    echo "   1. Execute: $0 start"
    echo "   2. Acesse Grafana: http://localhost:3001 (admin/admin)"
    echo "   3. Adicione Loki como data source: http://loki:3100"
}

start() {
    echo "🚀 Iniciando stack de logging..."
    
    if [ ! -f "$LOGGING_DIR/docker-compose.yml" ]; then
        echo "❌ Stack não instalada. Execute: $0 install"
        exit 1
    fi
    
    cd "$LOGGING_DIR"
    docker-compose up -d
    
    echo ""
    echo "✅ Stack iniciada!"
    echo ""
    echo "📊 Acesse:"
    echo "   - Grafana: http://localhost:3001 (admin/admin)"
    echo "   - Loki: http://localhost:3100"
    echo ""
    echo "📝 Para ver logs:"
    echo "   docker-compose -f $LOGGING_DIR/docker-compose.yml logs -f"
}

stop() {
    echo "🛑 Parando stack de logging..."
    
    if [ ! -f "$LOGGING_DIR/docker-compose.yml" ]; then
        echo "❌ Stack não encontrada."
        exit 1
    fi
    
    cd "$LOGGING_DIR"
    docker-compose down
    
    echo "✅ Stack parada!"
}

status() {
    echo "📊 Status da stack de logging:"
    echo ""
    
    if [ ! -f "$LOGGING_DIR/docker-compose.yml" ]; then
        echo "❌ Stack não instalada."
        exit 1
    fi
    
    cd "$LOGGING_DIR"
    docker-compose ps
    
    echo ""
    echo "📈 Containers WhatsApp monitorados:"
    docker ps --filter "label=app=whatsapp-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
}

case "$1" in
    install)
        install
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    *)
        echo "Uso: $0 {install|start|stop|status}"
        echo ""
        echo "Comandos:"
        echo "  install  - Instala stack de logging (Loki + Grafana)"
        echo "  start    - Inicia stack de logging"
        echo "  stop     - Para stack de logging"
        echo "  status   - Mostra status da stack"
        exit 1
        ;;
esac

