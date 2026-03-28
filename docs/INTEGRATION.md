# Integração técnica (fluxo de jogo)

Este documento descreve como as áreas **A**, **B** e **D** encaixam no que é “âncora” do projeto: `scripts/main.gd`, `scenes/main.tscn`, `scripts/systems/*` e `project.godot`.

## Responsabilidades (quem mexe no quê)

| Área | Foco sugerido | Evitar |
|------|----------------|--------|
| **A** | Menu, splash, `run/main_scene`, fluxo para entrar no jogo | Alterar `LoopSystem` / checklist sem alinhar |
| **B** | Salas (`scenes/rooms/*`), puzzles, `interactable_area`, conteúdo por nível | Renomear autoloads ou paths usados em código sem aviso |
| **D** | Textos de tarefas (`ChecklistSystem`), copy, labels de UI onde existirem | Lógica de tempo/reset (isso é `LoopSystem` + `DayNightSystem`) |

O ficheiro **este repositório trata como ponto de contacto** para o fluxo global: início de sessão de nível, falha/reset, vitória e transição opcional para menu ou próximo nível.

## Fluxo atual (Godot 4)

1. **Arranque**  
   `run/main_scene` = `res://scenes/bootstrap.tscn` → após `App.application_ready`, carrega `Game.first_play_scene` (por defeito `res://scenes/main.tscn`). Detalhes: [CORE_AND_BOOTSTRAP.md](CORE_AND_BOOTSTRAP.md).

2. **Início de nível**  
   Em `_ready()` de `main.gd`, chama-se `LoopSystem.start_level_session()` e `Game.notify_level_loaded()`, que:
   - repõe o temporizador global do nível;
   - chama `DayNightSystem.reset_run()` (noite + turnos).

3. **Falha (tempo esgotado)**  
   `LoopSystem` para timers, incrementa `current_loop`, limpa inventário e checklist, emite `level_failed` e faz **`reload_current_scene`** (reset completo da cena principal).

4. **Vitória**  
   Com checklist completa, a saída (`interactable_area` com `is_level_exit`) chama `LoopSystem.complete_level()`, que emite `level_completed`.  
   - `GameHUD` deixa de atualizar timers (estado “fim”).  
   - `main.gd` chama `Game.go_to_post_victory(post_victory_scene)`: path vazio → fase `LEVEL_WON` sem mudar de cena; com path → transição via `App`.

## Como **A** integra (menu e `main_scene`)

1. Manter **`run/main_scene`** = `res://scenes/bootstrap.tscn` (entrada única). Criar `res://scenes/menu.tscn` com botão “Jogar” que chama `App.go_to_scene("res://scenes/main.tscn")` (ou path acordado).

2. Definir **`Game.first_play_scene`** = `res://scenes/menu.tscn` no autoload **Game** (ou valor por defeito em `scripts/core/game.gd`), para o bootstrap mostrar primeiro o menu.

3. **Coordenação com quem mantém `project.godot`:**  
   - Evitar mudar `run/main_scene` sem aviso; o fluxo canónico é bootstrap → `first_play_scene`.  
   - **No mesmo dia em que outra pessoa também editar `project.godot`**, alinhar antes para reduzir merges difíceis.

4. **Vitória → menu:** no inspector do nó raiz **Main** em `main.tscn`, preencher **Post Victory Scene** com `res://scenes/menu.tscn` (ou equivalente).

5. **Commits:** alterações a **autoloads** em `project.godot` devem ir em **commits separados** dos restantes (regra de equipa).

## Como **B** integra (salas e puzzles)

- Instanciar salas como filhos de **Main** em `main.tscn` (ou via PackedScene único por nível, desde que a raiz continue a ser a cena acordada com A).
- Tarefas de nível: usar `completes_checklist_task` nos `Area2D` com script `interactable_area.gd`; IDs devem existir em `ChecklistSystem.level_1_tasks` (ou lista do nível atual).
- Saída do nível: `is_level_exit = true` na porta; `LoopSystem.is_exit_unlocked()` exige checklist completa.
- **Não** é necessário chamar `start_level_session()` nas salas — isso é responsabilidade de `main.gd`.

## Como **D** integra (conteúdo e tarefas)

- Labels das tarefas: método estático `ChecklistData.task_label()` em `scripts/systems/ChecklistSystem.gd` (ou lista por nível quando existir).
- Ordem e IDs das tarefas: propriedade exportada `level_1_tasks` (expandir para `level_2_tasks` etc. quando houver mais níveis — alinhar com B e com o fluxo em `main.gd`).

## Singletons úteis (autoloads)

| Nome global | Script | Notas |
|-------------|--------|--------|
| `LoopSystem` | `scripts/systems/LoopSystem.gd` | Tempo do nível, loops, falha, vitória, flags de sala |
| `ChecklistSystem` | `scripts/systems/ChecklistSystem.gd` | Tarefas e progresso |
| `DayNightSystem` | `scripts/systems/DayNightSystem.gd` | Dia/noite e turnos |
| `InventorySystem` | `scripts/systems/InventorySystem.gd` | Itens (limpos no reset e ao amanhecer) |
| `App` | `scripts/core/app.gd` | Arranque (`application_ready`) e mudança de cena penúltimo autoload |
| `Game` | `scripts/core/game.gd` | **Core de domínio:** `RunPhase`, `first_play_scene`, `go_to_post_victory`; **último** autoload |

Arquitetura detalhada (bootstrap, ordem, **como testar**): **[docs/CORE_AND_BOOTSTRAP.md](CORE_AND_BOOTSTRAP.md)**.

## Git: reduzir conflitos

- **Pull antes de editar** ficheiros partilhados.
- **Commits pequenos e com mensagem clara** (ex.: `feat(main): transição pós-vitória opcional` vs misturar com mudanças grandes em salas).
- **`project.godot`:** um propósito por commit quando possível; combinar com o grupo se várias pessoas o tocarem no mesmo dia.

---

*Última revisão alinhada com o fluxo em `main.gd` + `LoopSystem`.*
