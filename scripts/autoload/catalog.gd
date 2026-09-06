extends Node

const DIR: String = "res://data/characters"
const FALLBACK_ID: StringName = &"oc_a"
const KNOWN: Array[StringName] = [&"oc_a", &"oc_b", &"oc_c"]

var _cache: Dictionary = {}


func _ready() -> void:
	_scan_ids()


func _scan_ids() -> void:
	var da: DirAccess = DirAccess.open(DIR)
	if da == null:
		return
	da.list_dir_begin()
	var name: String = da.get_next()
	while name != "":
		if not da.current_is_dir() and name.ends_with(".tres") and not name.ends_with("_frames.tres"):
			var id: StringName = StringName(name.trim_suffix(".tres"))
			if not _cache.has(id):
				_cache[id] = null
		name = da.get_next()
	da.list_dir_end()
	for id: StringName in KNOWN:
		if not _cache.has(id):
			_cache[id] = null
	if not _cache.has(FALLBACK_ID):
		_cache[FALLBACK_ID] = null


func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for k: Variant in _cache.keys():
		ids.append(k as StringName)
	ids.sort_custom(func (a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func get_def(id: StringName) -> CharacterDef:
	if id == StringName():
		id = FALLBACK_ID
	if _cache.has(id) and _cache[id] is CharacterDef:
		return _cache[id] as CharacterDef
	var path: String = "%s/%s.tres" % [DIR, String(id)]
	if not ResourceLoader.exists(path):
		if id != FALLBACK_ID:
			return get_def(FALLBACK_ID)
		return null
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	var def: CharacterDef = loaded as CharacterDef
	if def == null:
		return null
	_cache[id] = def
	return def


func equipped_def() -> CharacterDef:
	return get_def(Save.equipped)


func is_loaded_id(id: StringName) -> bool:
	return _cache.has(id)
