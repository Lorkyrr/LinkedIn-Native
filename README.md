# LinkedIn-Native

Cliente desktop nativo e leve para o LinkedIn, focado em desempenho, privacidade e uma experiência sem distrações.

## Descrição do Projeto

O **LinkedIn-Native** é uma aplicação desktop desenvolvida para integrar a plataforma do LinkedIn diretamente no sistema operativo local, oferecendo uma experiência fluida, consumo reduzido de recursos e notificações nativas do sistema.

A aplicação utiliza uma arquitetura baseada em serviços locais, garantindo isolamento de sessão, gestão de dados em cache local e persistência cifrada.

## Nível do projeto

**Nível 3 — aplicação com servidor**: Aplicação que opera com serviços locais e remotos, persistência de dados durável e integração de rede.

Exigências cumpridas conforme as [Diretrizes de Código](architecture-docs/Conformidade-Diretrizes.md):
- Comunicação de rede segura utilizando TLS 1.3 obrigatório para chamadas remotas.
- Autenticação local e gestão segura de sessões/tokens no keyring do sistema operativo.
- Estrutura de retries com backoff exponencial e jitter para requisições de rede.
- Persistência e cache local resiliente a falhas ou interrupções de conexão.
- Tratamento estrito de dados pessoais de acordo com a LGPD e GDPR.

## Instalação e Pré-requisitos

### Pré-requisitos
- **Go**: 1.27 ou superior
- **Node.js**: v20+ e `npm` (necessário para compilação do frontend)
- **Wails CLI**: v2 (para a interface gráfica nativa)

### Passos de Instalação

```bash
# 1. Clonar o repositório
git clone [https://github.com/Lorkyrr/LinkedIn-Native.git](https://github.com/Lorkyrr/LinkedIn-Native.git)
cd LinkedIn-Native

# 2. Instalar dependências da interface
(cd frontend && npm ci)

# 3. Compilar a aplicação Desktop
wails build
