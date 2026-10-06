# Conformidade com as Diretrizes de Código

Aplicação das [Diretrizes de Código](Diretrizes-de-Codigo.md) **2.1.0** ao
KEngine, que é um projeto de **nível 4** (serviço crítico: pagamentos e
dados pessoais). Valem os checklists dos níveis 1 a 4.

Criado em 01/10/2026 e atualizado a cada feature; última revisão
completa em **04/10/2026**, na `main` em `260a9a7`. Rever este documento
antes de cada versão (seção *Antes de cada versão*) e sempre que um item
mudar.

**Legenda:** ✅ cumprido · 🟡 parcial · ❌ não cumprido. Entre colchetes, o
tipo de verificação que as diretrizes pedem: **[hook]**, **[CI]** ou
**[manual]**.

---

## Checklist por nível

### Nível 1: script ou experimento pessoal

| Item | Situação | Evidência |
| --- | --- | --- |
| Nível do projeto declarado no README **[manual]** | ✅ | `README.md`, seção *Nível do projeto* |
| Nenhum segredo no código ou no repositório **[hook]** | ✅ | Nenhum `.env`, `.pem`, `.key`, `.p12`, `.pfx` ou chave SSH versionado; o `pre-commit` barra esses arquivos no índice (03/10) |
| Código formatado e sem avisos do linter **[hook] [CI]** | ✅ | `gofmt`, `go vet` (padrão, demo, Windows) e `tsc` no `pre-commit`; `staticcheck` no `pre-push`; tudo repetido no CI a cada PR e push na `main` (03/10) |
| README diz o que o projeto faz e como rodar **[manual]** | ✅ | `README.md` no modelo do Anexo A |
| Nomes claros; comentários explicam o porquê **[manual]** | ✅ | Convenção do projeto: comentário de cabeçalho com o porquê de cada pacote |

### Nível 2: ferramenta local

| Item | Situação | Evidência |
| --- | --- | --- |
| Nenhum erro descartado nem panic sobre dado externo **[manual]** (em Rust, `unwrap`/`expect`) | 🟡 | Firewall, cofre e stores tratam e propagam os erros; não houve auditoria do código inteiro com esse foco |
| Erros novos classificados: transitório, permanente ou bug **[manual]** | ✅ | Venda em checkpoints (tabela *Classificação de erros* do spec) e outbox: erro comum é transitório, `ErrPermanente` termina o item, pânico é bug e isola o item (spec `outbox-resiliente`, 03/10) |
| Toda entrada externa validada **[manual]** | 🟡 | Entrada da tela e do HTTP: firewall com fuzzing (≈10 milhões de entradas, 28/09). Respostas das integrações: o adquirente exige `Identificador`; as respostas dos clientes reais serão validadas quando eles existirem |
| Testes do caminho feliz e das falhas principais passando **[hook] [CI]** | ✅ | `go test -race`, testes do modo demo e `npm test` no `pre-push` e no CI (03/10) |
| Dependências sem vulnerabilidade conhecida **[hook] [CI]** | ✅ | `govulncheck` v1.8.0: nenhuma vulnerabilidade; `npm audit`: 0 (03/10). Os dois no `pre-push` e no CI; Dependabot semanal |
| Ações destrutivas pedem confirmação **[manual]** | 🟡 | Nada é apagado: vendedor só é desativado, venda bloqueada nunca é descartada. `kengine-admin vendedor desativar` não pede confirmação |
| "Carregando", "sem dado" e "erro" nunca parecem iguais na interface **[manual]** | 🟡 | A tela distingue processando, bloqueado e erro; o painel de status do topo mostra latências fixas (`DEMO-ONLY`) |
| Versão semântica e CHANGELOG atualizados a cada lançamento **[manual]** | 🟡 | `CHANGELOG.md` criado em 01/10 (seção "Não lançado"); nenhuma versão lançada ainda |

### Nível 3: aplicação com servidor

| Item | Situação | Evidência |
| --- | --- | --- |
| Toda comunicação de rede com TLS **[manual]** | 🟡 | Saídas: mTLS 1.3 com certificate e IP pinning (pronto, sem cliente real ainda). Tela ↔ kernel: canal local sem rede (named pipe com `PIPE_REJECT_REMOTE_CLIENTS` e ACL no Windows; Unix socket 0700 em desenvolvimento), sem TLS — desvio registrado e revisado em 04/10 ([ADR 0004](../docs/adr/0004-sem-tls-entre-tela-e-kernel-local.md)) |
| Autenticação e autorização em todo endpoint **[manual]** | 🟡 | Canal administrativo do serviço só para administradores elevados (ACL do pipe; B1 corrigido) e canal da tela só para usuários interativos locais. Desde 04/10, abrir e fechar o caixa exige código e senha do supervisor (Argon2id, trava no 5º erro) e nenhuma venda entra sem caixa aberto; o operador não tem senha por decisão do dono do produto (o supervisor responde pelo caixa que abriu). Desconto acima de 20% também exige código e senha do supervisor (a senha nunca é gravada; a recusa é auditada e conta para a trava), e toda ação futura de supervisor passa pela mesma conferência (`acaoDeSupervisor`). Servidor HTTP de testes sem autenticação (só loopback). `/health` dispensado pela exceção das diretrizes |
| Retry com backoff e jitter só para erros transitórios, com limite de tentativas **[manual]** | ✅ | Outbox: backoff de 2 s a 5 min com jitter de ±20%, só para transitórios; depois de 30 min o item entra na DLQ e o operador é avisado, mas segue sendo tentado — desvio registrado ([ADR 0006](../docs/adr/0006-dlq-que-segue-tentando.md)) |
| Operações de mutação idempotentes **[manual]** | ✅ | Registro e cancelamento idempotentes pelo `VendaID` (hash da entrada; 02/10); processadores do Engine 2 idempotentes pelo estado; contrato de idempotência na emissão (`porta.EmissorFiscal`, chave = `VendaID`) |
| Fila local persistente para ações pendentes **[manual]** | ✅ | Outbox dentro do cofre, persistido a cada item e retomado no boot |
| Timeout em toda chamada externa **[manual]** | ✅ | Prazo de 30 s por item do outbox (todo adapter de saída roda dentro dele) e `Timeout` de 30 s no cliente HTTP seguro (`NovoClienteMTLS`) como segunda barreira (03/10) |
| Logs estruturados de falhas e retries **[manual]** | ✅ | `log/slog` em JSON; o outbox registra tentativa, erro e próxima tentativa |
| Toda feature offline classificada: offline, online ou híbrida **[manual]** | ✅ | Tabela em [`KEngine-kernel.md`](Arquitetura-1.0/Kernel-1.0/KEngine-kernel.md), Seção VIII, "Offline-First" (01/10) |
| Dados pessoais listados no README conforme a LGPD **[manual]** | ✅ | `README.md`, seção *Dados pessoais*. Base legal e prazo de guarda: a definir com o jurídico e o contador |

### Nível 4: serviço crítico

| Item | Situação | Evidência |
| --- | --- | --- |
| SLOs definidos e painel publicado **[manual]** | ❌ | Métricas calculadas, mas no serviço da loja não expostas (`/metrics` só no `kengine-server`); sem SLOs, painel ou alertas. Planejado (05/10): SLOs no resumo de cada ciclo de log, bloco "Saúde do sistema" na área do supervisor e vigia local; sem envio automático à central, desvio registrado ([ADR 0009](../docs/adr/0009-observabilidade-local-com-envio-manual.md), spec `observabilidade`) |
| DLQ com operador notificado **[manual]** | ✅ | Itens falhando há mais de 30 min e itens com bug aparecem como aviso na tela (relido a cada minuto), em log de erro e na métrica `kengine_outbox_dlq`; ADR 0006 |
| Auditoria de acesso a dados e ações sensíveis **[manual]** | 🟡 | Registradas: vendas divergentes, quem autorizou desconto, quem vendeu (código do vendedor), as ações de supervisor no `por` de `eventos_venda` (`supervisor:<código>`) e, desde 04/10, quem abriu e fechou o caixa, o fechamento automático e cada senha de supervisor recusada (`eventos_caixa`, sem a senha); a venda grava a abertura de caixa que responde por ela. Falta: quem cadastrou vendedor e supervisor (hoje só no log do serviço), acesso ao cofre |
| Pelo menos 3 cenários de falha testados por operação crítica **[manual]** | 🟡 | Venda: 7 testes de reinício sobre o mesmo cofre (`internal/venda/reinicio_test.go`: parada em Registrada, parada em Pagamento confirmado, confirmação pendente, invariante quebrado, adquirente fora, Protheus fora, item com bug), além de bloqueios, replay, divergência, fila cheia e cofre ausente. Caixa e ações de supervisor: a conferir |
| Vulnerabilidades críticas corrigidas em até 24 h **[manual]** | ✅ | Processo em *Resposta a vulnerabilidades* (abaixo): alertas e correções automáticas do Dependabot ligados no repositório, auditoria diária (`auditoria.yml`) e verificação a cada PR e push; responsável: o dono do produto (03/10) |

### Antes de cada versão, em qualquer nível

| Item | Situação | Evidência |
| --- | --- | --- |
| CHANGELOG atualizado **[manual]** | ✅ | `CHANGELOG.md`, seção "Não lançado" |
| Todo desvio das diretrizes registrado em ADR ou comentário **[manual]** | ✅ | Oito desvios em [`docs/adr/`](../docs/adr/0000-modelo.md) (abaixo) |
| Dependências sem uso removidas **[manual]** | ✅ | `go mod tidy -diff` sem diferenças (04/10), também verificado pelo CI a cada PR |
| O nível do projeto continua o mesmo? **[manual]** | ✅ | Nível 4 desde 01/10 |

---

## Resposta a vulnerabilidades

Decidido em 03/10. **Responsável:** o dono do produto (Lorkyrr), que recebe
os avisos por e-mail do GitHub.

| Como chega o aviso | Quando |
| --- | --- |
| Alerta de segurança do Dependabot (e PR de correção automático, quando existe versão corrigida) | Assim que a vulnerabilidade é publicada |
| Falha do workflow `auditoria.yml` (`govulncheck` e `npm audit --audit-level=high`) | Todo dia, 06:00 em Brasília |
| Falha do `ci.yml` ou do hook `pre-push` | A cada PR, push na `main` ou push local |

| Severidade | Prazo | O que fazer |
| --- | --- | --- |
| Crítica ou alta (e todo achado do `govulncheck`, que só aponta código de fato alcançado) | **24 h** | Atualizar a dependência (o PR do Dependabot, se houver); sem versão corrigida, contornar (desligar o trecho afetado ou bloquear a entrada) e registrar em ADR |
| Média ou baixa | Rodada semanal do Dependabot | Mergear o PR de atualização quando o CI passar |

---

## Desvios registrados

| ADR | Regra das diretrizes | Decisão |
| --- | --- | --- |
| [0001](../docs/adr/0001-cofre-local-cifrado.md) | Segurança > Autonomia: dados sensíveis locais | Cofre local cifrado para vender sem rede |
| [0002](../docs/adr/0002-checkpoints-entre-sistemas.md) | Consistência de estado: tudo ou nada | Venda em checkpoints duráveis entre sistemas |
| [0003](../docs/adr/0003-wails-typescript-sem-framework.md) | Tabela de tecnologias | Wails com TypeScript sem framework |
| [0004](../docs/adr/0004-sem-tls-entre-tela-e-kernel-local.md) | TLS em toda comunicação, inclusive interna | Sem TLS no canal local entre tela e kernel (permanente enquanto o canal for local; revisado em 04/10) |
| [0005](../docs/adr/0005-invariante-quebrado-isola-a-venda.md) | Bug: parar o processo | Invariante quebrado no boot isola a venda |
| [0006](../docs/adr/0006-dlq-que-segue-tentando.md) | Retry: DLQ depois de N falhas; Bug: parar o processo | DLQ que segue tentando; pânico isola só o item |
| [0007](../docs/adr/0007-cartao-conferido-so-localmente.md) | Confirmação explícita do destino | Cartão conferido só localmente; Pix conferido no Itaú |
| [0009](../docs/adr/0009-observabilidade-local-com-envio-manual.md) | Nível 4: alertas automáticos, falha alertada em < 5 min | Observabilidade local; o supervisor exporta os logs para a central (aceita em 05/10, a implementar) |

---

## Mecanismos

As diretrizes pedem que toda regra verificável por ferramenta seja
verificada por ferramenta. Os anexos delas são para Rust (`cargo`); no
KEngine (Go e TypeScript), os equivalentes são:

| Regra | Anexo (Rust) | Equivalente no KEngine | Situação |
| --- | --- | --- | --- |
| Formatação | `cargo fmt --check` | `gofmt -l` (não deve listar nada) | `pre-commit` e CI |
| Linter | `cargo clippy -D warnings` | `go vet` e `staticcheck` 2026.2.1 (padrão, demo, Windows); `tsc` | `go vet` e `tsc` no `pre-commit`, `staticcheck` no `pre-push`; todos no CI |
| Segredos fora do repositório | Hook de pre-commit (Anexo E) | O mesmo hook, sem a parte de `cargo` | `pre-commit` |
| Testes | `cargo test` | `go test -race ./internal/... ./cmd/...`, testes do modo demo e `npm test` | `pre-push` e CI |
| Vulnerabilidades | `cargo audit` | `govulncheck` v1.8.0 e `npm audit` | `pre-push`, CI e auditoria diária (`auditoria.yml`); alertas do Dependabot ligados |
| Dependências atualizadas | Dependabot (`cargo`, `github-actions`) | Dependabot com `gomod`, `npm` e `github-actions` | `.github/dependabot.yml` |
| Caracteres invisíveis | — | Mesma faixa de U+200B a U+FEFF | `pre-commit` e CI |
| Dependências sem uso | — | `go mod tidy -diff` | CI |
| Cobertura e duplicação | — | `go test -coverprofile` e `jscpd` 5.4.0 | CI (cobertura só medida; duplicação barra acima de 5%) |
| Modelos de README, CHANGELOG, ADR e PR | Anexos A a D | `README.md`, `CHANGELOG.md`, `docs/adr/`, `.github/pull_request_template.md` | ✅ (01/10) |

Hooks, Dependabot e CI em push e pull request entraram em 03/10 (feature 2
do epic, spec `mecanismos-diretrizes`); as actions seguem fixadas pelo hash
do commit. Os hooks só valem depois de `git config core.hooksPath .githooks`
em cada clone. A `main` não exige os checks antes do merge: repositório
privado em conta gratuita não tem proteção de ramo.

---

## Métricas

As metas das diretrizes que valem a partir do nível 3 ou 4, com o valor do
KEngine em 01/10:

| Métrica | Meta | KEngine hoje |
| --- | --- | --- |
| Entradas externas com validação | 100% | Entrada da tela e do HTTP: 100% (firewall). Respostas reais: a validar com os clientes reais |
| Cobertura de testes (branches) | > 80% | 74,5% das **instruções** em 04/10 (`go test -cover`; o Go não mede branches); medida no resumo de cada execução do CI |
| Cenários de falha por operação crítica | ≥ 3 | Venda: atende (7 testes de reinício e os de bloqueio). Caixa e ações de supervisor: a conferir |
| Dependências sem uso | Zero | Zero (`go mod tidy -diff`) |
| Índice de duplicação | < 5% | 0,31% das linhas de Go e TypeScript, sem testes e sem código gerado (`jscpd`, 03/10); o CI barra acima de 5% |
| Vulnerabilidades críticas sem correção | Nenhuma há mais de 24 h | Nenhuma conhecida: Go (`govulncheck`) e frontend (`npm audit`) em 03/10 |
| Operações entregues com sucesso | > 99,9% | Sem medição (sem uso real) |
| Latência P95 de I/O | < 100 ms | Sem medição |
| Tamanho do binário ou bundle | Alertar se subir > 10% | Sem acompanhamento |
| Tempo até falha detectada e alertada | < 5 min | Sem alertas. Planejado: vigia local a cada minuto, aviso na tela; fora da loja, só quando o supervisor exporta (ADR 0009) |
| Operações na DLQ | Alertar se > 1% | Medida em `kengine_outbox_dlq` (03/10); o alerta externo fica para a feature 11 |
| Sincronização após reconexão | < 30 s | Outbox: ciclo de 5 s, backoff até 5 min — pode passar de 30 s |
