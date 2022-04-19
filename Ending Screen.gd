extends Spatial


# https://opengameart.org/content/random-sounds-samples

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func cutscene():
    Manager.fade_time_factor = 8.0
    var alice = $Alice
    alice.dead_eyes()
    $CameraHolder/Camera.current = true
    
    if Manager.fading:
        yield(Manager, "fade_completed")
    Manager.push_input_mode("cutscene")
    
    yield(get_tree().create_timer(2.0), "timeout")
    
    $Camera2.current = true
    yield(get_tree().create_timer(1.0), "timeout")
    $Camera3.current = true
    yield(get_tree().create_timer(1.0), "timeout")
    
    alice.crossed_eyes()
    yield(get_tree().create_timer(1.0), "timeout")
    alice.awake_eyes()
    
    yield(get_tree().create_timer(1.0), "timeout")
    
    
    Manager.show_text(Vector2(0, -300), "Oh... Why'd I fall asleep out here?", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.show_text(Vector2(0, -300), "...Well, I guess it's a warm night.", "Alice")
    yield(Manager, "cutscene_continue")
    
    Manager.hide_text()
    yield(get_tree().create_timer(1.5), "timeout")
    $Camera2.current = true
    
    yield(get_tree().create_timer(1.0), "timeout")
    alice.crossed_eyes()
    yield(get_tree().create_timer(0.5), "timeout")
    alice.awake_eyes()
    yield(get_tree().create_timer(0.5), "timeout")
    alice.crossed_eyes()
    yield(get_tree().create_timer(0.25), "timeout")
    alice.awake_eyes()
    
    yield(get_tree().create_timer(1.0), "timeout")
    
    
    Manager.show_text(alice, "Why am I still wearing these clothes?", "Alice")
    yield(Manager, "cutscene_continue")
    Manager.hide_text()
    
    yield(get_tree().create_timer(0.5), "timeout")
    
    $CameraHolder/Camera.current = true
    
    yield(get_tree().create_timer(1.0), "timeout")
    
    yield(get_tree(), "idle_frame")
    Manager.pop_input_mode("cutscene")
    
    Manager.fade_time_factor = 8.0
    Manager.wipe_fade_out()
    yield(Manager, "fade_completed")
    
    $CanvasLayer/ThanksLabel.visible = true


# Called when the node enters the scene tree for the first time.
func _ready():
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    
    cutscene()

var volume_down = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    
    if !volume_down:
        var volume_speed = 6.0
        if $CricketSound.volume_db < -12.0:
            volume_speed = 48.0
        $CricketSound.volume_db = move_toward($CricketSound.volume_db, 0, volume_speed*delta)
    else:
        $CricketSound.volume_db = move_toward($CricketSound.volume_db, -80, 80.0*delta)
    pass
