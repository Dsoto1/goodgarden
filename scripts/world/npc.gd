class_name NPC
extends Node3D
## A named character the child can talk to. Dialogue content comes from data
## (content/dialogue/<dialogue_id>.json); where the NPC stands each day comes
## from the day definition's "npcs" anchors.

var npc_id: String
var dialogue_id: String
var model: CharacterModel
var talk: Interactable
var _face_target: Variant = null


static func create(id: String, look: Dictionary, dialogue: String) -> NPC:
	var npc := NPC.new()
	npc.name = id.capitalize()
	npc.npc_id = id
	npc.add_to_group("npc_%s" % id)
	npc.dialogue_id = dialogue
	npc.model = CharacterModel.new().build(look)
	npc.add_child(npc.model)
	MeshKit.solid(npc, Vector3(0.6, 1.6, 0.6), Vector3(0, 0.8, 0), 0.0, MeshKit.LAYER_CHARACTER)
	npc.talk = Interactable.create(npc, Vector3.ZERO, "Talk to %s" % Dialogue.character_name(id), npc._on_talk, 0.7, 1.95 * float(look.get("height", 1.0)))
	npc.talk.reach = 2.2
	return npc


func _ready() -> void:
	Dialogue.conversation_ended.connect(func(_id: String) -> void:
		_face_target = null
		model.set_expression("smile"))
	Dialogue.line_shown.connect(func(line: Dictionary) -> void:
		if Dialogue.active_id == dialogue_id and line.get("speaker", "") == npc_id:
			model.set_expression(str(line.get("mood", "smile"))))


func _on_talk() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		_face_target = player.global_position
	Dialogue.start(dialogue_id)


func _process(delta: float) -> void:
	var talking: bool = Dialogue.active_id == dialogue_id
	var player := get_tree().get_first_node_in_group("player") as Node3D
	# Look at the child when they come near, as a friendly neighbour would.
	var near := player != null and player.global_position.distance_to(global_position) < 4.5
	model.look_at_point(player.global_position + Vector3(0, 1.0, 0) if near else null)
	if near and _face_target == null:
		var to := player.global_position - global_position
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(delta * 2.0, 1.0))
	model.set_talking(1.0 if talking else 0.0)
	model.gesture(0.5 + 0.5 * sin(Time.get_ticks_msec() / 900.0) if talking else 0.0)
	model.animate(delta, 0.0, Settings.get_value("reduced_motion"))
	if _face_target != null:
		var to: Vector3 = _face_target - global_position
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(delta * 6.0, 1.0))
