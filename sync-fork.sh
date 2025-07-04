#!/bin/bash

# Script de Sincronização Automática do Fork
# Uso: ./sync-fork.sh

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

# Função para verificar se estamos em um repositório git
check_git_repo() {
    if [ ! -d ".git" ]; then
        log_error "Não é um repositório Git válido"
        exit 1
    fi
}

# Função para verificar se upstream está configurado
check_upstream() {
    if ! git remote | grep -q upstream; then
        log_error "Remote 'upstream' não configurado"
        log_info "Execute: git remote add upstream https://github.com/REPOSITORIO_ORIGINAL/go-whatsapp-web-multidevice.git"
        exit 1
    fi
}

# Função para verificar se há alterações não commitadas
check_uncommitted_changes() {
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "Há alterações não commitadas:"
        git status --short
        echo ""
        read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Sincronização cancelada"
            exit 0
        fi
    fi
}

# Função para sincronizar main
sync_main() {
    log_info "Sincronizando branch main..."
    
    # Mudar para main
    git checkout main
    
    # Buscar alterações do upstream
    git fetch upstream
    
    # Verificar se há alterações
    if [ "$(git log HEAD..upstream/main --oneline)" ]; then
        log_info "Novas alterações encontradas no upstream:"
        git log HEAD..upstream/main --oneline
        
        # Mesclar alterações
        git merge upstream/main
        
        # Enviar para origin
        git push origin main
        
        log_success "Main sincronizada com sucesso!"
    else
        log_success "Main já está atualizada"
    fi
}

# Função para sincronizar branch de desenvolvimento
sync_development() {
    log_info "Verificando branch de desenvolvimento..."
    
    # Verificar se branch desenvolvimento existe
    if git branch | grep -q "desenvolvimento"; then
        log_info "Sincronizando branch desenvolvimento..."
        
        # Mudar para desenvolvimento
        git checkout desenvolvimento
        
        # Mesclar alterações da main
        git merge main
        
        # Enviar para origin
        git push origin desenvolvimento
        
        log_success "Branch desenvolvimento sincronizada!"
    else
        log_warning "Branch 'desenvolvimento' não encontrada"
        log_info "Para criar: git checkout -b desenvolvimento"
    fi
}

# Função para mostrar resumo
show_summary() {
    log_info "Resumo da sincronização:"
    echo ""
    
    # Verificar status atual
    CURRENT_BRANCH=$(git branch --show-current)
    log_info "Branch atual: $CURRENT_BRANCH"
    
    # Verificar commits não sincronizados
    UNPUSHED_COMMITS=$(git log origin/main..HEAD --oneline)
    if [ -n "$UNPUSHED_COMMITS" ]; then
        log_warning "Commits não enviados para origin:"
        echo "$UNPUSHED_COMMITS"
    else
        log_success "Todos os commits estão sincronizados"
    fi
    
    # Verificar commits do upstream não mesclados
    UPSTREAM_COMMITS=$(git log HEAD..upstream/main --oneline)
    if [ -n "$UPSTREAM_COMMITS" ]; then
        log_warning "Commits do upstream não mesclados:"
        echo "$UPSTREAM_COMMITS"
    else
        log_success "Todos os commits do upstream estão mesclados"
    fi
}

# Função principal
main() {
    echo -e "${BLUE}🔄 Sincronizando fork com upstream...${NC}"
    echo ""
    
    # Verificações iniciais
    check_git_repo
    check_upstream
    check_uncommitted_changes
    
    # Sincronização
    sync_main
    sync_development
    
    # Resumo
    echo ""
    show_summary
    
    echo ""
    log_success "Sincronização concluída!"
}

# Executar função principal
main "$@" 