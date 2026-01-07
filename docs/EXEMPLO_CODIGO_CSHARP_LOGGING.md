# 💻 Exemplo Completo: Código C# com Logging

Código completo atualizado do `CreateContainerService` com suporte a logging e labels.

## 📋 Classe Completa Atualizada

```csharp
using ContainerDocker.Business.BaseService;
using ContainerDocker.Domain.Entities;
using Docker.DotNet;
using Docker.DotNet.Models;
using Microsoft.Extensions.Logging;
using System.Net.NetworkInformation;

namespace ContainerDocker.Business.CreateService
{
    /// <summary>
    /// Serviço para Cria Container
    /// </summary>
    internal class CreateContainerService : ContainerBaseService
    {
        private readonly ILogger<CreateContainerService> _logger;
        private readonly DiscordNotificationService _discordNotificationService;

        public CreateContainerService(
            ILogger<CreateContainerService> logger,
            DiscordNotificationService discordNotificationService)
        {
            _logger = logger;
            _discordNotificationService = discordNotificationService;
        }

        /// <summary>
        /// Cria Container
        /// </summary>
        public async Task ExecuteAsync(ServidorWhatsApp app)
        {
            try
            {
                _logger.LogInformation($"ExecuteServiceAsync Begin - {DateTime.Now:yyyy-MM-dd HH:mm:ss}");

                if (IsPortInUse(app.Porta))
                {
                    app.Porta = GenerateNewPort(app.Porta);
                }

                var networkName = GetNameNetWorkDocker();
                var internalPort = GetInternalPortDocker();
                var urlNotification = GetUrlNotification();
                var _enviroment = GetEnviroment();
                var callBack = GetUrlCallback();

                using var client = new DockerClientConfiguration(new Uri(GetLocalDocker())).CreateClient();

                // Configurar os volumes
                var storeName = (string.IsNullOrWhiteSpace(app.LojaNome) ? app.LojaAlias : app.LojaNome)
                    .ToLower().RemoveSpecialCharacter();
                
                var volumes = new List<string>
                {
                    $"/nebula/volume-whatsapp/{_enviroment}{storeName}/statics:/app/statics",
                    $"/nebula/volume-whatsapp/{_enviroment}{storeName}/storages:/app/storages",
                    $"/nebula/volume-whatsapp/{_enviroment}{storeName}/database:/app/database",
                };

                // ✅ CONFIGURAÇÃO DE LOGGING
                var logConfig = new LogConfig
                {
                    Type = "json-file",
                    Config = new Dictionary<string, string>
                    {
                        { "max-size", "10m" },      // Tamanho máximo por arquivo (10MB)
                        { "max-file", "5" },        // Número máximo de arquivos (rotação)
                        { "labels", "app,loja,loja-id,environment,version" } // Labels para filtro
                    }
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
                    LogConfig = logConfig
                };

                var envVariables = new Dictionary<string, string>
                {
                    { "API_WEBHOOK", $@"{callBack}{app.LojaId}" },
                    { "WHATSAPP_WEBHOOK", $@"{callBack}{app.LojaId}" },
                    { "DB_URI", "file:database/whatsapp.db?_foreign_keys=on" },
                    { "APP_BASIC_AUTH", $"{app.UsuarioWhatsApp}:{app.SenhaWhatsApp}" }
                };

                // ✅ LABELS PARA IDENTIFICAÇÃO E FILTRO
                var labels = new Dictionary<string, string>
                {
                    { "com.centurylinklabs.watchtower.enable", "false" },
                    { "app", "whatsapp-api" },                                    // Identificador da aplicação
                    { "loja", app.LojaNome ?? app.LojaAlias },                   // Nome da loja
                    { "loja-id", app.LojaId.ToString() },                        // ID da loja
                    { "environment", _enviroment },                               // Ambiente (dev, prd, etc)
                    { "version", "8.1.1" },                                      // Versão da imagem
                    { "container-type", "whatsapp-api" }                         // Tipo de container
                };

                var containerCreateParameters = new CreateContainerParameters
                {
                    Name = app.NomeContainer,
                    Cmd = new[]
                    {
                        "rest",
                        "--port=3000",
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
                    // ✅ ADICIONAR: Labels
                    Labels = labels,
                    NetworkingConfig = new NetworkingConfig
                    {
                        EndpointsConfig = new Dictionary<string, EndpointSettings>
                        {
                            {
                                networkName, new EndpointSettings
                                {
                                    NetworkID = networkName,
                                    IPAMConfig = new EndpointIPAMConfig
                                    {
                                        IPv4Address = null
                                    },
                                    Links = null,
                                    Aliases = null,
                                    IPAddress = null,
                                    IPPrefixLen = 0
                                }
                            }
                        }
                    }
                };

                var response = await client.Containers.CreateContainerAsync(containerCreateParameters);
                await client.Containers.StartContainerAsync(response.ID, new ContainerStartParameters());

                var ambiente = Environment.GetEnvironmentVariable("ENV_ZAP") ?? "N/A";
                var dataCriacao = DateTime.Now;

                await _discordNotificationService.SendContainerCreatedNotificationAsync(
                    containerName: app.NomeContainer,
                    lojaNome: string.IsNullOrWhiteSpace(app.LojaNome) ? app.LojaAlias : app.LojaNome,
                    portaExterna: app.Porta,
                    portaInterna: internalPort,
                    imagem: app.NomeImagem,
                    ambiente: ambiente,
                    volumes: volumes,
                    labels: labels,
                    envVariables: envVariables,
                    dataCriacao: dataCriacao
                );

                _logger.LogInformation($"Container criado com sucesso: {app.NomeContainer}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"CreateContainerService Error - {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
                throw;
            }
        }

        /// <summary>
        /// Verifica se a porta esta em uso
        /// </summary>
        private bool IsPortInUse(int port)
        {
            var ipGlobalProperties = IPGlobalProperties.GetIPGlobalProperties();
            var tcpListeners = ipGlobalProperties.GetActiveTcpListeners();
            return tcpListeners.Any(x => x.Port == port);
        }

        /// <summary>
        /// Gera uma nova porta
        /// </summary>
        private int GenerateNewPort(int port)
        {
            var newPort = port;
            while (newPort == port)
            {
                newPort++;
                if (!IsPortInUse(newPort))
                {
                    break;
                }
                Thread.Sleep(3000);
            }
            return newPort;
        }
    }
}
```

## 🔑 Mudanças Principais

### 1. LogConfig Adicionado

```csharp
var logConfig = new LogConfig
{
    Type = "json-file",
    Config = new Dictionary<string, string>
    {
        { "max-size", "10m" },
        { "max-file", "5" },
        { "labels", "app,loja,loja-id,environment,version" }
    }
};
```

### 2. Labels Adicionados

```csharp
var labels = new Dictionary<string, string>
{
    { "app", "whatsapp-api" },
    { "loja", app.LojaNome ?? app.LojaAlias },
    { "loja-id", app.LojaId.ToString() },
    { "environment", _enviroment },
    { "version", "8.1.1" }
};
```

### 3. HostConfig Atualizado

```csharp
HostConfig = new HostConfig
{
    // ... outras configurações ...
    LogConfig = logConfig  // ✅ Adicionado
}
```

### 4. CreateContainerParameters Atualizado

```csharp
var containerCreateParameters = new CreateContainerParameters
{
    // ... outras configurações ...
    Labels = labels  // ✅ Adicionado
}
```

## 📊 Benefícios

1. **Filtragem por Loja**: `{loja="pizzariaromanelli"}`
2. **Filtragem por Ambiente**: `{environment="production"}`
3. **Filtragem por App**: `{app="whatsapp-api"}`
4. **Rotação Automática**: Logs não crescem infinitamente
5. **Integração com Loki**: Labels são automaticamente indexados

## 🔄 Atualizar Containers Existentes

Se você já tem containers rodando, pode atualizar o logging (mas não os labels):

```csharp
// Atualizar apenas o logging de containers existentes
public async Task UpdateContainerLoggingAsync(string containerId)
{
    using var client = new DockerClientConfiguration(new Uri(GetLocalDocker())).CreateClient();
    
    await client.Containers.UpdateContainerAsync(
        containerId,
        new ContainerUpdateParameters
        {
            LogConfig = new LogConfig
            {
                Type = "json-file",
                Config = new Dictionary<string, string>
                {
                    { "max-size", "10m" },
                    { "max-file", "5" }
                }
            }
        }
    );
}
```

**Nota**: Labels só podem ser definidos na criação do container. Para adicionar labels, será necessário recriar os containers.

## ✅ Checklist de Implementação

- [ ] Adicionar `LogConfig` no `HostConfig`
- [ ] Adicionar `Labels` no `CreateContainerParameters`
- [ ] Testar criação de container
- [ ] Verificar logs no Docker: `docker logs <container>`
- [ ] Verificar labels: `docker inspect <container> | grep Labels`
- [ ] Configurar Loki + Grafana
- [ ] Testar queries no Grafana

## 📚 Referências

- [Docker Logging Drivers](https://docs.docker.com/config/containers/logging/)
- [Docker Labels](https://docs.docker.com/config/labels-custom-metadata/)
- [Loki Labels](https://grafana.com/docs/loki/latest/logql/log_queries/#label-filter-expression)

