#!/bin/bash

# Script de Deploy com Verificação de Branch e Alterações
# Uso: ./deploy-custom.sh <ambiente> <versão>

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 <ambiente> <versão> [OPÇÕES]"
    echo ""
    echo "Argumentos:"
    echo "  ambiente    Ambiente de deploy (dev, staging, prd)"
    echo "  versão      Versão da imagem (ex: 1.2.3)"
    echo ""
    echo "Opções:"
    echo "  --force     Força deploy mesmo com verificações falhando"
    echo "  --help      Exibe esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 prd 1.2.3"
    echo "  $0 dev 1.0.0 --force"
    echo ""
}

# Função para verificar se estamos em um repositório git
check_git_repo() {
    if [ ! -d ".git" ]; then
        log_error "Não é um repositório Git válido"
        exit 1
    fi
}

# Função para verificar branch atual
check_current_branch() {
    CURRENT_BRANCH=$(git branch --show-current)
    
    # Lista de branches permitidas para deploy
    ALLOWED_BRANCHES=("main" "desenvolvimento" "master")
    
    for branch in "${ALLOWED_BRANCHES[@]}"; do
        if [ "$CURRENT_BRANCH" = "$branch" ]; then
            log_success "Branch atual: $CURRENT_BRANCH"
            return 0
        fi
    done
    
    log_error "Branch atual ($CURRENT_BRANCH) não é permitida para deploy"
    log_info "Branches permitidas: ${ALLOWED_BRANCHES[*]}"
    return 1
}

# Função para verificar alterações não commitadas
check_uncommitted_changes() {
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "Há alterações não commitadas:"
        git status --short
        echo ""
        
        if [ "$FORCE_DEPLOY" = true ]; then
            log_warning "Deploy forçado - ignorando alterações não commitadas"
        else
            log_error "Faça commit das alterações antes do deploy"
            log_info "Use --force para ignorar esta verificação"
            return 1
        fi
    else
        log_success "Nenhuma alteração não commitada encontrada"
    fi
}

# Função para verificar se há commits não enviados
check_unpushed_commits() {
    UNPUSHED_COMMITS=$(git log origin/$(git branch --show-current)..HEAD --oneline)
    
    if [ -n "$UNPUSHED_COMMITS" ]; then
        log_warning "Há commits não enviados para origin:"
        echo "$UNPUSHED_COMMITS"
        echo ""
        
        if [ "$FORCE_DEPLOY" = true ]; then
            log_warning "Deploy forçado - ignorando commits não enviados"
        else
            log_error "Envie os commits antes do deploy"
            log_info "Use --force para ignorar esta verificação"
            return 1
        fi
    else
        log_success "Todos os commits estão sincronizados"
    fi
}

# Função para verificar se o script publish.sh existe
check_publish_script() {
    if [ ! -f "publish.sh" ]; then
        log_error "Script publish.sh não encontrado"
        exit 1
    fi
    
    if [ ! -x "publish.sh" ]; then
        log_warning "Script publish.sh não tem permissão de execução"
        log_info "Adicionando permissão de execução..."
        chmod +x publish.sh
    fi
    
    log_success "Script publish.sh encontrado e executável"
}

# Função para verificar argumentos
validate_args() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        show_help
        exit 1
    fi
    
    AMBIENTE=$1
    VERSAO=$2
    
    # Validação do ambiente
    case "$AMBIENTE" in
        dev|staging|prd|test)
            log_success "Ambiente: $AMBIENTE"
            ;;
        *)
            log_error "Ambiente inválido: $AMBIENTE"
            log_info "Ambientes válidos: dev, staging, prd, test"
            exit 1
            ;;
    esac
    
    # Validação da versão
    if [[ ! $VERSAO =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Versão inválida: $VERSAO"
        log_info "Use formato: X.Y.Z (ex: 1.2.3)"
        exit 1
    fi
    
    log_success "Versão: $VERSAO"
}

# Função para mostrar informações do deploy
show_deploy_info() {
    echo -e "${BLUE}🚀 Informações do Deploy${NC}"
    echo "=========================================="
    echo "Ambiente: $AMBIENTE"
    echo "Versão: $VERSAO"
    echo "Branch: $(git branch --show-current)"
    echo "Commit: $(git rev-parse --short HEAD)"
    echo "Data: $(date)"
    echo "Usuário: $(whoami)"
    echo "=========================================="
    echo ""
}

# Função para executar o deploy
execute_deploy() {
    log_info "Executando deploy..."
    
    # Executar script de publish
    if ./publish.sh "$AMBIENTE" "$VERSAO"; then
        log_success "Deploy executado com sucesso!"
    else
        log_error "Falha no deploy"
        exit 1
    fi
}

# Função para criar tag da versão
create_version_tag() {
    TAG_NAME="v$VERSAO-$AMBIENTE"
    
    log_info "Criando tag: $TAG_NAME"
    
    if git tag -l | grep -q "$TAG_NAME"; then
        log_warning "Tag $TAG_NAME já existe"
        read -p "Deseja sobrescrever? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "$TAG_NAME"
        else
            log_info "Tag não criada"
            return 0
        fi
    fi
    
    git tag -a "$TAG_NAME" -m "Deploy $AMBIENTE v$VERSAO"
    git push origin "$TAG_NAME"
    
    log_success "Tag $TAG_NAME criada e enviada"
}

# Função para mostrar resumo final
show_final_summary() {
    echo ""
    echo -e "${GREEN}🎉 Deploy Concluído com Sucesso!${NC}"
    echo "=========================================="
    echo "Ambiente: $AMBIENTE"
    echo "Versão: $VERSAO"
    echo "Tag: v$VERSAO-$AMBIENTE"
    echo "Branch: $(git branch --show-current)"
    echo "Commit: $(git rev-parse --short HEAD)"
    echo "Data: $(date)"
    echo "=========================================="
}

# Processamento de argumentos
FORCE_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_DEPLOY=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            log_error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Função principal
main() {
    echo -e "${BLUE}🚀 Deploy com Verificações - WhatsApp API${NC}"
    echo ""
    
    # Validação de argumentos
    validate_args "$1" "$2"
    
    # Verificações
    check_git_repo
    check_publish_script
    
    if [ "$FORCE_DEPLOY" = false ]; then
        check_current_branch
        check_uncommitted_changes
        check_unpushed_commits
    fi
    
    # Informações do deploy
    show_deploy_info
    
    # Confirmação final
    if [ "$FORCE_DEPLOY" = false ]; then
        read -p "Deseja continuar com o deploy? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Deploy cancelado"
            exit 0
        fi
    fi
    
    # Executar deploy
    execute_deploy
    
    # Criar tag
    create_version_tag
    
    # Resumo final
    show_final_summary
}

# Executar função principal
main "$@" 