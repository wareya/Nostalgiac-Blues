extends Spatial

func cutscene():
    $CutsceneCamera.current = true
    var player = Manager.find_player()
    player.health_max *= 2.0
    player.health *= 2.0
    player.look_towards($Cirno)
    player.get_node("Aimer").rotation_degrees.y = 180
    player.start_cutscene()
    player.get_camera().get_parent().scale = Vector3(2.0, 2.0, 2.0)
    #player.get_camera().transform.origin.z -= 0.75
    
    if Manager.fading:
        yield(Manager, "fade_completed")
    
    Manager.push_input_mode("cutscene")
    
    Manager.show_text(player, "I should be careful.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "...Wait, what do I have to be afraid of? I'm powerful as all heck, even in this younger body!", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(player, "That's right, [color=#FF0]my shots will travel for a lot longer here![/color]", "Alice")
    yield(Manager, "cutscene_continue")
    player.bullet_life_factor = 2.5
    
    Manager.hide_text()
    
    Manager.fade_time_factor = 0.25
    Manager.wipe_fade_out()
    yield(Manager, "fade_completed")
    
    player.get_camera().current = true
    Manager.wipe_fade_in()
    yield(Manager, "fade_completed")
    Manager.fade_time_factor = 1.0
    
    yield(get_tree(), "idle_frame")
    Manager.pop_input_mode("cutscene")

func _ready():
    EmitterFactory.loud_mode = true
    
    var touched = {}
    for child in get_children():
        if child is GeometryInstance:
            var _inst : GeometryInstance = child
            pass
        if child is Spatial:
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

