# Review — Tech Lead
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Tech Lead
**Data:** 2026-03-26

---

## Avaliação Técnica Geral

O Sprint 1 entregou exatamente o que um sprint de fundação deve entregar: **evidência empírica** de que as apostas arquiteturais são sólidas antes de construir sobre elas. Os dois gates passaram com folga. Vou analisar cada componente em detalhe.

---

## go-bridge: Análise de Código

### O Que Funcionou Bem

A implementação da `ParseTFState` está correta em relação às regras de segurança do cgo:

```go
// Go não mantém cópia do ponteiro C após o retorno — correto.
base := uintptr(outBuf)
for i := 0; i < limit; i++ {
    rec := (*C.NodeRecord)(unsafe.Pointer(base + uintptr(i)*NodeRecordSize))
    // ...
}
```

O uso de `uintptr` em vez de manter o `unsafe.Pointer` diretamente é o padrão correto: convertemos para `uintptr` (um inteiro, não rastreado pelo GC), fazemos a aritmética, e convertemos de volta apenas no momento de escrever. Isso satisfaz a regra do cgo que proíbe o Go de reter ponteiros C entre chamadas.

### Preocupações Técnicas

**1. Ausência de `//go:noescape` e anotações de unsafe:**
A função `callParseInProcess` no arquivo de testes usa `unsafe.Pointer` de forma que, em teoria, o compilador poderia reordenar. Para o teste isso é aceitável, mas a versão de produção deveria ter comentários de invariantes de segurança mais explícitos.

**2. `json.Unmarshal` como caminho de parsing:**
O design usa `encoding/json` para fazer o parse do TFState. Isso é correto para a PoC, mas em produção o gargalo será aqui — não na transferência FFI. O `encoding/json` da stdlib usa reflection e é notoriamente lento. Para escala real, deve-se considerar `github.com/bytedance/sonic` ou `github.com/json-iterator/go`. Recomendo abrir uma issue de performance para este ponto antes do Sprint 4.

**3. Gerador sintético acoplado ao formato interno:**
O `gen-tfstate` gera JSON com os campos `x`, `y`, `w`, `h` diretamente no recurso. Um `.tfstate` real do Terraform não tem esses campos — eles precisariam ser extraídos de `attributes` aninhados. Isso significa que o teste atual valida a bridge FFI mas **não** valida o parser HCL real. Deve ser documentado explicitamente como limitação do escopo da PoC.

---

## zig-engine: Análise de Código

### O Que Funcionou Bem

O benchmark `soa_bench.zig` está corretamente estruturado:
- Usa `ReleaseFast` — essencial para que o compilador Zig aplique vetorização SIMD
- O `+%=` (overflow wrapping) evita UB em ambos os loops, correto
- A variável `sink` previne que o compilador elimine o loop como dead code

### Preocupações Técnicas

**1. O teste de integração Zig não foi executado end-to-end:**
`src/main.zig` foi escrito mas não executado porque `LD_LIBRARY_PATH` não foi configurado no ambiente de runtime do `zig build test`. Isso é um bloqueio real: o PRT-01 tecnicamente não está completo para o lado Zig. A solução é adicionar ao `build.zig`:

```zig
run_prt01.addPathDir("../go-bridge");  // ou setenv LD_LIBRARY_PATH
```

**2. `rng.random()` retorna um valor com tempo de vida ligado a `rng`:**
No Zig 0.15, `var random = rng.random()` armazena uma referência ao PRNG interno do `rng`. A reatribuição de `rng` após obter `random` invalida a referência. No código atual:

```zig
var rng = std.Random.DefaultPrng.init(42);
var random = rng.random();         // aponta para rng interno
// ...
rng = std.Random.DefaultPrng.init(42);  // rng é substituído
random = rng.random();              // random atualizado — OK
```

A reatribuição de `random` logo após é correta, mas é um padrão frágil. Prefiro:
```zig
{ // escopo para o primeiro rng
    var rng1 = std.Random.DefaultPrng.init(42);
    // usar rng1.random() diretamente
}
```

**3. Build.zig sem fixação de versão mínima:**
Não há `minimum_zig_version` declarado no `build.zig`. Com as quebras de API que vimos entre 0.14 e 0.15, isso é essencial. Adicionar:
```zig
pub fn build(b: *std.Build) void {
    b.minimum_zig_version = "0.15.0";
    // ...
}
```

---

## Arquitetura: Avaliação

A decisão de usar `uintptr` para aritmética de ponteiro no Go e `@ptrCast` no Zig como "cola" entre os dois mundos de memória é correta e elegante. A regra de ouro — **Zig aloca, Go escreve, Zig libera** — foi implementada e mantida.

A escolha de `ArenaAllocator` também está correta: para um grafo que será carregado uma vez e descartado como unidade, arena é a estrutura ideal. O custo de `deinit()` é genuinamente O(1).

---

## Action Items para o Sprint 2

- [ ] Fechar PRT-01 Zig: configurar `LD_LIBRARY_PATH` no `build.zig` e executar `zig build test` com sucesso
- [ ] Documentar limitação do parser sintético vs TFState real
- [ ] Adicionar `minimum_zig_version` ao `build.zig`
- [ ] Consolidar Makefile → `build.zig` via `addSystemCommand`
- [ ] Abrir issue: avaliar `sonic` ou `json-iterator` para produção

**Nota Técnica: 8/10**
*(Excelência na FFI e benchmark; penalização por PRT-01 incompleto e fratura no pipeline de build)*
