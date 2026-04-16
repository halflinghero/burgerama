extends Label

var score = 0

func _on_burger_eaten():
	score += 1
	text = "Burgers Munched: %s" % score
