# Docker - Zap Nebula

Este documento explica como executar o **Zap Nebula** usando Docker, tanto com imagens pré-construídas quanto construindo a partir do código local.

## 🚀 Opções de Execução

### Opção 1: Imagem do Docker Hub (Rápida)
```bash
# Usar imagem pré-construída
docker-compose up -d
```

### Opção 2: Build Local (Recomendado para Desenvolvimento)
```bash
# Construir e executar a partir do código local
./build-and-run.sh
```

## 📋 Pré-requisitos

- Docker instalado e rodando
- Docker Compose instalado
- Git (para clonar o repositório)

## 🔧 Configuração

### 1. Clone o Repositório
```bash
git clone <repository-url>
cd zap-nebula
```

### 2. Configure as Variáveis de Ambiente
Edite o arquivo `docker-compose.yml` e ajuste as configurações:

```yaml
environment:
  WHATSAPP_WEBHOOK: "https://seu-webhook.com/endpoint"
  # Outras variáveis de ambiente...
```

## 🛠️ Script de Build e Execução

O projeto inclui um script automatizado para facilitar o build e execução:

### Uso Básico
```bash
# Build e executa automaticamente
./build-and-run.sh
```

### Opções Disponíveis
```bash
# Apenas fazer o build
./build-and-run.sh --build-only

# Apenas executar (assume que já foi buildado)
./build-and-run.sh --run-only

# Limpar containers e imagens antigas
./build-and-run.sh --clean

# Ver logs do container
./build-and-run.sh --logs

# Parar o container
./build-and-run.sh --stop

# Ver ajuda
./build-and-run.sh --help
```

## 📁 Estrutura de Arquivos Docker

```
zap-nebula/
├── docker/
│   └── golang.Dockerfile    # Dockerfile para build da aplicação
├── docker-compose.yml       # Configuração principal
├── docker-compose.local.yml # Configuração alternativa para desenvolvimento
├── build-and-run.sh         # Script automatizado
└── src/                     # Código fonte da aplicação
```

## 🔍 Dockerfile Explicado

O `docker/golang.Dockerfile` utiliza multi-stage build para otimizar o tamanho da imagem:

```dockerfile
# Stage 1: Build da aplicação
FROM golang:1.24-alpine3.20 AS builder
RUN apk update && apk add --no-cache gcc musl-dev gcompat
WORKDIR /whatsapp
COPY ./src .
RUN go mod download
RUN go build -a -ldflags="-w -s" -o /app/whatsapp

# Stage 2: Imagem final
FROM alpine:3.20
RUN apk add --no-cache ffmpeg
WORKDIR /app
COPY --from=builder /app/whatsapp /app/whatsapp
ENTRYPOINT ["/app/whatsapp"]
CMD [ "rest" ]
```

## 🌐 Acessando a Aplicação

Após a execução bem-sucedida, a aplicação estará disponível em:

- **URL**: http://localhost:3500
- **Porta**: 3500 (mapeada para 3000 do container)

## 📊 Volumes e Persistência

### Volumes Configurados
```yaml
volumes:
  - whatsapp:/app/storages          # Dados persistentes do WhatsApp
  - ./src/statics:/app/statics      # Arquivos estáticos (desenvolvimento)
```

### Dados Persistidos
- QR codes de autenticação
- Histórico de mensagens
- Configurações do WhatsApp
- Mídia baixada

## 🔍 Monitoramento e Logs

### Ver Logs em Tempo Real
```bash
# Usando o script
./build-and-run.sh --logs

# Ou diretamente
docker-compose logs -f whatsapp
```

### Ver Status do Container
```bash
docker-compose ps
```

### Ver Informações do Container
```bash
docker inspect zap-nebula_whatsapp_1
```

## 🛠️ Desenvolvimento

### Modo Desenvolvimento
Para desenvolvimento local com hot-reload:

1. **Monte o código fonte**:
```yaml
volumes:
  - ./src:/app/src  # Adicione esta linha no docker-compose.yml
```

2. **Use o script de desenvolvimento**:
```bash
./build-and-run.sh --dev
```

### Debug
Para habilitar logs de debug:

```yaml
command:
  - rest
  - --debug=true  # Altere para true
```

## 🔧 Troubleshooting

### Problema: Porta já em uso
```bash
# Verificar o que está usando a porta 3500
sudo lsof -i :3500

# Ou alterar a porta no docker-compose.yml
ports:
  - "3501:3000"  # Mude para 3501
```

### Problema: Permissões de volume
```bash
# Corrigir permissões
sudo chown -R $USER:$USER ./src/statics
```

### Problema: Build falha
```bash
# Limpar cache e rebuildar
./build-and-run.sh --clean
./build-and-run.sh --build-only
```

### Problema: Container não inicia
```bash
# Verificar logs
docker-compose logs whatsapp

# Verificar se o Docker está rodando
docker info
```

## 🔒 Segurança

### Variáveis de Ambiente Sensíveis
Nunca commite senhas ou tokens no repositório. Use arquivos `.env`:

```bash
# Criar arquivo .env
cp .env.example .env

# Editar variáveis sensíveis
nano .env
```

### Exemplo de .env
```env
WHATSAPP_WEBHOOK=https://seu-webhook.com/endpoint
WHATSAPP_WEBHOOK_SECRET=seu-secret-aqui
BASIC_AUTH=usuario:senha
```

## 📈 Performance

### Otimizações do Dockerfile
- **Multi-stage build**: Reduz tamanho da imagem final
- **Alpine Linux**: Imagem base leve
- **Build otimizado**: Flags de otimização do Go
- **FFmpeg**: Incluído para processamento de mídia

### Monitoramento de Recursos
```bash
# Ver uso de recursos
docker stats zap-nebula_whatsapp_1

# Ver tamanho da imagem
docker images zap-nebula_whatsapp
```

## 🔄 Atualizações

### Atualizar Código
```bash
# Pull das mudanças
git pull origin main

# Rebuild da imagem
./build-and-run.sh --clean
./build-and-run.sh
```

### Atualizar Dependências
```bash
# Rebuild completo
./build-and-run.sh --clean
./build-and-run.sh --build-only
```

## 📚 Comandos Úteis

### Docker Compose
```bash
# Build
docker-compose build

# Executar
docker-compose up -d

# Parar
docker-compose down

# Ver logs
docker-compose logs -f

# Rebuild e executar
docker-compose up --build -d
```

### Docker
```bash
# Ver imagens
docker images

# Ver containers
docker ps -a

# Executar comando no container
docker exec -it zap-nebula_whatsapp_1 sh

# Ver logs
docker logs zap-nebula_whatsapp_1
```

## 🆘 Suporte

### Logs Importantes
- **Aplicação**: `docker-compose logs whatsapp`
- **Docker**: `docker system info`
- **Sistema**: `journalctl -u docker`

### Recursos Adicionais
- [Documentação Docker](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Issues do Projeto](https://github.com/sistemasnebula/zap-nebula/issues)

---

**Última Atualização**: Dezembro 2024  
**Versão**: 1.0  
**Autor**: Assistente de Análise de Código 