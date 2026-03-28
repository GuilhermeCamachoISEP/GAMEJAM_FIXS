# API do núcleo — para menu, pausa, áudio, ecrã

Este ficheiro define **contratos** entre o núcleo (`App`, `Game`, `Settings`, `GamePaths`, `AudioBuses`) e o resto da equipa. **Não** substitui o vosso menu, mix de som, puzzles nem salas: apenas evita que cada um mexa no `project.godot` ou em `get_tree().paused` de forma diferente.

## Ordem dos autoloads (referência)

`InventorySystem` → `ChecklistSystem` → `DayNightSystem` → `LoopSystem` → **`App`** → **`Game`** → **`Settings`**

## Pausa

- **Fonte de verdade:** `SceneTree.paused` (definido só via API abaixo).
- **Ativar / desativar pausa global:**
  - `Game.set_game_paused(true | false)`
  - `Game.toggle_game_paused()` — devolve o novo estado.
  - `Game.is_game_paused()` — leitura.
  - Sinal: `Game.game_pause_changed(is_paused)`
- **Menu de pausa / opções (CanvasLayer):** o nó raiz do overlay deve ter **`process_mode = Always`** para continuar a receber input e animações com o jogo pausado.
- **Input:** há uma ação `pause_game` (Esc) no `project.godot` — o menu pode usar `Input.is_action_just_pressed("pause_game")` para abrir/fechar.
- **Troca de cena:** `App.go_to_scene` força **`paused = false`** antes de mudar a cena (evita ecrã preto/bloqueado).

Recomendação para **player** e systems sensíveis: no início de `_physics_process`, se quiseres proteger contra edge cases:

`if get_tree().paused: return`  
(normally redundante se o `CharacterBody2D` já respeitar a pausa da árvore).

## Áudio

- Constantes de nomes de bus: `AudioBuses.MASTER`, `AudioBuses.MUSIC`, `AudioBuses.SFX`.
- Ajustar volume **linear** 0..1: `AudioBuses.set_linear_music(0.75)` (etc.).
- No editor: **Project → Audio → Buses** — criar buses **`Music`** e **`SFX`** sob `Master` se ainda não existirem; caso contrário os setters ignoram silenciosamente (sem crash).
- **Menu / sliders:** ligar aos métodos de `Settings` (persistem em `user://settings.cfg`).

## Definições persistentes (`Settings`)

Autoload **`Settings`**:

| Método | Uso |
|--------|-----|
| `set_master_volume_linear(v, persist=true)` | Master + guardar |
| `set_music_volume_linear(v)` / `set_sfx_volume_linear(v)` | Idem |
| `set_fullscreen(enabled)` | Ecrã inteiro |
| `set_vsync(enabled)` | Vsync on/off |
| `load_and_apply()` | Recarregar ficheiro (raro) |
| `save_all()` | Gravar estado actual de buses + janela |

Sinais: `master_volume_changed`, `settings_saved`, etc. — útil para UI.

## Caminhos de cenas

Classe **`GamePaths`**: `BOOTSTRAP`, `INTRO_VAMPIRE_BITE`, `MAIN_LEVEL` — usar no código em vez de strings duplicadas.

A **`Game.first_play_scene`** continua a ser o ponto de entrada pós-bootstrap (intro vs menu, quando o menu existir).

## Grupos

- O nó raiz **`Main`** regista-se no grupo **`gameplay`** — útil para `call_group` ou lógica que só afecta o mundo (ex.: esconder HUD do mundo quando o menu de pausa abre).

## Ecrã

- **Stretch:** `canvas_items` + aspect `expand` no `project.godot` — escalonamento coerente de 2D/UI.
- Resolução base **1280×720**; UI com anchors/margins para diferentes rácios.
- Fullscreen/vsync via `Settings` acima.

## Cutscenes e TTS (narração)

- Cutscenes usam **`CutsceneVoice`**: `DisplayServer.tts_speak` com voz **portuguesa** quando o sistema expõe uma (`language` começa por `pt` ou contém `por`).
- **Windows:** costuma haver vozes PT‑PT / PT‑BR nas definições de *Text-to-speech*; sem voz PT, cai na primeira voz disponível.
- **Linux / Web / consolas:** TTS pode estar indisponível — as legendas mantêm-se; só o áudio sintético falha em silêncio.
- **Saltar** numa cutscene chama `CutsceneVoice.stop()` para calar a locução.

## O que ficou **de fora** (outros owners)

- Arte e layout do **menu**, **pause overlay**, **créditos**.
- **Player** (movimento, animação), **salas**, **enigmas**, **mix** criativo de som.
- **Trilha** e **SFX** nos buses — só os nomes e a API de volume estão alinhados aqui.

---

*Alinhado com `INTEGRATION.md` e `CORE_AND_BOOTSTRAP.md`.*
