extends Spatial

func cutscene():
    $CutsceneCamera2.current = true
    
    var player = Manager.find_player()
    player.start_cutscene()
    player.look_towards($Prop10)
    
    if Manager.fading:
        yield(Manager, "fade_completed")
        
    Manager.fade_time_factor = 0.25
    
    Manager.push_input_mode("cutscene")
    
    Manager.show_text(player, "Where am I? What's going on?", "Alice")
    yield(Manager, "cutscene_continue")
    
    player.look_towards($alicehouse)
    
    Manager.show_text(player, "That's my house. But this isn't the forest of magic.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "No, this is... I'm in my old clothes and everything.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "This must a dream.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "If I'm dreaming this vivid, I really must've overdone it working on Goliath.", "Alice")
    yield(Manager, "cutscene_continue")
    
    player.look_towards($BakeBake4)
    
    Manager.show_text(player, "Is that a bakebake? I haven't seen one of those since I lived in Makai.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "Well, you never know what a strange dream will show you.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    Manager.wipe_fade_out()
    yield(Manager, "fade_completed")
    
    player.get_camera().current = true
    Manager.wipe_fade_in()
    yield(Manager, "fade_completed")
    
    Manager.show_text(Vector2(), "[color=#8FF]This is a twin stick shooter.\nYou can play with just the keyboard, but keyboard + mouse or gamepad is recommended.[/color]", "", false)
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(Vector2(),
"""[color=#8FF]Control schemes:
    
- Arrows + shift (focus) + z/x/c (jump, shoot, swipe)

- Gamepad (right bumper to shoot, left bumper to focus, face buttons to jump/swipe, dpad/sticks to move/aim)

- WASD + mouse (mouse to aim, mouse1 to shoot, mouse2 to swipe, space to jump)[/color]""", "", false)
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(Vector2(), "[color=#8FF]Every control scheme is active at once. There is no need to configure anything.[/color]", "", false)
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(Vector2(), "[color=#8FF]Focusing keeps your aim direction from changing automatically. Also, swipes can destroy hostile bullets.[/color]", "", false)
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "Might as well run around and kill these things till I wake up.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "Also, these mushrooms look springy. I should try bouncing off of them. While they're still jiggling.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    
    Manager.fade_time_factor = 1.0
    yield(get_tree(), "idle_frame")
    Manager.pop_input_mode("cutscene")

var touched = {}
var to_resurface = []

func _ready():
    if false:
        for child in get_children():
            if child is GeometryInstance:
                var _inst : GeometryInstance = child
                pass
            if child is Spatial:
                #if child.name.begins_with("flowers") or child.name.begins_with("fern") or child.name.begins_with("grass") or child.name.begins_with("rock"):
                #    continue
                for child2 in child.get_children():
                    if child2 is MeshInstance:
                        var mesh : Mesh = child2.mesh
                        to_resurface.push_back(mesh)
    
    
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    Manager.play_bgm(Manager.main_bgm)
    cutscene()

func next_cutscene():
    Manager.push_input_mode("cutscene")
    Manager.fade_time_factor = 0.25
    
    var player = Manager.find_player()
    player.start_cutscene()
    
    Manager.show_text(player, "I guess that's all of them!", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "...Now what? I still can't wake up.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "Oh, I hate it when this happens. It's like sleep paralysis, but worse.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "Maybe there's a rabbit somewhere for me to follow. A whole adventure to be had!", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "As if.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    Manager.wipe_fade_out()
    yield(Manager, "fade_completed")
    var cirno = preload("res://scenes/CutsceneCirno.tscn").instance()
    add_child(cirno)
    cirno.global_transform.origin = $CirnoSpawn.global_transform.origin
    cirno.custom_move_and_slide(0.016, Vector3.DOWN)
    cirno.rotation_degrees.y = 90
    
    $CutsceneCamera.current = true
    Manager.wipe_fade_in()
    yield(Manager, "fade_completed")
    
    Manager.show_text(cirno, "No rabbits here! Just me!", "Cirno")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(Vector2(-100, 200), "Huh? What's Cirno doing...", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(cirno, "Follow the rabbit!", "Cirno")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(Vector2(-100, 200), "Hey, wait!", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    
    Manager.fade_time_factor = 1.0
    yield(get_tree(), "idle_frame")
    Manager.pop_input_mode("cutscene")
    
    Manager.change_to("res://scenes/Level2.tscn")

var time_since_clear = 0.0
var next_cutscene_consumed = false
func _process(delta):
    if to_resurface.size() > 0:
        var mesh : Mesh = to_resurface.pop_front()
        for surface in range(mesh.get_surface_count()):
            var mat : SpatialMaterial = mesh.surface_get_material(surface)
            if mat in touched:
                continue
            touched[mat] = null
            mat.params_cull_mode = SpatialMaterial.CULL_BACK
            mat.distance_fade_max_distance = 2.0
            mat.distance_fade_mode = SpatialMaterial.DISTANCE_FADE_PIXEL_DITHER
    
    var num_enemies = get_tree().get_nodes_in_group("Enemy").size()
    if num_enemies == 0:
        time_since_clear += delta
    
    if time_since_clear >= 1.0 and !next_cutscene_consumed:
        next_cutscene_consumed = true
        next_cutscene()
