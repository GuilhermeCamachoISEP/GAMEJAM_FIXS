# GAMEJAM_FIXS
os brabos da gamejam 

# 🧛 Sins Of The Vamps  
## Guião Explicativo do Jogo

---

## 🎯 Octalysis

### Significado Épico
- 

### Desenvolvimento e Realização
- 

### Criatividade
- 

### Propriedade e Posse
- 

### Influência Social
- 

---

## 🛠️ Requisitos Técnicos
- 

---

## 🎮 Como vai ser o jogo

O jogo cumpre a temática **"Into The Loop"**.

A história resume-se a um indivíduo que foi mordido por um vampiro, tornando-se um.  
Este indivíduo fica preso numa mansão com vários níveis e precisa de passar por todos para escapar.

### 🌗 Mecânica principal

- 🌙 **De noite** → o jogador é um vampiro  
- ☀️ **De dia** → o jogador é humano  

➡️ De dia:
- Perde todas as memórias do vampiro  
- Perde todos os itens do vampiro  

---

## 👥 Multiplayer

O jogo será multiplayer:

- Jogador da **noite (vampiro)**
- Jogador do **dia (humano)**

👉 Ambos têm de cooperar:
- Um faz tarefas à noite  
- Outro completa tarefas durante o dia  

---

## 🏰 Estrutura do jogo

A mansão tem 4 níveis:
1 → 2 → 3 → 4


### 🔄 Loop de jogo

1. O jogador começa como vampiro  
2. Tem tempo limitado para fazer tarefas da noite  
3. Passa para dia  
4. O jogador humano usa o progresso da noite  
5. Tenta escapar do nível  

❗ Se 24h passarem:
- O nível reinicia  
- Cria-se um **loop**

---

## 🧩 Como vão ser os enigmas

### 1. Código que muda de sala

- Sala A:
  - Quadro com símbolos (ex: 🜂 🜄 🜃 🜁)

- Sala B:
  - Cofre com combinação  

❗ O código não está na mesma sala  

👉 O jogador tem de memorizar  

**Loop:**
- Run 1 → encontra pista  
- Run 2 → vai direto ao cofre  

---

### 2. Porta que só abre como vampiro

- Porta que só abre à noite  
- Atrás dela há algo necessário durante o dia  

👉 Cria conflito:
- Tens de planear o timing  

---

### 3. Espelhos e luz solar

- Sala com espelhos  
- Tens de refletir luz para abrir porta  

**Twist:**
- Como vampiro → não podes tocar na luz  

👉 Tens de preparar tudo à noite para funcionar de dia  

---

### 4. Puzzle parcialmente persistente

Mesmo com reset:

- Algumas coisas permanecem alteradas (subtilmente)

**Exemplos:**
- Livro muda de página a cada loop  
- Porta abre mais rápido a cada tentativa  

💡 Dá sensação de progressão sem quebrar o loop

---

## Integração técnica (equipa)

Fluxo de nível, reset, vitória e transições: ver **[docs/INTEGRATION.md](docs/INTEGRATION.md)** (papéis A/B/D e como encaixar sem conflitos em `project.godot`).

Núcleo `App`, autoloads e bootstrap opcional: **[docs/CORE_AND_BOOTSTRAP.md](docs/CORE_AND_BOOTSTRAP.md)**.
