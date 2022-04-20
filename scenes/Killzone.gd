extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


var killed = {}
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    for other in get_overlapping_bodies():
        if other in killed:
            continue
        killed[other] = null
        if other.has_method("damage"):
            other.damage(other.health)
            other.iframes -= 2.0
            other.time_alive += 2.0
        elif other.has_method("kill"):
            other.kill()
    pass
