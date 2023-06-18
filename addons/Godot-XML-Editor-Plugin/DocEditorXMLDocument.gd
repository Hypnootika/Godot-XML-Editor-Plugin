@tool
class_name XMLDocument extends RefCounted

var root: XMLNode

func _to_string():
	return "<XMLDocument root=%s>" % str(root)
