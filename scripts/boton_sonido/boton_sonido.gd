extends Button

var sfx_navigate
var sfx_accept

func _ready():
	var root = get_tree().root
	sfx_navigate = root.get_node("MenuPrincipal/SFX_Navigate")
	sfx_accept = root.get_node("MenuPrincipal/SFX_Accept")


	focus_entered.connect(_on_focus_entered)
	pressed.connect(_on_pressed)


func _on_focus_entered():
	if sfx_navigate:
		sfx_navigate.play()


func _on_pressed():
	if sfx_accept:
		sfx_accept.play()
