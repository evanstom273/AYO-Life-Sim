@tool
extends EditorScript

const ICON_ROOT: String = "res://assets/Icons"
const TARGET_COLOUR: String = "#FFFFFF"
const MAKE_BACKUPS: bool = true


func _run() -> void:
    var svg_paths: Array[String] = []
    _collect_svg_files(ICON_ROOT, svg_paths)

    var changed_count: int = 0

    for path: String in svg_paths:
        var original_text: String = FileAccess.get_file_as_string(path)
        var updated_text: String = original_text

        # Remove baked-in white rounded-square/icon-tile backgrounds.
        updated_text = _remove_full_canvas_background_rects(updated_text)

        # Make remaining icon strokes/fills tintable from white.
        updated_text = _replace_attribute_value(updated_text, "stroke", TARGET_COLOUR)
        updated_text = _replace_attribute_value(updated_text, "fill", TARGET_COLOUR)
        updated_text = _replace_style_property(updated_text, "stroke", TARGET_COLOUR)
        updated_text = _replace_style_property(updated_text, "fill", TARGET_COLOUR)

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
    print("SVG icon cleanup complete")
    print("SVG files found: ", svg_paths.size())
    print("SVG files changed: ", changed_count)
    print("----------------------------------------")
    print("Now right-click res://assets/Icons and Reimport.")


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


# ------------------------------------------------------------
# Remove baked-in icon tile backgrounds
# ------------------------------------------------------------

func _remove_full_canvas_background_rects(source_text: String) -> String:
    var regex: RegEx = RegEx.new()
    var error: int = regex.compile("<rect\\b[^>]*\\/?>\\s*(?:<\\/rect>)?")

    if error != OK:
        push_error("Failed to compile rect cleanup regex")
        return source_text

    var result: String = ""
    var last_index: int = 0
    var matches: Array[RegExMatch] = regex.search_all(source_text)

    for match_result: RegExMatch in matches:
        var tag_start: int = match_result.get_start(0)
        var tag_end: int = match_result.get_end(0)
        var rect_tag: String = match_result.get_string(0)

        result += source_text.substr(last_index, tag_start - last_index)

        if not _is_full_canvas_background_rect(rect_tag):
            result += rect_tag
        else:
            print("Removed baked-in icon background rect: ", rect_tag)

        last_index = tag_end

    result += source_text.substr(last_index)
    return result


func _is_full_canvas_background_rect(rect_tag: String) -> bool:
    var width_value: String = _get_attribute(rect_tag, "width")
    var height_value: String = _get_attribute(rect_tag, "height")

    if not _is_full_canvas_dimension(width_value):
        return false

    if not _is_full_canvas_dimension(height_value):
        return false

    var fill_value: String = _get_attribute(rect_tag, "fill")

    if fill_value == "":
        fill_value = _get_style_property(rect_tag, "fill")

    if not _is_white_or_current_colour(fill_value):
        return false

    var stroke_value: String = _get_attribute(rect_tag, "stroke")

    if stroke_value == "":
        stroke_value = _get_style_property(rect_tag, "stroke")

    # Do not remove icon-like outlined rectangles.
    if stroke_value != "" and not _should_preserve_svg_value(stroke_value):
        return false

    return true


func _is_full_canvas_dimension(value: String) -> bool:
    var clean_value: String = value.strip_edges().to_lower()

    if clean_value == "100%":
        return true

    clean_value = clean_value.replace("px", "")

    if not clean_value.is_valid_float():
        return false

    var number_value: float = clean_value.to_float()

    return is_equal_approx(number_value, 24.0)


func _is_white_or_current_colour(value: String) -> bool:
    var clean_value: String = value.strip_edges().to_lower().replace(" ", "")

    return clean_value in [
        "#fff",
        "#ffffff",
        "white",
        "currentcolor",
		"rgb(255,255,255)"
    ]


# ------------------------------------------------------------
# Replace colour attributes
# ------------------------------------------------------------

func _replace_attribute_value(source_text: String, attribute_name: String, new_value: String) -> String:
    var regex: RegEx = RegEx.new()
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
            result += new_value

        last_index = value_end

    result += source_text.substr(last_index)
    return result


func _replace_style_property(source_text: String, property_name: String, new_value: String) -> String:
    var regex: RegEx = RegEx.new()
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
            result += new_value

        last_index = value_end

    result += source_text.substr(last_index)
    return result


func _should_preserve_svg_value(value: String) -> bool:
    var lower_value: String = value.strip_edges().to_lower()

    if lower_value == "":
        return true

    return (
        lower_value == "none"
        or lower_value == "transparent"
        or lower_value.begins_with("url(")
    )


# ------------------------------------------------------------
# Attribute/style helpers
# ------------------------------------------------------------

func _get_attribute(source_text: String, attribute_name: String) -> String:
    var regex: RegEx = RegEx.new()
    var error: int = regex.compile(attribute_name + "\\s*=\\s*(['\"])(.*?)\\1")

    if error != OK:
        return ""

    var match_result: RegExMatch = regex.search(source_text)

    if match_result == null:
        return ""

    return match_result.get_string(2)


func _get_style_property(source_text: String, property_name: String) -> String:
    var regex: RegEx = RegEx.new()
    var error: int = regex.compile(property_name + "\\s*:\\s*([^;'\"}]+)")

    if error != OK:
        return ""

    var match_result: RegExMatch = regex.search(source_text)

    if match_result == null:
        return ""

    return match_result.get_string(1).strip_edges()


func _write_text_file(path: String, text: String) -> void:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)

    if file == null:
        push_error("Could not write file: " + path)
        return

    file.store_string(text)
    file.close()
