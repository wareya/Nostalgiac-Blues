extends CanvasLayer

func _ready():
    $Blip.stream = preload("res://sfx/goodblip.wav")
    push_input_mode("transition")
    fading = true
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    wipe_fade_in()
    yield(self, "fade_completed")
    pop_input_mode("transition")

func get_sec():
    return OS.get_ticks_usec()/1_000_000.0

var fade_contrast = 1.0
var fade_color : Color = Color.black
signal fade_completed
var fading = false
var fade_time_factor = 1.0
func do_fade_anim(invert = false, fadein = false, _fade_time = 0.75):
    var fade_time = _fade_time * fade_time_factor
    fading = true
    var start_time = get_sec()
    var progress = 0.0
    while progress < 1.0:
        if fade_time > 0:
            progress = (get_sec() - start_time)/fade_time
        else:
            progress = 1.0
        #if do_timer_skip(): progress = 1.0
        
        $FadeLayer/ScreenFader.invert = invert
        $FadeLayer/ScreenFader.contrast = fade_contrast
        $FadeLayer/ScreenFader.modulate = fade_color
        $FadeLayer/ScreenFader.self_modulate = Color.white
        if fadein:
            $FadeLayer/ScreenFader.fadeamount = clamp(1.0-progress, 0.0, 1.0)
        else:
            $FadeLayer/ScreenFader.fadeamount = clamp(progress, 0.0, 1.0)
        
        yield(get_tree(), "idle_frame")
        
    fading = false
    emit_signal("fade_completed")

func wipe_fade_out(flat = false):
    fade_contrast = 0.0 if flat else 1.0
    return do_fade_anim(false, false)

func wipe_fade_in(flat = false):
    fade_contrast = 0.0 if flat else 1.0
    return do_fade_anim(true, true)


var floor_seeds = {}
var current_floor = 0
var current_floor_name = "The Edge of Dust"

var last_entered_room_name = ""
var changing_room = false
var changing_room_out = false
signal room_changed
signal room_change_complete
func change_to(target_level : String, flat_fade : bool = false):
    if changing_room_out:
        return
    
    last_entered_room_name = target_level
    changing_room = true
    changing_room_out = true
    #SaveData.savify_player_data()
    
    push_input_mode("transition")
    yield(wipe_fade_out(flat_fade), "completed")
    
    var scene = load(target_level).instance()
    
    #call_deferred("_change_to", scene, target_node) # wrong (at least in 3.3.x)
    yield(get_tree(), "idle_frame")
    _change_to(scene)
    changing_room_out = false
    yield(get_tree(), "idle_frame")
    
    
    emit_signal("room_changed")
    
    yield(wipe_fade_in(flat_fade), "completed")
    pop_input_mode("transition")
    
    #SaveData.unsavify_player_data()
    
    changing_room = false
    emit_signal("room_change_complete")

func _change_to(scene):
    if get_tree().current_scene and is_instance_valid(get_tree().current_scene):
        get_tree().current_scene.free()
    get_tree().get_root().add_child(scene)
    get_tree().current_scene = scene

func find_player():
    for obj in get_tree().get_nodes_in_group("Player"):
        return obj

func place_player(target_node):
    var player = find_player()
    if target_node:
        var spawn = get_tree().current_scene.find_node(target_node, true, false)
        if spawn and player:
            player.global_position = spawn.global_position
    if player:
        player.inform_mapchange()

var input_mode = "gameplay"
var input_mode_stack = []
func push_input_mode(mode):
    input_mode_stack.push_back(input_mode)
    input_mode = mode
func pop_input_mode(mode):
    if input_mode == mode:
        input_mode = input_mode_stack.pop_back()
    else:
        var same = input_mode_stack.find_last(mode)
        if same < 0:
            input_mode = input_mode_stack.pop_back()
        else:
            input_mode_stack.remove(same)



func play_bgm(audio : AudioStream):
    if $BGMPlayer.stream == audio and $BGMPlayer.playing:
        return
    $BGMPlayer.stop()
    $BGMPlayer.stream = audio
    $BGMPlayer.play()

func make_shattery_mat(mat : SpatialMaterial):
    var newmat = preload("res://resources/ShatterMaterial.tres").duplicate()
    newmat.set_shader_param("albedo", mat.albedo_color)
    newmat.set_shader_param("texture_albedo", mat.albedo_texture)
    newmat.set_shader_param("specular", mat.metallic_specular)
    newmat.set_shader_param("metallic", mat.metallic)
    newmat.set_shader_param("roughness", mat.roughness)
    newmat.set_shader_param("point_size", mat.params_point_size)
    newmat.set_shader_param("uv1_offset", mat.uv1_offset)
    newmat.set_shader_param("uv2_offset", mat.uv2_offset)
    newmat.set_shader_param("uv1_scale", mat.uv1_scale)
    newmat.set_shader_param("uv2_scale", mat.uv2_scale)
    newmat.next_pass = mat.next_pass
    return newmat

func show_text(where, bbcode : String, _speaker : String = "", blip = true):
    var loc : Vector2 = get_viewport().size/2.0
    var offset_3d = Vector3(0.0, 1.0, 0.0) 
    var centering = Vector2(0.5, 1.0)
    if where is Spatial:
        loc = get_viewport().get_camera().unproject_position(where.global_transform.origin + offset_3d)
    elif where is Vector3:
        loc = get_viewport().get_camera().unproject_position(where + offset_3d)
    elif where is Vector2:
        loc.y -= get_viewport().size.y*0.05
        loc += where
        centering = Vector2(0.5, 0.5)
    
    if _speaker != "":
        if _speaker == "Alice":
            _speaker = "[color=#FF0]Alice[/color]"
        if _speaker == "Cirno":
            _speaker = "[color=#8DF]Cirno[/color]"
        bbcode = _speaker + "\n" + bbcode
    
    $TextLabel.visible = true
    $TextLabel.bbcode_enabled = true
    $TextLabel.bbcode_text = ""
    text_visible_chars = -1
    $TextLabel.visible_characters = -1
    $TextLabel.propagate_notification(CanvasItem.NOTIFICATION_VISIBILITY_CHANGED)
    $TextLabel.rect_size = Vector2(500,0)
    $TextLabel.propagate_notification(CanvasItem.NOTIFICATION_VISIBILITY_CHANGED)
    $TextLabel.bbcode_text = bbcode
    $TextLabel.propagate_notification(CanvasItem.NOTIFICATION_VISIBILITY_CHANGED)
    
    $TextLabel.rect_global_position = loc - $TextLabel.rect_size * centering
    print($TextLabel.rect_global_position.y)
    if $TextLabel.rect_global_position.y < 0:
        $TextLabel.rect_global_position = loc - $TextLabel.rect_size * centering * Vector2(1, 0)
    
    if blip:
        text_visible_chars = 0.0
        $TextLabel.visible_characters = 0
    else:
        $Blip.stream.loop_mode = AudioStreamSample.LOOP_DISABLED
        $Blip.play()

func hide_text():
    $TextLabel.visible = false

signal cutscene_continue
var text_visible_chars = -1.0
func process_cutscene(delta):
    if input_mode != "cutscene":
        return
    if (Input.is_action_just_pressed("ui_accept") or
        Input.is_action_just_pressed("ui_cancel") or
        Input.is_action_just_pressed("m1")):
        if $Blip.stream.loop_mode != AudioStreamSample.LOOP_DISABLED:
            $Blip.stream.loop_mode = AudioStreamSample.LOOP_DISABLED
        if text_visible_chars < 0 or text_visible_chars >= $TextLabel.get_total_character_count():
            emit_signal("cutscene_continue")
        else:
            text_visible_chars = -1
    else:
        if text_visible_chars >= 0 and text_visible_chars < $TextLabel.get_total_character_count():
            if $Blip.stream.loop_mode != AudioStreamSample.LOOP_FORWARD:
                $Blip.stream.loop_mode = AudioStreamSample.LOOP_FORWARD
            if !$Blip.playing:
                $Blip.play()
            text_visible_chars += delta*120.0
        else:
            if $Blip.stream.loop_mode != AudioStreamSample.LOOP_DISABLED:
                $Blip.stream.loop_mode = AudioStreamSample.LOOP_DISABLED
    $TextLabel.visible_characters = int(text_visible_chars)

func _process(delta):
    $FPS.text = str(round(Engine.time_scale/delta))
    #$FPS.text = str(Engine.get_frames_per_second())
    if last_entered_room_name == "":
        last_entered_room_name = get_tree().current_scene.filename
    process_cutscene(delta)
    
    var player = find_player()
    if player:
        $HealthBar.visible = true
        var under : AtlasTexture = $HealthBar.texture_under
        var prog : AtlasTexture = $HealthBar.texture_progress
        under.region.size.x = under.atlas.get_size().x * player.health_max
        prog.region.size.x = prog.atlas.get_size().x * player.health_max
        $HealthBar.max_value = player.health_max
        $HealthBar.value = player.health
    else:
        $HealthBar.visible = false
    





