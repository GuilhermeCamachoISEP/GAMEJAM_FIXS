extends Node
class_name InventoryData

## Itens da run atual (noite / vampiro). Limpos ao amanhecer e no reset do nível.
## O singleton em Autoload chama-se `InventorySystem` (instância desta classe).

signal inventory_changed(items: Array[String])

var _items: Array[String] = []


func get_items() -> Array[String]:
	return _items.duplicate()


func has_item(id: String) -> bool:
	return id in _items


func add_item(id: String) -> void:
	if id.is_empty() or id in _items:
		return
	_items.append(id)
	inventory_changed.emit(get_items())


func remove_item(id: String) -> void:
	var i := _items.find(id)
	if i >= 0:
		_items.remove_at(i)
		inventory_changed.emit(get_items())


func clear() -> void:
	if _items.is_empty():
		return
	_items.clear()
	inventory_changed.emit(get_items())
