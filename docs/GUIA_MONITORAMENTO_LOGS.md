# 📊 Guia de Monitoramento de Logs para Múltiplos Containers

Este guia apresenta soluções práticas para monitorar logs de múltiplos containers WhatsApp de forma centralizada e eficiente.

## 📋 Situação Atual

- **50+ containers** rodando a mesma imagem
- **Mesma aplicação** (WhatsApp API)
- **Logs em stdout/stderr** (sem arquivos de log)
- **Necessidade**: Monitoramento centralizado e eficiente

---

## 🎯 Soluções Recomendadas

### Opção 1: Loki + Grafana (Recomendada - Leve e Eficiente)

**Vantagens:**
- ✅ Leve e rápido
- ✅ Fácil de configurar
- ✅ Interface visual (Grafana)
- ✅ Filtros por container/loja
- ✅ Baixo consumo de recursos

### Opção 2: Docker Logging Driver (JSON File)

**Vantagens:**
- ✅ Simples (sem containers adicionais)
- ✅ Logs em arquivos locais
- ✅ Rotação automática

### Opção 3: ELK Stack (Elasticsearch + Logstash + Kibana)

**Vantagens:**
- ✅ Muito robusto
- ✅ Análise avançada
- ✅ Escalável
- ⚠️ Mais pesado (requer mais recursos)

---

## 🚀 Solução 1: Loki + Grafana (Recomendada)

### Arquitetura

```
Containers WhatsApp → Docker Logging Driver → Loki → Grafana
```

### Passo 1: Configurar Docker Logging Driver

#### Opção A: Configuração Global (Docker Daemon)

Edite `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "labels": "production"
  }
}
```

Reinicie o Docker:
```bash
sudo systemctl restart docker
```

#### Opção B: Configuração por Container (Recomendado)

Atualize o código C# que cria os containers:

```csharp
var containerCreateParameters = new CreateContainerParameters
{
    Name = app.NomeContainer,
    Image = app.NomeImagem,
    // ... outras configurações ...
    
    // Adicionar labels para identificação
    Labels = new Dictionary<string, string>
    {
        { "com.centurylinklabs.watchtower.enable", "false" },
        { "app", "whatsapp-api" },
        { "loja", app.LojaNome ?? app.LojaAlias },
        { "loja-id", app.LojaId.ToString() },
        { "environment", "production" }
    },
    
    // Configurar logging driver
    HostConfig = new HostConfig
    {
        // ... outras configurações ...
        LogConfig = new LogConfig
        {
            Type = "json-file",
            Config = new Dictionary<string, string>
            {
                { "max-size", "10m" },
                { "max-file", "3" },
                { "labels", "app,loja,loja-id,environment" }
            }
        }
    }
};
```

### Passo 2: Instalar Loki + Grafana

Crie `docker-compose.logging.yml`:

```yaml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - loki-data:/loki
    networks:
      - logging

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./promtail-config.yml:/etc/promtail/config.yml:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - logging
    depends_on:
      - loki

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - logging
    depends_on:
      - loki

volumes:
  loki-data:
  grafana-data:

networks:
  logging:
    driver: bridge
```

### Passo 3: Configurar Promtail

Crie `promtail-config.yml`:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*-json.log
    
    # Extrair labels do Docker
    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            attrs: attrs
            tag: attrs.tag
      
      - json:
          expressions:
            container_name: attrs.name
            container_id: attrs.id
            image: attrs.image
            labels: attrs.labels
          source: attrs
      
      - labels:
          stream:
          container_name:
          container_id:
          image:
      
      # Extrair labels customizados
      - json:
          expressions:
            loja: labels.loja
            loja_id: labels.loja-id
            app: labels.app
          source: labels
      
      - labels:
          loja:
          loja_id:
          app:
      
      # Formatar mensagem
      - output:
          source: output
```

### Passo 4: Iniciar Stack de Logging

```bash
# Iniciar Loki + Grafana
docker-compose -f docker-compose.logging.yml up -d

# Verificar status
docker-compose -f docker-compose.logging.yml ps
```

### Passo 5: Configurar Grafana

1. Acesse: `http://localhost:3001`
2. Login: `admin` / `admin`
3. Adicione Loki como Data Source:
   - Configuration → Data Sources → Add data source
   - Selecione "Loki"
   - URL: `http://loki:3100`
   - Save & Test

4. Crie Dashboard:

**Query de exemplo:**
```logql
{app="whatsapp-api"} |= "error"
```

**Filtros úteis:**
```logql
# Logs de uma loja específica
{loja="pizzariaromanelli"}

# Logs de erro de todas as lojas
{app="whatsapp-api"} |= "error"

# Logs de uma loja com erro
{loja="pizzariaromanelli"} |= "error"

# Logs por container
{container_name="pizzariaromanelli"}

# Logs de webhook
{app="whatsapp-api"} |= "webhook"
```

---

## 🗂️ Solução 2: Docker Logging Driver (JSON File)

### Configuração Simples

Atualize o código C# para adicionar logging:

```csharp
var containerCreateParameters = new CreateContainerParameters
{
    // ... outras configurações ...
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
                { "labels", "app,loja,loja-id" }
            }
        }
    }
};
```

### Script para Visualizar Logs

Crie `scripts/view-logs.sh`:

```bash
#!/bin/bash

# Função para ver logs de uma loja específica
view_logs() {
    local loja=$1
    local container_name=$(docker ps --filter "name=$loja" --format "{{.Names}}" | head -1)
    
    if [ -z "$container_name" ]; then
        echo "Container não encontrado para: $loja"
        return 1
    fi
    
    echo "=== Logs de $container_name ==="
    docker logs --tail 100 -f "$container_name"
}

# Função para ver logs de erro de todas as lojas
view_errors() {
    echo "=== Logs de Erro (últimas 50 linhas) ==="
    docker ps --filter "ancestor=nebulasistemas/nebula-zap-api:prd-8.1.1" --format "{{.Names}}" | while read container; do
        echo "--- $container ---"
        docker logs --tail 50 "$container" 2>&1 | grep -i "error" || echo "Sem erros"
        echo ""
    done
}

# Função para buscar em todos os containers
search_logs() {
    local search_term=$1
    echo "=== Buscando '$search_term' em todos os containers ==="
    
    docker ps --filter "ancestor=nebulasistemas/nebula-zap-api:prd-8.1.1" --format "{{.Names}}" | while read container; do
        result=$(docker logs "$container" 2>&1 | grep -i "$search_term" | tail -5)
        if [ ! -z "$result" ]; then
            echo "--- $container ---"
            echo "$result"
            echo ""
        fi
    done
}

# Menu
case "$1" in
    view)
        view_logs "$2"
        ;;
    errors)
        view_errors
        ;;
    search)
        search_logs "$2"
        ;;
    *)
        echo "Uso: $0 {view|errors|search} [argumento]"
        echo ""
        echo "Exemplos:"
        echo "  $0 view pizzariaromanelli"
        echo "  $0 errors"
        echo "  $0 search 'webhook failed'"
        exit 1
        ;;
esac
```

Uso:
```bash
chmod +x scripts/view-logs.sh

# Ver logs de uma loja
./scripts/view-logs.sh view pizzariaromanelli

# Ver erros de todas as lojas
./scripts/view-logs.sh errors

# Buscar termo em todos os containers
./scripts/view-logs.sh search "webhook failed"
```

---

## 📈 Solução 3: ELK Stack (Avançada)

### docker-compose.elk.yml

```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    networks:
      - logging

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    container_name: logstash
    volumes:
      - ./logstash-config.conf:/usr/share/logstash/pipeline/logstash.conf:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    ports:
      - "5044:5044"
    networks:
      - logging
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    networks:
      - logging
    depends_on:
      - elasticsearch

volumes:
  elasticsearch-data:

networks:
  logging:
    driver: bridge
```

### logstash-config.conf

```ruby
input {
  file {
    path => "/var/lib/docker/containers/*/*-json.log"
    codec => json
    type => "docker"
  }
}

filter {
  if [type] == "docker" {
    json {
      source => "message"
    }
    
    # Extrair container name do path
    grok {
      match => { "path" => "/var/lib/docker/containers/%{DATA:container_id}/%{DATA:log_file}" }
    }
    
    # Adicionar campos úteis
    mutate {
      add_field => { "log_level" => "%{level}" }
      add_field => { "container_id" => "%{container_id}" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "docker-logs-%{+YYYY.MM.dd}"
  }
}
```

---

## 🔧 Implementação Prática: Atualizar Código C#

### Classe Atualizada: CreateContainerService

```csharp
using ContainerDocker.Business.BaseService;
using ContainerDocker.Domain.Entities;
using Docker.DotNet;
using Docker.DotNet.Models;
using Microsoft.Extensions.Logging;
using System.Net.NetworkInformation;

namespace ContainerDocker.Business.CreateService
{
    internal class CreateContainerService : ContainerBaseService
    {
        private readonly ILogger<CreateContainerService> _logger;

        public CreateContainerService(ILogger<CreateContainerService> logger)
        {
            _logger = logger;
        }

        public async Task ExecuteAsync(ServidorWhatsApp app)
        {
            try
            {
                // ... código existente de portas, volumes, etc. ...

                using var client = new DockerClientConfiguration(new Uri(GetLocalDocker())).CreateClient();

                var storeName = (string.IsNullOrWhiteSpace(app.LojaNome) ? app.LojaAlias : app.LojaNome)
                    .ToLower().RemoveSpecialCharacter();

                var volumes = new List<string>
                {
                    $"/nebula/volume-whatsapp/{_enviroment}{storeName}/statics:/app/statics",
                    $"/nebula/volume-whatsapp/{_enviroment}{storeName}/storages:/app/storages",
                    $"/nebula/volume-whatsapp/{_enviroment}{storeName}/database:/app/database",
                };

                var hostConfig = new HostConfig
                {
                    RestartPolicy = new RestartPolicy { Name = RestartPolicyKind.Always },
                    Binds = volumes,
                    PortBindings = new Dictionary<string, IList<PortBinding>>
                    {
                        {
                            $"{internalPort}/tcp", new List<PortBinding>
                            {
                                new PortBinding
                                {
                                    HostIP = "127.0.0.1",
                                    HostPort = app.Porta.ToString()
                                }
                            }
                        }
                    },
                    // ✅ ADICIONAR: Configuração de Logging
                    LogConfig = new LogConfig
                    {
                        Type = "json-file",
                        Config = new Dictionary<string, string>
                        {
                            { "max-size", "10m" },      // Tamanho máximo por arquivo
                            { "max-file", "5" },         // Número máximo de arquivos
                            { "labels", "app,loja,loja-id,environment" } // Labels para filtro
                        }
                    }
                };

                var envVariables = new Dictionary<string, string>
                {
                    { "API_WEBHOOK", $@"{callBack}{app.LojaId}" },
                    { "WHATSAPP_WEBHOOK", $@"{callBack}{app.LojaId}" },
                    { "DB_URI", "file:database/whatsapp.db?_foreign_keys=on" },
                    { "APP_BASIC_AUTH", $"{app.UsuarioWhatsApp}:{app.SenhaWhatsApp}" }
                };

                var containerCreateParameters = new CreateContainerParameters
                {
                    Name = app.NomeContainer,
                    Cmd = new[] { "rest", "--port=3000", "--debug=false", "--os=NS-Zap", "--account-validation=false", $"--webhook={callBack}{app.LojaId}" },
                    Hostname = app.NomeContainer,
                    Image = app.NomeImagem,
                    Env = envVariables.Select(kv => $"{kv.Key}={kv.Value}").ToList(),
                    ExposedPorts = new Dictionary<string, EmptyStruct>
                    {
                        { $"{internalPort}/tcp", default }
                    },
                    Volumes = new Dictionary<string, EmptyStruct>(),
                    HostConfig = hostConfig,
                    // ✅ ADICIONAR: Labels para identificação
                    Labels = new Dictionary<string, string>
                    {
                        { "com.centurylinklabs.watchtower.enable", "false" },
                        { "app", "whatsapp-api" },
                        { "loja", app.LojaNome ?? app.LojaAlias },
                        { "loja-id", app.LojaId.ToString() },
                        { "environment", _enviroment },
                        { "version", "8.1.1" }
                    },
                    // ... resto das configurações ...
                };

                var response = await client.Containers.CreateContainerAsync(containerCreateParameters);
                await client.Containers.StartContainerAsync(response.ID, new ContainerStartParameters());

                // ... resto do código ...
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"CreateContainerService Error - {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
                throw;
            }
        }
    }
}
```

---

## 📊 Dashboard Grafana - Exemplos

### 1. Visão Geral de Todos os Containers

```logql
# Total de logs por loja
sum by (loja) (count_over_time({app="whatsapp-api"}[5m]))
```

### 2. Logs de Erro por Loja

```logql
# Erros por loja
sum by (loja) (count_over_time({app="whatsapp-api"} |= "error" [5m]))
```

### 3. Top 10 Containers com Mais Logs

```logql
topk(10, sum by (container_name) (count_over_time({app="whatsapp-api"}[1h])))
```

### 4. Logs de Webhook

```logql
# Webhooks falhados
{app="whatsapp-api"} |= "webhook" |= "failed"
```

---

## 🚀 Quick Start (Recomendado)

### 1. Instalar Loki + Grafana

```bash
# Criar diretório
mkdir -p ~/logging-stack
cd ~/logging-stack

# Criar docker-compose.logging.yml (copiar conteúdo acima)
# Criar promtail-config.yml (copiar conteúdo acima)

# Iniciar
docker-compose -f docker-compose.logging.yml up -d
```

### 2. Atualizar Código C#

Adicionar `LogConfig` e `Labels` no `CreateContainerService` (código acima).

### 3. Recriar Containers (Opcional)

Se quiser aplicar logging aos containers existentes:

```bash
# Script para atualizar containers existentes
docker ps --filter "ancestor=nebulasistemas/nebula-zap-api:prd-8.1.1" --format "{{.ID}}" | while read id; do
    docker update --log-opt max-size=10m --log-opt max-file=5 $id
done
```

### 4. Acessar Grafana

- URL: `http://localhost:3001`
- User: `admin`
- Pass: `admin`

---

## 📝 Checklist de Implementação

- [ ] Instalar Loki + Grafana
- [ ] Configurar Promtail
- [ ] Atualizar código C# com LogConfig e Labels
- [ ] Recriar containers (ou atualizar existentes)
- [ ] Configurar Grafana Data Source
- [ ] Criar dashboards
- [ ] Configurar alertas (opcional)

---

## 🔔 Alertas (Opcional)

Configure alertas no Grafana para:
- Erros críticos
- Containers offline
- Webhook failures
- Alto volume de logs de erro

---

## 📚 Referências

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Docker Logging Drivers](https://docs.docker.com/config/containers/logging/)

