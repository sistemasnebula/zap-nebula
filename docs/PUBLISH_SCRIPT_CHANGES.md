# Mudanças no Script publish.sh

## 🔄 Resumo das Alterações

O script `publish.sh` foi modificado para usar `docker build` em vez de `docker-compose`, tornando-o mais eficiente e flexível.

## 📋 Principais Mudanças

### ❌ **Antes (docker-compose)**
```bash
# Sobe o serviço e faz build da imagem base
docker-compose up -d --build

# Tagueia a imagem com a versão e com o latest
docker tag "$IMAGE_ZAP_TAG" "$IMAGE_TAG"
docker tag "$IMAGE_ZAP_TAG" "$IMAGE_LATEST_TAG"
```

### ✅ **Depois (docker build)**
```bash
# Build da imagem usando docker build
docker build -f docker/golang.Dockerfile -t "$IMAGE_TAG" .

# Tagueia a imagem com o latest
docker tag "$IMAGE_TAG" "$IMAGE_LATEST_TAG"
```

## 🚀 Novas Funcionalidades

### 1. **Validação de Argumentos**
- Validação de ambiente (dev, staging, prd, test)
- Validação de versão (formato semântico X.Y.Z)
- Tratamento de erros robusto

### 2. **Verificação de Dependências**
- Verifica se Docker está instalado
- Verifica se Dockerfile existe
- Validação de permissões

### 3. **Opções Flexíveis**
```bash
# Build completo com push
./publish.sh prd 1.2.3

# Apenas build (sem push)
./publish.sh dev 1.0.0 --no-push

# Ajuda
./publish.sh --help
```

### 4. **Melhor Tratamento de Erros**
- Mensagens de erro claras e coloridas
- Saída em caso de falha
- Logs detalhados de cada etapa

### 5. **Interface Melhorada**
- Cabeçalho informativo
- Progresso visual
- Cores para diferentes tipos de mensagem

## 🔧 Configurações

### Variáveis Configuráveis
```bash
DOCKERFILE_PATH="docker/golang.Dockerfile"
DOCKER_USERNAME="nebulasistemas"
DOCKER_PASSWORD="0457bc93-4e0f-4786-a1e6-1cad45a44a0d"
```

### Ambientes Suportados
- `dev` - Desenvolvimento
- `staging` - Homologação
- `prd` - Produção
- `test` - Testes

## 📊 Vantagens da Mudança

### **Performance**
- ✅ **Build mais rápido** - Sem overhead do docker-compose
- ✅ **Menos recursos** - Não cria containers desnecessários
- ✅ **Cache eficiente** - Aproveita melhor o cache do Docker

### **Flexibilidade**
- ✅ **Build independente** - Não depende do docker-compose.yml
- ✅ **Opções de push** - Pode fazer apenas build sem push
- ✅ **Validações** - Verifica dependências antes de executar

### **Manutenibilidade**
- ✅ **Código modular** - Funções separadas para cada operação
- ✅ **Tratamento de erros** - Falha graciosamente em caso de erro
- ✅ **Documentação** - Help integrado e exemplos

### **Segurança**
- ✅ **Login seguro** - Usa --password-stdin para senha
- ✅ **Validação de entrada** - Previne execução com parâmetros inválidos
- ✅ **Limpeza automática** - Remove imagens locais após push

## 🧪 Como Testar

### 1. **Teste de Ajuda**
```bash
./publish.sh --help
```

### 2. **Teste de Validação**
```bash
# Deve falhar - ambiente inválido
./publish.sh invalid 1.0.0

# Deve falhar - versão inválida
./publish.sh dev 1.0

# Deve falhar - argumentos insuficientes
./publish.sh dev
```

### 3. **Teste de Build (sem push)**
```bash
./publish.sh dev 1.0.0 --no-push
```

### 4. **Teste Completo**
```bash
./publish.sh prd 1.2.3
```

## 🔍 Comparação de Comandos

### **Antes (docker-compose)**
```bash
# 1. Build via docker-compose
docker-compose up -d --build

# 2. Tag das imagens
docker tag "go-whatsapp-web-multidevice-whatsapp_go:latest" "nebulasistemas/nebula-zap-api:prd-1.2.3"
docker tag "go-whatsapp-web-multidevice-whatsapp_go:latest" "nebulasistemas/nebula-zap-api:prd-latest"

# 3. Push
docker push "nebulasistemas/nebula-zap-api:prd-1.2.3"
docker push "nebulasistemas/nebula-zap-api:prd-latest"
```

### **Depois (docker build)**
```bash
# 1. Build direto
docker build -f docker/golang.Dockerfile -t "nebulasistemas/nebula-zap-api:prd-1.2.3" .

# 2. Tag da imagem
docker tag "nebulasistemas/nebula-zap-api:prd-1.2.3" "nebulasistemas/nebula-zap-api:prd-latest"

# 3. Push
docker push "nebulasistemas/nebula-zap-api:prd-1.2.3"
docker push "nebulasistemas/nebula-zap-api:prd-latest"
```

## 📝 Logs de Execução

### **Saída Típica**
```
========================================
  Build e Deploy - WhatsApp API
========================================
Ambiente: prd
Versão: 1.2.3
Imagem: nebulasistemas/nebula-zap-api:prd-1.2.3
Push: Habilitado

Fazendo build da imagem Docker...
Dockerfile: docker/golang.Dockerfile
Tag: nebulasistemas/nebula-zap-api:prd-1.2.3
Build concluído com sucesso!

Tagueando imagem com: nebulasistemas/nebula-zap-api:prd-latest

Fazendo login no Docker Hub...

Enviando imagem nebulasistemas/nebula-zap-api:prd-1.2.3
Enviando imagem nebulasistemas/nebula-zap-api:prd-latest

Removendo imagens locais...

========================================
  Processo concluído com sucesso!
========================================
```

## 🔄 Migração

### **Para Usuários Existentes**
1. **Comportamento mantido** - O uso básico continua igual
2. **Novas opções** - Agora tem mais flexibilidade
3. **Melhor feedback** - Mensagens mais claras e informativas

### **Comandos Equivalentes**
```bash
# Antes
./publish.sh prd 1.2.3

# Depois (mesmo comando)
./publish.sh prd 1.2.3

# Nova opção (apenas build)
./publish.sh prd 1.2.3 --no-push
```

## 🎯 Conclusão

A mudança de `docker-compose` para `docker build` traz:
- **Melhor performance** no build
- **Mais flexibilidade** nas opções
- **Maior robustez** no tratamento de erros
- **Interface mais amigável** para o usuário

O script mantém compatibilidade com o uso anterior, mas oferece novas funcionalidades e melhor experiência de desenvolvimento. 