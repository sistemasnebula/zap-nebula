# 📚 Documentação Completa de Rotas da API WhatsApp

Este documento lista todas as rotas disponíveis na API REST, incluindo métodos HTTP, parâmetros de entrada e formato de resposta.

## 📋 Índice

1. [Autenticação](#autenticação)
2. [Device Management](#device-management)
3. [App (Aplicação)](#app-aplicação)
4. [Send (Envio de Mensagens)](#send-envio-de-mensagens)
5. [Message (Ações em Mensagens)](#message-ações-em-mensagens)
6. [Chat](#chat)
7. [User (Usuário)](#user-usuário)
8. [Group (Grupos)](#group-grupos)
9. [Newsletter](#newsletter)
10. [WebSocket](#websocket)

---

## 🔐 Autenticação

### Basic Auth

A maioria das rotas requer autenticação Basic Auth quando configurada via variável de ambiente `APP_BASIC_AUTH_CREDENTIAL`.

**Header:**
```
Authorization: Basic <base64(user:password)>
```

### Device ID

Para rotas que requerem contexto de dispositivo (exceto rotas de gerenciamento de devices), é necessário informar o `X-Device-Id` no header ou `device_id` como query parameter.

**Header:**
```
X-Device-Id: <device_id>
```

**Query Parameter (alternativo):**
```
?device_id=<device_id>
```

---

## 📱 Device Management

Rotas para gerenciar múltiplos dispositivos WhatsApp. **Não requerem** `X-Device-Id` no header.

### GET `/devices`

Lista todos os dispositivos cadastrados.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "List devices",
  "results": [
    {
      "id": "device-123",
      "display_name": "Meu WhatsApp",
      "jid": "5511999999999@s.whatsapp.net",
      "state": "connected",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

### POST `/devices`

Adiciona um novo dispositivo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `Content-Type: application/json`

**Body:**
```json
{
  "device_id": "device-123"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Device added",
  "results": {
    "id": "device-123",
    "display_name": "Meu WhatsApp",
    "jid": "",
    "state": "disconnected",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Resposta de Erro (400):**
```json
{
  "code": "BAD_REQUEST",
  "message": "Invalid request body",
  "results": null
}
```

---

### GET `/devices/:device_id`

Obtém informações de um dispositivo específico.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)

**Path Parameters:**
- `device_id` (string, obrigatório): ID do dispositivo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Device info",
  "results": {
    "id": "device-123",
    "display_name": "Meu WhatsApp",
    "jid": "5511999999999@s.whatsapp.net",
    "state": "connected",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

---

### DELETE `/devices/:device_id`

Remove um dispositivo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)

**Path Parameters:**
- `device_id` (string, obrigatório): ID do dispositivo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Device removed",
  "results": null
}
```

---

### GET `/devices/:device_id/login`

Inicia processo de login para um dispositivo específico.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)

**Path Parameters:**
- `device_id` (string, obrigatório): ID do dispositivo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Login started",
  "results": {
    "device_id": "device-123"
  }
}
```

---

### POST `/devices/:device_id/login/code`

Inicia login com código de pareamento.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `Content-Type: application/json`

**Path Parameters:**
- `device_id` (string, obrigatório): ID do dispositivo

**Query Parameters:**
- `phone` (string, opcional): Número de telefone

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Login with code started",
  "results": {
    "device_id": "device-123",
    "pair_code": "ABC-DEF-GHI"
  }
}
```

---

### POST `/devices/:device_id/logout`

Faz logout de um dispositivo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)

**Path Parameters:**
- `device_id` (string, obrigatório): ID do dispositivo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Logout requested",
  "results": null
}
```

---

### POST `/devices/:device_id/reconnect`

Reconecta um dispositivo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)

**Path Parameters:**
- `device_id` (string, obrigatório): ID do dispositivo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Reconnect requested",
  "results": null
}
```

---

### GET `/devices/:device_id/status`

Obtém status de conexão de um dispositivo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)

**Path Parameters:**
- `device_id` (string, obrigatório): ID do dispositivo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Device status",
  "results": {
    "device_id": "device-123",
    "is_connected": true,
    "is_logged_in": true
  }
}
```

---

## 📲 App (Aplicação)

Rotas para gerenciar conexão e status da aplicação. **Requerem** `X-Device-Id` no header.

### GET `/app/login`

Gera QR Code para login.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Login success",
  "results": {
    "device_id": "device-123",
    "qr_link": "http://localhost:8080/statics/qrcode/scan-qr-xxx.png",
    "qr_duration": 30
  }
}
```

---

### GET `/app/login-with-code`

Gera código de pareamento para login.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `phone` (string, opcional): Número de telefone

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Login with code success",
  "results": {
    "device_id": "device-123",
    "pair_code": "ABC-DEF-GHI"
  }
}
```

---

### GET `/app/logout`

Faz logout do dispositivo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success logout",
  "results": {
    "device_id": "device-123"
  }
}
```

---

### GET `/app/reconnect`

Reconecta o dispositivo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Reconnect success",
  "results": {
    "device_id": "device-123"
  }
}
```

---

### GET `/app/devices`

Lista dispositivos do contexto atual (compatibilidade).

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Fetch device success",
  "results": [
    {
      "id": "device-123",
      "display_name": "Meu WhatsApp",
      "jid": "5511999999999@s.whatsapp.net",
      "state": "connected"
    }
  ]
}
```

---

### GET `/app/status`

Verifica status de conexão.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Connection status retrieved",
  "results": {
    "is_connected": true,
    "is_logged_in": true,
    "device_id": "device-123"
  }
}
```

---

## 📤 Send (Envio de Mensagens)

Todas as rotas de envio **requerem** `X-Device-Id` no header.

### POST `/send/message`

Envia mensagem de texto.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "phone": "5511999999999",
  "message": "Olá, mundo!",
  "reply_message_id": "3EB0123456789ABCDEF",
  "duration": 0,
  "is_forwarded": false
}
```

**Campos:**
- `phone` (string, obrigatório): Número do destinatário (formato internacional sem +)
- `message` (string, obrigatório): Texto da mensagem
- `reply_message_id` (string, opcional): ID da mensagem para responder
- `duration` (int, opcional): Duração em segundos
- `is_forwarded` (boolean, opcional): Se a mensagem é encaminhada

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Message sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/image`

Envia imagem.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: multipart/form-data`

**Body (Form Data):**
- `phone` (string, obrigatório): Número do destinatário
- `image` (file, opcional): Arquivo de imagem
- `image_url` (string, opcional): URL da imagem
- `caption` (string, opcional): Legenda da imagem
- `view_once` (boolean, opcional): Visualização única
- `compress` (boolean, opcional): Comprimir imagem (padrão: true)
- `duration` (int, opcional): Duração
- `is_forwarded` (boolean, opcional): Se é encaminhada

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Image sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/file`

Envia arquivo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: multipart/form-data`

**Body (Form Data):**
- `phone` (string, obrigatório): Número do destinatário
- `file` (file, obrigatório): Arquivo a ser enviado
- `caption` (string, opcional): Legenda do arquivo
- `duration` (int, opcional): Duração
- `is_forwarded` (boolean, opcional): Se é encaminhada

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "File sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/video`

Envia vídeo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: multipart/form-data`

**Body (Form Data):**
- `phone` (string, obrigatório): Número do destinatário
- `video` (file, opcional): Arquivo de vídeo
- `video_url` (string, opcional): URL do vídeo
- `caption` (string, opcional): Legenda do vídeo
- `view_once` (boolean, opcional): Visualização única
- `compress` (boolean, opcional): Comprimir vídeo
- `duration` (int, opcional): Duração
- `is_forwarded` (boolean, opcional): Se é encaminhada

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Video sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/audio`

Envia áudio.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: multipart/form-data`

**Body (Form Data):**
- `phone` (string, obrigatório): Número do destinatário
- `audio` (file, opcional): Arquivo de áudio
- `audio_url` (string, opcional): URL do áudio
- `ptt` (boolean, opcional): Push-to-talk (áudio de voz)
- `duration` (int, opcional): Duração
- `is_forwarded` (boolean, opcional): Se é encaminhada

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Audio sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/sticker`

Envia sticker.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: multipart/form-data`

**Body (Form Data):**
- `phone` (string, obrigatório): Número do destinatário
- `sticker` (file, opcional): Arquivo de sticker
- `duration` (int, opcional): Duração
- `is_forwarded` (boolean, opcional): Se é encaminhada

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Sticker sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/contact`

Envia contato.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "phone": "5511999999999",
  "contact_name": "João Silva",
  "contact_phone": "5511888888888",
  "duration": 0,
  "is_forwarded": false
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Contact sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/link`

Envia link com preview.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "phone": "5511999999999",
  "url": "https://example.com",
  "caption": "Confira este link!",
  "duration": 0,
  "is_forwarded": false
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Link sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/location`

Envia localização.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "phone": "5511999999999",
  "latitude": -23.5505,
  "longitude": -46.6333,
  "name": "São Paulo",
  "address": "São Paulo, SP, Brasil",
  "duration": 0,
  "is_forwarded": false
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Location sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/poll`

Envia enquete.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "phone": "5511999999999",
  "question": "Qual sua cor favorita?",
  "options": ["Vermelho", "Azul", "Verde"],
  "duration": 0,
  "is_forwarded": false
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Poll sent",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "sent"
  }
}
```

---

### POST `/send/presence`

Atualiza presença do usuário.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "presence": "available"
}
```

**Valores de `presence`:**
- `available`: Disponível
- `unavailable`: Indisponível
- `composing`: Digitando
- `recording`: Gravando

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Presence updated",
  "results": {
    "status": "updated"
  }
}
```

---

### POST `/send/chat-presence`

Atualiza presença em um chat específico.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "phone": "5511999999999",
  "presence": "composing"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Chat presence updated",
  "results": {
    "status": "updated"
  }
}
```

---

## 💬 Message (Ações em Mensagens)

Todas as rotas **requerem** `X-Device-Id` no header.

### POST `/message/:message_id/reaction`

Adiciona reação a uma mensagem.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `message_id` (string, obrigatório): ID da mensagem

**Body:**
```json
{
  "phone": "5511999999999",
  "emoji": "👍"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Reaction added",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "reacted"
  }
}
```

---

### POST `/message/:message_id/revoke`

Revoga (exclui para todos) uma mensagem.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `message_id` (string, obrigatório): ID da mensagem

**Body:**
```json
{
  "phone": "5511999999999"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Message revoked",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "revoked"
  }
}
```

---

### POST `/message/:message_id/delete`

Exclui uma mensagem (apenas para você).

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `message_id` (string, obrigatório): ID da mensagem

**Body:**
```json
{
  "phone": "5511999999999"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Message deleted successfully",
  "results": null
}
```

---

### POST `/message/:message_id/update`

Atualiza o texto de uma mensagem.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `message_id` (string, obrigatório): ID da mensagem

**Body:**
```json
{
  "phone": "5511999999999",
  "message": "Texto atualizado"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Message updated",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "updated"
  }
}
```

---

### POST `/message/:message_id/read`

Marca mensagem como lida.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `message_id` (string, obrigatório): ID da mensagem

**Body:**
```json
{
  "phone": "5511999999999"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Message marked as read",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "read"
  }
}
```

---

### POST `/message/:message_id/star`

Marca mensagem como favorita.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `message_id` (string, obrigatório): ID da mensagem

**Body:**
```json
{
  "phone": "5511999999999"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Starred message successfully",
  "results": null
}
```

---

### POST `/message/:message_id/unstar`

Remove marca de favorita da mensagem.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `message_id` (string, obrigatório): ID da mensagem

**Body:**
```json
{
  "phone": "5511999999999"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Unstarred message successfully",
  "results": null
}
```

---

### GET `/message/:message_id/download`

Baixa mídia de uma mensagem.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Path Parameters:**
- `message_id` (string, obrigatório): ID da mensagem

**Query Parameters:**
- `phone` (string, obrigatório): Número do chat

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Media downloaded",
  "results": {
    "message_id": "3EB0123456789ABCDEF",
    "status": "downloaded",
    "media_type": "image",
    "filename": "image.jpg",
    "file_path": "/path/to/file",
    "file_size": 102400
  }
}
```

---

## 💭 Chat

Todas as rotas **requerem** `X-Device-Id` no header.

### GET `/chats`

Lista conversas.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `limit` (int, opcional, padrão: 25): Número máximo de resultados
- `offset` (int, opcional, padrão: 0): Offset para paginação
- `search` (string, opcional): Termo de busca
- `has_media` (boolean, opcional, padrão: false): Filtrar apenas chats com mídia

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get chat list",
  "results": {
    "chats": [
      {
        "jid": "5511999999999@s.whatsapp.net",
        "name": "João Silva",
        "unread_count": 5,
        "last_message": "Olá!",
        "last_message_time": "2024-01-01T12:00:00Z"
      }
    ],
    "total": 100,
    "limit": 25,
    "offset": 0
  }
}
```

---

### GET `/chat/:chat_jid/messages`

Obtém mensagens de um chat.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Path Parameters:**
- `chat_jid` (string, obrigatório): JID do chat (ex: `5511999999999@s.whatsapp.net`)

**Query Parameters:**
- `limit` (int, opcional, padrão: 50): Número máximo de resultados
- `offset` (int, opcional, padrão: 0): Offset para paginação
- `media_only` (boolean, opcional, padrão: false): Filtrar apenas mensagens com mídia
- `search` (string, opcional): Termo de busca
- `start_time` (string, opcional): Data/hora inicial (ISO 8601)
- `end_time` (string, opcional): Data/hora final (ISO 8601)
- `is_from_me` (boolean, opcional): Filtrar por mensagens enviadas/recebidas

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get chat messages",
  "results": {
    "messages": [
      {
        "id": "3EB0123456789ABCDEF",
        "from": "5511999999999@s.whatsapp.net",
        "to": "5511888888888@s.whatsapp.net",
        "message": "Olá!",
        "timestamp": "2024-01-01T12:00:00Z",
        "is_from_me": false
      }
    ],
    "total": 500,
    "limit": 50,
    "offset": 0
  }
}
```

---

### POST `/chat/:chat_jid/pin`

Fixa/desfixa um chat.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `chat_jid` (string, obrigatório): JID do chat

**Body:**
```json
{
  "pinned": true
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Chat pinned successfully",
  "results": {
    "chat_jid": "5511999999999@s.whatsapp.net",
    "pinned": true
  }
}
```

---

### POST `/chat/:chat_jid/disappearing`

Define timer de mensagens temporárias.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `chat_jid` (string, obrigatório): JID do chat

**Body:**
```json
{
  "seconds": 86400
}
```

**Valores de `seconds`:**
- `0`: Desabilitar
- `86400`: 24 horas
- `604800`: 7 dias
- `7776000`: 90 dias

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Disappearing timer set",
  "results": {
    "chat_jid": "5511999999999@s.whatsapp.net",
    "seconds": 86400
  }
}
```

---

### POST `/chat/:chat_jid/archive`

Arquiva/desarquiva um chat.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Path Parameters:**
- `chat_jid` (string, obrigatório): JID do chat

**Body:**
```json
{
  "archived": true
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Chat archived successfully",
  "results": {
    "chat_jid": "5511999999999@s.whatsapp.net",
    "archived": true
  }
}
```

---

## 👤 User (Usuário)

Todas as rotas **requerem** `X-Device-Id` no header.

### GET `/user/info`

Obtém informações de um usuário.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `phone` (string, obrigatório): Número do usuário

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get user info",
  "results": {
    "jid": "5511999999999@s.whatsapp.net",
    "name": "João Silva",
    "status": "Online"
  }
}
```

---

### GET `/user/avatar`

Obtém avatar de um usuário.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `phone` (string, obrigatório): Número do usuário

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get avatar",
  "results": {
    "url": "https://example.com/avatar.jpg",
    "exists": true
  }
}
```

---

### POST `/user/avatar`

Altera avatar do usuário logado.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: multipart/form-data`

**Body (Form Data):**
- `avatar` (file, obrigatório): Arquivo de imagem

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success change avatar",
  "results": null
}
```

---

### POST `/user/pushname`

Altera nome de exibição (push name).

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "push_name": "Meu Nome"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success change push name",
  "results": null
}
```

---

### GET `/user/my/privacy`

Obtém configurações de privacidade do usuário logado.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get privacy",
  "results": {
    "read_receipts": "everyone",
    "profile_photo": "contacts",
    "status": "contacts",
    "last_seen": "contacts"
  }
}
```

---

### GET `/user/my/groups`

Lista grupos do usuário logado.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get list groups",
  "results": [
    {
      "jid": "120363123456789012@g.us",
      "name": "Grupo de Trabalho",
      "subject": "Trabalho"
    }
  ]
}
```

---

### GET `/user/my/newsletters`

Lista newsletters do usuário logado.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get list newsletter",
  "results": [
    {
      "jid": "120363123456789012@newsletter",
      "name": "Newsletter Exemplo"
    }
  ]
}
```

---

### GET `/user/my/contacts`

Lista contatos do usuário logado.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get list contacts",
  "results": [
    {
      "jid": "5511999999999@s.whatsapp.net",
      "name": "João Silva",
      "phone": "5511999999999"
    }
  ]
}
```

---

### GET `/user/check`

Verifica se um número está no WhatsApp.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `phone` (string, obrigatório): Número a verificar

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success check user",
  "results": {
    "phone": "5511999999999",
    "is_on_whatsapp": true,
    "jid": "5511999999999@s.whatsapp.net"
  }
}
```

---

### GET `/user/business-profile`

Obtém perfil de negócio de um usuário.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `phone` (string, obrigatório): Número do usuário

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get business profile",
  "results": {
    "business_name": "Minha Empresa",
    "description": "Descrição do negócio",
    "category": "Tecnologia",
    "website": "https://example.com",
    "email": "contato@example.com"
  }
}
```

---

## 👥 Group (Grupos)

Todas as rotas **requerem** `X-Device-Id` no header.

### POST `/group`

Cria um novo grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "name": "Meu Grupo",
  "participants": ["5511999999999", "5511888888888"]
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success created group with id 120363123456789012@g.us",
  "results": {
    "group_id": "120363123456789012@g.us"
  }
}
```

---

### POST `/group/join-with-link`

Entra em um grupo via link de convite.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "link": "https://chat.whatsapp.com/ABC123DEF456"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success joined group",
  "results": {
    "group_id": "120363123456789012@g.us"
  }
}
```

---

### GET `/group/info-from-link`

Obtém informações de um grupo a partir do link.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `link` (string, obrigatório): Link do grupo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get group info from link",
  "results": {
    "group_id": "120363123456789012@g.us",
    "name": "Nome do Grupo",
    "subject": "Assunto",
    "participants_count": 10
  }
}
```

---

### GET `/group/info`

Obtém informações de um grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `group_id` (string, obrigatório): ID do grupo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get group info",
  "results": {
    "jid": "120363123456789012@g.us",
    "name": "Nome do Grupo",
    "subject": "Assunto",
    "creation_time": "2024-01-01T00:00:00Z",
    "participants_count": 10
  }
}
```

---

### POST `/group/leave`

Sai de um grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success leave group",
  "results": null
}
```

---

### GET `/group/participants`

Lista participantes de um grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `group_id` (string, obrigatório): ID do grupo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success getting group participants",
  "results": {
    "group_id": "120363123456789012@g.us",
    "participants": [
      {
        "jid": "5511999999999@s.whatsapp.net",
        "phone_number": "5511999999999",
        "display_name": "João Silva",
        "is_admin": true,
        "is_super_admin": false
      }
    ]
  }
}
```

---

### GET `/group/participants/export`

Exporta participantes de um grupo em CSV.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `group_id` (string, obrigatório): ID do grupo

**Resposta de Sucesso (200):**
```
Content-Type: text/csv; charset=utf-8
Content-Disposition: attachment; filename="group-120363123456789012_g_us-participants.csv"

participant_jid,phone_number,lid,display_name,role
5511999999999@s.whatsapp.net,5511999999999,,João Silva,admin
```

---

### POST `/group/participants`

Adiciona participantes a um grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "participants": ["5511999999999", "5511888888888"]
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success add participants",
  "results": {
    "added": ["5511999999999@s.whatsapp.net"],
    "failed": []
  }
}
```

---

### POST `/group/participants/remove`

Remove participantes de um grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "participants": ["5511999999999"]
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success delete participants",
  "results": {
    "removed": ["5511999999999@s.whatsapp.net"],
    "failed": []
  }
}
```

---

### POST `/group/participants/promote`

Promove participantes a administradores.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "participants": ["5511999999999"]
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success promote participants",
  "results": {
    "promoted": ["5511999999999@s.whatsapp.net"],
    "failed": []
  }
}
```

---

### POST `/group/participants/demote`

Remove privilégios de administrador.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "participants": ["5511999999999"]
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success demote participants",
  "results": {
    "demoted": ["5511999999999@s.whatsapp.net"],
    "failed": []
  }
}
```

---

### GET `/group/participant-requests`

Lista solicitações de entrada em grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `group_id` (string, obrigatório): ID do grupo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success getting list requested participants",
  "results": {
    "group_id": "120363123456789012@g.us",
    "requests": [
      {
        "jid": "5511999999999@s.whatsapp.net",
        "request_time": "2024-01-01T12:00:00Z"
      }
    ]
  }
}
```

---

### POST `/group/participant-requests/approve`

Aprova solicitações de entrada em grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "participants": ["5511999999999"]
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success approve requested participants",
  "results": {
    "approved": ["5511999999999@s.whatsapp.net"],
    "failed": []
  }
}
```

---

### POST `/group/participant-requests/reject`

Rejeita solicitações de entrada em grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "participants": ["5511999999999"]
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success reject requested participants",
  "results": {
    "rejected": ["5511999999999@s.whatsapp.net"],
    "failed": []
  }
}
```

---

### POST `/group/photo`

Define foto do grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: multipart/form-data`

**Body (Form Data):**
- `group_id` (string, obrigatório): ID do grupo
- `photo` (file, opcional): Arquivo de imagem (se não enviado, remove a foto)

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success update group photo",
  "results": {
    "picture_id": "123456789",
    "message": "Success update group photo"
  }
}
```

---

### POST `/group/name`

Altera nome do grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "name": "Novo Nome do Grupo"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success update group name to 'Novo Nome do Grupo'",
  "results": null
}
```

---

### POST `/group/locked`

Define se o grupo está bloqueado (apenas admins podem enviar mensagens).

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "locked": true
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success set group as locked",
  "results": null
}
```

---

### POST `/group/announce`

Define modo de anúncios (apenas admins podem enviar mensagens).

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "announce": true
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success enable announce mode",
  "results": null
}
```

---

### POST `/group/topic`

Define tópico do grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "group_id": "120363123456789012@g.us",
  "topic": "Tópico do grupo"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success update group topic",
  "results": null
}
```

---

### GET `/group/invite-link`

Obtém link de convite do grupo.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)

**Query Parameters:**
- `group_id` (string, obrigatório): ID do grupo

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success get group invite link",
  "results": {
    "link": "https://chat.whatsapp.com/ABC123DEF456",
    "group_id": "120363123456789012@g.us"
  }
}
```

---

## 📰 Newsletter

Todas as rotas **requerem** `X-Device-Id` no header.

### POST `/newsletter/unfollow`

Para de seguir uma newsletter.

**Headers:**
- `Authorization: Basic <credentials>` (se Basic Auth estiver habilitado)
- `X-Device-Id: <device_id>` (obrigatório)
- `Content-Type: application/json`

**Body:**
```json
{
  "newsletter_jid": "120363123456789012@newsletter"
}
```

**Resposta de Sucesso (200):**
```json
{
  "code": "SUCCESS",
  "message": "Success unfollow newsletter",
  "results": null
}
```

---

## 🔌 WebSocket

### GET `/ws`

Estabelece conexão WebSocket para receber eventos em tempo real.

**Headers:**
- `Upgrade: websocket`
- `Connection: Upgrade`
- `Sec-WebSocket-Key: <key>`
- `Sec-WebSocket-Version: 13`

**Nota:** Esta rota não requer Basic Auth, mas pode ser protegida por outras configurações.

**Eventos Enviados:**
- QR Code atualizado
- Status de conexão
- Mensagens recebidas
- Erros

---

## 📝 Formato Padrão de Resposta

Todas as rotas retornam respostas no seguinte formato:

### Sucesso (200)
```json
{
  "code": "SUCCESS",
  "message": "Mensagem de sucesso",
  "results": { /* dados específicos */ }
}
```

### Erro (400, 401, 404, 500, etc.)
```json
{
  "code": "ERROR_CODE",
  "message": "Mensagem de erro",
  "results": null
}
```

**Códigos de Erro Comuns:**
- `BAD_REQUEST`: Requisição inválida
- `UNAUTHORIZED`: Não autenticado
- `FORBIDDEN`: Sem permissão
- `NOT_FOUND`: Recurso não encontrado
- `DEVICE_ID_REQUIRED`: Device ID não fornecido
- `INTERNAL_SERVER_ERROR`: Erro interno do servidor

---

## 🔗 Base Path

Se configurado via `APP_BASE_PATH`, todas as rotas terão este prefixo.

**Exemplo:**
- Base Path: `/api/v1`
- Rota: `/send/message`
- URL completa: `/api/v1/send/message`

---

## 📌 Notas Importantes

1. **Device ID**: A maioria das rotas requer `X-Device-Id` no header. Exceções são as rotas de gerenciamento de devices (`/devices/*`).

2. **Formato de Telefone**: Use formato internacional sem o sinal `+` (ex: `5511999999999`).

3. **JID**: JID (Jabber ID) é o identificador único do WhatsApp no formato `número@s.whatsapp.net` para usuários ou `número@g.us` para grupos.

4. **Multipart/Form-Data**: Para envio de arquivos, use `multipart/form-data` como Content-Type.

5. **Timeouts**: Algumas operações podem demorar. Configure timeouts adequados no cliente.

6. **Rate Limiting**: Respeite os limites do WhatsApp para evitar bloqueios.

---

**Última atualização:** 2024-01-01

