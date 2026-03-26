**Documento de Requisitos da Prova de Conceito (PRT - PoC Requirements Tracker)**
**Projeto:** Motor ZUI (Zoomable User Interface) de Alta Performance para Infraestrutura como Código (IaC)
**Foco Arquitetural:** Culling Espacial (R-Trees), FFI Segura (Go ↔ Zig), Design Orientado a Dados (SoA) e Semantic LoD.

Este PRT define os portões de validação rigorosos para provar a viabilidade técnica de renderizar o Grafo Acíclico Dirigido (DAG) de 50.000+ recursos do Terraform a consistentes 60 quadros por segundo (16.6ms por quadro). A arquitetura abandona o gerenciamento de tempo de execução baseado em DOM e Garbage Collection em favor de programação de sistemas de baixo nível.

---

### 1. Visão Geral das Hipóteses Arquiteturais

A Prova de Conceito (PoC) não construirá o produto final, mas isolará e testará os quatro maiores gargalos de risco técnico que ferramentas tradicionais (como Rover ou Pluralith) enfrentam em alta escala:
1.  **Gargalo de I/O e Parsing:** Substituir o `terraform show -json` via subprocesso por invocações de memória direta usando a Interface Binária do C (C ABI).
2.  **Gargalo de Memória (GC Pauses):** Escapar do ciclo de marcação do Go (que pode consumir até 25% da CPU) e gerenciar a vida útil da memória deterministicamente em Zig usando `ArenaAllocator`.
3.  **Gargalo de Cache da CPU:** Mudar a estrutura dos nós de um *Array of Structures (AoS)* para *Structure of Arrays (SoA)*.
4.  **Gargalo de Renderização da GPU (Overdraw):** Implementar eliminação de frustum de visão (culling) usando uma R-Tree combinada com Nível de Detalhe Semântico (Semantic Zoom).

---

### 2. Casos de Teste da PoC e Critérios de Sucesso (PRT)

Abaixo estão os testes críticos a serem desenvolvidos, com métricas de aprovação binárias (Passa / Não Passa).

#### PRT-01: Ponte FFI de Inversão de Memória (Go Bridge ↔ Zig)
*   **Objetivo:** Validar o carregamento dos dados HCL sem serialização JSON e sem violar as regras de segurança de ponteiros do `cgo`.
*   **Metodologia:** Compilar um parser mínimo em Go usando a flag `-buildmode=c-shared`, que produzirá um arquivo compartilhado e um cabeçalho C. O código Zig alocará um buffer de bytes através de um `ArenaAllocator` nativo e passará o ponteiro (Ponteiro C) para o Go. O Go achatará a Árvore Sintática (AST) do Terraform e escreverá os dados primitivos nesse buffer.
*   **Regra de Segurança Estrita:** O Go não pode manter nenhuma cópia do Ponteiro C após o retorno da função, e o Zig não receberá nenhum ponteiro alocado no heap do Go.
*   **Critério de Sucesso:**
    *   [ ] Inicialização e parsing de um arquivo de estado sintético de 50.000 nós em **< 500ms** (contra os potenciais vários segundos da abordagem JSON).
    *   [ ] Zero falhas de segmentação (Segfaults) ou pânicos do Garbage Collector do Go apontando violação de ponteiro.

#### PRT-02: Localidade de Cache via Design Orientado a Dados (DoD)
*   **Objetivo:** Provar que estruturas SoA (Structure of Arrays) mitigam a invalidação de linha de cache L1 durante as iterações de renderização visual.
*   **Metodologia:** Em Zig, implementar o armazenamento dos recursos do Terraform usando `MultiArrayList`. Isso dividirá automaticamente as propriedades geométricas ($x$, $y$, $width$, $height$) das propriedades de metadados (IDs, nomes HCL) em matrizes contíguas isoladas em memória.
*   **Critério de Sucesso:**
    *   [ ] O loop que itera sobre a geometria de 50.000 nós para calcular a visibilidade (culling) deve demonstrar ser no mínimo **40% mais rápido** em SoA do que uma implementação tradicional em AoS (Array of Structures).
    *   [ ] Profiling de CPU deve confirmar uma queda drástica nos *L1 Cache Misses*.

#### PRT-03: Particionamento Espacial e View-Frustum Culling
*   **Objetivo:** Garantir que geometrias fora dos limites da tela atual não alcancem as chamadas de desenho (draw calls) da GPU, mantendo o orçamento do quadro.
*   **Metodologia:** Uma vez que os dados de nuvem consistem frequentemente em geometrias não-pontuais e altamente sobrepostas (ex: uma VPC retangular gigante contendo várias sub-redes retangulares), testaremos a estrutura espacial **R-Tree**. A R-Tree baseia-se em retângulos delimitadores mínimos (MBRs) e é superior aos Quadtrees para tratar polígonos densos e sobrepostos (window queries).
*   **Critério de Sucesso:**
    *   [ ] Consultas de janela (recorte na área de visão atual da câmera) a uma R-Tree de 50.000 polígonos devem ocorrer em $O(\log n)$ e retornar o subconjunto visível em tempo sub-milissegundo.
    *   [ ] As R-trees devem superar os Quadtrees em 2 a 3 vezes na velocidade de consulta visual contínua para esses polígonos sobrepostos.

#### PRT-04: Renderização com Nível de Detalhe Semântico (Semantic LoD)
*   **Objetivo:** Manter a "estabilidade geométrica" sem sobrecarregar o usuário ou a GPU no nível macro (quando a câmera está totalmente afastada no canvas infinito).
*   **Metodologia:** Acoplar o motor Zig ao Raylib ou ao Mach Engine. Implementar regras de visibilidade: se a câmera recuar acima de um limiar, milhares de recursos individuais (ex: instâncias EC2 dentro de uma sub-rede) perdem a visibilidade, sendo representados como um único polígono agregado do módulo/sub-rede pai. As texturas e rótulos de texto HCL só são enviados para renderização nas escalas meso ou micro.
*   **Critério de Sucesso:**
    *   [ ] Renderização estável a **60+ FPS** consistentes. O processamento total por quadro (culling espacial + chamadas da API de desenho) deve permanecer estritamente abaixo do orçamento de **16.6ms**.
    *   [ ] Sem artefatos visuais ou saltos de posição dos nós quando os agrupamentos transicionam do estado macro (visão geral) para o micro (detalhes finos).

---

### 3. Estratégia de Simulação de Carga (Test Data)

Para evitar a necessidade de criar uma infraestrutura massiva de nuvem para a PoC e estourar os orçamentos do provedor, a entrada dos testes usará:
*   Um gerador em script para escrever um JSON formatado no padrão `.tfstate` contendo 50.000 componentes sintéticos (módulos, instâncias e vínculos de sub-redes).
*   Este arquivo de estado será consumido pelo módulo `c-shared` do Go, emulando o ambiente real que o Zig exigiria e preenchendo as arestas da R-Tree e da geometria simulando a complexidade de uma verdadeira nuvem corporativa de forma offline.