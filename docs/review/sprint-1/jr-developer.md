# Review — Junior Developer
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Carlos Mendes, Desenvolvedor Júnior (6 meses de experiência)
**Data:** 2026-03-26

---

## Minha Perspectiva Como Dev Júnior

Recebi o material do Sprint 1 e tentei entender o máximo que pude. Vou ser honesto sobre o que entendi, o que não entendi, e o que gostaria que estivesse explicado de forma diferente.

---

## O Que Consegui Entender

### O Problema Que Estamos Resolvendo

Isso ficou claro: ferramentas atuais de visualização Terraform travam quando a infraestrutura é grande. Queremos construir uma ferramenta que aguente 50.000 componentes sem travar. Legal! Isso faz sentido para mim.

### Os Números do Benchmark

Entendi que 12.45× mais rápido é muito bom, e que a meta era apenas 1.40×. Também entendi que 70ms para carregar é muito rápido — sei que abaixo de 100ms parece instantâneo para o usuário humano.

### O Gerador Sintético

O arquivo `gen-tfstate/main.go` foi o que mais consegui ler. É basicamente um loop que gera dados aleatórios e salva em JSON. Compreensível! Conseguiria até modificar para gerar mais campos.

---

## O Que Não Consegui Entender (E Pedindo Ajuda)

### O Que É cgo?

No `bridge.go` tem `import "C"` e um comentário em C dentro de Go. Nunca vi isso antes. Li na documentação que é "C interop" mas ainda não entendo como o Go consegue "chamar" C ou "ser chamado" pelo Zig.

**Pergunta:** Existe algum recurso — artigo, vídeo, tutorial — que explique `cgo` de forma simples? Poderia colocar isso no `README` para devs novos?

### O Que É `-buildmode=c-shared`?

Sei que compila o Go como biblioteca. Mas não entendo o que `.so` significa, por que precisamos disso, e como o Zig "encontra" essa biblioteca quando roda. O `LD_LIBRARY_PATH` que aparece nos docs parece magia negra para mim.

### `unsafe.Pointer` e `uintptr`

No `bridge_test.go` tem esse trecho que me assustou:
```go
base := uintptr(unsafe.Pointer(&outBuf[0]))
for i := 0; i < limit; i++ {
    off := base + uintptr(i*nodeRecSize)
    writeInt32LE(unsafe.Pointer(off+0), r.Index)
```

Sei que `unsafe` significa "perigoso". Mas não entendo *por que* precisamos fazer isso em vez de simplesmente escrever em um slice normal do Go. O comentário diz "mimicando o que a função C-exported faz" mas ainda não claro para mim.

### Zig: Quase Nada

Com todo o respeito, o código Zig é como uma língua estrangeira para mim. O `soa_bench.zig` tem sintaxe muito diferente de Go ou Python. Não sei por onde começar a aprender.

---

## Crítica Construtiva Honesta

### O README Não Existe

Procurei um `README.md` na raiz do projeto para entender como configurar meu ambiente e rodar os testes. Não encontrei. Tive que ir no `Makefile` e no `journal/sprint-1.md` para descobrir os comandos.

Para um dev júnior que acabou de clonar o repositório, isso é uma barreira enorme. **Por favor criem um README** com pelo menos:
- O que esse projeto faz (1 parágrafo)
- Como instalar as dependências (Go, Zig)
- Como rodar os testes (`make go-test`, `make zig-bench`)
- Link para a documentação em `docs/`

### Os diagramas ajudaram muito!

O `ffi-sequence.png` foi o que mais me ajudou a entender o que está acontecendo. Ver visualmente a sequência "Zig aloca → Go escreve → Zig libera" fez mais sentido do que ler o código. **Mais diagramas por favor!**

### Não Consigo Contribuir Hoje

Se o Tech Lead pedisse para eu corrigir um bug simples no `bridge.go`, acho que conseguiria. Mas no `soa_bench.zig` ou no `build.zig`? Eu não saberia nem por onde começar. Isso me preocupa — quero ser útil no projeto mas sinto que preciso de meses de estudo antes de conseguir contribuir para as partes mais complexas.

---

## O Que Precisaria Para Me Sentir Parte do Projeto

1. **README.md** explicando como montar o ambiente
2. **Uma issue rotulada "good first issue"** no tracker — algo simples que eu pudesse resolver para ganhar familiaridade com o codebase
3. **Acesso a uma sessão de pair programming** com o dev principal do Zig, mesmo que seja 1 hora de observação

**Minha nota como júnior: 6/10**
*(Projeto tecnicamente impressionante, mas inacessível para quem está começando)*
