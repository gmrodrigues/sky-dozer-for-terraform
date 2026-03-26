# Review — UX / Frontend Specialist
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Isabela Ramos, UX Engineer & Frontend Specialist
**Data:** 2026-03-26

---

## Perspectiva de Experiência do Usuário e Frontend

Estou neste projeto para garantir que a excelência técnica do backend se traduza em uma interface que as pessoas realmente queiram usar. Performance sem usabilidade é uma solução para um problema que ninguém vai adotar. Minha análise do Sprint 1 cobre o que foi entregue, o que está faltando do ponto de vista de UX, e os riscos de design que já consigo identificar mesmo sem ter uma tela para revisar.

---

## O Que o Sprint 1 Significa Para o Produto Visual

### Os Números de Performance São UX Decisions

70ms de parse e 12.45× de speedup por SoA não são apenas benchmarks de engenharia. Eles são **decisões de UX com consequências diretas**:

- **70ms de parse:** Significa que podemos oferecer carregamento sem loading spinner (abaixo de 100ms é percebido como instantâneo). Isso é a diferença entre uma ferramenta que parece "pesada" e uma que parece "mágica". Excelente.

- **12.45× de speedup no culling:** Significa que o pan e zoom do canvas poderão rodar suavemente a 60fps sem stuttering. Stuttering durante navegação num mapa de infraestrutura causa desorientação espacial — o usuário perde o fio do raciocínio sobre onde está. Eliminar stuttering é uma decisão de UX crítica, não apenas de performance.

- **ArenaAllocator com reset O(1):** Para o usuário, isso significa que trocar de projeto Terraform ("fechar um mapa e abrir outro") vai parecer instantâneo, sem aquele delay de "limpando ambiente anterior". Isso é um detalhe de UX que ferramentas concorrentes ignoram.

---

## O Que Está Completamente Ausente e Me Preocupa

### 1. Nenhuma Definição de Mental Model do Usuário

O projeto assume que o usuário vai interagir com um "canvas ZUI com zoom semântico" — mas isso é um paradigma de interação relativamente incomum. Muitos engenheiros de plataforma estão acostumados com:
- **Árvores hierárquicas** (como o AWS Console)
- **Grafos com força dirigida** (como o Rover, Graphviz)
- **Tabelas filtráveis** (como o Terraform Cloud UI)

O **ZUI (Zoomable User Interface)** é mais parecido com Google Maps ou Prezi — exige uma curva de aprendizado diferente. Antes de construir o motor de renderização, precisamos validar: **o usuário realmente quer navegar por isso como um mapa?** Ou quer buscar por nome e ter o grafo centrado no recurso encontrado?

**Recomendação urgente:** Conduzir 3-5 entrevistas de usuário com engenheiros de plataforma antes do Sprint 3 (quando a renderização começa). Pergunta-chave: *"Se você pudesse navegar pela sua infraestrutura Terraform como quiser, como você navegaria?"*

### 2. Sem Modelo de Informação Definido

O que um "nó" representa visualmente? O que é exibido em zoom macro vs micro? As decisões do Sprint 1 mencionam:
- **Macro:** módulos como polígonos simplificados
- **Meso/Micro:** ícones individuais e rótulos HCL

Mas não existe ainda:
- Hierarquia visual (qual nó "pai" engloba quais "filhos"?)
- Sistema de cores (por tipo de recurso? por provider? por estado?)
- Tipografia (qual fonte para rótulos de recurso? tamanhos por zoom level?)
- Estados visuais (recurso saudável, em drift, não aplicado, destruído pendente)

**Esses são bloqueadores de design que precisam ser resolvidos antes da implementação do Sprint 3**, não depois. Se o motor de renderização for construído sem um sistema de design definido, haverá retrabalho significativo.

### 3. Interações Ainda Não Foram Pensadas

O ZUI é fundamentalmente uma interface de interação contínua. As seguintes interações precisam de design explícito:

| Interação | Comportamento Esperado | Status |
|---|---|---|
| Pinch to zoom | Zoom geométrico → semântico acima do threshold | ❓ Não especificado |
| Click em nó | Abre painel de detalhes? Seleciona? Navega para filho? | ❓ Não especificado |
| Search / Filter | Busca por nome, tipo, tag | ❓ Não no roadmap |
| Multi-select | Selecionar grupo de recursos para comparar | ❓ Não no roadmap |
| Undo/Redo de navegação | Voltar ao ponto de vista anterior | ❓ Não no roadmap |
| Keyboard navigation | Acessibilidade (WCAG) | ❓ Não mencionado |

---

## Riscos de UX Identificados a Nível de Arquitetura

### O "Semantic LoD" Pode Desorientar

O Sprint 1 menciona que nós desaparecem e agrupam quando a câmera afasta. Isso levanta uma questão crítica de UX — a **"mudança de nível" pode causar desorientação**:

> Usuário fica olhando para uma instância EC2 → afasta levemente → a instância desaparece e é substituída por um retângulo da "subnet" → usuário perde completamente a referência visual de onde estava.

O documento menciona "estabilidade geométrica" como solução, mas não especifica como implementá-la de forma que preserve o mental model do usuário. Isso precisa de um documento de especificação de UX antes da implementação.

### Sem Consideração de Acessibilidade

Uma interface baseada em canvas ZUI é intrinsecamente problemática para:
- Usuários de screen readers (canvas não é acessível por padrão)
- Usuários com daltomismo (se o sistema de cores não for pensado para isso)
- Usuários com dificuldade motora (navegação por zoom requer precisão de mouse/trackpad)

Se o produto for vendido para empresas enterprise, terão requisitos de WCAG 2.1 AA ou superior. Precisamos pensar nisso antes de solidificar o modelo de renderização.

---

## Pedidos Concretos para os Próximos Sprints

1. **Antes do Sprint 3:** Wireframes de baixa fidelidade para os 3 níveis de zoom (macro/meso/micro)
2. **Antes do Sprint 3:** Sistema de design mínimo: paleta de cores, tipografia, estados visuais dos nós
3. **Sprint 3:** Incluir UX Specialist no design do "Semantic Zoom" para garantir estabilidade cognitiva
4. **Sprint 4:** Teste de usabilidade com 3 usuários antes do lançamento de qualquer versão beta

**Score UX do Sprint 1: 4/10 (Sprint é de infra técnica — não esperava telas)**
**Score UX do Produto Planejado: 6/10 (potencial enorme, mas riscos de design não endereçados)**
