class_name ObjectPool
extends RefCounted

var _scene: PackedScene
var _parent: Node
var _free: Array[Node] = []


func _init(scene: PackedScene, parent: Node, prewarm: int = 10) -> void:
	_scene = scene
	_parent = parent
	for _i: int in prewarm:
		var node: Node = _scene.instantiate()
		_parent.add_child(node)
		if node.has_method("reset"):
			node.call("reset")
		_free.append(node)


func acquire() -> Node:
	var node: Node
	if _free.is_empty():
		node = _scene.instantiate()
		_parent.add_child(node)
	else:
		node = _free.pop_back()
	return node


func release(node: Node) -> void:
	if node.has_method("reset"):
		node.call("reset")
	if node not in _free:
		_free.append(node)
