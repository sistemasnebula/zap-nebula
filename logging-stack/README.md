# 📊 Stack de Logging - Loki + Grafana

Sistema de monitoramento de logs para containers WhatsApp.

## 🚀 Início Rápido

### 1. Iniciar Stack

```bash
# Na raiz do projeto
docker-compose -f docker-compose.logging.yml up -d
```

### 2. Verificar Status

```bash
docker-compose -f docker-compose.logging.yml ps
```

### 3. Acessar Grafana

- **URL**: http://localhost:3001
- **Usuário**: `admin`
- **Senha**: `admin`

### 4. Verificar Loki

- **URL**: http://localhost:3100
- **Health Check**: http://localhost:3100/ready

## 📋 Estrutura de Arquivos

```
logging-stack/
├── promtail-config.yml          # Configuração do Promtail
└── grafana-provisioning/
    └── datasources/
        └── loki.yml             # Data source automático do Grafana
```

## 🔍 Queries Úteis no Grafana

### Logs de Todos os Containers
```logql
{app="whatsapp-api"}
```

### Logs de uma Loja Específica
```logql
{loja="pizzariaromanelli"}
```

### Apenas Erros
```logql
{app="whatsapp-api"} |= "error"
```

### Erros de uma Loja
```logql
{loja="pizzariaromanelli"} |= "error"
```

### Webhooks Falhados
```logql
{app="whatsapp-api"} |= "webhook" |= "failed"
```

### Logs por Ambiente
```logql
{environment="production"}
```

## 🛠️ Comandos Úteis

### Ver Logs da Stack
```bash
# Todos os serviços
docker-compose -f docker-compose.logging.yml logs -f

# Apenas Loki
docker-compose -f docker-compose.logging.yml logs -f loki

# Apenas Grafana
docker-compose -f docker-compose.logging.yml logs -f grafana

# Apenas Promtail
docker-compose -f docker-compose.logging.yml logs -f promtail
```

### Parar Stack
```bash
docker-compose -f docker-compose.logging.yml down
```

### Parar e Remover Volumes
```bash
docker-compose -f docker-compose.logging.yml down -v
```

### Reiniciar Stack
```bash
docker-compose -f docker-compose.logging.yml restart
```

## 📊 Portas

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| Grafana | 3001 | Interface web |
| Loki | 3100 | API do Loki |
| Promtail | 9080 | API do Promtail (interno) |

## 🔧 Configuração

### Promtail

O Promtail está configurado para:
- ✅ Monitorar containers com label `app=whatsapp-api`
- ✅ Extrair labels: `loja`, `loja_id`, `app`, `environment`, `version`
- ✅ Parsear logs JSON do Docker
- ✅ Enviar para Loki

### Grafana

O Grafana está configurado com:
- ✅ Data source Loki pré-configurado
- ✅ Usuário admin/admin
- ✅ Sign-up desabilitado

## 🐛 Troubleshooting

### Promtail não está coletando logs

1. Verificar se containers têm label `app=whatsapp-api`:
```bash
docker ps --filter "label=app=whatsapp-api" --format "{{.Names}}"
```

2. Verificar logs do Promtail:
```bash
docker-compose -f docker-compose.logging.yml logs promtail
```

3. Verificar permissões do Docker socket:
```bash
ls -la /var/run/docker.sock
```

### Loki não está recebendo logs

1. Verificar saúde do Loki:
```bash
curl http://localhost:3100/ready
```

2. Verificar logs do Loki:
```bash
docker-compose -f docker-compose.logging.yml logs loki
```

### Grafana não conecta ao Loki

1. Verificar se Loki está rodando:
```bash
docker-compose -f docker-compose.logging.yml ps loki
```

2. Verificar data source no Grafana:
   - Configuration → Data Sources → Loki
   - URL deve ser: `http://loki:3100`

## 📈 Próximos Passos

1. Criar dashboards no Grafana
2. Configurar alertas
3. Adicionar mais labels aos containers
4. Configurar retenção de logs no Loki

## 📚 Referências

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Promtail Documentation](https://grafana.com/docs/loki/latest/clients/promtail/)

