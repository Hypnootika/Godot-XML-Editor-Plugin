@tool
extends Control

@onready var folder_path: String = "res://"
@onready var tree: Tree = %XMLTree
@onready var file_list: ItemList = %Filelist
@onready var editor_column: VBoxContainer = %EditorColumn
@onready var bbcode_preview: Window = %BbcodePreview
@onready var bbcode_richtext_label: RichTextLabel = %BbcodeRichText
@onready var selectpathdialog: FileDialog = %SelectPathDialog
@onready var save_button: Button = %Save
@onready var select_path_button: Button = %SelectPath

var currently_selected_text_edit: TextEdit = TextEdit.new()
var currently_selected_xml_node: XMLNode = XMLNode.new()
var currently_selected_xml_doc: XMLDocument = XMLDocument.new()
var currently_selected_xml_path: String = ""
var currently_selected_root_node: XMLNode = XMLNode.new()

func _ready()->void:
	_connect_signals()
	populate_file_list()
	
func populate_file_list()->void:
	file_list.clear()
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".xml"):
				file_list.add_item(file_name)
			file_name = dir.get_next()
			
func _on_file_list_item_selected(index)->void:
	_clear_editor_columns()
	var _selected_file: String = file_list.get_item_text(index)
	var xml_file_path: String = folder_path+"/"+_selected_file
	currently_selected_xml_path = xml_file_path
	var xml_document: XMLDocument = XML.parse_file(xml_file_path)
	currently_selected_xml_doc = xml_document
	var root_node: XMLNode = xml_document.root
	if root_node:
		tree.clear()
		var root_tree_item: TreeItem = tree.create_item()
		root_tree_item.set_text(0, root_node.name)
		root_tree_item.set_metadata(0, root_node)
		populate_tree(root_tree_item, root_node)

func populate_tree(root_tree_item: TreeItem, xml_node: XMLNode)->void:
	for child in xml_node.children:
		var tree_item: TreeItem = tree.create_item(root_tree_item)
		tree_item.set_text(0, child.name)
		tree_item.set_metadata(0, child)
		if child.children.size() > 0:
			populate_tree(tree_item, child)

		for attribute_name in child.attributes.keys():
			var attribute_tree_item: TreeItem = tree.create_item(tree_item)
			attribute_tree_item.set_text(0, attribute_name)
			attribute_tree_item.set_metadata(0, {"type": "attribute", "attribute_name": attribute_name, "value": child.attributes[attribute_name]})

func _on_xml_tree_cell_selected()->void:
	var selected_item: TreeItem = tree.get_selected()
	var metadata: Variant = selected_item.get_metadata(0)
	_clear_editor_columns()

	if typeof(metadata) == TYPE_DICTIONARY and metadata.has("type"):
		_handle_metadata_type(metadata)
	elif typeof(metadata) == TYPE_OBJECT:
		_handle_metadata_object(metadata)
		
# Handles
func _handle_metadata_type(metadata: Dictionary)->void:
	if metadata["type"] == "attribute":
		create_name_value_container(metadata.get("attribute_name", ""), metadata.get("value", ""))

func _handle_metadata_object(metadata: Object)->void:
	var xml_node: XMLNode = metadata
	currently_selected_xml_node = xml_node
	
	match xml_node.name:
		"class":
			_handle_class(xml_node)
		"brief_description", "description", "tutorials":
			_handle_description(xml_node)
		"member":
			_handle_member(xml_node)
		"method":
			_handle_method(xml_node)
		"signal":
			_handle_signal(xml_node)
		"constant":
			_handle_constant(xml_node)

func _handle_class(xml_node: XMLNode)->void:
	create_name_value_container("name", xml_node.attributes.get("name", ""))
	create_name_value_container("inherits", xml_node.attributes.get("inherits", ""))

func _handle_description(xml_node: XMLNode)->void:
	create_text_edit(xml_node.name, xml_node.content)

func _handle_member(xml_node: XMLNode)->void:
	var attributes = [
		["name", xml_node.attributes.name],
		["type", "type"],
		["setter", "setter"],
		["getter", "getter"],
		["overrides", "overrides"],
		["enum", "enum"],
		["default", "default"],
		["is_deprecated", "is_deprecated"],
		["is_experimental", "is_experimental"]
	]
	for pair in attributes:
		var attribute_name: String = pair[0]
		var key = pair[1]
		create_name_value_container(attribute_name, xml_node.attributes.get(key, ""))

	create_text_edit("Description", xml_node.content)


func _handle_method(xml_node: XMLNode) -> void:
	# Displaying Method name and attributes
	create_name_value_container("Method Name", xml_node.attributes.get("name", ""))
	create_name_value_container("Qualifiers", xml_node.attributes.get("qualifiers", ""))
	create_name_value_container("Is Deprecated", xml_node.attributes.get("is_deprecated", ""))
	create_name_value_container("Is Experimental", xml_node.attributes.get("is_experimental", ""))

	# Iterate through the children of the method node
	for child in xml_node.children:
		match child.name:
			"return":
				create_name_value_container("Return Type", child.attributes.get("type", ""))
				create_name_value_container("Return Enum", child.attributes.get("enum", ""))
				create_name_value_container("Return is_bitfield", child.attributes.get("is_bitfield", ""))
			"param":
				var param_attributes = [
					["Index", child.attributes.get("index", "")],
					["Name", child.attributes.get("name", "")],
					["Type", child.attributes.get("type", "")],
					["Enum", child.attributes.get("enum", "")],
					["Is Bitfield", child.attributes.get("is_bitfield", "")],
					["Default", child.attributes.get("default", "")]
				]
				var param_container = HBoxContainer.new()
				editor_column.add_child(param_container)
				for pair in param_attributes:
					var attribute_name: String = pair[0]
					var value = pair[1]
					create_name_value_container(attribute_name, value, param_container)


func _handle_signal(xml_node: XMLNode) -> void:
	# Displaying Signal name
	create_name_value_container("Signal Name", xml_node.attributes.get("name", ""))
	
	# Iterate through the children of the signal node
	for child in xml_node.children:
		match child.name:
			"argument":
				var param_attributes = [
					["Index", child.attributes.get("index", "")],
					["Name", child.attributes.get("name", "")],
					["Type", child.attributes.get("type", "")]
				]
				var param_container = HBoxContainer.new()
				editor_column.add_child(param_container)
				for pair in param_attributes:
					var attribute_name: String = pair[0]
					var value = pair[1]
					create_name_value_container(attribute_name, value, param_container)


func _handle_constant(xml_node: XMLNode) -> void:
	# Displaying Constant attributes
	create_name_value_container("Constant Name", xml_node.attributes.get("name", ""))
	create_name_value_container("Value", xml_node.attributes.get("value", ""))
	create_name_value_container("Enum", xml_node.attributes.get("enum", ""))
	create_name_value_container("Is Bitfield", xml_node.attributes.get("is_bitfield", ""))
	create_name_value_container("Is Deprecated", xml_node.attributes.get("is_deprecated", ""))
	create_name_value_container("Is Experimental", xml_node.attributes.get("is_experimental", ""))

	# Displaying constant description if available
	if xml_node.content:
		create_text_edit("Description", xml_node.content.strip_edges())


# Util
func create_name_value_container(attribute_name: String, value, parent_container: Container = editor_column)->void:
	var name_value_container: HBoxContainer = HBoxContainer.new()
	parent_container.add_child(name_value_container)

	var label: Label = Label.new()
	label.text = attribute_name
	name_value_container.add_child(label)
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio=0.2
	var line_edit: LineEdit = LineEdit.new()
	line_edit.text = value
	name_value_container.add_child(line_edit)
	line_edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	line_edit.editable = false
	
func create_text_edit(label_text, content)->void:
	var label: Label = Label.new()
	label.text = label_text
	editor_column.add_child(label)
	currently_selected_text_edit = null
	var text_edit: TextEdit = TextEdit.new()
	text_edit.text = content.strip_edges()
	editor_column.add_child(text_edit)
	text_edit.size_flags_vertical=Control.SIZE_EXPAND_FILL
	text_edit.deselect_on_focus_loss_enabled = false
	text_edit.text_changed.connect(_on_textedit_text_changed.bind(text_edit))
	currently_selected_text_edit = text_edit
	var button_bar = HBoxContainer.new()
	editor_column.add_child(button_bar)
	var bold_button: Button = create_button("Bold", _on_bold_button_pressed,button_bar)
	var italic_button: Button = create_button("Italic", _on_italic_button_pressed, button_bar)	
	var code_button:Button = create_button("Code", _on_code_button_pressed, button_bar)
	var code_block_button: Button = create_button("Codeblock", _on_codeblock_button_pressed, button_bar)
	var bb_button: Button = create_button("Preview BBcode", _on_bbcode_button_pressed,button_bar)
	
func create_button(label_text: String, signal_method: Callable, place) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.pressed.connect(signal_method)
	place.add_child(button)
	button.size_flags_horizontal=Control.SIZE_EXPAND
	return button

func _parsebbcode(bbcode_text: String, bbcode_richtext_label: RichTextLabel)->void:
	bbcode_richtext_label.append_text(bbcode_text)

func _clear_editor_columns()->void:
	for child in editor_column.get_children():
		editor_column.remove_child(child)
		child.queue_free()

# Signals
func _connect_signals()->void:
	if not file_list.item_selected.is_connected(_on_file_list_item_selected):
		file_list.item_selected.connect(_on_file_list_item_selected)
	if not tree.cell_selected.is_connected(_on_xml_tree_cell_selected):
		tree.cell_selected.connect(_on_xml_tree_cell_selected)
	if not selectpathdialog.dir_selected.is_connected(_on_select_path_dialog_dir_selected):
		selectpathdialog.dir_selected.connect(_on_select_path_dialog_dir_selected)

func _on_textedit_text_changed(text_edit: TextEdit):
	currently_selected_xml_node.content = text_edit.text
	print(currently_selected_xml_node.content)

func _on_bbcode_button_pressed()->void:
	bbcode_preview.show()
	_parsebbcode(currently_selected_text_edit.text, bbcode_richtext_label)

func _on_bold_button_pressed()->void:
	var selected_text = currently_selected_text_edit.get_selected_text()
	if selected_text and selected_text != "":
		var bbcode_bold: String = "[b]" + selected_text + "[/b]"
		currently_selected_text_edit.insert_text_at_caret(bbcode_bold)
		
func _on_italic_button_pressed()->void:
	var selected_text = currently_selected_text_edit.get_selected_text()
	if selected_text and selected_text != "":
		var bbcode_italic: String = "[i]" + selected_text + "[/i]"
		currently_selected_text_edit.insert_text_at_caret(bbcode_italic)
		
func _on_code_button_pressed()->void:
	var selected_text = currently_selected_text_edit.get_selected_text()
	if selected_text and selected_text != "":
		var bbcode_code: String = "[code]" + selected_text + "[/code]"
		currently_selected_text_edit.insert_text_at_caret(bbcode_code)

func _on_codeblock_button_pressed()->void:
	var selected_text = currently_selected_text_edit.get_selected_text()
	if selected_text and selected_text != "":
		var bbcode_codeblock: String = "[codeblock]" + selected_text + "[/codeblock]"
		currently_selected_text_edit.insert_text_at_caret(bbcode_codeblock)

func _on_bbcode_preview_visibility_changed()->void:
	if not bbcode_preview.visible:
		bbcode_richtext_label.clear()

func _on_select_path_dialog_dir_selected(path: String):
	_clear_editor_columns()
	tree.clear()
	folder_path = path
	%Path.text = path
	populate_file_list()

func _on_select_path_dialog_close_requested():
	%SelectPathDialog.hide()

func _on_close_window_button_pressed():
	bbcode_richtext_label.clear()
	bbcode_preview.hide()

func _on_save_pressed():
	XML.dump_file(currently_selected_xml_path, currently_selected_xml_doc, true)
func _on_select_path_pressed():
	selectpathdialog.popup_centered()
