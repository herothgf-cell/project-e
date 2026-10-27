extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var state: Variant = load("res://scripts/battle/battle_state.gd").new()
 state.reset()
 state._spawn_wave()
 state._spawn_wave()
 var index: int = 0
 for unit: Dictionary in state.units.values():
  if unit.kind == "minion":
   unit.pos = state.map.lane_point(unit.lane, 10 + (index % 8) * 8, unit.team)
   index += 1
 var view: Variant = load("res://scripts/presentation/team_vision_view.gd").new()
 root.add_child(view)
 view.configure(state)
 var samples: Array = []
 for i: int in range(12):
  view._sampled_sources.clear()
  view.update_view(null, 0, 1, false)
  samples.append(view.last_refresh_usec)
 samples.sort()
 print("VISION PROFILE: ", state.units.size(), " units / ", view.source_ids().size(), " allied sources, 124x80 / 1m, median ", samples[6], "us, max ", samples.back(), "us")
 var count: int = view.refresh_count
 for i: int in range(60):
  view.update_view(null,0,1.0/60,false)
 print("STATIC PROFILE: ", view.refresh_count-count, " raster refreshes in 60 presentation updates")
 view.queue_free()
 await process_frame
 quit()
