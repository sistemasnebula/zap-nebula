# 🔒 Guia de Segurança para Produção

Este documento descreve os mecanismos de segurança implementados e como configurá-los para uso em produção com múltiplas instâncias Docker.

## 📋 Índice

1. [Mecanismos de Segurança](#mecanismos-de-segurança)
2. [Configuração de Autenticação](#configuração-de-autenticação)
3. [Proteção de QR Codes](#proteção-de-qr-codes)
4. [Uso com Docker e Docker Hub](#uso-com-docker-e-docker-hub)
5. [Exemplos de Configuração](#exemplos-de-configuração)
6. [Boas Práticas](#boas-práticas)

> 💡 **Para integração com C# .NET e Node.js**, consulte o guia completo: [BASIC_AUTH_INTEGRACAO.md](./BASIC_AUTH_INTEGRACAO.md)

## 🔐 Mecanismos de Segurança

### 1. Basic Authentication (Autenticação Básica)

Todas as APIs REST requerem autenticação básica HTTP. Você pode configurar múltiplos usuários.

**Formato:** `usuario:senha`

**Exemplo:**
```bash
--basic-auth=admin:senhaSegura123,usuario2:outraSenha456
```

### 2. Proteção de QR Codes com Tokens Temporários

As imagens de QR code são protegidas por tokens temporários que expiram automaticamente:

- ✅ **Token único por QR code**
- ✅ **Expiração automática** (mesmo tempo do QR code + 30 segundos)
- ✅ **Validação de arquivo** (token só funciona para o arquivo específico)
- ✅ **Bloqueio de acesso direto** ao diretório `/statics/qrcode/`

## 🔑 Configuração de Autenticação

### Variáveis de Ambiente

Configure as credenciais via variáveis de ambiente para diferentes instâncias:

```yaml
environment:
  APP_BASIC_AUTH: "usuario1:senha1,usuario2:senha2"
  APP_PORT: "3000"
  APP_DEBUG: "false"
```

### Via Docker Compose

```yaml
services:
  whatsapp-instance-1:
    image: seu-usuario/go-whatsapp-web-multidevice:latest
    environment:
      APP_BASIC_AUTH: "admin:senhaSegura123"
      APP_PORT: "3000"
      APP_OS: "NS-Zap-Prod"
    
  whatsapp-instance-2:
    image: seu-usuario/go-whatsapp-web-multidevice:latest
    environment:
      APP_BASIC_AUTH: "admin:outraSenha456"
      APP_PORT: "3001"
      APP_OS: "NS-Zap-Prod-2"
```

### Via Linha de Comando

```bash
docker run -d \
  -e APP_BASIC_AUTH="admin:senhaSegura123" \
  -e APP_PORT="3000" \
  -p 3000:3000 \
  seu-usuario/go-whatsapp-web-multidevice:latest rest
```

## 🛡️ Proteção de QR Codes

### Como Funciona

1. **Geração do QR Code:**
   - Ao chamar `/app/login`, um QR code é gerado
   - Um token temporário único é criado automaticamente
   - O token expira junto com o QR code

2. **Acesso Seguro:**
   - A URL retornada inclui o token: `/api/qrcode/scan-qr-xxx.png?token=abc123...`
   - Acesso direto a `/statics/qrcode/` é bloqueado
   - Apenas a rota `/api/qrcode/:file?token=...` permite acesso

3. **Exemplo de Resposta:**

```json
{
  "status": 200,
  "code": "SUCCESS",
  "message": "Login success",
  "results": {
    "device_id": "628123456789@s.whatsapp.net",
    "qr_link": "http://localhost:3000/api/qrcode/scan-qr-abc123.png?token=xyz789...",
    "qr_duration": 60,
    "qr_token": "xyz789..."
  }
}
```

### Uso da API

```bash
# 1. Fazer login (requer Basic Auth)
curl -u admin:senhaSegura123 \
  -H "X-Device-Id: 628123456789@s.whatsapp.net" \
  http://localhost:3000/app/login

# 2. Acessar QR code usando o token retornado
curl "http://localhost:3000/api/qrcode/scan-qr-abc123.png?token=xyz789..."
```

## 🐳 Uso com Docker e Docker Hub

### 1. Build e Push da Imagem

```bash
# Build da imagem
docker build -f docker/golang.Dockerfile -t seu-usuario/go-whatsapp-web-multidevice:latest .

# Push para Docker Hub
docker push seu-usuario/go-whatsapp-web-multidevice:latest
```

### 2. Configuração para Múltiplas Instâncias

Crie diferentes arquivos `docker-compose.yml` ou use variáveis de ambiente:

**docker-compose.prod1.yml:**
```yaml
services:
  whatsapp:
    image: seu-usuario/go-whatsapp-web-multidevice:latest
    container_name: whatsapp-prod-1
    restart: always
    ports:
      - "3000:3000"
    volumes:
      - whatsapp-prod1:/app/storages
    environment:
      APP_BASIC_AUTH: "admin-prod1:senhaSegura123"
      APP_PORT: "3000"
      APP_OS: "NS-Zap-Prod-1"
      APP_DEBUG: "false"
    command:
      - rest
      - --port=3000

volumes:
  whatsapp-prod1:
```

**docker-compose.prod2.yml:**
```yaml
services:
  whatsapp:
    image: seu-usuario/go-whatsapp-web-multidevice:latest
    container_name: whatsapp-prod-2
    restart: always
    ports:
      - "3001:3000"
    volumes:
      - whatsapp-prod2:/app/storages
    environment:
      APP_BASIC_AUTH: "admin-prod2:outraSenha456"
      APP_PORT: "3000"
      APP_OS: "NS-Zap-Prod-2"
      APP_DEBUG: "false"
    command:
      - rest
      - --port=3000

volumes:
  whatsapp-prod2:
```

### 3. Executar Instâncias

```bash
# Instância 1
docker-compose -f docker-compose.prod1.yml up -d

# Instância 2
docker-compose -f docker-compose.prod2.yml up -d
```

## 📝 Exemplos de Configuração

### Exemplo 1: Desenvolvimento Local

```yaml
services:
  whatsapp:
    image: seu-usuario/go-whatsapp-web-multidevice:latest
    environment:
      APP_BASIC_AUTH: "dev:dev123"
      APP_DEBUG: "true"
      APP_PORT: "3000"
    ports:
      - "3000:3000"
```

### Exemplo 2: Produção com Múltiplos Usuários

```yaml
services:
  whatsapp:
    image: seu-usuario/go-whatsapp-web-multidevice:latest
    environment:
      APP_BASIC_AUTH: "admin:senhaForte123,operador:senhaOperador456,monitor:senhaMonitor789"
      APP_DEBUG: "false"
      APP_PORT: "3000"
      APP_OS: "NS-Zap-Production"
    ports:
      - "3000:3000"
    volumes:
      - whatsapp-data:/app/storages
```

### Exemplo 3: Com Proxy Reverso (Nginx)

```nginx
# Nginx config
location /whatsapp/ {
    proxy_pass http://localhost:3000/;
    proxy_set_header Authorization $http_authorization;
    proxy_set_header X-Device-Id $http_x_device_id;
    proxy_set_header Host $host;
}
```

```yaml
# docker-compose.yml
services:
  whatsapp:
    image: seu-usuario/go-whatsapp-web-multidevice:latest
    environment:
      APP_BASIC_AUTH: "admin:senhaSegura123"
      APP_BASE_PATH: "/whatsapp"
      APP_TRUSTED_PROXIES: "127.0.0.1,10.0.0.0/8"
```

## ✅ Boas Práticas

### 1. Senhas Fortes

- ✅ Use senhas com pelo menos 16 caracteres
- ✅ Combine letras, números e símbolos
- ✅ Use senhas diferentes para cada instância
- ❌ Nunca use senhas padrão como `admin:admin`

### 2. Variáveis de Ambiente

- ✅ Use variáveis de ambiente para credenciais
- ✅ Não commite senhas no código
- ✅ Use secrets management (Docker Secrets, Kubernetes Secrets, etc.)

### 3. Rede e Firewall

- ✅ Exponha apenas a porta necessária
- ✅ Use firewall para restringir acesso
- ✅ Configure proxy reverso com SSL/TLS

### 4. Logs e Monitoramento

- ✅ Desabilite `APP_DEBUG` em produção
- ✅ Configure `WHATSAPP_LOG_LEVEL` apropriado
- ✅ Monitore tentativas de acesso não autorizado

### 5. Tokens QR Code

- ✅ Sempre use a URL com token retornada pela API
- ✅ Não compartilhe tokens publicamente
- ✅ Tokens expiram automaticamente (não precisa limpar manualmente)

## 🔍 Verificação de Segurança

### Testar Autenticação

```bash
# Teste sem autenticação (deve falhar)
curl http://localhost:3000/app/devices

# Teste com autenticação (deve funcionar)
curl -u admin:senhaSegura123 http://localhost:3000/app/devices
```

### Testar Proteção de QR Code

```bash
# Tentar acesso direto (deve ser bloqueado)
curl http://localhost:3000/statics/qrcode/scan-qr-abc123.png

# Acessar com token válido (deve funcionar)
curl "http://localhost:3000/api/qrcode/scan-qr-abc123.png?token=xyz789..."
```

## 🚨 Troubleshooting

### Problema: "UNAUTHORIZED" em todas as requisições

**Solução:** Verifique se `APP_BASIC_AUTH` está configurado corretamente:
```bash
docker exec -it whatsapp env | grep APP_BASIC_AUTH
```

### Problema: QR code não carrega

**Solução:** Verifique se está usando a URL com token:
- ❌ `http://localhost:3000/statics/qrcode/scan-qr-xxx.png`
- ✅ `http://localhost:3000/api/qrcode/scan-qr-xxx.png?token=...`

### Problema: Token expirado muito rápido

**Solução:** O token expira junto com o QR code. Gere um novo QR code se necessário.

## 📚 Referências

- [Documentação Docker Compose](https://docs.docker.com/compose/)
- [HTTP Basic Authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)

