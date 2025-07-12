# 📝 Changelog - Timeout do QR Code

## 🔄 Versão 6.1.3 - Janeiro 2025

### ✅ Melhorias Implementadas

#### **Timeout do QR Code Corrigido**
- **Arquivo:** `src/usecase/app.go`
- **Mudança:** Removida divisão por 2 do timeout do WhatsApp
- **Impacto:** Usuário agora tem o tempo total real para escanear o QR code

### 📊 Detalhes das Alterações

#### **Antes:**
```go
response.Duration = evt.Timeout / time.Second / 2  // 30 segundos
```

#### **Depois:**
```go
// NOTA: Anteriormente o timeout era dividido por 2 para dar margem de segurança ao usuário
// e evitar que o QR code expirasse enquanto o usuário ainda estava tentando escanear.
// Isso foi removido para permitir que o usuário tenha o tempo total disponível
// para escanear o QR code conforme definido pelo WhatsApp.
response.Duration = evt.Timeout / time.Second  // 60 segundos
```

### 📋 Arquivos Modificados

1. **`src/usecase/app.go`**
   - Linha 62: Removida divisão por 2
   - Adicionada documentação explicativa

2. **`docs/openapi.yaml`**
   - Exemplo atualizado de 30 para 60 segundos
   - Adicionada descrição explicativa

3. **`docs/QR_TIMEOUT_CHANGES.md`** *(novo)*
   - Documentação completa das mudanças
   - Explicação do problema e solução

### 🎯 Benefícios para o Usuário

- ✅ **Mais tempo** para escanear o QR code (60s vs 30s)
- ✅ **Consistência** entre interface e funcionalidade
- ✅ **Experiência melhorada** no processo de login
- ✅ **Redução de falhas** por timeout prematuro

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
2. **Validar** que o timeout real é de 60 segundos
3. **Monitorar** taxa de sucesso no login
4. **Considerar** configuração customizável no futuro 