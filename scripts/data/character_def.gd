class_name CharacterDef
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var skill_blurb: String = ""
@export var unlocked_default: bool = false
@export var currency: StringName = &"coin"
@export var price: int = 0
@export var iap_sku: String = ""
@export var max_jumps: int = 2
@export var can_glide: bool = false
@export var glide_gravity_scale: float = 0.35
@export var start_sprint_sec: float = 0.0
@export var hitbox_run: Vector2 = Vector2(42, 86)
@export var hitbox_slide: Vector2 = Vector2(56, 46)
@export var sprite_frames: SpriteFrames
@export var shop_portrait: Texture2D
@export var sprite_offset: Vector2 = Vector2(4, -248)
@export var sprite_scale: Vector2 = Vector2(0.22, 0.22)
