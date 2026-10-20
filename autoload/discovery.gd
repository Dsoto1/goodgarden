extends Node
## Map/DiscoveryService: which places the child has physically walked to.
## The illustrated map offers travel only to discovered places.

signal discovered(region_id: String)

## How many places must be found before the map is offered at all.
const MAP_UNLOCK_COUNT := 3

var _discovered: Dictionary = {} # region id -> day first visited


func discover(region_id: String) -> void:
	if _discovered.has(region_id):
		return
	_discovered[region_id] = Days.current_day
	Observations.record("place_discovered", "", {"region": region_id})
	discovered.emit(region_id)


func is_discovered(region_id: String) -> bool:
	return _discovered.has(region_id)


func discovered_ids() -> Array:
	return _discovered.keys()


func map_unlocked() -> bool:
	return _discovered.size() >= MAP_UNLOCK_COUNT


func reset() -> void:
	_discovered.clear()


func to_save() -> Dictionary:
	return _discovered.duplicate()


func from_save(data: Dictionary) -> void:
	_discovered.clear()
	for k: String in data:
		_discovered[k] = int(data[k])
