# 🚀 Quick Start: Monitoramento de Logs

Guia rápido para implementar monitoramento de logs para seus 50+ containers WhatsApp.

## ⚡ Solução Rápida (5 minutos)

### 1. Instalar Stack de Logging

```bash
cd /caminho/do/projeto
./scripts/setup-logging.sh install
./scripts/setup-logging.sh start
```

### 2. Atualizar Código C# (CreateContainerService)

Adicione estas duas seções no `CreateContainerParameters`:

```csharp
// 1. Labels para identificação
Labels = new Dictionary<string, string>
{
    { "com.centurylinklabs.watchtower.enable", "false" },
    { "app", "whatsapp-api" },
    { "loja", app.LojaNome ?? app.LojaAlias },
    { "loja-id", app.LojaId.ToString() },
    { "environment", _enviroment }
},

// 2. Configuração de Logging
HostConfig = new HostConfig
{
    // ... outras configurações ...
    LogConfig = new LogConfig
    {
        Type = "json-file",
        Config = new Dictionary<string, string>
        {
            { "max-size", "10m" },
            { "max-file", "5" },
            { "labels", "app,loja,loja-id,environment" }
        }
    }
}
```

### 3. Acessar Grafana

- URL: http://localhost:3001
- User: `admin`
- Pass: `admin`

### 4. Configurar Data Source no Grafana

1. Configuration → Data Sources → Add data source
2. Selecione "Loki"
3. URL: `http://loki:3100`
4. Save & Test

### 5. Criar Primeira Query

No Grafana, Explore → Loki:

```logql
{app="whatsapp-api"}
```

## 📊 Queries Úteis

```logql
# Todos os logs
{app="whatsapp-api"}

# Logs de uma loja específica
{loja="pizzariaromanelli"}

# Apenas erros
{app="whatsapp-api"} |= "error"

# Erros de uma loja
{loja="pizzariaromanelli"} |= "error"

# Webhooks falhados
{app="whatsapp-api"} |= "webhook" |= "failed"
```

## 🛠️ Scripts Úteis

```bash
# Ver logs de uma loja
./scripts/view-logs.sh view pizzariaromanelli

# Ver erros de todas as lojas
./scripts/view-logs.sh errors

# Buscar termo em todos os containers
./scripts/view-logs.sh search "webhook failed"

# Listar containers
./scripts/view-logs.sh list

# Status da stack
./scripts/setup-logging.sh status
```

## 📝 Checklist

- [ ] Instalar stack (setup-logging.sh install)
- [ ] Iniciar stack (setup-logging.sh start)
- [ ] Atualizar código C# com LogConfig e Labels
- [ ] Recriar containers (ou atualizar existentes)
- [ ] Configurar Grafana Data Source
- [ ] Testar queries

## 🔄 Atualizar Containers Existentes

Se quiser aplicar logging aos containers já rodando:

```bash
# Atualizar todos os containers existentes
docker ps --filter "ancestor=nebulasistemas/nebula-zap-api:prd-8.1.1" --format "{{.ID}}" | while read id; do
    docker update --log-opt max-size=10m --log-opt max-file=5 $id
done
```

**Nota**: Labels só podem ser adicionados na criação do container. Para adicionar labels, será necessário recriar os containers.

## 📚 Documentação Completa

Para mais detalhes, consulte: [GUIA_MONITORAMENTO_LOGS.md](./GUIA_MONITORAMENTO_LOGS.md)

