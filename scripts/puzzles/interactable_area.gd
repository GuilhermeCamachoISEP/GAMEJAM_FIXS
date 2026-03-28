extends Area2D

@export var message_day: String = "Não vês nada de especial."
@export var message_night: String = "As sombras revelam algo."
@export var vampire_only: bool = false
@export var human_only: bool = false

# Este sinal vai avisar a sala principal qual o objeto que foi clicado
signal interacted(object_name: String)

# Agora recebe o estado (dia/noite) do jogador
func interact(is_night: bool) -> void:
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
		
	# Avisa o resto do jogo que este objeto (ex: "Quadro") foi ativado
	interacted.emit(name)
