class_name GroundScroll
extends Sprite2D

var speed: float = 0.0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	region_enabled = true
	centered = false


func _physics_process(delta: float) -> void:
	if speed == 0.0:
		return
	var rect: Rect2 = region_rect
	rect.position.x += speed * delta
	region_rect = rect
