# Mapeamento Completo das Tabelas do Banco `whatsapp.db`

Este documento descreve todas as tabelas presentes no banco de dados `whatsapp.db` (SQLite) utilizado pelo projeto Zap Nebula.

## 📋 Visão Geral

O banco `whatsapp.db` é dividido em duas categorias principais:
1. **Tabelas criadas pela biblioteca `whatsmeow`** - Gerencia autenticação, criptografia e sincronização
2. **Tabelas criadas pelo projeto** - Gerencia armazenamento de chats e mensagens

---

## 🔐 Tabelas do WhatsApp (`whatsmeow/sqlstore`)

Estas tabelas são criadas automaticamente pela biblioteca `whatsmeow` para gerenciar a conexão e criptografia com o WhatsApp.

### 1. **`whatsmeow_devices`**
**Função**: Armazena informações sobre os dispositivos pareados com WhatsApp

**Campos principais**:
- `jid` (TEXT, PRIMARY KEY) - JID do dispositivo (número de telefone no formato `55XXXXXXXXXX.0:64@s.whatsapp.net`)
- `registration_id` (BLOB) - ID de registro do dispositivo
- `noise_key` (BLOB) - Chave de ruído para comunicação
- `identity_key` (BLOB) - Chave de identidade do dispositivo
- `signed_prekey` (BLOB) - Chave pré-compartilhada assinada
- `signed_prekey_id` (INTEGER) - ID da chave pré-compartilhada
- `signed_prekey_timestamp` (INTEGER) - Timestamp da chave pré-compartilhada
- `next_prekey_id` (INTEGER) - Próximo ID de chave pré-compartilhada
- `first_unuploaded_prekey_id` (INTEGER) - Primeiro ID de chave não enviada
- `account` (BLOB) - Informações da conta
- `me` (BLOB) - Informações do usuário (inclui PushName, BusinessName)
- `signal_identities` (BLOB) - Identidades Signal
- `my_app_state_key_id` (BLOB) - ID da chave de estado do app
- `platform` (TEXT) - Plataforma do dispositivo
- `business_name` (TEXT) - Nome comercial (se conta Business)
- `push_name` (TEXT) - Nome de exibição no WhatsApp
- `adv` (BLOB) - Dados de propaganda/ADV

**Observação**: Esta é a tabela onde está armazenado o **número pareado** e as informações do dispositivo.

**Uso no código**:
```go
// src/infrastructure/whatsapp/init.go:105
device, err := storeContainer.GetFirstDevice(ctx)
```

---

### 2. **`whatsmeow_identities`**
**Função**: Armazena chaves de identidade de contatos para verificação de segurança

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK para `whatsmeow_devices`)
- `their_jid` (TEXT) - JID do contato
- `identity_key` (BLOB) - Chave de identidade do contato
- `trust_level` (INTEGER) - Nível de confiança (0=unknown, 1=trusted, 2=untrusted)
- `added` (INTEGER) - Timestamp de quando foi adicionado

**Função**: Usado para verificar a identidade de contatos e prevenir ataques MITM (Man-in-the-Middle).

---

### 3. **`whatsmeow_sessions`**
**Função**: Armazena sessões de criptografia para cada contato/grupo

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `their_jid` (TEXT) - JID do contato ou grupo
- `session_id` (TEXT) - ID da sessão
- `record` (BLOB) - Registro de sessão criptografado

**Função**: Gerencia as chaves de criptografia usadas para criptografar/descriptografar mensagens com cada contato.

**Uso no código**:
```go
// src/infrastructure/whatsapp/init.go:131
device.Sessions = innerStore
```

---

### 4. **`whatsmeow_prekeys`**
**Função**: Armazena chaves pré-compartilhadas para estabelecimento de comunicação criptografada

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `key_id` (INTEGER) - ID da chave pré-compartilhada
- `key` (BLOB) - Chave pré-compartilhada
- `uploaded` (BOOLEAN) - Se a chave foi enviada ao servidor

**Função**: Usado no protocolo Signal para estabelecer comunicação criptografada de forma segura sem prévio compartilhamento de chaves.

**Uso no código**:
```go
// src/infrastructure/whatsapp/init.go:132
device.PreKeys = innerStore
```

---

### 5. **`whatsmeow_sender_keys`**
**Função**: Armazena chaves de remetente para grupos (criptografia em grupo)

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `chat_id` (TEXT) - ID do grupo/chat
- `sender_id` (TEXT) - JID do remetente
- `sender_key_id` (INTEGER) - ID da chave do remetente
- `sender_key` (BLOB) - Chave do remetente
- `timestamp` (INTEGER) - Timestamp da chave

**Função**: Gerencia criptografia de mensagens em grupos, onde cada remetente tem uma chave específica.

**Uso no código**:
```go
// src/infrastructure/whatsapp/init.go:133
device.SenderKeys = innerStore
```

---

### 6. **`whatsmeow_msg_secrets`**
**Função**: Armazena segredos de mensagens (usado para descriptografar mensagens específicas)

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `chat_id` (TEXT) - ID do chat
- `sender_jid` (TEXT) - JID do remetente
- `message_id` (TEXT) - ID da mensagem
- `secret` (BLOB) - Segredo da mensagem
- `timestamp` (INTEGER) - Timestamp

**Função**: Armazena segredos necessários para descriptografar mensagens específicas.

**Uso no código**:
```go
// src/infrastructure/whatsapp/init.go:134
device.MsgSecrets = innerStore
```

---

### 7. **`whatsmeow_privacy_tokens`**
**Função**: Armazena tokens de privacidade (usado para verificação de status de leitura)

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `token` (BLOB) - Token de privacidade
- `timestamp` (INTEGER) - Timestamp

**Função**: Gerencia tokens usados para verificações de privacidade, como confirmações de leitura.

**Uso no código**:
```go
// src/infrastructure/whatsapp/init.go:135
device.PrivacyTokens = innerStore
```

---

### 8. **`whatsmeow_app_state_sync_keys`**
**Função**: Armazena chaves para sincronização de estado da aplicação

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `key_id` (BLOB) - ID da chave
- `key_data` (BLOB) - Dados da chave
- `timestamp` (INTEGER) - Timestamp
- `fingerprint` (BLOB) - Impressão digital

**Função**: Gerencia sincronização de estado da aplicação entre dispositivos (como configurações, bloqueios, etc.).

---

### 9. **`whatsmeow_app_state_version`**
**Função**: Controla versões de estado da aplicação

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `name` (TEXT) - Nome do estado (ex: "mute", "pin", etc.)
- `version` (INTEGER) - Versão do estado
- `hash` (BLOB) - Hash do estado

**Função**: Mantém controle de versão para estados da aplicação (mute, pin de chats, etc.).

---

### 10. **`whatsmeow_app_state_mutation_macs`**
**Função**: Armazena MACs (Message Authentication Codes) para mutações de estado

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `name` (TEXT) - Nome do estado
- `version` (INTEGER) - Versão
- `index_mac` (BLOB) - MAC do índice
- `value_mac` (BLOB) - MAC do valor

**Função**: Valida integridade de mutações de estado da aplicação.

---

### 11. **`whatsmeow_app_state_mutation_versions`**
**Função**: Controla versões de mutações de estado

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `name` (TEXT) - Nome do estado
- `version` (INTEGER) - Versão da mutação

**Função**: Controla versões de mutações no estado da aplicação.

---

### 12. **`whatsmeow_app_state_store`**
**Função**: Armazena valores de estado da aplicação (mute, pin, etc.)

**Campos principais**:
- `our_jid` (TEXT) - JID do dispositivo (FK)
- `name` (TEXT) - Nome do estado
- `key` (BLOB) - Chave do estado
- `value` (BLOB) - Valor do estado
- `timestamp` (INTEGER) - Timestamp

**Função**: Armazena estados da aplicação como chats mutados, chats fixados, configurações de privacidade, etc.

---

## 💬 Tabelas do Projeto (Chat Storage)

Estas tabelas são criadas pelo próprio projeto para armazenar histórico de chats e mensagens.

### 13. **`chats`**
**Função**: Armazena informações sobre conversas (chats individuais e grupos)

**Campos**:
- `jid` (TEXT, PRIMARY KEY) - JID do chat (ex: `55XXXXXXXXXX@s.whatsapp.net` ou `120363XXXXXXXX@g.us`)
- `name` (TEXT, NOT NULL) - Nome do chat/contato/grupo
- `last_message_time` (TIMESTAMP, NOT NULL) - Timestamp da última mensagem
- `ephemeral_expiration` (INTEGER, DEFAULT 0) - Tempo de expiração para mensagens efêmeras (em segundos)
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP) - Data de criação do registro
- `updated_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP) - Data da última atualização

**Índices**:
- `idx_chats_last_message` - Índice em `last_message_time` para ordenação
- `idx_chats_name` - Índice em `name` para busca

**Uso no código**:
```go
// src/infrastructure/chatstorage/sqlite_repository.go:32-44
INSERT INTO chats (jid, name, last_message_time, ephemeral_expiration, created_at, updated_at)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(jid) DO UPDATE SET ...
```

---

### 14. **`messages`**
**Função**: Armazena todas as mensagens enviadas e recebidas

**Campos**:
- `id` (TEXT, NOT NULL) - ID único da mensagem do WhatsApp
- `chat_jid` (TEXT, NOT NULL) - JID do chat (FK para `chats.jid`)
- `sender` (TEXT, NOT NULL) - JID do remetente
- `content` (TEXT) - Conteúdo da mensagem (texto)
- `timestamp` (TIMESTAMP, NOT NULL) - Timestamp da mensagem
- `is_from_me` (BOOLEAN, DEFAULT FALSE) - Se a mensagem foi enviada por você
- `media_type` (TEXT) - Tipo de mídia (image, video, audio, document, sticker, etc.)
- `filename` (TEXT) - Nome do arquivo (se for mídia)
- `url` (TEXT) - URL do arquivo de mídia (se armazenado)
- `media_key` (BLOB) - Chave de descriptografia da mídia
- `file_sha256` (BLOB) - SHA256 do arquivo
- `file_enc_sha256` (BLOB) - SHA256 criptografado do arquivo
- `file_length` (INTEGER, DEFAULT 0) - Tamanho do arquivo em bytes
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP) - Data de criação do registro
- `updated_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP) - Data da última atualização

**Chave Primária**: `(id, chat_jid)` - Permite mensagens com mesmo ID em chats diferentes

**Chave Estrangeira**: 
- `chat_jid` → `chats(jid) ON DELETE CASCADE` - Se o chat for deletado, as mensagens são deletadas automaticamente

**Índices**:
- `idx_messages_chat_jid` - Índice em `chat_jid` para buscar mensagens de um chat
- `idx_messages_timestamp` - Índice em `timestamp` para ordenação cronológica
- `idx_messages_media_type` - Índice em `media_type` para filtrar por tipo
- `idx_messages_sender` - Índice em `sender` para buscar mensagens de um remetente
- `idx_messages_id` - Índice em `id` para busca rápida por ID

**Uso no código**:
```go
// src/infrastructure/chatstorage/sqlite_repository.go:780-798
CREATE TABLE IF NOT EXISTS messages (
    id TEXT NOT NULL,
    chat_jid TEXT NOT NULL,
    sender TEXT NOT NULL,
    ...
    PRIMARY KEY (id, chat_jid),
    FOREIGN KEY (chat_jid) REFERENCES chats(jid) ON DELETE CASCADE
)
```

---

### 15. **`schema_info`**
**Função**: Controla versões de migração do schema do banco de dados

**Campos**:
- `version` (INTEGER, PRIMARY KEY, DEFAULT 0) - Versão atual do schema
- `updated_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP) - Data da última atualização

**Função**: Mantém controle de versão das migrações do banco de dados, permitindo que o sistema aplique atualizações de schema automaticamente.

**Uso no código**:
```go
// src/infrastructure/chatstorage/sqlite_repository.go:721-741
func (r *SQLiteRepository) getSchemaVersion() (int, error) {
    // Cria a tabela se não existir
    _, err := r.db.Exec(`
        CREATE TABLE IF NOT EXISTS schema_info (
            version INTEGER PRIMARY KEY DEFAULT 0,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `)
    // Retorna a versão atual
    var version int
    err = r.db.QueryRow("SELECT COALESCE(MAX(version), 0) FROM schema_info").Scan(&version)
    return version, nil
}
```

---

## 📊 Resumo das Tabelas

| Categoria | Tabela | Função Principal | Onde está o número pareado? |
|-----------|--------|------------------|----------------------------|
| **WhatsApp** | `whatsmeow_devices` | ✅ **Dispositivos pareados** | ✅ **SIM - Campo `jid`** |
| **WhatsApp** | `whatsmeow_identities` | Chaves de identidade de contatos | Não |
| **WhatsApp** | `whatsmeow_sessions` | Sessões de criptografia | Não |
| **WhatsApp** | `whatsmeow_prekeys` | Chaves pré-compartilhadas | Não |
| **WhatsApp** | `whatsmeow_sender_keys` | Chaves de remetente (grupos) | Não |
| **WhatsApp** | `whatsmeow_msg_secrets` | Segredos de mensagens | Não |
| **WhatsApp** | `whatsmeow_privacy_tokens` | Tokens de privacidade | Não |
| **WhatsApp** | `whatsmeow_app_state_sync_keys` | Chaves de sincronização | Não |
| **WhatsApp** | `whatsmeow_app_state_version` | Versões de estado | Não |
| **WhatsApp** | `whatsmeow_app_state_mutation_macs` | MACs de mutações | Não |
| **WhatsApp** | `whatsmeow_app_state_mutation_versions` | Versões de mutações | Não |
| **WhatsApp** | `whatsmeow_app_state_store` | Estados da aplicação | Não |
| **Projeto** | `chats` | Conversas/contatos/grupos | Não (armazena JID dos contatos) |
| **Projeto** | `messages` | Mensagens enviadas/recebidas | Não (armazena JID do remetente) |
| **Projeto** | `schema_info` | Controle de versão do schema | Não |

---

## 🔍 Como Encontrar o Número Pareado

O número do dispositivo pareado está na tabela **`whatsmeow_devices`**:

```sql
-- Buscar o número pareado
SELECT 
    jid,                    -- JID completo (ex: 5511999999999.0:64@s.whatsapp.net)
    push_name,              -- Nome no WhatsApp
    business_name,          -- Nome comercial (se Business)
    platform               -- Plataforma do dispositivo
FROM whatsmeow_devices
LIMIT 1;
```

**Formato do JID**: `[CÓDIGO_PAÍS][NÚMERO].0:64@s.whatsapp.net`
- Exemplo: `5511999999999.0:64@s.whatsapp.net` = Brasil (55) + 11999999999

---

## 📝 Notas Importantes

1. **Foreign Keys**: O projeto usa `_foreign_keys=on` no SQLite (ver `config.DBURI`), garantindo integridade referencial.

2. **Cascade Delete**: Quando um chat é deletado da tabela `chats`, todas as mensagens relacionadas são deletadas automaticamente devido ao `ON DELETE CASCADE`.

3. **Separate Databases**: O projeto pode usar bancos separados:
   - `whatsapp.db` - Tabelas do whatsmeow + dados principais
   - `chatstorage.db` - Chat storage (se configurado separadamente)
   - `keys.db` - Banco dedicado para chaves (se `DBKeysURI` estiver configurado)

4. **Migrações**: O sistema de chat storage usa migrações versionadas através da tabela `schema_info`.

---

## 🔗 Referências no Código

- **Inicialização do banco**: `src/infrastructure/whatsapp/init.go:49-72`
- **Schema do chat storage**: `src/infrastructure/chatstorage/sqlite_repository.go:764-814`
- **Configuração**: `src/config/settings.go:24-25`

