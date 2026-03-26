Para construir a Interface de Usuário com Zoom (ZUI) de alto desempenho focada em Infraestrutura como Código (IaC), o desenvolvimento deve ser focado na mitigação de gargalos de gerenciamento de memória e na otimização da localidade de cache da CPU. Abaixo apresento o plano de execução iterativo dividido em Sprints, detalhando a integração da ponte C-ABI e testes de estruturas de dados.

### Sprint 1: Fundação de Memória, Go Bridge e Teste do `MultiArrayList`

O primeiro Sprint isola o maior risco de interoperabilidade da aplicação: extrair dados do HashiCorp Configuration Language (HCL) de forma rápida e populá-los em um layout amigável ao cache da CPU no motor Zig, contornando a latência de I/O do JSON e as interrupções do Garbage Collector (GC).

**Objetivos Técnicos:**
*   Implementar a biblioteca Go compartilhada (C-Shared Library) exportando os símbolos necessários para consumir estados do Terraform.
*   Implementar a inversão de propriedade de memória respeitando as rigorosas regras de ponteiros do `cgo`.
*   **Ação Crítica (Validação do Usuário):** Provar a eficiência do Design Orientado a Dados (DoD) testando a alocação dos recursos parseados dentro do `MultiArrayList` nativo do Zig.

**Plano de Execução e Teste do `MultiArrayList`:**
1.  **Definição do Contrato C-ABI:** Criar a assinatura da função exportada em Go (ex: `//export ParseHCL`) que aceita um ponteiro bruto (Ponteiro C) pré-alocado pelo Zig. 
2.  **Configuração da Arena no Zig:** No lado do motor ZUI, instanciar um `std.heap.ArenaAllocator`. A principal vantagem desta abordagem é a capacidade de alocar gigabytes de dados estruturais da árvore do Terraform e liberar toda a memória de uma única vez em uma operação $O(1)$ (chamando `arena.deinit()`), sem causar fragmentação de heap.
3.  **Achatamento (Flattening) Seguro em Go:** O código Go deve fazer o parse do HCL em uma AST, mas, de acordo com as regras do `cgo`, o Go não pode armazenar ponteiros Go em memória C (Zig), e a memória passada ao C não pode conter outros ponteiros Go rastreados pelo GC. A biblioteca Go deve serializar e "achatar" as propriedades críticas (ID, Tipo, Posição X/Y geométrica) em tipos primitivos para transferi-las diretamente ao buffer bruto do Zig.
4.  **Teste de Desempenho SoA (Structure of Arrays):**
    *   No Zig, em vez de instanciar nós de UI como um *Array of Structures* (AoS) (onde cada nó sobrecarrega a linha de 64 bytes de cache com metadados durante cálculos espaciais), mapearemos os dados recebidos para um `MultiArrayList`.
    *   O `MultiArrayList` automaticamente divide os campos da estrutura em arrays paralelos e contíguos na memória (ex: um array maciço só de coordenadas `X`, outro de coordenadas `Y`).
    *   **Métrica de Validação:** Executar um loop de varredura (simulando um frustum culling ignorante) sobre 50.000 instâncias. O teste passa se iterações consumindo apenas as matrizes puramente geométricas (Structure of Arrays) comprovarem redução drástica de *L1 Cache Misses* em relação à travessia de nós opacos tradicionais (Array of Structures), confirmando que a CPU está mantendo as esteiras vetoriais (SIMD) alimentadas eficientemente.

### Sprint 2: Particionamento Espacial Baseado em R-Tree e Culling

Com a memória corretamente formatada (SoA), o próximo passo é estruturar o grafo do Terraform espacialmente, assegurando que componentes invisíveis não enviem chamadas de desenho à GPU.

**Objetivos Técnicos:**
*   Substituir a iteração linear das geometrias por um índice espacial altamente eficiente.
*   Implementar o descarte frustum (View-Frustum Culling) garantindo 60+ FPS em panning/zooming.

**Plano de Execução:**
1.  **Adoção da R-Tree vs Quadtree:** Embora Quadtrees recursivas sejam comumente usadas em motores de jogos para dados baseados em pontos (com custo de inserção de $O(\log n)$), redes em nuvem são melhor representadas como polígonos sobrepostos (ex: grandes VPCs encapsulando múltiplas sub-redes e instâncias). Para consultas visuais focadas em retângulos delimitadores aninhados (window queries), as R-Trees superam as Quadtrees em 2 a 3 vezes em eficiência contínua.
2.  **Integração DOD na Árvore:** Construir a R-Tree de forma que seus nós folha atuem apenas como índices apontando para a base de memória orientada a dados (`MultiArrayList`) do Sprint 1, evitando o antipadrão arquitetural de embutir listas completas de contêineres e metadados gerenciados individualmente dentro de cada nó da árvore.

### Sprint 3: Nível de Detalhe Semântico (Semantic LoD) e Rendering

Neste Sprint, o foco passa para a interface humana e manipulação do Canvas infinito usando o pipeline gráfico (ex: Mach Engine ou Raylib utilizando chamadas nativas compatíveis com a ABI em C do Zig).

**Objetivos Técnicos:**
*   Implementar o Nível de Detalhe (LoD) para suprimir poluição visual em redes massivas de instâncias de nuvem.

**Plano de Execução:**
1.  **Semantic Zooming:** Diferente do zoom geométrico tradicional, o *Semantic Zoom* muda qualitativamente a apresentação visual baseada na escala do observador (ex: mostrando apenas limites retangulares genéricos de um módulo Terraform de longe, e renderizando textos HCL ou rótulos finos quando a câmera se aproxima).
2.  **Clustering Aglomerativo:** Quando a câmera afasta-se para uma escala macro, o motor deve utilizar agrupamentos que fundem centenas de nós Terraform em um único polígono agregado. Isto reduz drasticamente o número de chamadas de desenho (*draw calls*). A persistência semântica garantirá que nós não desapareçam erraticamente e que haja estabilidade geométrica durante a transição da câmera para preservar a referência espacial do usuário.

### Sprint 4: Afinação do GC do Go e Integração Assíncrona

A etapa final concentra-se em mitigar anomalias durante recargas de estado em tempo real e orquestrar as threads.

**Objetivos Técnicos:**
*   Suprimir o ruído imposto pela thread em background do Go quando grandes arquivos Terraform (`.tfstate`) são manipulados ou relidos.

**Plano de Execução:**
1.  **Controle Agressivo do GOMEMLIMIT e GOGC:** Tirar proveito dos controles do tempo de execução de Go. Definir a variável `GOMEMLIMIT` para um teto rígido e alterar `GOGC=off` para o componente Bridge. Isso faz com que a biblioteca parseadora do HashiCorp em Go não atrase a thread de resposta do Zig com interrupções contínuas (*background marking*), preenchendo as memórias alocadas e engatilhando uma coleta limpa apenas quando absolutamente necessário ou após a transferência segura via `cgo` ser finalizada.
2.  **Cleanups em Massa:** Fazer com que atualizações visuais destrutivas (como o usuário abrindo outro projeto inteiro do Terraform) engatilhem a redefinição puramente linear no Zig pela chamada à Arena. Como apontado na arquitetura, destruir 50.000 objetos individualmente causa pausas severas; simplesmente abandonar o ponteiro da raiz da Arena evita vazamentos e recicla todo o canvas ZUI sem custos residuais.