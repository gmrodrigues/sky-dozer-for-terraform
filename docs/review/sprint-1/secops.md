# Review — SecOps (Security Operations)
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** SecOps Engineer
**Data:** 2026-03-26

---

## Sumário Executivo de Segurança

O Sprint 1 introduziu código em três linguagens (Go, Zig, C via ABI) com interoperabilidade direta de memória. Do ponto de vista de segurança, essa arquitetura é ao mesmo tempo **promissora** — por evitar overhead de serialização que frequentemente introduz surface de ataque — e **preocupante** — por depender de contratos de ponteiro que, se violados, produzem comportamento indefinido sem safety net de runtime.

**Classificação geral de risco: MÉDIO** (aceitável para PoC; requer mitigações antes de produção)

---

## Análise de Surface de Ataque

### Vetor 1: FFI de Ponteiro Cruzado (Go ↔ Zig)

A função `ParseTFState` aceita:
```c
int32_t ParseTFState(const char* json_data, void* out_buf, int32_t max_nodes);
```

**Riscos identificados:**

1. **Buffer overflow potencial:** `out_buf` tem capacidade para `max_nodes` registros, mas o Go escreve `min(len(resources), max_nodes)` sem validar que `out_buf` tem de fato `max_nodes * 20` bytes disponíveis. Se o caller Zig passar um `max_nodes` maior que o buffer alocado, há escrita fora dos bounds. Zig em modo `Debug` detectaria isso com seu runtime safety, mas em `ReleaseFast` (modo de produção), o comportamento é indefinido.

   **Mitigação recomendada:** Passar também o tamanho do buffer em bytes e validar dentro do Go:
   ```go
   if uintptr(maxNodes)*NodeRecordSize > uintptr(bufSizeBytes) {
       return -1
   }
   ```

2. **Input não sanitizado (`json_data`):** O JSON passado via ponteiro C não é validado em tamanho antes de ser lido pelo `C.GoString()`, que lê até o primeiro `\0`. Um JSON malicioso ou corrompido sem terminador nulo causaria leitura além dos bounds. Em produção, onde o input viria de disco ou rede, isso é um risco real.

   **Mitigação:** Aceitar também o tamanho do JSON em bytes e usar `C.GoBytes()` em vez de `C.GoString()`.

3. **Sem timeout de parsing:** Arquivos `.tfstate` corrompidos com estruturas profundamente aninhadas (JSON bomb) podem causar o parser Go a consumir memória indefinidamente. O `encoding/json` da stdlib não tem limite de profundidade configurável.

   **Mitigação:** Usar `MaxBytesReader` ou parser alternativo com limite de profundidade.

### Vetor 2: Carregamento Dinâmico de `libbridge.so`

O `src/main.zig` carrega `libbridge.so` via linking dinâmico. Em produção:

1. **Path injection:** Se `LD_LIBRARY_PATH` for configurado de forma insegura, um atacante com acesso ao sistema de arquivos poderia substituir `libbridge.so` por uma biblioteca maliciosa com o mesmo nome de símbolo.

   **Mitigação:** Usar linking estático (`-static`) em produção, ou verificar hash do `.so` antes de carregar.

2. **Ausência de assinatura da biblioteca:** `libbridge.so` não é assinado digitalmente. Em pipelines de CI/CD, a cadeia de custódia do artefato não está garantida.

   **Mitigação:** Adicionar etapa de `sha256sum` do `.so` ao pipeline e armazenar hash esperado em controle de versão.

### Vetor 3: Dados Sintéticos em Ambiente de Desenvolvimento

O gerador `gen-tfstate` cria dados com seed fixo (`--seed=42`). Isso é adequado para a PoC, mas:

1. **Risco de dados de produção em testes:** Em algum momento um desenvolvedor pode substituir o fixture sintético por um `.tfstate` real contendo credenciais, ARNs, IPs privados, ou topologia de rede sensível. Não há nenhuma proteção contra isso hoje.

   **Mitigação:** Adicionar ao `.gitignore`: `zig-engine/testdata/*.tfstate.json` e documentar que apenas fixtures sintéticos devem viver aí.

---

## Compliance e Governança

| Item | Status | Observação |
|---|---|---|
| Dados de produção em repositório | ✅ Sem risco (PoC usa dados sintéticos) | Risco latente se substituídos |
| Dependências de terceiros | ✅ Zero (apenas stdlib Go + Zig) | Excelente postura de supply chain |
| Logging de operações sensíveis | ⚠️ Ausente | Sem audit trail das chamadas FFI |
| Validação de input externo | ⚠️ Parcial | JSON não tem limites de tamanho/profundidade |
| Gestão de secrets | ✅ N/A para PoC | Sem credentials no código |

---

## Recomendações Prioritizadas

**Alta Prioridade (antes de produção):**
1. Adicionar `buf_size_bytes` à assinatura de `ParseTFState` e validar bounds
2. Substituir `C.GoString()` por `C.GoBytes()` com tamanho explícito
3. Signing de `libbridge.so` no pipeline de CI

**Média Prioridade (Sprint 2-3):**
4. Limite de profundidade/tamanho no parser JSON
5. `.gitignore` para fixtures TFState reais

**Baixa Prioridade (pre-GA):**
6. Audit logging das chamadas FFI
7. Avaliar linking estático vs dinâmico para distribuição

---

## Conclusão

Para uma PoC interna, o nível de segurança é aceitável. A ausência de dependências de terceiros é uma postura excelente de supply chain security. As vulnerabilidades identificadas são classicas de código que opera em fronteiras de memória não gerenciada e precisam ser endereçadas antes que este código seja exposto a input não confiável.

**Score de Segurança: 6.5/10 (PoC) / 4/10 (produção no estado atual)**
