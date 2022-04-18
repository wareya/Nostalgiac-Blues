extends Spatial

func cutscene():
    var player = Manager.find_player()
    player.start_cutscene()
    
    var cirno = $Cirno
    
    player.look_towards(cirno)
    
    $StaticCutsceneCamera2.current = true
    if Manager.fading:
        yield(Manager, "fade_completed")
    
    Manager.fade_time_factor = 0.25
    
    Manager.push_input_mode("cutscene")
    
    Manager.show_text(player, "I don't know what you're doing in my dream, but...", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    Manager.wipe_fade_out()
    yield(Manager, "fade_completed")
    $StaticCutsceneCamera.current = true
    Manager.wipe_fade_in()
    yield(Manager, "fade_completed")
    
    Manager.show_text(cirno, "Catch me if ya can!", "Cirno")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    Manager.wipe_fade_out()
    yield(Manager, "fade_completed")
    $CutsceneCamera/Camera.current = true
    Manager.wipe_fade_in()
    yield(Manager, "fade_completed")
    
    Manager.show_text(player, "What? Why am I chasing you all of a sudden?!", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(cirno, "Aww, ya dream taking over?", "Cirno")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "No, I just—", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(cirno, "Come on, don't be so down, be up! Up, up and away!", "Cirno")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "I mean, I know they say stupid people like high places, but... You expect me to climb this thing?!", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(cirno, "What's wrong, can't fly?", "Cirno")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(cirno, "Wait, where the heck are my wings?!", "Cirno")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    Manager.wipe_fade_out()
    yield(Manager, "fade_completed")
    player.get_camera().current = true
    Manager.wipe_fade_in()
    yield(Manager, "fade_completed")
    
    Manager.show_text(player, "Ugh! Get back here!", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    
    Manager.fade_time_factor = 1.0
    
    yield(get_tree(), "idle_frame")
    Manager.pop_input_mode("cutscene")

func _ready():
    var touched = {}
    for child in get_children():
        if child is GeometryInstance:
            var _inst : GeometryInstance = child
            pass
        if child is Spatial:
            if child.name.begins_with("flowers") or child.name.begins_with("fern") or child.name.begins_with("grass") or child.name.begins_with("Prop"):
                continue
            for child2 in child.get_children():
                if child2 is MeshInstance:
                    var mesh : Mesh = child2.mesh
                    for surface in range(mesh.get_surface_count()):
                        var mat : SpatialMaterial = mesh.surface_get_material(surface)
                        if !mat:
                            continue
                        if mat in touched:
                            continue
                        touched[mat] = null
                        mat.params_cull_mode = SpatialMaterial.CULL_BACK
                        mat.distance_fade_max_distance = 2.0
                        mat.distance_fade_mode = SpatialMaterial.DISTANCE_FADE_PIXEL_DITHER
    
    Manager.play_bgm(preload("res://bgm/A Wonderful Land.ogg"))
    
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    cutscene()

func _process(delta):
    if $CutsceneCamera/Camera.current:
        $CutsceneCamera.rotation_degrees.y += 15.0*delta
