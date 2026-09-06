extends Node

const PRICE_SHIELD: int = 800
const PRICE_MAGNET: int = 400

var equipped: String = ""
var last_run_score: int = 0
var last_run_coins: int = 0
var last_run_distance: int = 0
var last_was_best: bool = false

var coins: int:
	get:
		return Save.coins
	set(value):
		Save.coins = value
		Save.persist()


func price_of(item: String) -> int:
	match item:
		"shield":
			return PRICE_SHIELD
		"magnet":
			return PRICE_MAGNET
		_:
			return 0


func try_equip(item: String) -> bool:
	if item == "":
		equipped = ""
		return true
	var price: int = price_of(item)
	if Save.coins < price:
		return false
	Save.add_coins(-price)
	equipped = item
	return true


func grant(amount: int) -> void:
	Save.add_coins(amount)
