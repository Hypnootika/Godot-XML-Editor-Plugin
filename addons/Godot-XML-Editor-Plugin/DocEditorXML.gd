@tool
class_name XML extends RefCounted

enum XMLNodeType {
	XML_NODE_ELEMENT_START,
	XML_NODE_ELEMENT_END, 
	XML_NODE_COMMENT, 
}
static func parse_file(path: String) -> XMLDocument:
	var file = FileAccess.open(path, FileAccess.READ)
	var xml: PackedByteArray = file.get_as_text().to_utf8_buffer()
	file = null
	return _parse(xml)

static func dump_file(path: String, document: XMLDocument, beautify: bool = true):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var xml: String = dump_str(document, beautify)
	file.store_string(xml)
	file = null

static func dump_str(document: XMLDocument, beautify: bool = true) -> String:
	return _dump(document, beautify)

static func _dump(document: XMLDocument, beautify: bool = true):
	return _dump_beautifully(document.root)

static func _dump_beautifully(node: XMLNode, indent: int = 0) -> String:
	var out: String = ""
	if indent == 0:
		out += "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
	out += _dump_node(node, false, true, indent)
	for child in node.children:
		out += _dump_beautifully(child, indent +1)
	if not node.standalone:
		out += _dump_node(node, true, true, indent)
	return out
	
static func _dump_node(node: XMLNode, closing: bool = false, beautify: bool = false, indent: int = 0) -> String:
	var attrs: Array[String] = []
	for attr in node.attributes:
		attrs.append(attr + "=\"" + node.attributes.get(attr) + "\"")
	var attrstr = " ".join(attrs)
	var indent_str = ""
	for i in range(indent):
		indent_str += "    "

	if node.standalone:
		return indent_str + "<%s %s />%s" % [node.name, attrstr, "\n"]
	else:
		if closing:
			return indent_str + "</%s>%s" % [node.name, "\n"]
		else:
#			if node.content:
#				return indent_str + "<%s %s>%s%s%s" % [node.name, attrstr, "\n", _beauty(node.content, indent+1), "\n"]
			if node.content:
				var indented_content = _indent_content_lines(node.content, indent + 1)
				return indent_str + "<%s %s>%s%s%s" % [node.name, attrstr, "\n", indented_content, "\n"]
			else:
				return indent_str + "<%s %s>%s" % [node.name, attrstr, "\n"]

static func _beauty(string: String, indent: int) -> String:
	var indent_str = ""
	for i in range(indent):
		indent_str += "    "
	return indent_str + string

static func _indent_string(indent: int) -> String:
	var indent_str = ""
	for i in range(indent):
		indent_str += "    "
	return indent_str

static func _indent_content_lines(content: String, indent: int) -> String:
	var lines = content.split("\n")
	var indent_str = _indent_string(indent)
	for i in range(lines.size()):
		lines[i] = indent_str + lines[i].strip_edges(true, false)
	return "\n".join(lines)

static func _parse(xml: PackedByteArray) -> XMLDocument:
	var doc: XMLDocument = XMLDocument.new()
	var queue: Array = []
	var parser: XMLParser = XMLParser.new()
	parser.open_buffer(xml)
	while parser.read() != ERR_FILE_EOF:
		var node: XMLNode = _make_node(queue, parser)
		if node == null:
			continue
		if len(queue) == 0:
			doc.root = node
			queue.append(node)
		else:
			var node_type = parser.get_node_type()
			if node_type == XMLParser.NODE_TEXT:
				continue
			if node.standalone and not node_type == XMLParser.NODE_ELEMENT_END:
				queue.back().children.append(node)
			elif node_type == XMLParser.NODE_ELEMENT_END and not node.standalone:
				queue.pop_back()
			else:
				queue.back().children.append(node)
				queue.append(node)
	return doc

static func _make_node(queue: Array, parser: XMLParser):
	var node_type = parser.get_node_type()
	match node_type:
		XMLParser.NODE_ELEMENT:
			return _make_node_element(parser)
		XMLParser.NODE_ELEMENT_END:
			return _make_node_element_end(parser)
		XMLParser.NODE_TEXT:
			_attach_node_data(queue.back(), parser)
			return

static func _make_node_element(parser: XMLParser):
	var node: XMLNode = XMLNode.new()

	node.name = parser.get_node_name()
	node.attributes = _get_attributes(parser)
	node.content = ""
	node.standalone = parser.is_empty()
	node.children = []

	return node

static func _make_node_element_end(parser: XMLParser) -> XMLNode:
	var node: XMLNode = XMLNode.new()
	node.name = parser.get_node_name()
	node.attributes = {}
	node.content = ""
	node.standalone = false
	node.children = []
	return node

static func _attach_node_data(node: XMLNode, parser: XMLParser) -> void:
	if node.content.is_empty():
		node.content = parser.get_node_data().strip_edges().lstrip(" ").rstrip(" ")

static func _get_attributes(parser: XMLParser) -> Dictionary:
	var attrs: Dictionary = {}
	var attr_count: int = parser.get_attribute_count()

	for attr_idx in range(attr_count):
		attrs[parser.get_attribute_name(attr_idx)] = parser.get_attribute_value(attr_idx)
	
	return attrs


