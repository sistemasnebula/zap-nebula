#!/bin/bash

# Script para build e execução do Zap Nebula
# Autor: Assistente de Análise de Código
# Data: Julho 2025

set -e  # Para o script se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir mensagens coloridas
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Zap Nebula - Build & Run${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  --build-only     Apenas faz o build da imagem"
    echo "  --run-only       Apenas executa o container (assume que já foi buildado)"
    echo "  --clean          Remove containers e imagens antigas"
    echo "  --logs           Mostra logs do container"
    echo "  --stop           Para o container"
    echo "  --help           Exibe esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0               # Build e executa"
    echo "  $0 --build-only  # Apenas build"
    echo "  $0 --run-only    # Apenas executa"
    echo "  $0 --clean       # Limpa tudo"
}

# Função para verificar se Docker está rodando
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker não está rodando. Inicie o Docker e tente novamente."
        exit 1
    fi
}

# Função para limpar containers e imagens antigas
cleanup() {
    print_message "Limpando containers e imagens antigas..."
    
    # Para e remove containers
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Remove imagens antigas
    docker rmi $(docker images -q zap-nebula_whatsapp 2>/dev/null) 2>/dev/null || true
    
    print_message "Limpeza concluída!"
}

# Função para build da imagem
build_image() {
    print_message "Iniciando build da imagem..."
    
    # Verifica se o Dockerfile existe
    if [ ! -f "docker/golang.Dockerfile" ]; then
        print_error "Dockerfile não encontrado em docker/golang.Dockerfile"
        exit 1
    fi
    
    # Verifica se o código fonte existe
    if [ ! -d "src" ]; then
        print_error "Diretório src não encontrado. Certifique-se de estar no diretório raiz do projeto."
        exit 1
    fi
    
    # Faz o build
    docker-compose build --no-cache
    
    print_message "Build concluído com sucesso!"
}

# Função para executar o container
run_container() {
    print_message "Iniciando container..."
    
    # Verifica se a imagem existe
    if ! docker images | grep -q "zap-nebula_whatsapp"; then
        print_warning "Imagem não encontrada. Fazendo build primeiro..."
        build_image
    fi
    
    # Executa o container
    docker-compose up -d
    
    print_message "Container iniciado com sucesso!"
    print_message "Aplicação disponível em: http://localhost:3500"
    print_message "Para ver logs: $0 --logs"
}

# Função para mostrar logs
show_logs() {
    print_message "Mostrando logs do container..."
    docker-compose logs -f whatsapp
}

# Função para parar o container
stop_container() {
    print_message "Parando container..."
    docker-compose down
    print_message "Container parado!"
}

# Processamento de argumentos
BUILD_ONLY=false
RUN_ONLY=false
CLEAN=false
SHOW_LOGS=false
STOP_CONTAINER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --run-only)
            RUN_ONLY=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --logs)
            SHOW_LOGS=true
            shift
            ;;
        --stop)
            STOP_CONTAINER=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Verifica se Docker está rodando
check_docker

# Exibe header
print_header

# Executa ações baseadas nos argumentos
if [ "$CLEAN" = true ]; then
    cleanup
    exit 0
fi

if [ "$STOP_CONTAINER" = true ]; then
    stop_container
    exit 0
fi

if [ "$SHOW_LOGS" = true ]; then
    show_logs
    exit 0
fi

if [ "$BUILD_ONLY" = true ]; then
    build_image
    exit 0
fi

if [ "$RUN_ONLY" = true ]; then
    run_container
    exit 0
fi

# Se nenhuma opção específica foi passada, faz build e executa
print_message "Iniciando build e execução..."
build_image
run_container

print_message "Processo concluído com sucesso!"
print_message "Acesse http://localhost:3500 para usar a aplicação" 