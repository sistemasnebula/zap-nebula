# 🔐 Guia de Integração: Basic Authentication

Este documento descreve como configurar e usar a autenticação básica HTTP (Basic Auth) ao integrar a API WhatsApp com aplicações **C# .NET** e **Node.js**.

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Configuração no Container Docker](#configuração-no-container-docker)
3. [Integração com C# .NET](#integração-com-c-net)
4. [Integração com Node.js](#integração-com-nodejs)
5. [Webhooks e Autenticação](#webhooks-e-autenticação)
6. [Exemplos Práticos](#exemplos-práticos)
7. [Troubleshooting](#troubleshooting)

## 🎯 Visão Geral

A API WhatsApp suporta autenticação básica HTTP para proteger todas as rotas REST. A autenticação é configurada via variável de ambiente `APP_BASIC_AUTH` no formato:

```
usuario:senha
```

Para múltiplos usuários, separe por vírgula:

```
usuario1:senha1,usuario2:senha2,usuario3:senha3
```

## 🐳 Configuração no Container Docker

### Via Variável de Ambiente

Ao criar o container Docker, adicione a variável `APP_BASIC_AUTH`:

```csharp
var envVariables = new Dictionary<string, string>
{
    { "API_WEBHOOK", $@"{callBack}{app.LojaId}" },
    { "WHATSAPP_WEBHOOK", $@"{callBack}{app.LojaId}" },
    { "DB_URI", "file:database/whatsapp.db?_foreign_keys=on" },
    // Adicione a autenticação básica
    { "APP_BASIC_AUTH", $"{app.UsuarioWhatsApp}:{app.SenhaWhatsApp}" }
};
```

### Via Docker Compose

```yaml
services:
  whatsapp:
    image: seu-usuario/go-whatsapp-web-multidevice:latest
    environment:
      APP_BASIC_AUTH: "admin:senhaSegura123"
      APP_PORT: "3000"
      APP_DEBUG: "false"
    ports:
      - "3000:3000"
    volumes:
      - whatsapp-data:/app/storages
      - whatsapp-db:/app/database
```

### Via Linha de Comando

```bash
docker run -d \
  -e APP_BASIC_AUTH="admin:senhaSegura123" \
  -e APP_PORT="3000" \
  -p 3000:3000 \
  seu-usuario/go-whatsapp-web-multidevice:latest rest
```

## 💻 Integração com C# .NET

### 1. Configuração Inicial

Adicione as credenciais via Dependency Injection ou configuração:

```csharp
// appsettings.json
{
  "WhatsApp": {
    "Usuario": "admin",
    "Senha": "senhaSegura123"
  }
}
```

### 2. Classe Proxy com Autenticação

```csharp
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using RestSharp;
using System;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace Nebula.Global.Business.Proxy
{
    internal class WhatsAppProxy
    {
        private readonly ILogger<WhatsAppProxy> _logger;
        private readonly string _usuarioWhatsApp;
        private readonly string _senhaWhatsApp;

        public WhatsAppProxy(
            ILogger<WhatsAppProxy> logger,
            string usuarioWhatsApp,
            string senhaWhatsApp)
        {
            _logger = logger;
            _usuarioWhatsApp = usuarioWhatsApp;
            _senhaWhatsApp = senhaWhatsApp;
        }

        /// <summary>
        /// Cria um cliente RestSharp configurado com autenticação básica
        /// </summary>
        private RestClient CreateAuthenticatedClient(string url)
        {
            var client = new RestClient(url);
            
            // Adiciona autenticação básica se configurada
            if (!string.IsNullOrWhiteSpace(_usuarioWhatsApp) && 
                !string.IsNullOrWhiteSpace(_senhaWhatsApp))
            {
                var credentials = Convert.ToBase64String(
                    Encoding.UTF8.GetBytes($"{_usuarioWhatsApp}:{_senhaWhatsApp}")
                );
                client.AddDefaultHeader("Authorization", $"Basic {credentials}");
            }
            
            return client;
        }

        /// <summary>
        /// Criar um Dispositivo no Whatsapp
        /// </summary>
        public async Task<ReturnDeviceZapViewModel<DeviceViewZapViewModel>> CreateDeviceAsync(
            WhatsAppProxyViewModel model)
        {
            try
            {
                var url = $"{model.Url}/devices";
                _logger.LogInformation($"Criar dispositivo - Url: [{model.Url}]");

                var client = CreateAuthenticatedClient(url);
                var request = new RestRequest(new Uri(url), Method.Post);
                request.AddJsonBody(new { device_id = model.StoreId });

                var response = await client.ExecuteAsync(request);
                
                if (response.IsSuccessful)
                {
                    return JsonConvert.DeserializeObject<ReturnDeviceZapViewModel<DeviceViewZapViewModel>>(
                        response.Content
                    );
                }
                else
                {
                    _logger.LogWarning($"Falha ao criar dispositivo. Status: {response.StatusCode}, Content: {response.Content}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Erro ao criar dispositivo para loja [{model.StoreName}]");
                throw;
            }
        }

        /// <summary>
        /// Parear dispositivo (Login)
        /// </summary>
        public async Task<ReturnDeviceZapViewModel<PairDeviceWhastAppViewModel>> PairDeviceAsync(
            WhatsAppProxyViewModel model)
        {
            var results = new ReturnDeviceZapViewModel<PairDeviceWhastAppViewModel>();
            try
            {
                var url = $"{model.Url}/app/login";
                _logger.LogInformation($"Parear dispositivo - Url: [{model.Url}]");

                var client = CreateAuthenticatedClient(url);
                var request = new RestRequest(new Uri(url), Method.Get);
                request.AddHeader("X-Device-Id", model.StoreId);

                var response = await client.GetAsync(request);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    var content = JsonConvert.DeserializeObject<ReturnDeviceZapViewModel<PairDeviceWhastAppViewModel>>(
                        response.Content
                    );
                    results.Results = content.Results;
                    results.Message = content.Message;
                    results.Code = content.Code;
                }
                else
                {
                    _logger.LogWarning($"Falha ao parear dispositivo. Status: {response.StatusCode}");
                }

                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Erro ao parear dispositivo da loja [{model.StoreName}]");
                throw;
            }
        }

        /// <summary>
        /// Desconectar dispositivo
        /// </summary>
        public async Task<ReturnDeviceZapViewModel> DisconnectDeviceAsync(
            WhatsAppProxyViewModel model)
        {
            try
            {
                var url = $"{model.Url}/app/logout";
                var client = CreateAuthenticatedClient(url);
                var request = new RestRequest(new Uri(url), Method.Get);
                request.AddHeader("X-Device-Id", model.StoreId);

                var response = await client.GetAsync(request);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    return JsonConvert.DeserializeObject<ReturnDeviceZapViewModel>(response.Content);
                }
                else
                {
                    _logger.LogWarning($"Falha ao desconectar dispositivo. Status: {response.StatusCode}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao desconectar dispositivo");
                throw;
            }
        }

        /// <summary>
        /// Buscar dispositivos conectados
        /// </summary>
        public async Task<ReturnDeviceZapViewModel<List<DeviceNumberWhatsAppViewModel>>> GetDevicesAsync(
            WhatsAppProxyViewModel model)
        {
            try
            {
                var url = $"{model.Url}/app/devices";
                var client = CreateAuthenticatedClient(url);
                var request = new RestRequest(new Uri(url), Method.Get);
                request.AddHeader("X-Device-Id", model.StoreId);

                var response = await client.ExecuteAsync(request);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    return JsonConvert.DeserializeObject<ReturnDeviceZapViewModel<List<DeviceNumberWhatsAppViewModel>>>(
                        response.Content
                    );
                }
                else
                {
                    _logger.LogWarning($"Falha ao buscar dispositivos. Status: {response.StatusCode}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao buscar dispositivos");
                throw;
            }
        }
    }
}
```

### 3. Alternativa: Usando RestClientOptions (RestSharp Moderno)

Se estiver usando uma versão mais recente do RestSharp, use `RestClientOptions`:

```csharp
using RestSharp.Authenticators;

private RestClient CreateAuthenticatedClient(string url)
{
    var options = new RestClientOptions(url);
    
    if (!string.IsNullOrWhiteSpace(_usuarioWhatsApp) && 
        !string.IsNullOrWhiteSpace(_senhaWhatsApp))
    {
        options.Authenticator = new HttpBasicAuthenticator(_usuarioWhatsApp, _senhaWhatsApp);
    }
    
    return new RestClient(options);
}
```

### 4. Configuração no CreateContainerService

Atualize o método de criação de container para incluir `APP_BASIC_AUTH`:

```csharp
var envVariables = new Dictionary<string, string>
{
    { "API_WEBHOOK", $@"{callBack}{app.LojaId}" },
    { "WHATSAPP_WEBHOOK", $@"{callBack}{app.LojaId}" },
    { "DB_URI", "file:database/whatsapp.db?_foreign_keys=on" },
    // Adicione a autenticação básica
    { "APP_BASIC_AUTH", $"{app.UsuarioWhatsApp}:{app.SenhaWhatsApp}" }
};

var containerCreateParameters = new CreateContainerParameters
{
    // ... outras configurações ...
    Env = envVariables.Select(kv => $"{kv.Key}={kv.Value}").ToList(),
    // ... resto das configurações ...
};
```

## 🟢 Integração com Node.js

### 1. Usando Axios

```javascript
const axios = require('axios');
const https = require('https');

class WhatsAppClient {
    constructor(baseUrl, usuario, senha) {
        this.baseUrl = baseUrl;
        this.usuario = usuario;
        this.senha = senha;
        
        // Configurar cliente HTTP com autenticação básica
        this.client = axios.create({
            baseURL: baseUrl,
            auth: {
                username: usuario,
                password: senha
            },
            headers: {
                'Content-Type': 'application/json'
            }
        });
    }

    /**
     * Criar um dispositivo
     */
    async createDevice(deviceId) {
        try {
            const response = await this.client.post('/devices', {
                device_id: deviceId
            });
            return response.data;
        } catch (error) {
            console.error('Erro ao criar dispositivo:', error.response?.data || error.message);
            throw error;
        }
    }

    /**
     * Parear dispositivo (Login)
     */
    async pairDevice(deviceId) {
        try {
            const response = await this.client.get('/app/login', {
                headers: {
                    'X-Device-Id': deviceId
                }
            });
            return response.data;
        } catch (error) {
            console.error('Erro ao parear dispositivo:', error.response?.data || error.message);
            throw error;
        }
    }

    /**
     * Desconectar dispositivo
     */
    async disconnectDevice(deviceId) {
        try {
            const response = await this.client.get('/app/logout', {
                headers: {
                    'X-Device-Id': deviceId
                }
            });
            return response.data;
        } catch (error) {
            console.error('Erro ao desconectar dispositivo:', error.response?.data || error.message);
            throw error;
        }
    }

    /**
     * Buscar dispositivos conectados
     */
    async getDevices(deviceId) {
        try {
            const response = await this.client.get('/app/devices', {
                headers: {
                    'X-Device-Id': deviceId
                }
            });
            return response.data;
        } catch (error) {
            console.error('Erro ao buscar dispositivos:', error.response?.data || error.message);
            throw error;
        }
    }
}

// Uso
const client = new WhatsAppClient(
    'http://localhost:3000',
    'admin',
    'senhaSegura123'
);

// Exemplo de uso
(async () => {
    try {
        // Criar dispositivo
        const device = await client.createDevice('loja-123');
        console.log('Dispositivo criado:', device);

        // Parear dispositivo
        const pairResult = await client.pairDevice('loja-123');
        console.log('QR Link:', pairResult.results?.qr_link);
    } catch (error) {
        console.error('Erro:', error);
    }
})();
```

### 2. Usando Fetch API (Node.js 18+)

```javascript
class WhatsAppClient {
    constructor(baseUrl, usuario, senha) {
        this.baseUrl = baseUrl;
        this.credentials = Buffer.from(`${usuario}:${senha}`).toString('base64');
    }

    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;
        const headers = {
            'Authorization': `Basic ${this.credentials}`,
            'Content-Type': 'application/json',
            ...options.headers
        };

        const response = await fetch(url, {
            ...options,
            headers
        });

        if (!response.ok) {
            const error = await response.text();
            throw new Error(`HTTP ${response.status}: ${error}`);
        }

        return await response.json();
    }

    async createDevice(deviceId) {
        return this.request('/devices', {
            method: 'POST',
            body: JSON.stringify({ device_id: deviceId })
        });
    }

    async pairDevice(deviceId) {
        return this.request('/app/login', {
            method: 'GET',
            headers: {
                'X-Device-Id': deviceId
            }
        });
    }

    async disconnectDevice(deviceId) {
        return this.request('/app/logout', {
            method: 'GET',
            headers: {
                'X-Device-Id': deviceId
            }
        });
    }
}

// Uso
const client = new WhatsAppClient(
    'http://localhost:3000',
    'admin',
    'senhaSegura123'
);
```

### 3. Usando Request (Deprecated, mas ainda usado)

```javascript
const request = require('request');

function createWhatsAppRequest(baseUrl, usuario, senha) {
    return request.defaults({
        baseUrl: baseUrl,
        auth: {
            user: usuario,
            pass: senha
        },
        json: true
    });
}

// Exemplo de uso
const client = createWhatsAppRequest(
    'http://localhost:3000',
    'admin',
    'senhaSegura123'
);

// Criar dispositivo
client.post('/devices', {
    body: { device_id: 'loja-123' }
}, (error, response, body) => {
    if (error) {
        console.error('Erro:', error);
        return;
    }
    console.log('Dispositivo criado:', body);
});
```

## 🔔 Webhooks e Autenticação

### ⚠️ Importante: Webhooks NÃO usam Basic Auth

**Os webhooks são requisições HTTP que a API WhatsApp ENVIA para o seu servidor**, não o contrário. Portanto:

- ✅ **Webhooks NÃO precisam de autenticação básica** (Basic Auth)
- ✅ **Webhooks usam assinatura HMAC SHA256** para verificação de segurança
- ✅ **Header de segurança**: `X-Hub-Signature-256`

### Como Funciona

1. **Autenticação Básica (Basic Auth)**:
   - Protege as **rotas REST da API** (requisições que chegam na API)
   - Usado quando você faz requisições **PARA** a API WhatsApp
   - Exemplo: `GET /app/login`, `POST /devices`, etc.

2. **Assinatura HMAC (Webhooks)**:
   - Protege as **requisições de webhook** (requisições que a API envia para você)
   - Usado quando a API WhatsApp faz requisições **PARA** o seu servidor
   - Header: `X-Hub-Signature-256: sha256={signature}`

### Verificação de Assinatura no Webhook (C# .NET)

```csharp
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class WebhookController : ControllerBase
{
    private readonly string _webhookSecret = "seu-secret-key"; // Mesmo valor de WHATSAPP_WEBHOOK_SECRET

    [HttpPost("whatsapp/callback/{storeId}")]
    public async Task<IActionResult> ReceiveWebhook(string storeId)
    {
        // Ler o header de assinatura
        var signature = Request.Headers["X-Hub-Signature-256"].FirstOrDefault();
        if (string.IsNullOrEmpty(signature))
        {
            return Unauthorized("Missing signature");
        }

        // Ler o body da requisição
        Request.EnableBuffering();
        var bodyStream = new StreamReader(Request.Body);
        var bodyText = await bodyStream.ReadToEndAsync();
        Request.Body.Position = 0;

        // Verificar assinatura
        if (!VerifySignature(bodyText, signature, _webhookSecret))
        {
            return Unauthorized("Invalid signature");
        }

        // Processar webhook
        var payload = System.Text.Json.JsonSerializer.Deserialize<WebhookPayload>(bodyText);
        
        // Seu código de processamento aqui
        // ...

        return Ok();
    }

    private bool VerifySignature(string payload, string signature, string secret)
    {
        // Remover prefixo "sha256="
        var receivedSignature = signature.Replace("sha256=", "");

        // Calcular assinatura esperada
        var secretBytes = Encoding.UTF8.GetBytes(secret);
        var payloadBytes = Encoding.UTF8.GetBytes(payload);
        
        using var hmac = new HMACSHA256(secretBytes);
        var hashBytes = hmac.ComputeHash(payloadBytes);
        var expectedSignature = BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant();

        // Comparação segura contra timing attacks
        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(expectedSignature),
            Encoding.UTF8.GetBytes(receivedSignature)
        );
    }
}

public class WebhookPayload
{
    public string Event { get; set; }
    public string DeviceId { get; set; }
    public object Payload { get; set; }
}
```

### Verificação de Assinatura no Webhook (Node.js)

```javascript
const crypto = require('crypto');
const express = require('express');
const app = express();

const WEBHOOK_SECRET = 'seu-secret-key'; // Mesmo valor de WHATSAPP_WEBHOOK_SECRET

app.use(express.raw({ type: 'application/json' }));

app.post('/api/whatsapp/callback/:storeId', (req, res) => {
    const signature = req.headers['x-hub-signature-256'];
    
    if (!signature) {
        return res.status(401).send('Missing signature');
    }

    // Verificar assinatura
    if (!verifyWebhookSignature(req.body, signature, WEBHOOK_SECRET)) {
        return res.status(401).send('Invalid signature');
    }

    // Processar webhook
    const payload = JSON.parse(req.body);
    console.log('Webhook recebido:', payload);

    // Seu código de processamento aqui
    // ...

    res.status(200).send('OK');
});

function verifyWebhookSignature(payload, signature, secret) {
    const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(payload, 'utf8')
        .digest('hex');

    const receivedSignature = signature.replace('sha256=', '');

    // Comparação segura contra timing attacks
    return crypto.timingSafeEqual(
        Buffer.from(expectedSignature, 'hex'),
        Buffer.from(receivedSignature, 'hex')
    );
}

app.listen(3000, () => {
    console.log('Webhook server listening on port 3000');
});
```

### Resumo: Autenticação vs Webhooks

| Tipo | Direção | Autenticação | Quando Usar |
|------|---------|--------------|-------------|
| **API REST** | Cliente → API WhatsApp | Basic Auth (`Authorization: Basic ...`) | Ao fazer requisições para a API |
| **Webhook** | API WhatsApp → Seu Servidor | HMAC SHA256 (`X-Hub-Signature-256`) | Ao receber eventos da API |

### Configuração do Secret do Webhook

No container Docker, configure o secret do webhook:

```csharp
var envVariables = new Dictionary<string, string>
{
    { "WHATSAPP_WEBHOOK", $@"{callBack}{app.LojaId}" },
    { "WHATSAPP_WEBHOOK_SECRET", "seu-secret-key-aqui" }, // Use o mesmo valor no seu código
    { "APP_BASIC_AUTH", $"{app.UsuarioWhatsApp}:{app.SenhaWhatsApp}" }
};
```

**Importante**: Use o mesmo valor de `WHATSAPP_WEBHOOK_SECRET` tanto no container quanto no código que verifica a assinatura.

## 📝 Exemplos Práticos

### Exemplo 1: C# - Criação de Container com Autenticação

```csharp
var envVariables = new Dictionary<string, string>
{
    { "API_WEBHOOK", "http://meu-webhook.com/callback" },
    { "WHATSAPP_WEBHOOK", "http://meu-webhook.com/callback" },
    { "DB_URI", "file:database/whatsapp.db?_foreign_keys=on" },
    { "APP_BASIC_AUTH", "admin:MinhaSenhaSegura123!" }
};

var containerCreateParameters = new CreateContainerParameters
{
    Name = "whatsapp-loja-123",
    Image = "meu-usuario/go-whatsapp-web-multidevice:latest",
    Env = envVariables.Select(kv => $"{kv.Key}={kv.Value}").ToList(),
    Cmd = new[] { "rest", "--port=3000" },
    // ... outras configurações ...
};
```

### Exemplo 2: Node.js - Cliente Completo

```javascript
// whatsapp-client.js
const axios = require('axios');

class WhatsAppAPI {
    constructor(config) {
        this.client = axios.create({
            baseURL: config.baseUrl,
            auth: {
                username: config.usuario,
                password: config.senha
            }
        });
    }

    async criarDispositivo(deviceId) {
        const { data } = await this.client.post('/devices', { device_id: deviceId });
        return data;
    }

    async parear(deviceId) {
        const { data } = await this.client.get('/app/login', {
            headers: { 'X-Device-Id': deviceId }
        });
        return data;
    }

    async desconectar(deviceId) {
        const { data } = await this.client.get('/app/logout', {
            headers: { 'X-Device-Id': deviceId }
        });
        return data;
    }
}

module.exports = WhatsAppAPI;
```

## 🔍 Troubleshooting

### Problema: Erro 401 Unauthorized

**Causa:** Credenciais incorretas ou não configuradas.

**Solução:**
1. Verifique se `APP_BASIC_AUTH` está configurado no container:
   ```bash
   docker exec -it whatsapp env | grep APP_BASIC_AUTH
   ```

2. Verifique se as credenciais no código cliente correspondem às do container.

3. Teste manualmente com curl:
   ```bash
   curl -u usuario:senha http://localhost:3000/app/devices
   ```

### Problema: Autenticação não funciona em requisições C#

**Causa:** Header Authorization não está sendo enviado corretamente.

**Solução:**
1. Verifique se o método `CreateAuthenticatedClient` está sendo usado em todas as requisições.

2. Adicione logs para verificar o header:
   ```csharp
   _logger.LogInformation($"Authorization Header: Basic {credentials.Substring(0, 10)}...");
   ```

3. Use Fiddler ou Postman para verificar se o header está sendo enviado.

### Problema: Erro ao criar container com APP_BASIC_AUTH

**Causa:** Formato incorreto da variável de ambiente.

**Solução:**
- Formato correto: `usuario:senha`
- Múltiplos usuários: `usuario1:senha1,usuario2:senha2`
- Não use espaços: ❌ `"admin : senha"` ✅ `"admin:senha"`

### Problema: Autenticação funciona no Postman mas não no código

**Causa:** Diferença na codificação Base64 ou encoding.

**Solução:**
- Use `Encoding.UTF8` para converter credenciais em Base64
- Verifique se não há caracteres especiais mal codificados
- Compare o header gerado com o do Postman

## ✅ Boas Práticas

1. **Nunca commite credenciais no código**
   - Use variáveis de ambiente
   - Use Azure Key Vault, AWS Secrets Manager, etc.

2. **Use senhas fortes**
   - Mínimo 16 caracteres
   - Combine letras, números e símbolos
   - Diferentes senhas para cada ambiente

3. **Rotacione credenciais regularmente**
   - Mude senhas periodicamente
   - Use diferentes usuários para diferentes propósitos

4. **Monitore tentativas de acesso**
   - Configure logs para detectar tentativas não autorizadas
   - Use ferramentas de monitoramento

5. **Use HTTPS em produção**
   - Basic Auth envia credenciais em texto plano
   - Sempre use HTTPS para proteger as credenciais em trânsito

## 📚 Referências

- [HTTP Basic Authentication - MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)
- [RestSharp Documentation](https://restsharp.dev/)
- [Axios Documentation](https://axios-http.com/docs/auth)
- [Node.js Fetch API](https://nodejs.org/api/globals.html#fetch)

