# 📈 PLANO DE AÇÃO: Multi-Dispositivo por Instância (WhatsApp API)

## 1. Objetivo
Permitir que uma única instância do container gerencie múltiplos dispositivos WhatsApp pareados simultaneamente, utilizando banco PostgreSQL compartilhado.

---

## 2. Mapeamento de Mudanças Necessárias

### A. Refatoração do Core
- [ ] Substituir variável global `cli` por um mapa/estrutura thread-safe: `map[DeviceID]*whatsmeow.Client`
- [ ] Refatorar inicialização para carregar todos os devices do banco e criar um cliente para cada um
- [ ] Implementar gerenciamento de ciclo de vida (conectar, desconectar, reconectar) para cada cliente

### B. API Multi-tenant
- [ ] Adicionar parâmetro `device_id` em todas as rotas relevantes (envio, consulta, etc)
- [ ] Refatorar handlers para buscar o cliente correto pelo `device_id` antes de executar ações

### C. Gerenciamento de Sessões
- [ ] Criar endpoints para login/logout de devices (adicionar/remover clientes em tempo real)
- [ ] Implementar inicialização automática de todos os devices do banco ao subir a instância

### D. Webhook e Eventos
- [ ] Incluir `device_id` em todos os eventos enviados ao webhook
- [ ] (Opcional) Permitir configuração de webhooks diferentes por device

### E. Banco de Dados
- [ ] Garantir que o banco PostgreSQL está configurado e acessível para múltiplos devices
- [ ] (Opcional) Criar índices para otimizar consultas por device

### F. Testes e Documentação
- [ ] Testar concorrência, race conditions, reconexão, envio/recebimento simultâneo
- [ ] Atualizar documentação da API, exemplos de uso e instruções de deploy

---

## 3. Checklist de Tarefas

### Estrutura de Código
- [ ] Criar estrutura global: `var clients sync.Map // map[string]*whatsmeow.Client`
- [ ] Refatorar inicialização:
    - Buscar todos os devices do banco
    - Para cada device, criar e conectar um cliente
- [ ] Refatorar shutdown para desconectar todos os clientes

### Handlers/API
- [ ] Adicionar `device_id` como parâmetro obrigatório nas rotas
- [ ] Buscar o cliente correto em cada handler:
    ```go
    cli, ok := clients.Load(deviceID)
    if !ok { /* retornar erro */ }
    ```
- [ ] Adaptar webhooks para incluir `device_id` no payload

### Gerenciamento de Sessões
- [ ] Endpoint: `/device/login` para adicionar novo device
- [ ] Endpoint: `/device/logout` para remover/desconectar device
- [ ] Endpoint: `/device/list` para listar devices ativos

### Banco de Dados
- [ ] Configurar `DB_URI` para PostgreSQL
- [ ] Testar concorrência com múltiplos devices

### Testes
- [ ] Testar envio/recebimento simultâneo em múltiplos devices
- [ ] Testar reconexão automática
- [ ] Testar webhooks para múltiplos devices

### Documentação
- [ ] Atualizar README e documentação de API
- [ ] Adicionar exemplos de uso multi-device

---

## 4. Exemplos de Código

### Estrutura Global
```go
import "sync"

var clients sync.Map // map[string]*whatsmeow.Client

func InitAllDevices(ctx context.Context, storeContainer *sqlstore.Container) {
    devices, _ := storeContainer.GetAllDevices(ctx)
    for _, device := range devices {
        cli := whatsmeow.NewClient(device, ...)
        clients.Store(device.ID.String(), cli)
        go cli.Connect()
    }
}
```

### Handler de Envio de Mensagem
```go
func SendMessageHandler(c *fiber.Ctx) error {
    deviceID := c.Query("device_id")
    value, ok := clients.Load(deviceID)
    if !ok {
        return c.Status(404).JSON(fiber.Map{"error": "Device not found"})
    }
    cli := value.(*whatsmeow.Client)
    // ... enviar mensagem usando cli ...
}
```

### Webhook com DeviceID
```go
func handleWebhookForward(ctx context.Context, evt *events.Message, deviceID string) {
    payload := map[string]interface{}{
        "device_id": deviceID,
        // ... outros campos ...
    }
    // ... enviar para webhook ...
}
```

### Endpoints de Gerenciamento
```go
// POST /device/login
// POST /device/logout
// GET  /device/list
```

---

## 5. Exemplo de Configuração PostgreSQL

```yaml
environment:
  DB_URI: "postgres://user:pass@host:5432/whatsapp?sslmode=disable"
```

---

## 6. Dicas Finais
- Use `sync.Map` ou `map` com mutex para thread safety.
- Sempre valide o `device_id` recebido nas rotas.
- Monitore o consumo de recursos (RAM/CPU) conforme aumenta o número de devices.
- Considere limites de conexões simultâneas do PostgreSQL.

---

## 7. Diagrama Resumido

```mermaid
graph TD
    subgraph Instância Docker
        DB[(PostgreSQL)]
        C1[Cliente WhatsApp 1]
        C2[Cliente WhatsApp 2]
        C3[Cliente WhatsApp 3]
        API[API REST]
        WEBHOOK[Webhook]
    end
    API -- device_id --> C1
    API -- device_id --> C2
    API -- device_id --> C3
    C1 -- eventos --> WEBHOOK
    C2 -- eventos --> WEBHOOK
    C3 -- eventos --> WEBHOOK
    C1 -- sessão --> DB
    C2 -- sessão --> DB
    C3 -- sessão --> DB
```

---

## 8. Resumo
- **Esforço considerável**: exige refatoração do core, APIs, eventos e testes.
- **Vantagem**: maior escalabilidade, menos containers, melhor uso do PostgreSQL.
- **Risco**: aumento de complexidade e necessidade de testes robustos.

Avalie se o ganho operacional compensa o esforço de desenvolvimento neste momento! 