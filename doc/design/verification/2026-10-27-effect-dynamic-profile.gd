extends SceneTree
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var state: Variant = load("res://scripts/battle/battle_state.gd").new()
 state.reset("bas", true)
 state.bots_enabled = false
 var view: MeshInstance3D = load("res://scripts/presentation/effects_view.gd").new()
 root.add_child(view)
 await process_frame
 var hero: Dictionary = state.units[state.controlled_id]
 for unit: Dictionary in state.units.values():
  if unit.team == 0:
   unit.alive = unit.id == hero.id
 hero.pos = Vector2(-10,0)
 state.effects = [{"shape":"cone", "origin":Vector2(3,0),"target":Vector2(-3,0),"radius":6.0,"angle":70.0,"team":1,"telegraph":true,"duration":0.6,"remaining":0.3}]
 var cold: int = Time.get_ticks_usec()
 view.redraw(state,{},-1,null)
 print("COLD PARTIAL CONE us=", Time.get_ticks_usec()-cold)
 var started: int = Time.get_ticks_usec()
 for index: int in range(12):
  hero.pos.x += 0.03
  view.redraw(state,{},-1,null)
 print("MOVING SOURCE PARTIAL CONE mean_us=",(Time.get_ticks_usec()-started)/12.0)
 state.effects = [{"shape":"circle","origin":Vector2(-10,0),"radius":2.2,"team":1,"telegraph":true,"duration":0.2,"remaining":0.1}]
 view.redraw(state,{},-1,null)
 started=Time.get_ticks_usec()
 for index: int in range(12):
  state.effects[0].remaining -= 0.005
  view.redraw(state,{},-1,null)
 print("VISIBLE CIRCLE WITH TIMER mean_us=",(Time.get_ticks_usec()-started)/12.0)
 view.queue_free()
 await process_frame
 quit(0)
