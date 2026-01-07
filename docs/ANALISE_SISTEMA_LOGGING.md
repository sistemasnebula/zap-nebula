# 📊 Análise do Sistema de Logging

Este documento apresenta uma análise completa do sistema de logging implementado no projeto, identificando onde os logs são gerados, como são configurados e se há escrita de arquivos de log.

## 📋 Resumo Executivo

**Conclusão**: O projeto **NÃO possui um serviço de log que escreva em arquivos de log tradicionais**. Todos os logs são direcionados para **stdout/stderr** e podem ser capturados pelo Docker ou sistema de orquestração.

### ✅ O que foi encontrado:

1. **Logs da aplicação**: Usam `logrus` → stdout/stderr
2. **Logs do WhatsApp (whatsmeow)**: Usam `waLog.Stdout` → stdout
3. **Arquivos de History Sync**: JSON files escritos em `storages/` (não são logs, são dados)
4. **Nenhum arquivo de log tradicional**: Não há escrita de `.log` ou arquivos de log rotativos

---

## 🔍 Análise Detalhada

### 1. Sistema de Logging da Aplicação (logrus)

#### Localização do Código
- **Arquivo**: `src/cmd/root.go`
- **Biblioteca**: `github.com/sirupsen/logrus`

#### Configuração

```go
// src/cmd/root.go:282-285
func initApp() {
    if config.AppDebug {
        config.WhatsappLogLevel = "DEBUG"
        logrus.SetLevel(logrus.DebugLevel)
    }
    // ...
}
```

#### Características

- ✅ **Output**: stdout/stderr (padrão do logrus)
- ✅ **Níveis**: DEBUG, INFO, WARN, ERROR, FATAL
- ✅ **Configuração**: Controlada por `APP_DEBUG` (variável de ambiente)
- ❌ **Arquivo de log**: Não há configuração para escrever em arquivo

#### Exemplos de Uso

```go
// src/cmd/root.go
logrus.Errorln(err)
logrus.Fatalf("failed to initialize chat storage: %v", err)

// src/cmd/rest.go
logrus.Fatalln("Basic auth is not valid, please this following format <user>:<secret>")
logrus.Fatalln("Failed to start: ", err.Error())
```

---

### 2. Sistema de Logging do WhatsApp (whatsmeow)

#### Localização do Código
- **Arquivo**: `src/infrastructure/whatsapp/init.go`
- **Biblioteca**: `go.mau.fi/whatsmeow/util/log`

#### Configuração

```go
// src/infrastructure/whatsapp/init.go:105
baseLogger := waLog.Stdout("Client", config.WhatsappLogLevel, true)
client := whatsmeow.NewClient(device, newFilteredLogger(baseLogger))
```

#### Características

- ✅ **Output**: stdout (via `waLog.Stdout`)
- ✅ **Níveis**: Configurável via `WHATSAPP_LOG_LEVEL` (padrão: "ERROR")
- ✅ **Filtro**: Wrapper customizado para reduzir ruído de reconexão
- ❌ **Arquivo de log**: Não há configuração para escrever em arquivo

#### Logger Filtrado

O projeto implementa um logger filtrado para reduzir ruído de erros de reconexão:

```go
// src/infrastructure/whatsapp/logger.go
type filteredLogger struct {
    base waLog.Logger
}

// Filtra erros de EOF do websocket que são esperados durante reconexão
func (l *filteredLogger) Errorf(msg string, args ...interface{}) {
    formatted := fmt.Sprintf(msg, args...)
    if isWebsocketEOFError(formatted) {
        l.base.Debugf("WebSocket closed after idle; auto-reconnecting...")
        return
    }
    l.base.Errorf(msg, args...)
}
```

---

### 3. Arquivos de History Sync (JSON)

#### Localização do Código
- **Arquivo**: `src/infrastructure/whatsapp/history_sync.go`

#### O que são

**NÃO são arquivos de log**, mas sim **arquivos de dados** contendo histórico de sincronização do WhatsApp.

#### Características

```go
// src/infrastructure/whatsapp/history_sync.go:28-34
fileName := fmt.Sprintf("%s/history-%d-%s-%d-%s.json",
    config.PathStorages,  // "storages"
    startupTime,
    client.Store.ID.String(),
    id,
    evt.Data.SyncType.String(),
)
```

- ✅ **Localização**: `storages/history-{timestamp}-{device_id}-{id}-{sync_type}.json`
- ✅ **Formato**: JSON indentado
- ✅ **Permissões**: 0600 (apenas leitura/escrita pelo proprietário)
- ⚠️ **Propósito**: Armazenar dados de sincronização, não logs

#### Exemplo de Arquivo Gerado

```
storages/history-1234567890-628123456789@s.whatsapp.net-1-INITIAL_BOOTSTRAP.json
```

---

## 📁 Estrutura de Arquivos Gerados

### Arquivos que são escritos no disco:

```
/app/
├── database/                    # Banco de dados SQLite
│   ├── whatsapp.db
│   └── chatstorage.db
│
├── storages/                    # Arquivos de dados e mídia
│   ├── history-*.json          # ⚠️ History sync (dados, não logs)
│   ├── media/                  # Mídia baixada
│   └── temp/                   # Arquivos temporários
│
└── statics/                     # Arquivos estáticos
    ├── qrcode/                 # QR codes gerados
    ├── senditems/              # Itens enviados
    └── media/                  # Mídia estática
```

### ❌ Arquivos de log que NÃO existem:

- `logs/app.log`
- `logs/whatsapp.log`
- `logs/error.log`
- Qualquer arquivo `.log` no projeto

---

## 🔧 Configuração de Logging

### Variáveis de Ambiente

| Variável | Descrição | Padrão | Exemplo |
|----------|-----------|--------|---------|
| `APP_DEBUG` | Habilita logs de debug | `false` | `APP_DEBUG=true` |
| `WHATSAPP_LOG_LEVEL` | Nível de log do WhatsApp | `ERROR` | `WHATSAPP_LOG_LEVEL=DEBUG` |

### Níveis de Log Disponíveis

Para `WHATSAPP_LOG_LEVEL`:
- `DEBUG` - Todos os logs (muito verboso)
- `INFO` - Informações gerais
- `WARN` - Avisos
- `ERROR` - Apenas erros (padrão)

Para `logrus` (quando `APP_DEBUG=true`):
- `DebugLevel` - Todos os logs
- `InfoLevel` - Informações
- `WarnLevel` - Avisos
- `ErrorLevel` - Erros
- `FatalLevel` - Erros fatais

---

## 🐳 Captura de Logs no Docker

Como os logs são direcionados para stdout/stderr, eles podem ser capturados pelo Docker:

### 1. Visualizar Logs do Container

```bash
# Logs em tempo real
docker logs -f whatsapp

# Últimas 100 linhas
docker logs --tail 100 whatsapp

# Logs com timestamp
docker logs -t whatsapp
```

### 2. Redirecionar Logs para Arquivo (Docker)

```yaml
# docker-compose.yml
services:
  whatsapp:
    # ... outras configurações ...
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

Isso criará arquivos de log em:
```
/var/lib/docker/containers/{container-id}/{container-id}-json.log
```

### 3. Usar Driver de Log Externo

```yaml
services:
  whatsapp:
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://localhost:514"
```

---

## 📊 Comparação: Logs vs Dados

| Tipo | Localização | Propósito | É Log? |
|------|------------|-----------|--------|
| **Logs da aplicação** | stdout/stderr | Informações de execução | ✅ Sim |
| **Logs do WhatsApp** | stdout | Informações do cliente | ✅ Sim |
| **History Sync JSON** | `storages/` | Dados de sincronização | ❌ Não |
| **QR Codes** | `statics/qrcode/` | Imagens de QR | ❌ Não |
| **Mídia** | `storages/media/` | Arquivos de mídia | ❌ Não |

---

## ⚠️ Considerações de Segurança

### 1. History Sync Files

Os arquivos `history-*.json` contêm **dados sensíveis**:
- ✅ Permissões restritas (0600)
- ✅ Localizados em `storages/` (volume Docker)
- ⚠️ **Recomendação**: Não expor via volume público

### 2. Logs no Docker

- ✅ Logs não são escritos em arquivos dentro do container
- ✅ Podem ser capturados pelo Docker daemon
- ⚠️ **Recomendação**: Configurar rotação de logs no Docker

---

## 🔄 Recomendações

### Se precisar de arquivos de log:

#### Opção 1: Configurar Docker Logging Driver

```yaml
# docker-compose.yml
services:
  whatsapp:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
        labels: "production"
```

#### Opção 2: Implementar File Logger (Código)

Se necessário, pode-se adicionar um file logger customizado:

```go
// Exemplo (não implementado no código atual)
import (
    "os"
    "github.com/sirupsen/logrus"
)

func initFileLogger(logPath string) {
    file, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
    if err == nil {
        logrus.SetOutput(file)
    } else {
        logrus.Info("Failed to log to file, using default stderr")
    }
}
```

#### Opção 3: Usar Sistema de Logging Centralizado

- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Loki** (Grafana)
- **Fluentd/Fluent Bit**
- **Splunk**

---

## 📝 Conclusão

### ✅ Confirmação

**NÃO existe um serviço de log que escreva em arquivos de log tradicionais no código atual.**

### 📊 Resumo

1. **Logs da aplicação**: stdout/stderr via `logrus`
2. **Logs do WhatsApp**: stdout via `waLog.Stdout`
3. **Arquivos JSON**: History sync (dados, não logs)
4. **Captura de logs**: Via Docker ou sistema de orquestração

### 🎯 Próximos Passos (se necessário)

Se precisar de arquivos de log:
1. Configurar Docker logging driver (recomendado)
2. Implementar file logger customizado (código)
3. Integrar com sistema de logging centralizado (produção)

---

## 📚 Referências

- [Logrus Documentation](https://github.com/sirupsen/logrus)
- [Docker Logging Drivers](https://docs.docker.com/config/containers/logging/)
- [WhatsApp Meow Library](https://github.com/tulir/whatsmeow)

