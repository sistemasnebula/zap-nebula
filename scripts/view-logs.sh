#!/bin/bash

# Script para visualizar logs dos containers WhatsApp
# Uso: ./view-logs.sh [view|errors|search|list] [argumento]

set -e

view_logs() {
    local loja=$1
    
    if [ -z "$loja" ]; then
        echo "❌ Especifique o nome da loja"
        echo "Uso: $0 view <nome-loja>"
        exit 1
    fi
    
    # Buscar container por nome ou label
    local container_name=$(docker ps --filter "name=$loja" --filter "label=app=whatsapp-api" --format "{{.Names}}" | head -1)
    
    if [ -z "$container_name" ]; then
        # Tentar buscar por label loja
        container_name=$(docker ps --filter "label=loja=$loja" --format "{{.Names}}" | head -1)
    fi
    
    if [ -z "$container_name" ]; then
        echo "❌ Container não encontrado para: $loja"
        echo ""
        echo "Containers disponíveis:"
        docker ps --filter "label=app=whatsapp-api" --format "{{.Names}}" | head -10
        exit 1
    fi
    
    echo "📋 Logs de: $container_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker logs --tail 100 -f "$container_name"
}

view_errors() {
    echo "🔍 Buscando erros em todos os containers..."
    echo ""
    
    local count=0
    docker ps --filter "label=app=whatsapp-api" --format "{{.Names}}" | while read container; do
        errors=$(docker logs --tail 100 "$container" 2>&1 | grep -i "error" | tail -5)
        if [ ! -z "$errors" ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "❌ $container"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "$errors"
            echo ""
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo "✅ Nenhum erro encontrado nos últimos logs!"
    fi
}

search_logs() {
    local search_term=$1
    
    if [ -z "$search_term" ]; then
        echo "❌ Especifique o termo de busca"
        echo "Uso: $0 search <termo>"
        exit 1
    fi
    
    echo "🔍 Buscando '$search_term' em todos os containers..."
    echo ""
    
    local found=0
    docker ps --filter "label=app=whatsapp-api" --format "{{.Names}}" | while read container; do
        result=$(docker logs "$container" 2>&1 | grep -i "$search_term" | tail -5)
        if [ ! -z "$result" ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📦 $container"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "$result"
            echo ""
            found=1
        fi
    done
    
    if [ $found -eq 0 ]; then
        echo "❌ Nenhum resultado encontrado para: $search_term"
    fi
}

list_containers() {
    echo "📋 Containers WhatsApp disponíveis:"
    echo ""
    
    docker ps --filter "label=app=whatsapp-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
    
    local total=$(docker ps --filter "label=app=whatsapp-api" --format "{{.Names}}" | wc -l)
    echo ""
    echo "Total: $total containers"
}

case "$1" in
    view)
        view_logs "$2"
        ;;
    errors)
        view_errors
        ;;
    search)
        search_logs "$2"
        ;;
    list)
        list_containers
        ;;
    *)
        echo "Uso: $0 {view|errors|search|list} [argumento]"
        echo ""
        echo "Comandos:"
        echo "  view <loja>     - Ver logs de uma loja específica"
        echo "  errors          - Ver erros de todas as lojas"
        echo "  search <termo>  - Buscar termo em todos os containers"
        echo "  list            - Listar todos os containers"
        echo ""
        echo "Exemplos:"
        echo "  $0 view pizzariaromanelli"
        echo "  $0 errors"
        echo "  $0 search 'webhook failed'"
        echo "  $0 list"
        exit 1
        ;;
esac

