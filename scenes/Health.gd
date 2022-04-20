tool
extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
var time_alive = 0.0
func _process(delta):
    for body in get_overlapping_bodies():
        body.restore_health(1)
        queue_free()
        EmitterFactory.emit("healthrestore")
        return
    time_alive += delta
    $Model.rotation_degrees.y += delta*60
    $Model.transform.origin.y = sin(time_alive*4)*0.05
    pass
