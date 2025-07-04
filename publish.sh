#!/bin/bash

# Configurações
DOCKERFILE_PATH="docker/golang.Dockerfile"
DOCKER_USERNAME="nebulasistemas"
DOCKER_PASSWORD="0457bc93-4e0f-4786-a1e6-1cad45a44a0d"

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 <Ambiente> <Versão> [OPÇÕES]"
    echo ""
    echo "Argumentos:"
    echo "  Ambiente    Ambiente de deploy (ex: dev, staging, prd)"
    echo "  Versão      Versão da imagem (ex: 1.2.3)"
    echo ""
    echo "Opções:"
    echo "  --no-push   Apenas faz o build, não envia para o registry"
    echo "  --help      Exibe esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 prd 1.2.3"
    echo "  $0 dev 1.0.0 --no-push"
    echo ""
}

# Função para tratamento de erros
handle_error() {
    echo -e "\e[31mErro: $1\e[0m"
    exit 1
}

# Função para validação de argumentos
validate_args() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        show_help
        exit 1
    fi
    
    # Validação do ambiente
    case "$1" in
        dev|staging|prd|test)
            AMBIENTE=$1
            ;;
        *)
            handle_error "Ambiente inválido: $1. Use: dev, staging, prd, test"
            ;;
    esac
    
    # Validação da versão (formato semântico)
    if [[ ! $2 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        handle_error "Versão inválida: $2. Use formato: X.Y.Z (ex: 1.2.3)"
    fi
    VERSAO=$2
}

# Função para verificar dependências
check_dependencies() {
    if ! command -v docker &> /dev/null; then
        handle_error "Docker não está instalado ou não está no PATH"
    fi
    
    if [ ! -f "$DOCKERFILE_PATH" ]; then
        handle_error "Dockerfile não encontrado em: $DOCKERFILE_PATH"
    fi
}

# Função para build da imagem
build_image() {
    echo -e "\e[36mFazendo build da imagem Docker...\e[0m"
    echo -e "\e[37mDockerfile: $DOCKERFILE_PATH\e[0m"
    echo -e "\e[37mTag: $IMAGE_TAG\e[0m"
    
    if ! docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_TAG" .; then
        handle_error "Falha no build da imagem Docker"
    fi
    
    echo -e "\e[32mBuild concluído com sucesso!\e[0m"
}

# Função para tag da imagem
tag_image() {
    echo -e "\e[36mTagueando imagem com: $IMAGE_LATEST_TAG\e[0m"
    
    if ! docker tag "$IMAGE_TAG" "$IMAGE_LATEST_TAG"; then
        handle_error "Falha ao criar tag da imagem"
    fi
}

# Função para login no Docker Hub
docker_login() {
    echo -e "\e[37mFazendo login no Docker Hub...\e[0m"
    
    if ! echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin; then
        handle_error "Falha no login no Docker Hub"
    fi
}

# Função para push das imagens
push_images() {
    echo -e "\e[37mEnviando imagem $IMAGE_TAG\e[0m"
    if ! docker push "$IMAGE_TAG"; then
        handle_error "Falha ao enviar imagem $IMAGE_TAG"
    fi
    
    echo -e "\e[37mEnviando imagem $IMAGE_LATEST_TAG\e[0m"
    if ! docker push "$IMAGE_LATEST_TAG"; then
        handle_error "Falha ao enviar imagem $IMAGE_LATEST_TAG"
    fi
}

# Função para limpeza
cleanup() {
    echo -e "\e[37mRemovendo imagens locais...\e[0m"
    docker rmi "$IMAGE_TAG" 2>/dev/null || true
    docker rmi "$IMAGE_LATEST_TAG" 2>/dev/null || true
}

# Processamento de argumentos
NO_PUSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-push)
            NO_PUSH=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            handle_error "Opção desconhecida: $1"
            ;;
        *)
            break
            ;;
    esac
done

# Validação dos argumentos principais
validate_args "$1" "$2"

# Define as tags da imagem
IMAGE_NAME="nebulasistemas/nebula-zap-api"
IMAGE_TAG="$IMAGE_NAME:$AMBIENTE-$VERSAO"
IMAGE_LATEST_TAG="$IMAGE_NAME:$AMBIENTE-latest"

# Limpa o console
clear
echo -e "\e[32m========================================\e[0m"
echo -e "\e[32m  Build e Deploy - WhatsApp API\e[0m"
echo -e "\e[32m========================================\e[0m"
echo -e "\e[37mAmbiente: $AMBIENTE\e[0m"
echo -e "\e[37mVersão: $VERSAO\e[0m"
echo -e "\e[37mImagem: $IMAGE_TAG\e[0m"
echo -e "\e[37mPush: $([ "$NO_PUSH" = true ] && echo "Desabilitado" || echo "Habilitado")\e[0m"
echo ""

# Verificação de dependências
check_dependencies

# Build da imagem
build_image

# Tag da imagem
tag_image

# Push das imagens (se habilitado)
if [ "$NO_PUSH" = false ]; then
    docker_login
    push_images
    cleanup
    echo -e "\e[32m========================================\e[0m"
    echo -e "\e[32m  Processo concluído com sucesso!\e[0m"
    echo -e "\e[32m========================================\e[0m"
else
    echo -e "\e[33m========================================\e[0m"
    echo -e "\e[33m  Build concluído (push desabilitado)\e[0m"
    echo -e "\e[33m========================================\e[0m"
fi
