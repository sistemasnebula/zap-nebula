# API WhatsApp MultiDevice — Controllers e Rotas

Este documento lista todas as **controllers** e **rotas** expostas pela API, com dados de **entrada** e **saída** de cada uma.

- **Base URL:** `http://localhost:3000` (ou conforme `AppHost`/`AppPort`). Se `AppBasePath` estiver configurado, todas as rotas são prefixadas por ele (ex.: `/api`).
- **Autenticação:** HTTP Basic Auth (quando `APP_BASIC_AUTH` está definido).
- **Escopo por dispositivo:** Na maioria das rotas é necessário informar o dispositivo via cabeçalho **`X-Device-Id`** ou query **`device_id`**. As rotas sob **Device** não exigem `X-Device-Id`.

---

## Índice

1. [App](#1-app) — Conexão e login
2. [Device](#2-device) — Gestão de dispositivos (multi-device)
3. [User](#3-user) — Informações de usuário e contatos
4. [Send](#4-send) — Envio de mensagens e mídia
5. [Message](#5-message) — Reações, revogação, leitura, download
6. [Chat](#6-chat) — Conversas e mensagens do chat
7. [Group](#7-group) — Grupos
8. [Newsletter](#8-newsletter) — Canais/Newsletter

---

## 1. App

Conexão inicial ao WhatsApp (QR Code, código de pareamento), logout, reconexão e status.

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/app/login` | Login via QR Code |
| GET | `/app/login-with-code` | Login com código de pareamento |
| GET | `/app/logout` | Logout e remoção do banco do dispositivo |
| GET | `/app/reconnect` | Reconectar ao WhatsApp |
| GET | `/app/devices` | Listar dispositivos conectados (legado) |
| GET | `/app/status` | Status da conexão do dispositivo |

### GET `/app/login`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** —
  - **Body:** —
- **Saída (200)**
```json
{
  "status": 200,
  "code": "SUCCESS",
  "message": "Login success",
  "results": {
    "device_id": "string",
    "qr_link": "string (URL da imagem QR)",
    "qr_duration": 30
  }
}
```
- **Saída (500):** `ErrorInternalServer`

---

### GET `/app/login-with-code`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** `phone` (string, ex.: 628912344551)
  - **Body:** —
- **Saída (200)**
```json
{
  "status": 200,
  "code": "SUCCESS",
  "message": "Login with code success",
  "results": {
    "device_id": "string",
    "pair_code": "string"
  }
}
```
- **Saída (500):** `ErrorInternalServer`

---

### GET `/app/logout`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** —
  - **Body:** —
- **Saída (200):** `GenericResponse` (code, message, results)
- **Saída (500):** `ErrorInternalServer`

---

### GET `/app/reconnect`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** —
  - **Body:** —
- **Saída (200):** `GenericResponse`
- **Saída (500):** `ErrorInternalServer`

---

### GET `/app/devices`

- **Entrada**
  - **Headers:** —
  - **Query:** —
  - **Body:** —
- **Saída (200)**
```json
{
  "code": "SUCCESS",
  "message": "Fetch device success",
  "results": [
    { "name": "string", "device": "string (JID)" }
  ]
}
```
- **Saída (500):** `ErrorInternalServer`

---

### GET `/app/status`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** —
  - **Body:** —
- **Saída (200)**
```json
{
  "status": 200,
  "code": "SUCCESS",
  "message": "Connection status retrieved",
  "results": {
    "is_connected": true,
    "is_logged_in": true,
    "device_id": "string"
  }
}
```
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

## 2. Device

Gestão de dispositivos (listar, adicionar, remover, login por dispositivo, logout, reconectar, status). **Não exige** `X-Device-Id` nas rotas desta controller.

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/devices` | Listar todos os dispositivos |
| POST | `/devices` | Adicionar novo dispositivo |
| GET | `/devices/:device_id` | Obter info de um dispositivo |
| DELETE | `/devices/:device_id` | Remover dispositivo |
| GET | `/devices/:device_id/login` | Login (QR) do dispositivo |
| POST | `/devices/:device_id/login/code` | Login com código de pareamento |
| POST | `/devices/:device_id/logout` | Logout do dispositivo |
| POST | `/devices/:device_id/reconnect` | Reconectar dispositivo |
| GET | `/devices/:device_id/status` | Status do dispositivo |

### GET `/devices`

- **Entrada:** —
- **Saída (200)**
```json
{
  "code": "SUCCESS",
  "message": "List devices",
  "status": 200,
  "results": [
    {
      "id": "string",
      "phone_number": "string",
      "display_name": "string",
      "state": "disconnected | connected | logged_in",
      "jid": "string",
      "created_at": "date-time"
    }
  ]
}
```
- **Saída (500):** `ErrorInternalServer`

---

### POST `/devices`

- **Entrada**
  - **Body (JSON):**
    - `device_id` (string, opcional) — ID customizado; se omitido, um é gerado.
- **Saída (200)**
```json
{
  "code": "SUCCESS",
  "message": "Device added",
  "status": 200,
  "results": { "id": "string", "phone_number": "", "display_name": "", "state": "disconnected", "jid": "", "created_at": "date-time" }
}
```
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/devices/:device_id`

- **Entrada**
  - **Path:** `device_id` (string)
- **Saída (200):** `DeviceInfoResponse` (code, message, status, results com DeviceInfo)
- **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

### DELETE `/devices/:device_id`

- **Entrada**
  - **Path:** `device_id` (string)
- **Saída (200):** `GenericResponse`
- **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

### GET `/devices/:device_id/login`

- **Entrada**
  - **Path:** `device_id` (string)
- **Saída (200):** igual a `/app/login` (device_id, qr_link, qr_duration)
- **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

### POST `/devices/:device_id/login/code`

- **Entrada**
  - **Path:** `device_id` (string)
  - **Query:** `phone` (string, obrigatório, ex.: 628912344551)
- **Saída (200):** igual a `/app/login-with-code` (device_id, pair_code)
- **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

### POST `/devices/:device_id/logout`

- **Entrada**
  - **Path:** `device_id` (string)
- **Saída (200):** `GenericResponse`
- **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

### POST `/devices/:device_id/reconnect`

- **Entrada**
  - **Path:** `device_id` (string)
- **Saída (200):** `GenericResponse`
- **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

### GET `/devices/:device_id/status`

- **Entrada**
  - **Path:** `device_id` (string)
- **Saída (200)**
```json
{
  "code": "SUCCESS",
  "message": "Device status",
  "status": 200,
  "results": {
    "device_id": "string",
    "is_connected": true,
    "is_logged_in": true
  }
}
```
- **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

## 3. User

Informações de usuário, avatar, nome, privacidade, grupos, newsletters, contatos, verificação e perfil business.

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/user/info` | Info do usuário (phone) |
| GET | `/user/avatar` | Avatar do usuário |
| POST | `/user/avatar` | Alterar avatar |
| POST | `/user/pushname` | Alterar nome exibido |
| GET | `/user/my/privacy` | Configurações de privacidade |
| GET | `/user/my/groups` | Lista de grupos do usuário |
| GET | `/user/my/newsletters` | Lista de newsletters |
| GET | `/user/my/contacts` | Lista de contatos |
| GET | `/user/check` | Verificar se número está no WhatsApp |
| GET | `/user/business-profile` | Perfil business (phone) |

### GET `/user/info`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** `phone` (string, ex.: 6289685028129@s.whatsapp.net)
- **Saída (200):** `UserInfoResponse` — results com verified_name, status, picture_id, devices
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/user/avatar`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** `phone`, `is_preview` (boolean), `is_community` (boolean)
- **Saída (200):** results com url, id, type
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/user/avatar`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Body (multipart/form-data):** `avatar` (arquivo)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/user/pushname`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Body (JSON):** `push_name` (string, obrigatório)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/user/my/privacy`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
- **Saída (200):** results com group_add, last_seen, status, profile, read_receipts
- **Saída (500):** `ErrorInternalServer`

---

### GET `/user/my/groups`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
- **Saída (200):** results.data (array de grupos com JID, OwnerJID, Name, etc.)
- **Saída (500):** `ErrorInternalServer`

---

### GET `/user/my/newsletters`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
- **Saída (200):** results.data (array de newsletters)
- **Saída (500):** `ErrorInternalServer`

---

### GET `/user/my/contacts`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
- **Saída (200):** results.data (array de { jid, name })
- **Saída (500):** `ErrorInternalServer`

---

### GET `/user/check`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** `phone` (string)
- **Saída (200):** results com is_on_whatsapp (boolean)
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/user/business-profile`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** `phone` (string, obrigatório)
- **Saída (200):** results com jid, email, address, categories, profile_options, business_hours_timezone, business_hours
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

## 4. Send

Envio de mensagem de texto, imagem, áudio, arquivo, sticker, vídeo, contato, link, localização, enquete, presença e indicador de digitação.

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/send/message` | Enviar texto |
| POST | `/send/image` | Enviar imagem |
| POST | `/send/audio` | Enviar áudio |
| POST | `/send/file` | Enviar arquivo |
| POST | `/send/sticker` | Enviar sticker |
| POST | `/send/video` | Enviar vídeo |
| POST | `/send/contact` | Enviar contato |
| POST | `/send/link` | Enviar link |
| POST | `/send/location` | Enviar localização |
| POST | `/send/poll` | Enviar enquete |
| POST | `/send/presence` | Enviar presença (available/unavailable) |
| POST | `/send/chat-presence` | Indicador de digitação (start/stop) |

Todas as rotas de envio exigem **Headers:** `X-Device-Id` (opcional quando há um único dispositivo).

### POST `/send/message`

- **Entrada**
  - **Body (JSON):**
    - `phone` (string) — ex.: 6289685028129@s.whatsapp.net
    - `message` (string)
    - `reply_message_id` (string, opcional)
    - `is_forwarded` (boolean, opcional)
    - `duration` (integer, opcional) — segundos para mensagem temporária
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/image`

- **Entrada**
  - **Body (multipart/form-data):**
    - `phone` (string)
    - `caption` (string, opcional)
    - `view_once` (boolean, opcional)
    - `image` (arquivo) ou `image_url` (string)
    - `compress` (boolean, opcional)
    - `duration` (integer, opcional)
    - `is_forwarded` (boolean, opcional)
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/audio`

- **Entrada**
  - **Body (multipart/form-data):** `phone`, `audio` (arquivo) ou `audio_url`, `is_forwarded`, `duration`
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/file`

- **Entrada**
  - **Body (multipart/form-data):** `phone`, `caption`, `file` (arquivo), `is_forwarded`, `duration`
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/sticker`

- **Entrada**
  - **Body (multipart/form-data):** `phone`, `sticker` (arquivo) ou `sticker_url`, `duration`, `is_forwarded`
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/video`

- **Entrada**
  - **Body (multipart/form-data):** `phone`, `caption`, `view_once`, `video` (arquivo) ou `video_url`, `compress`, `duration`, `is_forwarded`
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/contact`

- **Entrada**
  - **Body (JSON):** `phone`, `contact_name`, `contact_phone`, `is_forwarded`, `duration`
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/link`

- **Entrada**
  - **Body (JSON):** `phone`, `link`, `caption`, `is_forwarded`, `duration`
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/location`

- **Entrada**
  - **Body (JSON):** `phone`, `latitude`, `longitude`, `is_forwarded`, `duration`
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/poll`

- **Entrada**
  - **Body (JSON):**
    - `phone` (string)
    - `question` (string)
    - `options` (array de string)
    - `max_answer` (integer)
    - `duration` (integer, opcional)
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/presence`

- **Entrada**
  - **Body (JSON):** `type` ("available" | "unavailable"), `is_forwarded` (opcional)
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/send/chat-presence`

- **Entrada**
  - **Body (JSON):** `phone`, `action` ("start" | "stop") — indicador de digitação
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

## 5. Message

Reação, revogação, exclusão, edição, marcar como lida, destacar/desmarcar e download de mídia.

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/message/:message_id/reaction` | Reagir com emoji |
| POST | `/message/:message_id/revoke` | Revogar mensagem |
| POST | `/message/:message_id/delete` | Excluir mensagem |
| POST | `/message/:message_id/update` | Editar mensagem (até 15 min) |
| POST | `/message/:message_id/read` | Marcar como lida |
| POST | `/message/:message_id/star` | Destacar mensagem |
| POST | `/message/:message_id/unstar` | Remover destaque |
| GET | `/message/:message_id/download` | Baixar mídia da mensagem |

Todas exigem **Headers:** `X-Device-Id` (opcional).

### POST `/message/:message_id/reaction`

- **Entrada**
  - **Path:** `message_id` (string)
  - **Body (JSON):** `phone` (string), `emoji` (string, ex.: "🙏")
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/message/:message_id/revoke`

- **Entrada**
  - **Path:** `message_id` (string)
  - **Body (JSON):** `phone` (string)
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/message/:message_id/delete`

- **Entrada**
  - **Path:** `message_id` (string)
  - **Body (JSON):** `phone` (string)
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/message/:message_id/update`

- **Entrada**
  - **Path:** `message_id` (string)
  - **Body (JSON):** `phone` (string), `message` (string) — novo texto
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/message/:message_id/read`

- **Entrada**
  - **Path:** `message_id` (string)
  - **Body (JSON):** `phone` (string)
- **Saída (200):** results com message_id, status
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/message/:message_id/star`

- **Entrada**
  - **Path:** `message_id` (string)
  - **Body (JSON):** `phone` (string)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/message/:message_id/unstar`

- **Entrada**
  - **Path:** `message_id` (string)
  - **Body (JSON):** `phone` (string)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/message/:message_id/download`

- **Entrada**
  - **Path:** `message_id` (string)
  - **Query:** `phone` (string, obrigatório)
- **Saída (200)**
```json
{
  "status": 200,
  "code": "SUCCESS",
  "message": "Media downloaded successfully",
  "results": {
    "status": "string",
    "mime_type": "string",
    "file_size": 0,
    "file_name": "string",
    "data": "string (Base64)"
  }
}
```
- **Saída (400):** `ErrorBadRequest` | **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

## 6. Chat

Listagem de conversas, mensagens de um chat, fixar, mensagens temporárias e arquivar.

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/chats` | Listar conversas |
| GET | `/chat/:chat_jid/messages` | Mensagens de um chat |
| POST | `/chat/:chat_jid/pin` | Fixar ou desfixar chat |
| POST | `/chat/:chat_jid/disappearing` | Timer de mensagens temporárias |
| POST | `/chat/:chat_jid/archive` | Arquivar ou desarquivar chat |

### GET `/chats`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Query:** `limit` (integer, default 25, max 100), `offset` (integer, default 0), `search` (string), `has_media` (boolean, default false)
- **Saída (200):** results.data (array de Chat), results.pagination (limit, offset, total)
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/chat/:chat_jid/messages`

- **Entrada**
  - **Path:** `chat_jid` (string) — ex.: 6289685028129@s.whatsapp.net ou groupid@g.us
  - **Query:** `limit` (default 50, max 100), `offset`, `start_time`, `end_time` (date-time), `media_only` (boolean), `is_from_me` (boolean), `search` (string)
- **Saída (200):** results.data (array de ChatMessage), results.pagination, results.chat_info
- **Saída (400):** `ErrorBadRequest` | **Saída (401):** `ErrorUnauthorized` | **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

### POST `/chat/:chat_jid/pin`

- **Entrada**
  - **Path:** `chat_jid` (string)
  - **Body (JSON):** `pinned` (boolean) — true fixar, false desfixar
- **Saída (200):** results com status, message, chat_jid, pinned
- **Saída (400):** `ErrorBadRequest` | **Saída (401):** `ErrorUnauthorized` | **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

### POST `/chat/:chat_jid/disappearing`

- **Entrada**
  - **Path:** `chat_jid` (string)
  - **Body (JSON):** `timer_seconds` (integer) — 0 (desligado), 86400 (24h), 604800 (7d), 7776000 (90d)
- **Saída (200):** results com status, message, chat_jid, timer_seconds
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/chat/:chat_jid/archive`

- **Entrada**
  - **Path:** `chat_jid` (string)
  - **Body (JSON):** `archived` (boolean)
- **Saída (200):** results com status, message, chat_jid, archived
- **Saída (400):** `ErrorBadRequest` | **Saída (401):** `ErrorUnauthorized` | **Saída (404):** `ErrorNotFound` | **Saída (500):** `ErrorInternalServer`

---

## 7. Group

Criação, entrada por link, informações, participantes, pedidos de entrada, foto, nome, bloqueio, anúncio, tema e link de convite.

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/group` | Criar grupo |
| POST | `/group/join-with-link` | Entrar por link |
| GET | `/group/info-from-link` | Info do grupo a partir do link |
| GET | `/group/info` | Info do grupo (group_id) |
| POST | `/group/leave` | Sair do grupo |
| GET | `/group/participants` | Listar participantes |
| GET | `/group/participants/export` | Exportar participantes (CSV) |
| POST | `/group/participants` | Adicionar participantes |
| POST | `/group/participants/remove` | Remover participantes |
| POST | `/group/participants/promote` | Promover a admin |
| POST | `/group/participants/demote` | Rebaixar admin |
| GET | `/group/participant-requests` | Pedidos de entrada no grupo |
| POST | `/group/participant-requests/approve` | Aprovar pedidos |
| POST | `/group/participant-requests/reject` | Rejeitar pedidos |
| POST | `/group/photo` | Definir/remover foto do grupo |
| POST | `/group/name` | Alterar nome do grupo |
| POST | `/group/locked` | Bloquear/desbloquear (só admin edita) |
| POST | `/group/announce` | Modo apenas admins (anúncio) |
| POST | `/group/topic` | Definir tema/descrição |
| GET | `/group/invite-link` | Obter link de convite |

### POST `/group`

- **Entrada**
  - **Body (JSON):** `title` (string), `participants` (array de string — JIDs ou números)
- **Saída (200):** results com group_id
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/join-with-link`

- **Entrada**
  - **Body (JSON):** `link` (string) — link de convite do grupo
- **Saída (200):** results com group_id
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/group/info-from-link`

- **Entrada**
  - **Query:** `link` (string)
- **Saída (200):** results com group_id, name, topic, created_at, participant_count, is_locked, is_announce, is_ephemeral, description
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/group/info`

- **Entrada**
  - **Query:** `group_id` (string, ex.: 120363025982934543@g.us)
- **Saída (200):** results com dados completos do grupo (Group)
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/leave`

- **Entrada**
  - **Body (JSON):** `group_id` (string)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/group/participants`

- **Entrada**
  - **Query:** `group_id` (string)
- **Saída (200):** results com group_id, name, participants (array com jid, phone_number, lid, display_name, is_admin, is_super_admin)
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/group/participants/export`

- **Entrada**
  - **Query:** `group_id` (string)
- **Saída (200):** CSV de participantes (Content-Type apropriado) ou JSON conforme implementação
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/participants`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `participants` (array de string)
- **Saída (200):** results (array de { participant, status, message })
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/participants/remove`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `participants` (array de string)
- **Saída (200):** results com status por participante
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/participants/promote`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `participants` (array de string)
- **Saída (200):** results com status por participante
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/participants/demote`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `participants` (array de string)
- **Saída (200):** results com status por participante
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/group/participant-requests`

- **Entrada**
  - **Query:** `group_id` (string)
- **Saída (200):** results.data (array de { jid, phone_number, display_name, requested_at })
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/participant-requests/approve`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `participants` (array de string) — JIDs dos pedidos a aprovar
- **Saída (200):** results com status por participante
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/participant-requests/reject`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `participants` (array de string)
- **Saída (200):** results com status por participante
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/photo`

- **Entrada**
  - **Body (multipart/form-data):** `group_id` (string), `photo` (arquivo) — ou sem photo para remover
- **Saída (200):** results com picture_id, message
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/name`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `name` (string)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/locked`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `locked` (boolean)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/announce`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `announce` (boolean)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### POST `/group/topic`

- **Entrada**
  - **Body (JSON):** `group_id` (string), `topic` (string)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

### GET `/group/invite-link`

- **Entrada**
  - **Query:** `group_id` (string)
- **Saída (200):** results com invite_link, group_id
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

## 8. Newsletter

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/newsletter/unfollow` | Deixar de seguir newsletter/canal |

### POST `/newsletter/unfollow`

- **Entrada**
  - **Headers:** `X-Device-Id` (opcional)
  - **Body (JSON):** `newsletter_id` (string, ex.: 120363024512399999@newsletter)
- **Saída (200):** `GenericResponse`
- **Saída (400):** `ErrorBadRequest` | **Saída (500):** `ErrorInternalServer`

---

## Respostas de erro padrão

- **ErrorBadRequest (400):** `{ "code": "400", "message": "string", "results": null }`
- **ErrorUnauthorized (401):** `{ "code": "401", "message": "string", "results": null }`
- **ErrorNotFound (404):** `{ "code": "404", "message": "string", "results": null }`
- **ErrorInternalServer (500):** `{ "code": "INTERNAL_SERVER_ERROR", "message": "string", "results": null }`

---

## Esquema genérico de sucesso

A maioria das respostas 200 segue:

```json
{
  "status": 200,
  "code": "SUCCESS",
  "message": "string",
  "results": { ... }
}
```

Algumas rotas retornam apenas `code`, `message` e `results` (sem `status`). O conteúdo de `results` varia conforme a rota, conforme descrito em cada seção acima.

---

*Documento gerado a partir do código (controllers REST) e do `openapi.yaml` (versão 8.1.0).*
