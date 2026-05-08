@tool
extends EditorScript

const ICON_ROOT: String = "res://assets/Icons"
const TARGET_COLOUR: String = "#FFFFFF"
const MAKE_BACKUPS: bool = true

const GRAPHIC_TAGS: Array[String] = [
    "path",
    "circle",
    "rect",
    "line",
    "polyline",
    "polygon",
	"ellipse"
]


func _run() -> void:
    var svg_paths: Array[String] = []
    _collect_svg_files(ICON_ROOT, svg_paths)

    var changed_count: int = 0

    for path: String in svg_paths:
        var original_text: String = FileAccess.get_file_as_string(path)
        var updated_text: String = original_text

        updated_text = _force_svg_colours(updated_text)

        if updated_text != original_text:
            if MAKE_BACKUPS:
                var backup_path: String = path + ".bak"

                if not FileAccess.file_exists(backup_path):
                    _write_text_file(backup_path, original_text)

            _write_text_file(path, updated_text)
            changed_count += 1
            print("Updated SVG: ", path)
        else:
            print("No changes needed: ", path)

    print("----------------------------------------")
    print("SVG colour update complete")
    print("SVG files found: ", svg_paths.size())
    print("SVG files changed: ", changed_count)
    print("----------------------------------------")
    print("Right-click the icons folder in Godot and Reimport if they do not visually update.")


func _collect_svg_files(directory_path: String, output_paths: Array[String]) -> void:
    var directory: DirAccess = DirAccess.open(directory_path)

    if directory == null:
        push_error("Could not open icon directory: " + directory_path)
        return

    directory.list_dir_begin()

    while true:
        var item_name: String = directory.get_next()

        if item_name == "":
            break

        if item_name.begins_with("."):
            continue

        var full_path: String = directory_path.path_join(item_name)

        if directory.current_is_dir():
            _collect_svg_files(full_path, output_paths)
        else:
            var extension: String = item_name.get_extension().to_lower()

            if extension == "svg":
                output_paths.append(full_path)

    directory.list_dir_end()


func _force_svg_colours(svg_text: String) -> String:
    var output: String = svg_text

    output = _replace_attribute_value(output, "stroke")
    output = _replace_attribute_value(output, "fill")

    output = _replace_style_property(output, "stroke")
    output = _replace_style_property(output, "fill")

    # Only add missing colours if the SVG has no usable visible colour definition.
    # This avoids accidentally filling outline icons that already inherit stroke from the <svg> tag.
    if not _has_visible_colour_definition(output):
        for tag_name: String in GRAPHIC_TAGS:
            output = _force_colour_on_tag(output, tag_name)

    return output


func _replace_attribute_value(source_text: String, attribute_name: String) -> String:
    var regex: RegEx = RegEx.new()

    # Handles:
    # stroke="#000000"
    # stroke='#000000'
    # stroke = "currentColor"
    var error: int = regex.compile(attribute_name + "\\s*=\\s*(['\"])(.*?)\\1")

    if error != OK:
        push_error("Failed to compile attribute regex for: " + attribute_name)
        return source_text

    var result: String = ""
    var last_index: int = 0
    var matches: Array[RegExMatch] = regex.search_all(source_text)

    for match_result: RegExMatch in matches:
        var value_start: int = match_result.get_start(2)
        var value_end: int = match_result.get_end(2)
        var current_value: String = match_result.get_string(2)

        result += source_text.substr(last_index, value_start - last_index)

        if _should_preserve_svg_value(current_value):
            result += current_value
        else:
            result += TARGET_COLOUR

        last_index = value_end

    result += source_text.substr(last_index)
    return result


func _replace_style_property(source_text: String, property_name: String) -> String:
    var regex: RegEx = RegEx.new()

    # Handles style="stroke:#000; fill: currentColor;"
    var error: int = regex.compile(property_name + "\\s*:\\s*([^;'\"}]+)")

    if error != OK:
        push_error("Failed to compile style regex for: " + property_name)
        return source_text

    var result: String = ""
    var last_index: int = 0
    var matches: Array[RegExMatch] = regex.search_all(source_text)

    for match_result: RegExMatch in matches:
        var value_start: int = match_result.get_start(1)
        var value_end: int = match_result.get_end(1)
        var current_value: String = match_result.get_string(1).strip_edges()

        result += source_text.substr(last_index, value_start - last_index)

        if _should_preserve_svg_value(current_value):
            result += current_value
        else:
            result += TARGET_COLOUR

        last_index = value_end

    result += source_text.substr(last_index)
    return result


func _should_preserve_svg_value(value: String) -> bool:
    var lower_value: String = value.strip_edges().to_lower()

    if lower_value == "":
        return true

    # Important:
    # Do NOT preserve currentColor.
    # In Godot, currentColor often resolves black, which is exactly what we are fixing.
    return (
        lower_value == "none"
        or lower_value == "transparent"
        or lower_value.begins_with("url(")
    )


func _has_visible_colour_definition(svg_text: String) -> bool:
    return (
        _has_visible_attribute(svg_text, "stroke")
        or _has_visible_attribute(svg_text, "fill")
        or _has_visible_style_property(svg_text, "stroke")
        or _has_visible_style_property(svg_text, "fill")
    )


func _has_visible_attribute(source_text: String, attribute_name: String) -> bool:
    var regex: RegEx = RegEx.new()
    var error: int = regex.compile(attribute_name + "\\s*=\\s*(['\"])(.*?)\\1")

    if error != OK:
        return false

    var matches: Array[RegExMatch] = regex.search_all(source_text)

    for match_result: RegExMatch in matches:
        var value: String = match_result.get_string(2)

        if not _should_preserve_svg_value(value):
            return true

    return false


func _has_visible_style_property(source_text: String, property_name: String) -> bool:
    var regex: RegEx = RegEx.new()
    var error: int = regex.compile(property_name + "\\s*:\\s*([^;'\"}]+)")

    if error != OK:
        return false

    var matches: Array[RegExMatch] = regex.search_all(source_text)

    for match_result: RegExMatch in matches:
        var value: String = match_result.get_string(1).strip_edges()

        if not _should_preserve_svg_value(value):
            return true

    return false


func _force_colour_on_tag(source_text: String, tag_name: String) -> String:
    var regex: RegEx = RegEx.new()
    var error: int = regex.compile("<" + tag_name + "\\b([^>]*)>")

    if error != OK:
        push_error("Failed to compile tag regex for: " + tag_name)
        return source_text

    var result: String = ""
    var last_index: int = 0
    var matches: Array[RegExMatch] = regex.search_all(source_text)

    for match_result: RegExMatch in matches:
        var tag_start: int = match_result.get_start(0)
        var tag_end: int = match_result.get_end(0)
        var full_tag: String = match_result.get_string(0)

        var rewritten_tag: String = _rewrite_graphic_tag(full_tag, tag_name)

        result += source_text.substr(last_index, tag_start - last_index)
        result += rewritten_tag

        last_index = tag_end

    result += source_text.substr(last_index)
    return result


func _rewrite_graphic_tag(full_tag: String, tag_name: String) -> String:
    var lower_tag: String = full_tag.to_lower()

    var has_stroke: bool = lower_tag.contains("stroke=") or lower_tag.contains("stroke:")
    var has_fill: bool = lower_tag.contains("fill=") or lower_tag.contains("fill:")

    if tag_name in ["line", "polyline"]:
        if not has_stroke:
            return _insert_attribute_before_close(full_tag, "stroke", TARGET_COLOUR)

        return full_tag

    if not has_stroke and not has_fill:
        return _insert_attribute_before_close(full_tag, "fill", TARGET_COLOUR)

    return full_tag


func _insert_attribute_before_close(tag_text: String, attribute_name: String, value: String) -> String:
    if tag_text.ends_with("/>"):
        return tag_text.substr(0, tag_text.length() - 2) + " " + attribute_name + "=\"" + value + "\"/>"

    return tag_text.substr(0, tag_text.length() - 1) + " " + attribute_name + "=\"" + value + "\">"


func _write_text_file(path: String, text: String) -> void:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)

    if file == null:
        push_error("Could not write file: " + path)
        return

    file.store_string(text)
    file.close()
