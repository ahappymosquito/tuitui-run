extends Node

signal remote_updated(rows: Array)
signal save_changed

const BOARD_PATH: String = "user://leaderboard.json"
const SAVE_PATH: String = "user://save.json"
const MAX_ROWS: int = 20
const REMOTE: String = "http://qrqto.club:8091"
const WIPE_MARK: String = "user://board_wipe_141"
const START_COINS: int = 800

var remote_top: Array = []
var _http_post: HTTPRequest
var _http_get: HTTPRequest

var v: int = 1
var player_id: String = ""
var nickname: String = ""
var coins: int = START_COINS
var owned: PackedStringArray = PackedStringArray(["oc_a"])
var equipped: String = "oc_a"
var best_score_local: int = 0
var best_distance: int = 0
var iap_owned: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_http_post = HTTPRequest.new()
	_http_get = HTTPRequest.new()
	add_child(_http_post)
	add_child(_http_get)
	_http_get.request_completed.connect(_on_get)
	if not FileAccess.file_exists(WIPE_MARK):
		clear_local()
		var f: FileAccess = FileAccess.open(WIPE_MARK, FileAccess.WRITE)
		if f != null:
			f.store_string("1")
	_load_save()


func _default_owned() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for id: StringName in Catalog.all_ids():
		var def: CharacterDef = Catalog.get_def(id)
		if def != null and def.unlocked_default:
			ids.append(String(id))
	if ids.is_empty():
		ids.append("oc_a")
	return ids


func _load_save() -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(SAVE_PATH):
		var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f != null:
			var raw: String = f.get_as_text().strip_edges()
			if raw != "":
				var parsed: Variant = JSON.parse_string(raw)
				if parsed is Dictionary:
					data = parsed
	if data.is_empty() and FileAccess.file_exists("user://economy.cfg"):
		var cf: ConfigFile = ConfigFile.new()
		if cf.load("user://economy.cfg") == OK:
			coins = int(cf.get_value("wallet", "coins", START_COINS))
	v = int(data.get("v", 1))
	player_id = str(data.get("player_id", ""))
	nickname = str(data.get("nickname", ""))
	if data.has("coins"):
		coins = int(data.get("coins", START_COINS))
	best_score_local = int(data.get("best_score", 0))
	best_distance = int(data.get("best_distance", 0))
	owned = _to_packed(data.get("owned", ["oc_a"]))
	equipped = str(data.get("equipped", "oc_a"))
	iap_owned = _to_packed(data.get("iap_owned", []))
	call_deferred("_sanitize_after_catalog")


func _sanitize_after_catalog() -> void:
	if owned.is_empty():
		owned = _default_owned()
	for id: String in _default_owned():
		if not is_owned(id):
			owned.append(id)
	for sku_id: String in iap_owned:
		if not is_owned(sku_id):
			owned.append(sku_id)
	if not is_owned(equipped):
		equipped = "oc_a"
	persist()


func _to_packed(value: Variant) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if value is Array:
		for item: Variant in value:
			out.append(str(item))
	elif value is PackedStringArray:
		return value
	return out


func persist() -> void:
	var data: Dictionary = {
		"v": v,
		"player_id": player_id if player_id != "" else Settings.player_id,
		"nickname": nickname if nickname != "" else Settings.nickname,
		"coins": coins,
		"owned": Array(owned),
		"equipped": equipped,
		"best_score": best_score_local,
		"best_distance": best_distance,
		"iap_owned": Array(iap_owned),
	}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
	save_changed.emit()


func is_owned(id: String) -> bool:
	return owned.has(id)


func buy_with_coins(id: String) -> bool:
	if is_owned(id):
		return false
	var def: CharacterDef = Catalog.get_def(StringName(id))
	if def == null:
		return false
	if def.currency != &"coin":
		return false
	if coins < def.price:
		return false
	coins -= def.price
	owned.append(id)
	persist()
	return true


func equip(id: String) -> bool:
	if not is_owned(id):
		return false
	equipped = id
	persist()
	return true


func grant_iap(id: String) -> bool:
	var def: CharacterDef = Catalog.get_def(StringName(id))
	if def == null:
		return false
	if def.currency != &"iap" and def.iap_sku == "":
		return false
	if not iap_owned.has(id):
		iap_owned.append(id)
	if not is_owned(id):
		owned.append(id)
	persist()
	return true


func add_coins(amount: int) -> void:
	coins += amount
	persist()


func reload_from_disk() -> void:
	_load_save()


func wipe_progress() -> void:
	var keep_iap: PackedStringArray = iap_owned.duplicate()
	coins = START_COINS
	owned = _default_owned()
	for id: String in keep_iap:
		if not is_owned(id):
			owned.append(id)
	iap_owned = keep_iap
	equipped = "oc_a"
	best_score_local = 0
	best_distance = 0
	persist()


func load_board() -> Array:
	if not FileAccess.file_exists(BOARD_PATH):
		return []
	var f: FileAccess = FileAccess.open(BOARD_PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		return parsed
	return []


func add_run(p_player_id: String, p_nickname: String, score: int, distance: int, p_coins: int) -> bool:
	var rows: Array = load_board()
	var prev_best: int = 0
	for old: Variant in rows:
		if str(old.get("player_id", "")) == p_player_id:
			prev_best = maxi(prev_best, int(old.get("score", 0)))
	var now: String = Time.get_datetime_string_from_system(false, true)
	var row: Dictionary = {
		"player_id": p_player_id,
		"name": p_nickname,
		"score": score,
		"distance": distance,
		"coins": p_coins,
		"date": now,
	}
	rows.append(row)
	rows.sort_custom(func (a: Variant, b: Variant) -> bool: return int(a["score"]) > int(b["score"]))
	if rows.size() > MAX_ROWS:
		rows = rows.slice(0, MAX_ROWS)
	var f: FileAccess = FileAccess.open(BOARD_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(rows))
	_post_remote(row)
	if score > best_score_local:
		best_score_local = score
	if distance > best_distance:
		best_distance = distance
	persist()
	return score > prev_best


func best_score() -> int:
	var rows: Array = load_board()
	var best: int = best_score_local
	if not rows.is_empty():
		best = maxi(best, int(rows[0]["score"]))
	return best


func best_for(p_player_id: String) -> int:
	var best: int = 0
	for row: Variant in load_board():
		if str(row.get("player_id", "")) != p_player_id:
			continue
		best = maxi(best, int(row.get("score", 0)))
	return best


func clear_local() -> void:
	var f: FileAccess = FileAccess.open(BOARD_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string("[]")


func _post_remote(row: Dictionary) -> void:
	var body: String = JSON.stringify(row)
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
	_http_post.request(REMOTE + "/v1/scores", headers, HTTPClient.METHOD_POST, body)


func fetch_top() -> void:
	_http_get.request(REMOTE + "/v1/scores/top?limit=20")


func _on_get(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary and (parsed as Dictionary).has("rows"):
		parsed = (parsed as Dictionary)["rows"]
	if parsed is Array:
		remote_top = parsed
		remote_updated.emit(remote_top)
