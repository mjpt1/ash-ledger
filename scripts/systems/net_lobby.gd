extends Node

## Online co-op lobby: host authority for waves, peers sync player state.

signal lobby_changed
signal net_message(text: String)
signal start_coop_run

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var is_online: bool = false
var is_host: bool = false
var peer_names: Dictionary = {} # peer_id -> display name
var my_name: String = "مسافر"
var last_error: String = ""

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func reset_offline() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_online = false
	is_host = false
	peer_names.clear()
	last_error = ""
	lobby_changed.emit()

func host_game(port: int = DEFAULT_PORT, display_name: String = "میزبان") -> bool:
	reset_offline()
	my_name = display_name
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		last_error = Locale.t("connection_failed")
		net_message.emit(last_error)
		return false
	multiplayer.multiplayer_peer = peer
	is_online = true
	is_host = true
	peer_names[1] = my_name
	net_message.emit(Locale.t("connected"))
	lobby_changed.emit()
	return true

func join_game(address: String, port: int = DEFAULT_PORT, display_name: String = "مهمان") -> bool:
	reset_offline()
	my_name = display_name
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), port)
	if err != OK:
		last_error = Locale.t("connection_failed")
		net_message.emit(last_error)
		return false
	multiplayer.multiplayer_peer = peer
	is_online = true
	is_host = false
	net_message.emit("…")
	lobby_changed.emit()
	return true

func player_count() -> int:
	if not is_online:
		return 1
	return peer_names.size()

func get_roster() -> Array:
	var list: Array = []
	var ids: Array = peer_names.keys()
	ids.sort()
	for id in ids:
		list.append({"id": id, "name": peer_names[id]})
	return list

func request_start_run() -> void:
	if not is_online:
		start_coop_run.emit()
		return
	if is_host:
		_rpc_start_run.rpc()
	else:
		net_message.emit(Locale.t("waiting_host"))

@rpc("authority", "call_local", "reliable")
func _rpc_start_run() -> void:
	start_coop_run.emit()

func _on_peer_connected(id: int) -> void:
	if is_host:
		_rpc_sync_roster.rpc(peer_names)
		_rpc_request_name.rpc_id(id)

func _on_peer_disconnected(id: int) -> void:
	peer_names.erase(id)
	lobby_changed.emit()

func _on_connected() -> void:
	_rpc_register_name.rpc_id(1, my_name)
	net_message.emit(Locale.t("connected"))
	lobby_changed.emit()

func _on_connection_failed() -> void:
	last_error = Locale.t("connection_failed")
	net_message.emit(last_error)
	reset_offline()

func _on_server_disconnected() -> void:
	net_message.emit(Locale.t("connection_failed"))
	reset_offline()

@rpc("any_peer", "reliable")
func _rpc_register_name(display_name: String) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	peer_names[id] = display_name
	_rpc_sync_roster.rpc(peer_names)
	lobby_changed.emit()

@rpc("authority", "reliable")
func _rpc_request_name() -> void:
	_rpc_register_name.rpc_id(1, my_name)

@rpc("authority", "call_local", "reliable")
func _rpc_sync_roster(roster: Dictionary) -> void:
	peer_names = roster.duplicate()
	lobby_changed.emit()
