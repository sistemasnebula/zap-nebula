# Especificação Técnica - Implementação de Status de Entrega e Leitura

## 📋 Visão Geral

Este documento especifica a implementação de um sistema completo de monitoramento de status de entrega e leitura de mensagens WhatsApp no projeto **Zap Nebula**.

---

## 🎯 Objetivos da Implementação

### Objetivos Primários
1. **Persistir status** de entrega e leitura de mensagens
2. **Fornecer APIs** para consulta de status
3. **Implementar WebSocket** para atualizações em tempo real
4. **Melhorar respostas** de envio com informações de status

### Objetivos Secundários
1. **Auditoria completa** de mensagens
2. **Histórico de mudanças** de status
3. **Integração** com sistemas externos
4. **Monitoramento** em tempo real

---

## 🏗️ Arquitetura Proposta

### 1. Modelo de Dados

#### Tabela: `message_status`
```sql
CREATE TABLE message_status (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL,
    recipient_jid TEXT NOT NULL,
    sender_jid TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('sent', 'delivered', 'read', 'failed')),
    timestamp DATETIME NOT NULL,
    metadata TEXT, -- JSON com informações adicionais
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_message_status_message_id ON message_status(message_id);
CREATE INDEX idx_message_status_recipient ON message_status(recipient_jid);
CREATE INDEX idx_message_status_sender ON message_status(sender_jid);
CREATE INDEX idx_message_status_status ON message_status(status);
CREATE INDEX idx_message_status_timestamp ON message_status(timestamp);
CREATE INDEX idx_message_status_composite ON message_status(message_id, recipient_jid, status);
```

#### Tabela: `message_status_history`
```sql
CREATE TABLE message_status_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL,
    recipient_jid TEXT NOT NULL,
    sender_jid TEXT NOT NULL,
    old_status TEXT,
    new_status TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_message_status_history_message_id ON message_status_history(message_id);
CREATE INDEX idx_message_status_history_timestamp ON message_status_history(timestamp);
```

### 2. Estrutura de Domínio

#### Domain: `src/domains/message/status.go`
```go
package message

import "time"

type MessageStatus string

const (
	StatusSent      MessageStatus = "sent"
	StatusDelivered MessageStatus = "delivered"
	StatusRead      MessageStatus = "read"
	StatusFailed    MessageStatus = "failed"
)

type MessageStatusInfo struct {
	ID           int64        `json:"id"`
	MessageID    string       `json:"message_id"`
	RecipientJID string       `json:"recipient_jid"`
	SenderJID    string       `json:"sender_jid"`
	Status       MessageStatus `json:"status"`
	Timestamp    time.Time    `json:"timestamp"`
	Metadata     string       `json:"metadata,omitempty"`
	CreatedAt    time.Time    `json:"created_at"`
	UpdatedAt    time.Time    `json:"updated_at"`
}

type MessageStatusHistory struct {
	ID           int64        `json:"id"`
	MessageID    string       `json:"message_id"`
	RecipientJID string       `json:"recipient_jid"`
	SenderJID    string       `json:"sender_jid"`
	OldStatus    MessageStatus `json:"old_status,omitempty"`
	NewStatus    MessageStatus `json:"new_status"`
	Timestamp    time.Time    `json:"timestamp"`
	CreatedAt    time.Time    `json:"created_at"`
}

type MessageStatusRequest struct {
	MessageID string `json:"message_id" uri:"message_id"`
}

type MessageStatusResponse struct {
	MessageID    string              `json:"message_id"`
	RecipientJID string              `json:"recipient_jid"`
	CurrentStatus MessageStatusInfo  `json:"current_status"`
	History      []MessageStatusInfo `json:"history,omitempty"`
}

type MultipleMessageStatusRequest struct {
	MessageIDs []string `json:"message_ids" form:"message_ids"`
}

type MultipleMessageStatusResponse struct {
	Statuses map[string]MessageStatusInfo `json:"statuses"`
}

type MessageStatusFilter struct {
	RecipientJID string       `json:"recipient_jid" form:"recipient_jid"`
	SenderJID    string       `json:"sender_jid" form:"sender_jid"`
	Status       MessageStatus `json:"status" form:"status"`
	FromDate     *time.Time   `json:"from_date" form:"from_date"`
	ToDate       *time.Time   `json:"to_date" form:"to_date"`
	Limit        int          `json:"limit" form:"limit"`
	Offset       int          `json:"offset" form:"offset"`
}
```

### 3. Interface de Serviço

#### Interface: `src/domains/message/status.go`
```go
type IMessageStatusUsecase interface {
	// Consultas
	GetMessageStatus(ctx context.Context, request MessageStatusRequest) (response MessageStatusResponse, err error)
	GetMultipleMessageStatus(ctx context.Context, request MultipleMessageStatusRequest) (response MultipleMessageStatusResponse, err error)
	GetMessagesByStatus(ctx context.Context, filter MessageStatusFilter) (response []MessageStatusInfo, err error)
	GetMessageStatusHistory(ctx context.Context, request MessageStatusRequest) (response []MessageStatusHistory, err error)
	
	// Atualizações
	UpdateMessageStatus(ctx context.Context, messageID, recipientJID, senderJID string, status MessageStatus, metadata string) error
	BulkUpdateMessageStatus(ctx context.Context, updates []MessageStatusInfo) error
	
	// Limpeza
	CleanupOldStatus(ctx context.Context, daysToKeep int) error
}
```

---

## 🔧 Implementação dos Componentes

### 1. Repositório de Dados

#### Repository: `src/infrastructure/repository/message_status.go`
```go
package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/aldinokemal/go-whatsapp-web-multidevice/domains/message"
)

type messageStatusRepository struct {
	db *sql.DB
}

func NewMessageStatusRepository(db *sql.DB) message.IMessageStatusRepository {
	return &messageStatusRepository{db: db}
}

func (r *messageStatusRepository) SaveStatus(ctx context.Context, status message.MessageStatusInfo) error {
	query := `
		INSERT INTO message_status (message_id, recipient_jid, sender_jid, status, timestamp, metadata)
		VALUES (?, ?, ?, ?, ?, ?)
	`
	
	_, err := r.db.ExecContext(ctx, query,
		status.MessageID,
		status.RecipientJID,
		status.SenderJID,
		status.Status,
		status.Timestamp,
		status.Metadata,
	)
	
	return err
}

func (r *messageStatusRepository) UpdateStatus(ctx context.Context, messageID, recipientJID string, status message.MessageStatus, metadata string) error {
	query := `
		UPDATE message_status 
		SET status = ?, metadata = ?, updated_at = CURRENT_TIMESTAMP
		WHERE message_id = ? AND recipient_jid = ?
	`
	
	result, err := r.db.ExecContext(ctx, query, status, metadata, messageID, recipientJID)
	if err != nil {
		return err
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	
	if rowsAffected == 0 {
		return fmt.Errorf("no status found for message %s and recipient %s", messageID, recipientJID)
	}
	
	return nil
}

func (r *messageStatusRepository) GetStatus(ctx context.Context, messageID, recipientJID string) (message.MessageStatusInfo, error) {
	query := `
		SELECT id, message_id, recipient_jid, sender_jid, status, timestamp, metadata, created_at, updated_at
		FROM message_status
		WHERE message_id = ? AND recipient_jid = ?
		ORDER BY timestamp DESC
		LIMIT 1
	`
	
	var status message.MessageStatusInfo
	err := r.db.QueryRowContext(ctx, query, messageID, recipientJID).Scan(
		&status.ID,
		&status.MessageID,
		&status.RecipientJID,
		&status.SenderJID,
		&status.Status,
		&status.Timestamp,
		&status.Metadata,
		&status.CreatedAt,
		&status.UpdatedAt,
	)
	
	return status, err
}

func (r *messageStatusRepository) GetMultipleStatus(ctx context.Context, messageIDs []string) (map[string]message.MessageStatusInfo, error) {
	if len(messageIDs) == 0 {
		return make(map[string]message.MessageStatusInfo), nil
	}
	
	// Construir query dinâmica
	placeholders := make([]string, len(messageIDs))
	args := make([]interface{}, len(messageIDs))
	for i, id := range messageIDs {
		placeholders[i] = "?"
		args[i] = id
	}
	
	query := fmt.Sprintf(`
		SELECT message_id, recipient_jid, sender_jid, status, timestamp, metadata, created_at, updated_at
		FROM message_status
		WHERE message_id IN (%s)
		AND (message_id, recipient_jid, timestamp) IN (
			SELECT message_id, recipient_jid, MAX(timestamp)
			FROM message_status
			WHERE message_id IN (%s)
			GROUP BY message_id, recipient_jid
		)
	`, strings.Join(placeholders, ","), strings.Join(placeholders, ","))
	
	rows, err := r.db.QueryContext(ctx, query, append(args, args...)...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	statuses := make(map[string]message.MessageStatusInfo)
	for rows.Next() {
		var status message.MessageStatusInfo
		err := rows.Scan(
			&status.MessageID,
			&status.RecipientJID,
			&status.SenderJID,
			&status.Status,
			&status.Timestamp,
			&status.Metadata,
			&status.CreatedAt,
			&status.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		statuses[status.MessageID] = status
	}
	
	return statuses, nil
}

func (r *messageStatusRepository) GetStatusHistory(ctx context.Context, messageID, recipientJID string) ([]message.MessageStatusHistory, error) {
	query := `
		SELECT id, message_id, recipient_jid, sender_jid, old_status, new_status, timestamp, created_at
		FROM message_status_history
		WHERE message_id = ? AND recipient_jid = ?
		ORDER BY timestamp ASC
	`
	
	rows, err := r.db.QueryContext(ctx, query, messageID, recipientJID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	var history []message.MessageStatusHistory
	for rows.Next() {
		var h message.MessageStatusHistory
		err := rows.Scan(
			&h.ID,
			&h.MessageID,
			&h.RecipientJID,
			&h.SenderJID,
			&h.OldStatus,
			&h.NewStatus,
			&h.Timestamp,
			&h.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		history = append(history, h)
	}
	
	return history, nil
}

func (r *messageStatusRepository) CleanupOldStatus(ctx context.Context, daysToKeep int) error {
	query := `
		DELETE FROM message_status 
		WHERE created_at < datetime('now', '-%d days')
	`
	
	_, err := r.db.ExecContext(ctx, fmt.Sprintf(query, daysToKeep))
	return err
}
```

### 2. Serviço de Negócio

#### Service: `src/usecase/message_status.go`
```go
package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	domainMessage "github.com/aldinokemal/go-whatsapp-web-multidevice/domains/message"
	"github.com/aldinokemal/go-whatsapp-web-multidevice/infrastructure/repository"
	"github.com/sirupsen/logrus"
)

type messageStatusService struct {
	repo repository.IMessageStatusRepository
}

func NewMessageStatusService(repo repository.IMessageStatusRepository) domainMessage.IMessageStatusUsecase {
	return &messageStatusService{repo: repo}
}

func (s *messageStatusService) GetMessageStatus(ctx context.Context, request domainMessage.MessageStatusRequest) (response domainMessage.MessageStatusResponse, err error) {
	// Buscar status atual
	status, err := s.repo.GetStatus(ctx, request.MessageID, request.RecipientJID)
	if err != nil {
		return response, err
	}
	
	response.MessageID = request.MessageID
	response.RecipientJID = request.RecipientJID
	response.CurrentStatus = status
	
	// Buscar histórico se solicitado
	if request.IncludeHistory {
		history, err := s.repo.GetStatusHistory(ctx, request.MessageID, request.RecipientJID)
		if err != nil {
			logrus.Warnf("Failed to get status history: %v", err)
		} else {
			response.History = history
		}
	}
	
	return response, nil
}

func (s *messageStatusService) GetMultipleMessageStatus(ctx context.Context, request domainMessage.MultipleMessageStatusRequest) (response domainMessage.MultipleMessageStatusResponse, err error) {
	statuses, err := s.repo.GetMultipleStatus(ctx, request.MessageIDs)
	if err != nil {
		return response, err
	}
	
	response.Statuses = statuses
	return response, nil
}

func (s *messageStatusService) UpdateMessageStatus(ctx context.Context, messageID, recipientJID, senderJID string, status domainMessage.MessageStatus, metadata string) error {
	// Criar novo registro de status
	statusInfo := domainMessage.MessageStatusInfo{
		MessageID:    messageID,
		RecipientJID: recipientJID,
		SenderJID:    senderJID,
		Status:       status,
		Timestamp:    time.Now(),
		Metadata:     metadata,
	}
	
	return s.repo.SaveStatus(ctx, statusInfo)
}

func (s *messageStatusService) BulkUpdateMessageStatus(ctx context.Context, updates []domainMessage.MessageStatusInfo) error {
	for _, update := range updates {
		err := s.repo.SaveStatus(ctx, update)
		if err != nil {
			logrus.Errorf("Failed to save status for message %s: %v", update.MessageID, err)
			return err
		}
	}
	return nil
}

func (s *messageStatusService) CleanupOldStatus(ctx context.Context, daysToKeep int) error {
	return s.repo.CleanupOldStatus(ctx, daysToKeep)
}
```

### 3. Controllers REST

#### Controller: `src/ui/rest/message_status.go`
```go
package rest

import (
	"strconv"
	"strings"

	domainMessage "github.com/aldinokemal/go-whatsapp-web-multidevice/domains/message"
	"github.com/aldinokemal/go-whatsapp-web-multidevice/pkg/utils"
	"github.com/gofiber/fiber/v2"
)

type MessageStatus struct {
	Service domainMessage.IMessageStatusUsecase
}

func InitRestMessageStatus(app *fiber.App, service domainMessage.IMessageStatusUsecase) MessageStatus {
	rest := MessageStatus{Service: service}
	
	app.Get("/message/:message_id/status", rest.GetMessageStatus)
	app.Get("/messages/status", rest.GetMultipleMessageStatus)
	app.Get("/messages/by-status/:status", rest.GetMessagesByStatus)
	app.Get("/message/:message_id/status-history", rest.GetMessageStatusHistory)
	
	return rest
}

func (controller *MessageStatus) GetMessageStatus(c *fiber.Ctx) error {
	var request domainMessage.MessageStatusRequest
	request.MessageID = c.Params("message_id")
	request.RecipientJID = c.Query("recipient_jid")
	request.IncludeHistory = c.Query("include_history") == "true"
	
	response, err := controller.Service.GetMessageStatus(c.UserContext(), request)
	utils.PanicIfNeeded(err)
	
	return c.JSON(utils.ResponseData{
		Status:  200,
		Code:    "SUCCESS",
		Message: "Message status retrieved successfully",
		Results: response,
	})
}

func (controller *MessageStatus) GetMultipleMessageStatus(c *fiber.Ctx) error {
	var request domainMessage.MultipleMessageStatusRequest
	messageIDs := c.Query("message_ids")
	if messageIDs != "" {
		request.MessageIDs = strings.Split(messageIDs, ",")
	}
	
	response, err := controller.Service.GetMultipleMessageStatus(c.UserContext(), request)
	utils.PanicIfNeeded(err)
	
	return c.JSON(utils.ResponseData{
		Status:  200,
		Code:    "SUCCESS",
		Message: "Multiple message status retrieved successfully",
		Results: response,
	})
}

func (controller *MessageStatus) GetMessagesByStatus(c *fiber.Ctx) error {
	var filter domainMessage.MessageStatusFilter
	filter.Status = domainMessage.MessageStatus(c.Params("status"))
	filter.RecipientJID = c.Query("recipient_jid")
	filter.SenderJID = c.Query("sender_jid")
	
	// Parse limit and offset
	if limitStr := c.Query("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil {
			filter.Limit = limit
		}
	}
	
	if offsetStr := c.Query("offset"); offsetStr != "" {
		if offset, err := strconv.Atoi(offsetStr); err == nil {
			filter.Offset = offset
		}
	}
	
	response, err := controller.Service.GetMessagesByStatus(c.UserContext(), filter)
	utils.PanicIfNeeded(err)
	
	return c.JSON(utils.ResponseData{
		Status:  200,
		Code:    "SUCCESS",
		Message: "Messages by status retrieved successfully",
		Results: response,
	})
}

func (controller *MessageStatus) GetMessageStatusHistory(c *fiber.Ctx) error {
	var request domainMessage.MessageStatusRequest
	request.MessageID = c.Params("message_id")
	request.RecipientJID = c.Query("recipient_jid")
	
	response, err := controller.Service.GetMessageStatusHistory(c.UserContext(), request)
	utils.PanicIfNeeded(err)
	
	return c.JSON(utils.ResponseData{
		Status:  200,
		Code:    "SUCCESS",
		Message: "Message status history retrieved successfully",
		Results: response,
	})
}
```

### 4. Modificação do Handler de Receipts

#### Modificação: `src/infrastructure/whatsapp/init.go`
```go
func handleReceipt(ctx context.Context, evt *events.Receipt) {
	// Determinar o status baseado no tipo de receipt
	var status domainMessage.MessageStatus
	var metadata string
	
	switch evt.Type {
	case types.ReceiptTypeRead, types.ReceiptTypeReadSelf:
		status = domainMessage.StatusRead
		metadata = fmt.Sprintf(`{"read_by": "%s", "read_type": "%s"}`, evt.SourceString(), evt.Type.String())
	case types.ReceiptTypeDelivered:
		status = domainMessage.StatusDelivered
		metadata = fmt.Sprintf(`{"delivered_to": "%s"}`, evt.SourceString())
	default:
		status = domainMessage.StatusSent
		metadata = fmt.Sprintf(`{"receipt_type": "%s"}`, evt.Type.String())
	}
	
	// Salvar status no banco de dados
	for _, messageID := range evt.MessageIDs {
		err := messageStatusService.UpdateMessageStatus(
			ctx,
			messageID,
			evt.SourceString(),
			cli.Store.ID.String(),
			status,
			metadata,
		)
		if err != nil {
			log.Errorf("Failed to save message status: %v", err)
		}
	}
	
	// Broadcast via WebSocket se configurado
	if websocket.IsWebSocketEnabled() {
		for _, messageID := range evt.MessageIDs {
			websocket.Broadcast <- websocket.BroadcastMessage{
				Code: "MESSAGE_STATUS_UPDATE",
				Data: map[string]interface{}{
					"message_id": messageID,
					"status":     status,
					"timestamp":  evt.Timestamp,
					"recipient":  evt.SourceString(),
				},
			}
		}
	}
	
	// Log existente
	switch evt.Type {
	case types.ReceiptTypeRead, types.ReceiptTypeReadSelf:
		log.Infof("%v was read by %s at %s", evt.MessageIDs, evt.SourceString(), evt.Timestamp)
	case types.ReceiptTypeDelivered:
		log.Infof("%s was delivered to %s at %s", evt.MessageIDs[0], evt.SourceString(), evt.Timestamp)
	}
}
```

### 5. Modificação das Respostas de Envio

#### Modificação: `src/usecase/send.go`
```go
func (service serviceSend) SendText(ctx context.Context, request domainSend.MessageRequest) (response domainSend.GenericResponse, err error) {
	// ... código existente ...
	
	ts, err := service.wrapSendMessage(ctx, dataWaRecipient, msg, request.Message)
	if err != nil {
		return response, err
	}
	
	// Salvar status inicial
	err = messageStatusService.UpdateMessageStatus(
		ctx,
		ts.ID,
		dataWaRecipient.String(),
		service.WaCli.Store.ID.String(),
		domainMessage.StatusSent,
		fmt.Sprintf(`{"sent_at": "%s"}`, ts.Timestamp.Format(time.RFC3339)),
	)
	if err != nil {
		logrus.Warnf("Failed to save initial message status: %v", err)
	}
	
	response.MessageID = ts.ID
	response.Status = fmt.Sprintf("Message sent to %s (server timestamp: %s)", request.Phone, ts.Timestamp.String())
	response.SentAt = ts.Timestamp
	
	return response, nil
}
```

---

## 🔌 Integração com WebSocket

### Evento de Status Update
```go
// Evento enviado via WebSocket
type StatusUpdateEvent struct {
	Type      string                 `json:"type"`
	MessageID string                 `json:"message_id"`
	Status    domainMessage.MessageStatus `json:"status"`
	Timestamp time.Time              `json:"timestamp"`
	Recipient string                 `json:"recipient"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// Exemplo de uso no frontend
const ws = new WebSocket('ws://localhost:3000/ws');

ws.onmessage = function(event) {
	const data = JSON.parse(event.data);
	
	if (data.type === 'MESSAGE_STATUS_UPDATE') {
		console.log(`Message ${data.message_id} status: ${data.status}`);
		// Atualizar UI com novo status
		updateMessageStatus(data.message_id, data.status);
	}
};
```

---

## 📝 Documentação da API

### Endpoints Novos

#### 1. GET /message/{message_id}/status
Consulta o status atual de uma mensagem específica.

**Parâmetros**:
- `message_id` (path): ID da mensagem
- `recipient_jid` (query): JID do destinatário
- `include_history` (query): Incluir histórico (true/false)

**Resposta**:
```json
{
  "code": "SUCCESS",
  "message": "Message status retrieved successfully",
  "results": {
    "message_id": "3EB0288F008D32FCD0A424",
    "recipient_jid": "5511999999999@s.whatsapp.net",
    "current_status": {
      "status": "read",
      "timestamp": "2024-12-01T10:01:30Z",
      "metadata": "{\"read_by\": \"5511999999999@s.whatsapp.net\"}"
    },
    "history": [
      {
        "status": "sent",
        "timestamp": "2024-12-01T10:00:00Z"
      },
      {
        "status": "delivered",
        "timestamp": "2024-12-01T10:00:05Z"
      }
    ]
  }
}
```

#### 2. GET /messages/status
Consulta o status de múltiplas mensagens.

**Parâmetros**:
- `message_ids` (query): IDs separados por vírgula

**Resposta**:
```json
{
  "code": "SUCCESS",
  "message": "Multiple message status retrieved successfully",
  "results": {
    "statuses": {
      "3EB0288F008D32FCD0A424": {
        "status": "read",
        "timestamp": "2024-12-01T10:01:30Z"
      },
      "57D29F74B7FC62F57D8AC2": {
        "status": "delivered",
        "timestamp": "2024-12-01T10:00:05Z"
      }
    }
  }
}
```

#### 3. GET /messages/by-status/{status}
Consulta mensagens por status específico.

**Parâmetros**:
- `status` (path): Status para filtrar (sent, delivered, read, failed)
- `recipient_jid` (query): Filtrar por destinatário
- `limit` (query): Limite de resultados
- `offset` (query): Offset para paginação

---

## 🧪 Testes

### Testes Unitários
```go
func TestMessageStatusService_GetMessageStatus(t *testing.T) {
	// Setup
	mockRepo := &MockMessageStatusRepository{}
	service := NewMessageStatusService(mockRepo)
	
	// Test data
	request := domainMessage.MessageStatusRequest{
		MessageID:    "test-message-id",
		RecipientJID: "5511999999999@s.whatsapp.net",
	}
	
	expectedStatus := domainMessage.MessageStatusInfo{
		MessageID:    "test-message-id",
		RecipientJID: "5511999999999@s.whatsapp.net",
		Status:       domainMessage.StatusRead,
		Timestamp:    time.Now(),
	}
	
	mockRepo.On("GetStatus", mock.Anything, request.MessageID, request.RecipientJID).
		Return(expectedStatus, nil)
	
	// Execute
	response, err := service.GetMessageStatus(context.Background(), request)
	
	// Assert
	assert.NoError(t, err)
	assert.Equal(t, expectedStatus, response.CurrentStatus)
	mockRepo.AssertExpectations(t)
}
```

### Testes de Integração
```go
func TestMessageStatusAPI_GetMessageStatus(t *testing.T) {
	// Setup
	app := fiber.New()
	service := setupTestService()
	InitRestMessageStatus(app, service)
	
	// Test
	req := httptest.NewRequest("GET", "/message/test-id/status?recipient_jid=5511999999999@s.whatsapp.net", nil)
	resp, _ := app.Test(req)
	
	// Assert
	assert.Equal(t, 200, resp.StatusCode)
	
	var response utils.ResponseData
	json.NewDecoder(resp.Body).Decode(&response)
	assert.Equal(t, "SUCCESS", response.Code)
}
```

---

## 🚀 Plano de Implementação

### Fase 1: Infraestrutura (2 dias)
- [ ] Criar tabelas no banco de dados
- [ ] Implementar repositório
- [ ] Configurar migrações

### Fase 2: Serviços (3 dias)
- [ ] Implementar service de status
- [ ] Modificar handler de receipts
- [ ] Adicionar validações

### Fase 3: APIs (3 dias)
- [ ] Implementar controllers REST
- [ ] Adicionar endpoints
- [ ] Documentar APIs

### Fase 4: WebSocket (2 dias)
- [ ] Implementar eventos de status
- [ ] Configurar broadcast
- [ ] Testar tempo real

### Fase 5: Testes (2 dias)
- [ ] Testes unitários
- [ ] Testes de integração
- [ ] Testes de performance

### Fase 6: Documentação (1 dia)
- [ ] Atualizar OpenAPI
- [ ] Criar guias de uso
- [ ] Documentar exemplos

**Total**: 13 dias de desenvolvimento

---

## 📊 Métricas de Sucesso

### Técnicas
- [ ] 100% de cobertura de testes
- [ ] Latência < 100ms para consultas
- [ ] Suporte a 1000+ mensagens simultâneas
- [ ] Zero downtime durante deploy

### Funcionais
- [ ] Status persistidos corretamente
- [ ] APIs respondendo conforme especificação
- [ ] WebSocket funcionando em tempo real
- [ ] Histórico completo mantido

### Negócio
- [ ] Redução de 50% em dúvidas sobre entrega
- [ ] Aumento de 30% na confiança do sistema
- [ ] Melhoria na experiência do usuário

---

**Documento**: Especificação Técnica - Status de Entrega e Leitura  
**Versão**: 1.0  
**Data**: Dezembro 2024  
**Status**: Pronto para implementação 