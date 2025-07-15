# 📝 Changelog - Timeout do QR Code

## 🔄 Versão 6.1.4 - Julho de 2025

### ✅ Alteração Revertida

#### **Timeout do QR Code novamente reduzido pela metade**
- **Arquivo:** `src/usecase/app.go`
- **Mudança:** Timeout do WhatsApp volta a ser dividido por 2
- **Impacto:** Usuário tem metade do tempo real para escanear o QR code, como margem de segurança

### 📊 Detalhes das Alterações

#### **Antes:**
```go
response.Duration = evt.Timeout / time.Second  // 60 segundos
```

#### **Depois:**
```go
// NOTA: O timeout volta a ser dividido por 2 para dar margem de segurança ao usuário
// e evitar que o QR code expire enquanto o usuário ainda está tentando escanear.
response.Duration = evt.Timeout / time.Second / 2  // 30 segundos
```

### 📋 Arquivos Modificados

1. **`src/usecase/app.go`**
   - Linha 62: Timeout volta a ser dividido por 2
   - Comentário explicativo atualizado

2. **`docs/openapi.yaml`**
   - Exemplo ajustado de 60 para 30 segundos
   - Descrição explicativa atualizada

3. **`docs/QR_TIMEOUT_CHANGES.md`**
   - Documentação revisada para refletir a volta da divisão por 2
   - Explicação do motivo da alteração

### 🎯 Benefícios e Pontos de Atenção

- ✅ **Margem de segurança**: Reduz risco do QR code expirar enquanto o usuário tenta escanear
- ⚠️ **Menos tempo para o usuário**: Pode aumentar a sensação de pressa ou frustração
- ✅ **Consistência** com versões anteriores
- ✅ **Experiência previsível** para o sistema

### 🔧 Compatibilidade

- ✅ **Compatível** com versões anteriores
- ✅ **Não quebra** funcionalidades existentes
- ✅ **Transparente** para outras partes do sistema

### 📈 Impacto Técnico

- **Performance:** Nenhum impacto
- **Memória:** Nenhum impacto
- **API:** Compatível (mesmo endpoint, valor diferente)
- **Frontend:** Compatível (usa valor dinâmico)

### 🚀 Próximos Passos

1. **Testar** a mudança em ambiente de desenvolvimento
2. **Validar** que o timeout exibido é metade do real
3. **Monitorar** taxa de sucesso no login e feedback dos usuários
4. **Avaliar** ajuste fino da margem de segurança se necessário 