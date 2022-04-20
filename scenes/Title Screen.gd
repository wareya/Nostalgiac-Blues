extends Spatial


# https://opengameart.org/content/random-sounds-samples

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    $Controls/Buttons/Start.grab_focus()
    $Controls/Buttons/Start.connect("pressed", self, "start_game")
    pass # Replace with function body.

func start_game():
    $Controls/Buttons/Start.disabled = true
    Manager.change_to("res://scenes/Level1.tscn")
    EmitterFactory.emit("startbleep")
    volume_down = true

var volume_down = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    var focuser = $Controls.get_focus_owner()
    if focuser == $Controls/Buttons/Start:
        $Controls/Sprite.global_position = focuser.get_global_rect().position
        $Controls/Sprite.global_position.x -= 20
        $Controls/Sprite.global_position.y += focuser.get_global_rect().size.y/2.0
    
    if !volume_down:
        var volume_speed = 6.0
        if $CricketSound.volume_db < -12.0:
            volume_speed = 48.0
        $CricketSound.volume_db = move_toward($CricketSound.volume_db, 0, volume_speed*delta)
    else:
        $CricketSound.volume_db = move_toward($CricketSound.volume_db, -80, 80.0*delta)
    pass
