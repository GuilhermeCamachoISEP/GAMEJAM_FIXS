extends Node2D
## Teste direto da Room4 - Sala dos Sons
## Arrastar esta cena para o editor e correr com F6 (Play Scene)

func _ready() -> void:
	## Inicializa sistemas necessários
	print("[Room4Test] Inicializando teste da Sala dos Sons...")

	## Garante que DayNightSystem começa na fase correta
	if DayNightSystem:
		DayNightSystem.reset_run()
		print("[Room4Test] DayNightSystem resetado - começa à noite (vampiro)")

	## Checklist só para as tarefas desta sala (fluxo principal usa `begin_room_requirements` em `main.gd`).
	if ChecklistSystem:
		var cl: ChecklistData = ChecklistSystem as ChecklistData
		if cl:
			cl.begin_room_requirements(cl.room4_tasks)
		print("[Room4Test] Checklist da Room4 ativa")

	print("[Room4Test] Teste pronto! Começa à NOITE (vampiro)")
	print("[Room4Test] Instruções:")
	print("  1. Vê os símbolos na parede esquerda")
	print("  2. Clica na máquina para GRAVAR a sequência")
	print("  3. Espera mudar para DIA (humano)")
	print("  4. Clica na máquina para ouvir a sequência")
	print("  5. Clica nos sinos na ordem certa")
	print("  6. ⚠️ NOTA: Os sons da máquina são ligeiramente diferentes!")
