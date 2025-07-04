# Documentação Completa - WhatsApp API Multi-Device

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Arquitetura do Projeto](#arquitetura-do-projeto)
3. [Tecnologias Utilizadas](#tecnologias-utilizadas)
4. [Funcionalidades](#funcionalidades)
5. [Configuração e Deploy](#configuração-e-deploy)
6. [Limitações e Considerações](#limitações-e-considerações)
7. [Análise de Banco de Dados](#análise-de-banco-de-dados)
8. [Casos de Uso](#casos-de-uso)
9. [Análise Técnica Detalhada](#análise-técnica-detalhada)
10. [Recomendações](#recomendações)

---

## 🎯 Visão Geral

### Propósito
Este projeto implementa uma **API REST** para integração programática com WhatsApp através do protocolo Multi-Device, permitindo enviar e receber mensagens, gerenciar grupos e automatizar interações com WhatsApp.

### Características Principais
- ✅ API REST completa para WhatsApp
- ✅ Suporte ao protocolo Multi-Device
- ✅ Interface web embutida
- ✅ Webhook para eventos
- ✅ Modo MCP (Model Context Protocol)
- ✅ Containerização com Docker
- ✅ Suporte a múltiplas plataformas

---

## 🏗️ Arquitetura do Projeto

### Estrutura de Diretórios
```
src/
├── cmd/           # Comandos CLI (rest, mcp, root)
├── config/        # Configurações da aplicação
├── domains/       # Domínios de negócio
│   ├── app/       # Autenticação e gerenciamento
│   ├── send/      # Envio de mensagens
│   ├── user/      # Informações de usuário
│   ├── message/   # Manipulação de mensagens
│   ├── group/     # Gerenciamento de grupos
│   └── newsletter/# Newsletter e envio em massa
├── infrastructure/# Infraestrutura
│   └── whatsapp/  # Cliente WhatsApp
├── pkg/          # Pacotes utilitários
├── usecase/      # Casos de uso da aplicação
├── views/        # Templates HTML
├── ui/           # Interface web e WebSocket
└── main.go       # Ponto de entrada
```

### Padrão Arquitetural
- **Clean Architecture** com separação clara de responsabilidades
- **Domain-Driven Design** com domínios bem definidos
- **Dependency Injection** para injeção de dependências
- **Repository Pattern** para acesso a dados

---

## 🔧 Tecnologias Utilizadas

### Backend
| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| **Go** | 1.24+ | Linguagem principal |
| **Fiber** | v2.52.8 | Framework web |
| **WhatsMeow** | Latest | Biblioteca WhatsApp Multi-Device |
| **SQLite/PostgreSQL** | - | Armazenamento de dados |
| **FFmpeg** | - | Processamento de mídia |
| **Cobra** | v1.9.1 | CLI framework |
| **Viper** | v1.20.1 | Gerenciamento de configuração |

### Frontend
| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| **HTML Templates** | - | Interface web embutida |
| **Vue.js** | 3.x | Interatividade |
| **WebSocket** | - | Comunicação em tempo real |
| **Semantic UI** | - | Framework CSS |

### Infraestrutura
| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| **Docker** | - | Containerização |
| **Docker Compose** | - | Orquestração |
| **Alpine Linux** | 3.20 | Imagem base |

---

## 🚀 Funcionalidades

### 1. API REST Completa

#### Autenticação
- `GET /app/login` - Login com QR Code
- `GET /app/login-with-code` - Login com código de pareamento
- `GET /app/logout` - Logout
- `GET /app/reconnect` - Reconectar
- `GET /app/devices` - Listar dispositivos

#### Envio de Mensagens
- `POST /send/text` - Enviar texto
- `POST /send/image` - Enviar imagem
- `POST /send/video` - Enviar vídeo
- `POST /send/document` - Enviar documento
- `POST /send/contact` - Enviar contato
- `POST /send/location` - Enviar localização
- `POST /send/audio` - Enviar áudio
- `POST /send/poll` - Enviar enquete
- `POST /send/link` - Enviar link

#### Gerenciamento de Grupos
- `POST /group/create` - Criar grupo
- `POST /group/join-with-link` - Entrar com link
- `POST /group/leave` - Sair do grupo
- `POST /group/add-participants` - Adicionar participantes
- `POST /group/remove-participants` - Remover participantes

#### Manipulação de Mensagens
- `POST /message/delete` - Deletar mensagem
- `POST /message/revoke` - Revogar mensagem
- `POST /message/react` - Reagir à mensagem
- `POST /message/update` - Atualizar mensagem

#### Informações de Usuário
- `GET /user/info` - Informações do usuário
- `GET /user/avatar` - Avatar do usuário
- `GET /user/check` - Verificar se está no WhatsApp

### 2. Recursos Avançados

#### Webhook
- Notificações automáticas de eventos
- Suporte a múltiplos webhooks
- Assinatura HMAC-SHA256 para segurança
- Retry automático em caso de falha

#### Auto-Reply
- Respostas automáticas configuráveis
- Filtros por tipo de mensagem
- Suporte a grupos e broadcasts

#### Compressão de Mídia
- Compressão automática de imagens
- Compressão automática de vídeos
- Limites configuráveis de tamanho

#### Armazenamento de Chat
- Histórico de mensagens em CSV
- Limpeza automática configurável
- Suporte a reply de mensagens

### 3. Modos de Operação

#### REST API
- Servidor HTTP tradicional
- Documentação OpenAPI completa
- Autenticação básica configurável

#### MCP Server (Model Context Protocol)
- Integração com IA e automação
- Protocolo padronizado
- Suporte a SSE (Server-Sent Events)

#### WebSocket
- Comunicação em tempo real
- Notificações de eventos
- Interface web interativa

---

## ⚙️ Configuração e Deploy

### Variáveis de Ambiente

| Variável | Descrição | Padrão | Exemplo |
|----------|-----------|--------|---------|
| `APP_PORT` | Porta da aplicação | `3000` | `APP_PORT=8080` |
| `APP_DEBUG` | Modo debug | `false` | `APP_DEBUG=true` |
| `APP_OS` | Nome do dispositivo | `Chrome` | `APP_OS=MyApp` |
| `APP_BASIC_AUTH` | Credenciais de autenticação | - | `APP_BASIC_AUTH=user1:pass1,user2:pass2` |
| `DB_URI` | URI do banco de dados | `file:storages/whatsapp.db` | `DB_URI=postgres://user:pass@host/db` |
| `WHATSAPP_WEBHOOK` | URLs dos webhooks | - | `WHATSAPP_WEBHOOK=https://webhook.site/xxx` |
| `WHATSAPP_WEBHOOK_SECRET` | Chave secreta do webhook | `secret` | `WHATSAPP_WEBHOOK_SECRET=super-secret` |
| `WHATSAPP_AUTO_REPLY` | Mensagem de auto-reply | - | `WHATSAPP_AUTO_REPLY="Auto reply"` |

### Docker Compose

```yaml
services:
  whatsapp:
    image: aldinokemal2104/go-whatsapp-web-multidevice
    container_name: whatsapp
    restart: always
    ports:
      - "3500:3000"
    volumes:
      - whatsapp:/app/storages
    environment:
      WHATSAPP_WEBHOOK: https://webhook.site/56daebcf-0ea3-400f-8bb5-de98580c62ae
    command:
      - rest
      - --port=3000
      - --debug=false
      - --os=NS-Zap
      - --account-validation=false
      - --webhook="https://webhook.site/56daebcf-0ea3-400f-8bb5-de98580c62ae"

volumes:
  whatsapp:
```

### Build Local

```bash
# Clone do repositório
git clone https://github.com/aldinokemal/go-whatsapp-web-multidevice
cd go-whatsapp-web-multidevice

# Build da aplicação
cd src
go build -o whatsapp

# Execução
./whatsapp rest --port=3000 --debug=true
```

---

## ⚠️ Limitações e Considerações

### Limitações Técnicas

#### 1. Conexão Única por Instância
- **Problema:** Uma instância Docker pode conectar apenas **1 dispositivo WhatsApp** por vez
- **Causa:** Uso de variável global `cli` e função `GetFirstDevice()`
- **Impacto:** Impossibilidade de múltiplas contas simultâneas

```go
// Código problemático
var cli *whatsmeow.Client  // ← Apenas 1 cliente global

func InitWaCLI(ctx context.Context, storeContainer *sqlstore.Container) *whatsmeow.Client {
    device, err := storeContainer.GetFirstDevice(ctx)  // ← Apenas 1 dispositivo
    cli = whatsmeow.NewClient(device, ...)
    return cli
}
```

#### 2. Armazenamento de Dados
- **Problema:** Dados persistentes em volume Docker
- **Causa:** Perda de dados ao recriar container
- **Impacto:** Necessidade de backup manual

#### 3. Recursos do Sistema
- **Problema:** Limitação de memória e CPU
- **Causa:** Processamento de mídia intensivo
- **Impacto:** Performance degradada com múltiplas instâncias

### Limitações do WhatsApp

#### 1. Multi-Device
- Máximo de 4 dispositivos por conta
- Limitações de funcionalidades em dispositivos secundários
- Necessidade de reautenticação periódica

#### 2. Rate Limiting
- Limites de envio de mensagens
- Restrições de spam
- Bloqueios temporários

#### 3. Políticas de Uso
- Termos de serviço do WhatsApp
- Proibição de uso comercial não autorizado
- Risco de banimento de conta

---

## 🗄️ Análise de Banco de Dados

### Visão Geral

O projeto suporta dois sistemas de banco de dados:
- **SQLite** (padrão) - Banco de dados embutido
- **PostgreSQL** (opcional) - Sistema de banco de dados robusto

### Configuração

```go
// src/config/settings.go
DBURI = "file:storages/whatsapp.db?_foreign_keys=on"

// src/infrastructure/whatsapp/init.go
func initDatabase(ctx context.Context, dbLog waLog.Logger) (*sqlstore.Container, error) {
    if strings.HasPrefix(config.DBURI, "file:") {
        return sqlstore.New(ctx, "sqlite3", config.DBURI, dbLog)
    } else if strings.HasPrefix(config.DBURI, "postgres:") {
        return sqlstore.New(ctx, "postgres", config.DBURI, dbLog)
    }
    return nil, fmt.Errorf("unknown database type")
}
```

### Comparação Detalhada

#### **SQLite - Recomendado para a Maioria dos Casos**

**✅ Vantagens:**
- **Simplicidade:** Zero configuração, funciona out-of-the-box
- **Portabilidade:** Arquivo único que move com a aplicação
- **Performance:** Latência zero, sem overhead de rede
- **Recursos:** Transações ACID, índices eficientes, suporte a JSON
- **Isolamento:** Cada instância tem seu banco independente
- **Backup:** Simples - copiar arquivo é suficiente

**❌ Limitações:**
- Concorrência limitada (mas adequada para 1 conexão WhatsApp)
- Sem recursos avançados de replicação
- Limitações de tamanho para datasets muito grandes

#### **PostgreSQL - Para Casos Específicos**

**✅ Vantagens:**
- **Concorrência:** Múltiplas conexões simultâneas
- **Recursos Avançados:** Índices complexos, views materializadas
- **Escalabilidade:** Backup avançado, replicação, sharding
- **Monitoramento:** Estatísticas detalhadas e logs estruturados
- **Integração:** Fácil integração com sistemas existentes

**❌ Desvantagens:**
- **Complexidade:** Requer servidor separado e configuração
- **Overhead:** ~50MB RAM + processo separado
- **Manutenção:** Backup, monitoramento e tuning necessários

### Análise para o Caso de Uso

#### **Dados Armazenados:**
```sql
-- Tabelas típicas do WhatsMeow
- devices (dispositivos conectados)
- sessions (sessões de autenticação)
- contacts (contatos)
- chat_settings (configurações de chat)
- message_handles (handles de mensagens)
- app_state_sync_keys (chaves de sincronização)
- privacy_tokens (tokens de privacidade)
```

#### **Padrão de Uso:**
- **Leitura intensiva:** Consultas de dispositivos, contatos
- **Escrita moderada:** Sessões, mensagens
- **Volume baixo:** 1 dispositivo por instância
- **Consultas simples:** CRUD básico

### Recomendação Técnica

#### **Para a Maioria dos Casos: SQLite**

```yaml
# docker-compose.yml otimizado
services:
  whatsapp:
    image: aldinokemal2104/go-whatsapp-web-multidevice
    volumes:
      - whatsapp_data:/app/storages  # SQLite isolado
    environment:
      DB_URI: "file:storages/whatsapp.db?_foreign_keys=on"
```

**Razões:**
- ✅ **Simplicidade:** Zero configuração
- ✅ **Performance:** Sem overhead de rede
- ✅ **Portabilidade:** Move com o container
- ✅ **Isolamento:** Cada instância tem seu banco
- ✅ **Recursos:** ACID, índices, JSON suficientes

#### **PostgreSQL Apenas Quando:**

1. **Integração com Sistema Existente**
   ```sql
   -- Se já existe PostgreSQL na infraestrutura
   -- Compartilhar dados com outras aplicações
   -- Backup centralizado
   ```

2. **Análise de Dados Complexa**
   ```sql
   -- Queries complexas de histórico
   -- Relatórios agregados
   -- Integração com BI tools
   ```

3. **Enterprise com Políticas Específicas**
   ```yaml
   # Se precisar de:
   - Failover automático
   - Replicação geográfica
   - Backup em tempo real
   - Auditoria avançada
   ```

### Configuração PostgreSQL

```yaml
# docker-compose.yml com PostgreSQL
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: whatsapp
      POSTGRES_USER: whatsapp_user
      POSTGRES_PASSWORD: whatsapp_pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  whatsapp:
    image: aldinokemal2104/go-whatsapp-web-multidevice
    environment:
      DB_URI: "postgres://whatsapp_user:whatsapp_pass@postgres:5432/whatsapp?sslmode=disable"
    depends_on:
      - postgres

volumes:
  postgres_data:
```

### Conclusão

**Para um projeto que suporta apenas 1 conexão WhatsApp por instância, SQLite é a escolha mais adequada.** O PostgreSQL seria overkill e adicionaria complexidade desnecessária sem benefícios significativos para o caso de uso específico.

A robustez do PostgreSQL é valiosa quando você tem múltiplas conexões simultâneas, consultas complexas ou necessidade de integração com outros sistemas - cenários que não se aplicam a este projeto.

---

## 📊 Casos de Uso

### 1. Bots de Atendimento
- **Descrição:** Automação de atendimento ao cliente
- **Funcionalidades:** Auto-reply, integração com CRM
- **Implementação:** Webhook + API REST

### 2. Notificações Empresariais
- **Descrição:** Envio de notificações automáticas
- **Funcionalidades:** Envio em massa, agendamento
- **Implementação:** Newsletter + API REST

### 3. Integração com Sistemas
- **Descrição:** Integração com sistemas existentes
- **Funcionalidades:** Webhook, API REST
- **Implementação:** MCP Server + REST API

### 4. Monitoramento
- **Descrição:** Monitoramento de eventos WhatsApp
- **Funcionalidades:** Webhook, logs
- **Implementação:** WebSocket + Webhook

---

## 🔍 Análise Técnica Detalhada

### Arquitetura de Conexão

#### Inicialização do Cliente
```go
// src/infrastructure/whatsapp/init.go
func InitWaCLI(ctx context.Context, storeContainer *sqlstore.Container) *whatsmeow.Client {
    // 1. Obtém apenas o primeiro dispositivo
    device, err := storeContainer.GetFirstDevice(ctx)
    
    // 2. Configura propriedades do dispositivo
    osName := fmt.Sprintf("%s %s", config.AppOs, config.AppVersion)
    store.DeviceProps.PlatformType = &config.AppPlatform
    store.DeviceProps.Os = &osName
    
    // 3. Cria cliente único
    cli = whatsmeow.NewClient(device, waLog.Stdout("Client", config.WhatsappLogLevel, true))
    cli.EnableAutoReconnect = true
    cli.AutoTrustIdentity = true
    
    // 4. Adiciona handler de eventos
    cli.AddEventHandler(func(rawEvt interface{}) {
        handler(ctx, rawEvt)
    })
    
    return cli
}
```

#### Gerenciamento de Eventos
```go
func handler(ctx context.Context, rawEvt interface{}) {
    switch evt := rawEvt.(type) {
    case *events.Message:
        handleMessage(ctx, evt)
    case *events.Receipt:
        handleReceipt(ctx, evt)
    case *events.Presence:
        handlePresence(ctx, evt)
    // ... outros eventos
    }
}
```

### Processamento de Mídia

#### Extração de Mídia
```go
func ExtractMedia(ctx context.Context, storageLocation string, mediaFile whatsmeow.DownloadableMessage) (extractedMedia ExtractedMedia, err error) {
    // 1. Download da mídia
    data, err := cli.Download(ctx, mediaFile)
    
    // 2. Validação de tamanho
    maxFileSize := config.WhatsappSettingMaxDownloadSize
    if int64(len(data)) > maxFileSize {
        return extractedMedia, fmt.Errorf("file size exceeds limit")
    }
    
    // 3. Determinação de extensão
    var extension string
    if ext, err := mime.ExtensionsByType(extractedMedia.MimeType); err == nil && len(ext) > 0 {
        extension = ext[0]
    }
    
    // 4. Salvamento em arquivo
    extractedMedia.MediaPath = fmt.Sprintf("%s/%d-%s%s", storageLocation, time.Now().Unix(), uuid.NewString(), extension)
    err = os.WriteFile(extractedMedia.MediaPath, data, 0600)
    
    return extractedMedia, nil
}
```

### Sistema de Webhook

#### Criação de Payload
```go
func createPayload(ctx context.Context, evt *events.Message) (map[string]interface{}, error) {
    body := make(map[string]interface{})
    
    // Informações básicas
    if from := evt.Info.SourceString(); from != "" {
        body["from"] = from
    }
    
    // Conteúdo da mensagem
    message := buildEventMessage(evt)
    if message.ID != "" {
        body["message"] = message
    }
    
    // Metadados
    if pushname := evt.Info.PushName; pushname != "" {
        body["pushname"] = pushname
    }
    
    // Timestamp
    if timestamp := evt.Info.Timestamp.Format(time.RFC3339); timestamp != "" {
        body["timestamp"] = timestamp
    }
    
    return body, nil
}
```

---

## 💡 Recomendações

### Para Desenvolvimento

#### 1. Múltiplas Instâncias
```bash
# Para múltiplas contas, use instâncias separadas
docker run -d --name whatsapp-account1 -p 3500:3000 -v whatsapp1:/app/storages whatsapp-api
docker run -d --name whatsapp-account2 -p 3501:3000 -v whatsapp2:/app/storages whatsapp-api
docker run -d --name whatsapp-account3 -p 3502:3000 -v whatsapp3:/app/storages whatsapp-api
```

#### 2. Load Balancer
```yaml
# docker-compose.yml com múltiplos serviços
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - whatsapp-account1
      - whatsapp-account2
      - whatsapp-account3
  
  whatsapp-account1:
    image: aldinokemal2104/go-whatsapp-web-multidevice
    volumes:
      - whatsapp1:/app/storages
  
  whatsapp-account2:
    image: aldinokemal2104/go-whatsapp-web-multidevice
    volumes:
      - whatsapp2:/app/storages
  
  whatsapp-account3:
    image: aldinokemal2104/go-whatsapp-web-multidevice
    volumes:
      - whatsapp3:/app/storages
```

### Para Produção

#### 1. Monitoramento
- Implementar health checks
- Configurar alertas de disponibilidade
- Monitorar uso de recursos

#### 2. Backup
- Backup automático dos volumes Docker
- Backup do banco de dados
- Versionamento de configurações

#### 3. Segurança
- Usar HTTPS para APIs
- Implementar rate limiting
- Configurar firewall adequado
- Rotacionar chaves de webhook

#### 4. Escalabilidade
- Usar orquestrador (Kubernetes/Docker Swarm)
- Implementar auto-scaling
- Configurar cache distribuído

### Para Manutenção

#### 1. Logs
```bash
# Configurar rotação de logs
docker run --log-driver=json-file --log-opt max-size=10m --log-opt max-file=3 whatsapp-api
```

#### 2. Updates
```bash
# Script de atualização
#!/bin/bash
docker-compose pull
docker-compose up -d --build
docker system prune -f
```

#### 3. Troubleshooting
```bash
# Verificar logs
docker logs whatsapp-container

# Verificar recursos
docker stats whatsapp-container

# Acessar container
docker exec -it whatsapp-container sh
```

---

## 📚 Recursos Adicionais

### Documentação
- [OpenAPI Specification](./docs/openapi.yaml)
- [WhatsMeow Documentation](https://github.com/tulir/whatsmeow)
- [Fiber Documentation](https://docs.gofiber.io/)

### Exemplos de Uso
- [SDK Examples](./docs/sdk/)
- [Webhook Examples](./docs/webhook/)
- [MCP Integration](./docs/mcp/)

### Comunidade
- [GitHub Issues](https://github.com/aldinokemal/go-whatsapp-web-multidevice/issues)
- [Discussions](https://github.com/aldinokemal/go-whatsapp-web-multidevice/discussions)
- [Patreon Support](https://www.patreon.com/c/aldinokemal)

---

## 📄 Licença

Este projeto está licenciado sob a licença incluída no arquivo [LICENCE.txt](./LICENCE.txt).

---

**Última atualização:** Dezembro 2024  
**Versão do documento:** 1.0  
**Autor:** Análise Técnica Completa 