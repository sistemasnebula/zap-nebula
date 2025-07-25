# Detecção de Desconexão de Dispositivo Remoto no WhatsApp

Este documento explica como o projeto detecta e lida com a remoção de um dispositivo pareado diretamente pelo aplicativo do WhatsApp no celular (logout remoto).

---

## 1. O que acontece quando o dispositivo é removido pelo app do WhatsApp?

Quando um dispositivo é removido pelo app do WhatsApp (logout remoto), a sessão correspondente é invalidada nos servidores da Meta. O cliente WhatsApp Web (e, por consequência, o cliente WhatsMeow usado neste projeto) perde a conexão e não pode mais enviar ou receber mensagens.

---

## 2. Como o projeto detecta essa remoção?

### a) Eventos de Desconexão (WhatsMeow)

O cliente WhatsMeow escuta eventos de conexão e desconexão. Quando o WhatsApp detecta que o dispositivo foi removido remotamente, ele envia um evento de logout/desconexão para o cliente.

- O handler de eventos do WhatsMeow (em `src/infrastructure/whatsapp/init.go`) captura esse evento.
- O cliente é desconectado automaticamente.
- O status de conexão (`cli.IsConnected()` e `cli.IsLoggedIn()`) passa a ser `false`.

### b) Status de Conexão na API

A rota `/app/status` retorna o status de conexão em tempo real, consultando o cliente WhatsMeow:

```go
func GetConnectionStatus() (isConnected bool, isLoggedIn bool, deviceID string) {
    if cli == nil {
        return false, false, ""
    }
    isConnected = cli.IsConnected()
    isLoggedIn = cli.IsLoggedIn()
    if cli.Store != nil && cli.Store.ID != nil {
        deviceID = cli.Store.ID.String()
    }
    return isConnected, isLoggedIn, deviceID
}
```

Se o dispositivo foi removido pelo app, `isConnected` e `isLoggedIn` serão `false`.

### c) Banco de Dados Local

A lista de dispositivos (`/app/devices`) **não é automaticamente atualizada** quando o dispositivo é removido remotamente. O registro do dispositivo ainda permanece no banco local até que seja feita uma limpeza (por exemplo, via logout manual ou rotina de sincronização).

---

## 3. Resumo do Comportamento

- **Status de conexão**: Sempre atualizado em tempo real via `/app/status` (reflete se o cliente está realmente conectado/logado).
- **Lista de dispositivos**: Pode ficar desatualizada se o dispositivo for removido remotamente, pois depende do banco local.
- **Ação recomendada**: Sempre consulte `/app/status` para saber se o dispositivo está realmente conectado. Se não estiver, pode ser necessário remover o registro localmente ou tentar reconectar.

---

## 4. Diferença entre /app/status e /app/devices

### **/app/status**
- **O que retorna**: Status de conexão em tempo real (`is_connected`, `is_logged_in`, `device_id`)
- **Limitação**: Apenas o ID do dispositivo, sem nome ou detalhes
- **Uso**: Verificar se há conexão ativa com WhatsApp

### **/app/devices**
- **O que retorna**: Lista de dispositivos com informações completas (`name`, `device`)
- **Vantagem**: Informações detalhadas de todos os dispositivos pareados
- **Uso**: Obter nomes e detalhes dos dispositivos

### **Estratégia Recomendada**
Para obter informações completas sobre o dispositivo conectado:

1. **Primeiro**: Chame `/app/status` para verificar se há conexão ativa
2. **Depois**: Se `is_connected: true`, chame `/app/devices` para obter o nome do dispositivo

**Exemplo de fluxo:**
```bash
# 1. Verificar status
GET /app/status
# Resposta: {"is_connected": true, "device_id": "1234567890abcdef"}

# 2. Obter detalhes do dispositivo
GET /app/devices  
# Resposta: [{"name": "Meu WhatsApp", "device": "1234567890abcdef"}]
```

**Conclusão**: Para saber se existe um dispositivo conectado, use `/app/status`. Para obter detalhes como nome do dispositivo, use `/app/devices`.

---

## 5. Fluxo típico após remoção remota

1. Dispositivo é removido pelo app do WhatsApp.
2. Cliente WhatsMeow recebe evento de desconexão.
3. `/app/status` passa a retornar `isConnected: false`, `isLoggedIn: false`.
4. `/app/devices` ainda mostra o dispositivo até que seja feita uma limpeza manual/local.

---

## 6. Observações

- O projeto sabe que o dispositivo não está mais conectado porque o cliente WhatsMeow detecta a desconexão automaticamente e o status de conexão é atualizado.
- A lista de dispositivos só é atualizada se houver uma rotina de limpeza ou sincronização manual.
- Para automatizar a remoção do dispositivo do banco local após detectar o logout remoto, pode-se implementar uma rotina que limpe o banco quando o status de conexão for perdido. 