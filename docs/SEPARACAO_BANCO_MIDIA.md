# 🗄️ Separação de Banco de Dados e Arquivos de Mídia

## 🎯 Problema Identificado

Atualmente, o SQLite (`whatsapp.db`) e os arquivos de mídia estão na mesma pasta (`/app/storages`), causando:

- ❌ **Dificuldade na limpeza** de arquivos de mídia
- ❌ **Risco de corrupção** do banco ao deletar mídia
- ❌ **Backup complexo** - precisa separar dados críticos
- ❌ **Performance** - busca de arquivos misturada

## ✅ Solução Proposta

### **1. Estrutura de Pastas Separada**

```
/app/
├── database/           # 📁 Banco de dados SQLite
│   └── whatsapp.db
├── storages/           # 📁 Arquivos de mídia e temporários
│   ├── media/          # 📁 Mídia baixada
│   ├── temp/           # 📁 Arquivos temporários
│   └── chat.csv        # 📄 Histórico de chat
└── statics/            # 📁 Arquivos estáticos
    ├── qrcode/
    ├── senditems/
    └── media/
```

### **2. Configuração de Variáveis de Ambiente**

```bash
# Banco de dados
DB_PATH=/app/database
DB_URI=file:/app/database/whatsapp.db?_foreign_keys=on

# Mídia e arquivos temporários
STORAGE_PATH=/app/storages
MEDIA_PATH=/app/storages/media
TEMP_PATH=/app/storages/temp

# Chat storage
CHAT_STORAGE_PATH=/app/storages/chat.csv
```

### **3. Modificações no Código**

#### **A. Atualizar Configurações (src/config/settings.go)**

```go
var (
    // ... outras configurações ...
    
    // Caminhos separados
    PathDatabase     = "database"
    PathStorages     = "storages"
    PathMedia        = "storages/media"
    PathTemp         = "storages/temp"
    PathChatStorage  = "storages/chat.csv"
    
    // URI do banco separado
    DBURI = "file:database/whatsapp.db?_foreign_keys=on"
)
```

#### **B. Atualizar Inicialização (src/cmd/root.go)**

```go
func initApp() {
    // ... código existente ...
    
    // Criar pastas separadas
    err := utils.CreateFolder(
        config.PathQrCode, 
        config.PathSendItems, 
        config.PathDatabase,    // ← Nova pasta
        config.PathStorages,    // ← Mantida para mídia
        config.PathMedia,       // ← Subpasta para mídia
        config.PathTemp,        // ← Subpasta para temp
        config.PathMedia,       // ← Pasta de mídia estática
    )
    if err != nil {
        logrus.Errorln(err)
    }
    
    // ... resto do código ...
}
```

### **4. Configuração do Docker**

#### **A. Docker Compose Atualizado**

```yaml
services:
  whatsapp:
    image: aldinokemal2104/go-whatsapp-web-multidevice
    container_name: whatsapp
    restart: always
    ports:
      - "3500:3000"
    volumes:
      # Banco de dados - persistente e isolado
      - whatsapp_database:/app/database
      # Mídia - pode ser limpa sem afetar o banco
      - whatsapp_storages:/app/storages
      # Arquivos estáticos
      - whatsapp_statics:/app/statics
    environment:
      # Configurações de caminhos
      DB_PATH: /app/database
      STORAGE_PATH: /app/storages
      MEDIA_PATH: /app/storages/media
      TEMP_PATH: /app/storages/temp
      CHAT_STORAGE_PATH: /app/storages/chat.csv
      # Outras configurações
      WHATSAPP_WEBHOOK: https://webhook.site/56daebcf-0ea3-400f-8bb5-de98580c62ae
    command:
      - rest
      - --port=3000
      - --debug=false
      - --os=NS-Zap
      - --account-validation=false
      - --webhook="https://webhook.site/56daebcf-0ea3-400f-8bb5-de98580c62ae"

volumes:
  whatsapp_database:    # 📁 Volume para banco de dados
  whatsapp_storages:    # 📁 Volume para mídia
  whatsapp_statics:     # 📁 Volume para arquivos estáticos
```

#### **B. Dockerfile Atualizado**

```dockerfile
############################
# STEP 1 build executable binary
############################
FROM golang:1.24-alpine3.20 AS builder
RUN apk update && apk add --no-cache gcc musl-dev gcompat
WORKDIR /whatsapp
COPY ./src .

# Fetch dependencies.
RUN go mod download
# Build the binary with optimizations
RUN go build -a -ldflags="-w -s" -o /app/whatsapp

#############################
## STEP 2 build a smaller image
#############################
FROM alpine:3.20
RUN apk add --no-cache ffmpeg
WORKDIR /app

# Criar estrutura de pastas
RUN mkdir -p /app/database \
    && mkdir -p /app/storages/media \
    && mkdir -p /app/storages/temp \
    && mkdir -p /app/statics/qrcode \
    && mkdir -p /app/statics/senditems \
    && mkdir -p /app/statics/media

# Copy compiled from builder.
COPY --from=builder /app/whatsapp /app/whatsapp

# Definir permissões
RUN chmod +x /app/whatsapp

# Run the binary.
ENTRYPOINT ["/app/whatsapp"]
CMD [ "rest" ]
```

### **5. Atualização da Classe C#**

#### **A. Volumes Separados**

```csharp
private async Task<bool> CreateContainerAsync(ServidorWhatsApp app)
{
    var results = false;
    var networkName = GetNameNetWorkDocker();
    var internalPort = GetInternalPortDocker();
    var urlNotification = GetUrlNotification();
    var _enviroment = GetEnviroment();
    var callBack = GetUrlCallback();
    
    try
    {
        _logger.LogInformation($"CreateContainerAsync - [{app.LojaNome}/{app.NomeContainer}]");
        using var client = new DockerClientConfiguration(new Uri(GetLocalDocker())).CreateClient();

        // Configurar volumes separados
        var storeName = (string.IsNullOrWhiteSpace(app.LojaNome) ? app.LojaAlias : app.LojaNome).ToLower().RemoveSpecialCharacter();
        var volumes = new List<string>
        {
            // Volume para banco de dados - persistente
            $"/nebula/volume-whatsapp/{_enviroment}{storeName}/database:/app/database",
            
            // Volume para mídia - pode ser limpo
            $"/nebula/volume-whatsapp/{_enviroment}{storeName}/storages:/app/storages",
            
            // Volume para arquivos estáticos
            $"/nebula/volume-whatsapp/{_enviroment}{storeName}/statics:/app/statics",
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
            }
        };

        var envVariables = new Dictionary<string, string>
        {
            { "API_WEBHOOK", $@"{callBack}{app.LojaId}" },
            { "WHATSAPP_WEBHOOK", $@"{callBack}{app.LojaId}" },
            // Novas variáveis de ambiente para caminhos
            { "DB_PATH", "/app/database" },
            { "STORAGE_PATH", "/app/storages" },
            { "MEDIA_PATH", "/app/storages/media" },
            { "TEMP_PATH", "/app/storages/temp" },
            { "CHAT_STORAGE_PATH", "/app/storages/chat.csv" }
        };

        var containerCreateParameters = new CreateContainerParameters
        {
            Name = app.NomeContainer,
            Cmd = new List<string>
            {
                "rest",
                $"--port={internalPort}",
                "--debug=false",
                "--os=NS-Zap",
                "--account-validation=false",
                $"--webhook={callBack}{app.LojaId}"
            },
            Hostname = app.NomeContainer,
            Image = app.NomeImagem,
            Env = envVariables.Select(kv => $"{kv.Key}={kv.Value}").ToList(),
            ExposedPorts = new Dictionary<string, EmptyStruct>
            {
                { $"{internalPort}/tcp", default }
            },
            Volumes = new Dictionary<string, EmptyStruct>(),
            HostConfig = hostConfig,
            Labels = new Dictionary<string, string>
            {
                { "com.centurylinklabs.watchtower.enable", "false" }
            },
            NetworkingConfig = new NetworkingConfig
            {
                EndpointsConfig = new Dictionary<string, EndpointSettings>
                {
                    {
                        networkName, new EndpointSettings
                        {
                            NetworkID = networkName
                        }
                    }
                }
            }
        };

        var response = await client.Containers.CreateContainerAsync(containerCreateParameters);
        await client.Containers.StartContainerAsync(response.ID, new ContainerStartParameters());

        results = true;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, $"CreateContainerAsync - [{app.NomeContainer}]");
    }

    return results;
}
```

### **6. Scripts de Manutenção**

#### **A. Script de Limpeza de Mídia**

```bash
#!/bin/bash
# cleanup-media.sh

CONTAINER_NAME=$1
STORAGE_PATH="/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages"

if [ -z "$CONTAINER_NAME" ]; then
    echo "Uso: $0 <nome_do_container>"
    exit 1
fi

echo "🧹 Limpando arquivos de mídia do container: $CONTAINER_NAME"

# Verificar se o container existe
if ! docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
    echo "❌ Container $CONTAINER_NAME não encontrado"
    exit 1
fi

# Parar o container temporariamente
echo "⏸️  Parando container..."
docker stop "$CONTAINER_NAME"

# Limpar apenas arquivos de mídia (não o banco)
echo "🗑️  Removendo arquivos de mídia..."
find "$STORAGE_PATH/media" -type f -name "*.jpg" -delete
find "$STORAGE_PATH/media" -type f -name "*.png" -delete
find "$STORAGE_PATH/media" -type f -name "*.mp4" -delete
find "$STORAGE_PATH/media" -type f -name "*.mp3" -delete
find "$STORAGE_PATH/media" -type f -name "*.pdf" -delete
find "$STORAGE_PATH/temp" -type f -delete

# Limpar arquivos antigos (mais de 30 dias)
find "$STORAGE_PATH" -type f -mtime +30 -delete

# Reiniciar o container
echo "▶️  Reiniciando container..."
docker start "$CONTAINER_NAME"

echo "✅ Limpeza concluída!"
```

#### **B. Script de Backup do Banco**

```bash
#!/bin/bash
# backup-database.sh

CONTAINER_NAME=$1
BACKUP_PATH="/backup/whatsapp"
DATABASE_PATH="/nebula/volume-whatsapp/prod${CONTAINER_NAME}/database"

if [ -z "$CONTAINER_NAME" ]; then
    echo "Uso: $0 <nome_do_container>"
    exit 1
fi

echo "💾 Fazendo backup do banco de dados: $CONTAINER_NAME"

# Criar pasta de backup
mkdir -p "$BACKUP_PATH"

# Backup com timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_PATH/${CONTAINER_NAME}_whatsapp_${TIMESTAMP}.db"

# Parar o container para backup consistente
echo "⏸️  Parando container..."
docker stop "$CONTAINER_NAME"

# Copiar banco de dados
echo "📋 Copiando banco de dados..."
cp "$DATABASE_PATH/whatsapp.db" "$BACKUP_FILE"

# Reiniciar o container
echo "▶️  Reiniciando container..."
docker start "$CONTAINER_NAME"

# Comprimir backup
echo "🗜️  Comprimindo backup..."
gzip "$BACKUP_FILE"

echo "✅ Backup salvo em: ${BACKUP_FILE}.gz"

# Limpar backups antigos (manter apenas últimos 7 dias)
find "$BACKUP_PATH" -name "*.db.gz" -mtime +7 -delete

echo "🧹 Backups antigos removidos"
```

### **7. Vantagens da Separação**

#### **✅ Benefícios**

1. **Segurança do Banco**
   - Banco isolado em volume separado
   - Backup independente
   - Sem risco de corrupção por limpeza de mídia

2. **Gestão de Mídia**
   - Limpeza fácil de arquivos de mídia
   - Controle de espaço em disco
   - Manutenção simplificada

3. **Performance**
   - I/O separado para banco e mídia
   - Cache mais eficiente
   - Menos fragmentação

4. **Backup e Restore**
   - Backup seletivo (só banco ou só mídia)
   - Restore parcial
   - Versionamento independente

#### **📊 Comparação**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Estrutura** | Tudo em `/storages` | Separado em `/database` e `/storages` |
| **Limpeza** | Risco de deletar banco | Seguro - só mídia |
| **Backup** | Arquivo único grande | Backup seletivo |
| **Performance** | I/O misturado | I/O otimizado |
| **Manutenção** | Complexa | Simplificada |

### **8. Migração**

#### **A. Script de Migração**

```bash
#!/bin/bash
# migrate-structure.sh

CONTAINER_NAME=$1

if [ -z "$CONTAINER_NAME" ]; then
    echo "Uso: $0 <nome_do_container>"
    exit 1
fi

echo "🔄 Migrando estrutura do container: $CONTAINER_NAME"

# Parar container
docker stop "$CONTAINER_NAME"

# Criar nova estrutura
mkdir -p "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/database"
mkdir -p "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages/media"
mkdir -p "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages/temp"

# Mover banco de dados
if [ -f "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages/whatsapp.db" ]; then
    echo "📋 Movendo banco de dados..."
    mv "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages/whatsapp.db" \
       "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/database/"
fi

# Mover arquivos de mídia
if [ -d "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages" ]; then
    echo "📁 Organizando arquivos de mídia..."
    find "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages" -type f \
         \( -name "*.jpg" -o -name "*.png" -o -name "*.mp4" -o -name "*.mp3" -o -name "*.pdf" \) \
         -exec mv {} "/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages/media/" \;
fi

echo "✅ Migração concluída!"
```

### **9. Monitoramento**

#### **A. Script de Monitoramento**

```bash
#!/bin/bash
# monitor-storage.sh

CONTAINER_NAME=$1

if [ -z "$CONTAINER_NAME" ]; then
    echo "Uso: $0 <nome_do_container>"
    exit 1
fi

DATABASE_PATH="/nebula/volume-whatsapp/prod${CONTAINER_NAME}/database"
STORAGE_PATH="/nebula/volume-whatsapp/prod${CONTAINER_NAME}/storages"

echo "📊 Status de armazenamento: $CONTAINER_NAME"
echo "=========================================="

# Tamanho do banco
if [ -f "$DATABASE_PATH/whatsapp.db" ]; then
    DB_SIZE=$(du -h "$DATABASE_PATH/whatsapp.db" | cut -f1)
    echo "🗄️  Banco de dados: $DB_SIZE"
else
    echo "❌ Banco de dados não encontrado"
fi

# Tamanho da mídia
if [ -d "$STORAGE_PATH/media" ]; then
    MEDIA_SIZE=$(du -sh "$STORAGE_PATH/media" | cut -f1)
    MEDIA_COUNT=$(find "$STORAGE_PATH/media" -type f | wc -l)
    echo "📁 Mídia: $MEDIA_SIZE ($MEDIA_COUNT arquivos)"
else
    echo "❌ Pasta de mídia não encontrada"
fi

# Arquivos temporários
if [ -d "$STORAGE_PATH/temp" ]; then
    TEMP_SIZE=$(du -sh "$STORAGE_PATH/temp" | cut -f1)
    TEMP_COUNT=$(find "$STORAGE_PATH/temp" -type f | wc -l)
    echo "🗑️  Temporários: $TEMP_SIZE ($TEMP_COUNT arquivos)"
fi

echo "=========================================="
```

### **10. Conclusão**

Com essa separação, você terá:

- ✅ **Banco de dados seguro** em volume isolado
- ✅ **Limpeza fácil** de arquivos de mídia
- ✅ **Backup seletivo** e eficiente
- ✅ **Performance otimizada**
- ✅ **Manutenção simplificada**

A implementação pode ser feita gradualmente, migrando um container por vez para evitar interrupções no serviço. 