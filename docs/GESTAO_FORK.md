# 🍴 Guia de Gestão de Fork com Alterações Customizadas

## 📋 Visão Geral

Este documento explica como manter suas alterações customizadas em um fork do GitHub, mesmo após sincronizar com o repositório original (upstream).

## 🎯 Estratégias Recomendadas

### **Estratégia 1: Branch de Desenvolvimento (Recomendada)**

Esta é a estratégia mais limpa e segura para manter alterações customizadas.

#### **1. Configurar o Upstream**
```bash
# Adicionar o repositório original como upstream
git remote add upstream https://github.com/REPOSITORIO_ORIGINAL/go-whatsapp-web-multidevice.git

# Verificar os remotes
git remote -v
```

#### **2. Criar Branch de Desenvolvimento**
```bash
# Criar e mudar para branch de desenvolvimento
git checkout -b desenvolvimento

# Fazer commit das alterações customizadas
git add .
git commit -m "feat: alterações customizadas do projeto"

# Enviar branch para o fork
git push origin desenvolvimento
```

#### **3. Manter Main Limpa**
```bash
# Voltar para main
git checkout main

# Sincronizar com upstream
git fetch upstream
git merge upstream/main

# Enviar atualizações para o fork
git push origin main
```

#### **4. Mesclar Alterações do Upstream**
```bash
# Mudar para branch de desenvolvimento
git checkout desenvolvimento

# Mesclar alterações do upstream
git merge upstream/main

# Resolver conflitos se houver
# git add .
# git commit -m "merge: upstream changes"

# Enviar para o fork
git push origin desenvolvimento
```

### **Estratégia 2: Commits Customizados na Main**

Para projetos menores ou quando você é o único desenvolvedor.

#### **1. Configurar Upstream**
```bash
git remote add upstream https://github.com/REPOSITORIO_ORIGINAL/go-whatsapp-web-multidevice.git
```

#### **2. Fazer Commit das Alterações**
```bash
# Commit das alterações customizadas
git add .
git commit -m "feat: alterações customizadas - publish script e documentação"

# Enviar para o fork
git push origin main
```

#### **3. Sincronizar com Upstream**
```bash
# Buscar alterações do upstream
git fetch upstream

# Mesclar com rebase para manter histórico limpo
git rebase upstream/main

# Resolver conflitos se houver
# git add .
# git rebase --continue

# Enviar para o fork (force push pode ser necessário)
git push origin main --force-with-lease
```

## 🔧 Configuração Inicial

### **1. Identificar o Repositório Original**
```bash
# Verificar se já tem upstream configurado
git remote -v

# Se não tiver, adicionar upstream
git remote add upstream https://github.com/REPOSITORIO_ORIGINAL/go-whatsapp-web-multidevice.git
```

### **2. Configurar Git para o Projeto**
```bash
# Configurar usuário para este repositório
git config user.name "Seu Nome"
git config user.email "seu.email@exemplo.com"

# Configurar editor preferido
git config core.editor "code --wait"
```

## 📝 Workflow Diário

### **Para Novas Alterações**
```bash
# 1. Verificar se há atualizações do upstream
git fetch upstream

# 2. Se houver atualizações, mesclar primeiro
git checkout main
git merge upstream/main
git push origin main

# 3. Mesclar na branch de desenvolvimento
git checkout desenvolvimento
git merge main

# 4. Fazer suas alterações
# ... editar arquivos ...

# 5. Commit e push
git add .
git commit -m "feat: nova funcionalidade"
git push origin desenvolvimento
```

### **Para Sincronização Periódica**
```bash
# 1. Buscar alterações do upstream
git fetch upstream

# 2. Verificar o que mudou
git log HEAD..upstream/main --oneline

# 3. Mesclar alterações
git checkout main
git merge upstream/main

# 4. Mesclar na branch de desenvolvimento
git checkout desenvolvimento
git merge main

# 5. Resolver conflitos se houver
# git status
# ... resolver conflitos ...
# git add .
# git commit -m "merge: resolve conflicts"

# 6. Enviar alterações
git push origin main
git push origin desenvolvimento
```

## 🛠️ Scripts Úteis

### **Script de Sincronização Automática**
```bash
#!/bin/bash
# sync-fork.sh

echo "🔄 Sincronizando fork com upstream..."

# Buscar alterações
git fetch upstream

# Verificar se há alterações
if [ "$(git log HEAD..upstream/main --oneline)" ]; then
    echo "📥 Novas alterações encontradas!"
    
    # Mesclar na main
    git checkout main
    git merge upstream/main
    
    # Mesclar na branch de desenvolvimento
    git checkout desenvolvimento
    git merge main
    
    # Enviar alterações
    git push origin main
    git push origin desenvolvimento
    
    echo "✅ Sincronização concluída!"
else
    echo "✅ Nenhuma alteração nova encontrada."
fi
```

### **Script de Deploy com Verificação**
```bash
#!/bin/bash
# deploy-custom.sh

echo "🚀 Deploy com alterações customizadas..."

# Verificar se está na branch correta
if [ "$(git branch --show-current)" != "desenvolvimento" ]; then
    echo "❌ Erro: Deve estar na branch 'desenvolvimento'"
    exit 1
fi

# Verificar se há alterações não commitadas
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Erro: Há alterações não commitadas"
    git status
    exit 1
fi

# Fazer deploy
./publish.sh "$1" "$2"

echo "✅ Deploy concluído!"
```

## 🔍 Resolução de Conflitos

### **Quando Ocorrem Conflitos**
```bash
# 1. Identificar arquivos com conflito
git status

# 2. Abrir arquivos e resolver conflitos
# Procurar por marcadores: <<<<<<< HEAD, =======, >>>>>>>

# 3. Após resolver, adicionar arquivos
git add .

# 4. Continuar o processo (merge ou rebase)
git commit  # para merge
# ou
git rebase --continue  # para rebase
```

### **Estratégias de Resolução**
1. **Manter suas alterações** - Se o upstream não afetar seus arquivos
2. **Mesclar manualmente** - Combinar alterações do upstream com suas customizações
3. **Usar suas versões** - Quando suas alterações são mais importantes
4. **Usar versão do upstream** - Quando as alterações do upstream são melhores

## 📊 Monitoramento

### **Verificar Status do Fork**
```bash
# Verificar branches
git branch -a

# Verificar commits não sincronizados
git log upstream/main..HEAD --oneline

# Verificar commits do upstream não mesclados
git log HEAD..upstream/main --oneline

# Verificar diferenças
git diff upstream/main
```

### **Configurar Notificações**
1. **GitHub Notifications** - Ativar notificações para o repositório original
2. **GitHub Actions** - Criar workflow para verificar atualizações
3. **Dependabot** - Para dependências do projeto

## 🎯 Boas Práticas

### **1. Commits Semânticos**
```bash
# Usar prefixos claros
git commit -m "feat: adiciona script de publish customizado"
git commit -m "fix: corrige problema no docker build"
git commit -m "docs: atualiza documentação do projeto"
git commit -m "refactor: reorganiza estrutura de arquivos"
```

### **2. Branch Naming**
```bash
# Padrão recomendado
feature/nova-funcionalidade
fix/correcao-bug
docs/atualizacao-docs
refactor/reorganizacao
```

### **3. Pull Requests**
- Sempre criar PRs para mesclar alterações importantes
- Usar templates de PR para padronizar
- Solicitar review quando apropriado

### **4. Backup e Versionamento**
```bash
# Criar tags para versões importantes
git tag -a v1.0.0 -m "Versão 1.0.0 com alterações customizadas"
git push origin v1.0.0

# Backup local
git bundle create backup-$(date +%Y%m%d).bundle --all
```

## 🚨 Cenários de Emergência

### **Se Perder Alterações Locais**
```bash
# Verificar reflog
git reflog

# Recuperar commit perdido
git checkout -b recovery-branch HASH_DO_COMMIT

# Ou reset para commit anterior
git reset --hard HASH_DO_COMMIT
```

### **Se Fork Ficar Dessincronizado**
```bash
# Reset completo para upstream
git fetch upstream
git reset --hard upstream/main

# Recriar alterações customizadas
# ... recriar alterações ...
git add .
git commit -m "feat: recria alterações customizadas"
git push origin main --force
```

## 📈 Métricas de Sucesso

### **Indicadores de Boa Gestão**
- ✅ Fork sempre atualizado com upstream
- ✅ Alterações customizadas preservadas
- ✅ Conflitos resolvidos rapidamente
- ✅ Histórico de commits limpo
- ✅ Deploy funcionando corretamente

### **Checklist Mensal**
- [ ] Sincronizar com upstream
- [ ] Verificar se alterações customizadas ainda são necessárias
- [ ] Atualizar documentação
- [ ] Fazer backup do repositório
- [ ] Revisar e limpar branches antigas

## 🎯 Conclusão

Com essas estratégias, você pode:
- **Manter seu fork atualizado** com o repositório original
- **Preservar suas alterações customizadas** de forma organizada
- **Facilitar a manutenção** do projeto ao longo do tempo
- **Evitar conflitos** desnecessários
- **Ter um workflow profissional** para gestão do fork

A **Estratégia 1 (Branch de Desenvolvimento)** é recomendada para a maioria dos casos, pois oferece a melhor separação entre código original e customizações. 