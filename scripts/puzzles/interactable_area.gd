extends Area2D

@export var message_day: String = "Não vês nada de especial."
@export var message_night: String = "As sombras revelam algo."
@export var vampire_only: bool = false
@export var human_only: bool = false
## Se não estiver vazio, completa esta tarefa da checklist ao interagir com sucesso.
@export var completes_checklist_task: String = ""
## Porta de saída do nível: só avança com checklist completa (via LoopSystem).
@export var is_level_exit: bool = false

signal interacted(object_name: String)


func interact(is_night: bool) -> void:
	if is_level_exit:
		if LoopSystem.is_exit_unlocked():
			LoopSystem.complete_level()
		else:
			print("Ainda faltam tarefas da checklist.")
		interacted.emit(name)
		return

	if vampire_only and not is_night:
		print("És demasiado fraco para mover isto de dia.")
		return

	if human_only and is_night:
		print("As tuas garras não te permitem mexer nisto com precisão.")
		return

	if is_night:
		print("[Noite] ", message_night)
	else:
		print("[Dia] ", message_day)

	if not completes_checklist_task.is_empty():
		(get_node("/root/ChecklistSystem") as ChecklistData).complete_task(completes_checklist_task)

	interacted.emit(name)
