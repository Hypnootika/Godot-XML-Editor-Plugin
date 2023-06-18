@tool
class_name XMLNode extends RefCounted

var name: String = ""
var attributes: Dictionary = {}
var content: String = ""
var standalone: bool = false
var children: Array[XMLNode] = []

func _to_string():
	return "<XMLNode name=%s attributes=%s content=%s standalone=%s children=%s>" % [
		name,
		"{...}" if len(attributes) > 0 else "{}",
		"\"...\"" if len(content) > 0 else "\"\"",
		str(standalone),
		"[...]" if len(children) > 0 else "[]"
	]
