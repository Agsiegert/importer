EXPORT_PATH = Rails.root.join("tmp/scrivito_export")
EXPORT_FILE = "objs.json"
$links = {}

def import
  raw_content = File.read(File.join(EXPORT_PATH, EXPORT_FILE))
  content = JSON.parse(raw_content)
  content.each do |json_content|
    json_to_object(json_content)
  end
end

def json_to_object(obj_json)
  return unless ruby_class_exists?(obj_json["_obj_class"])
  obj_attr = build_attr(obj_json, obj_json["id"])
  Obj.create(obj_attr)
end

def ruby_class_exists?(class_name)
  begin
    class_name.constantize
    true
  rescue
    false
    unless class_name == "MigrationStore" # MigrationStore is an internal SDK class used only once during setup
      puts "*** error: #{class_name} class may have moved or no longer exists, manual import of this object type required if needed"
    end
  end
end

def build_attr(obj_json, obj_id, widget_id = nil)
  obj_json.inject({}) do |attr, (attr_name, attr_json)|
    if attr_name == "_last_changed"
    elsif attr_name == "id"
      attr["_id"] = attr_json
    else
      value = json_to_attr(attr_json, { obj_id: obj_id, widget_id: widget_id, attr_name: attr_name })
      attr[attr_name] = value if value
    end
    attr
  end
end

def json_to_attr(value, content_desc)
  return if !value
  if value.is_a?(String)
    value
  elsif value.is_a?(Array) # export script does not produce stringlist
    value
  elsif value["reference"]
    value["reference"]
  elsif value["referencelist"]
    value["referencelist"]
  elsif value["date"]
    Date.parse(value["date"])
  elsif value["link"]
    $links[content_desc] = value
    nil
  elsif value["links"]
    $links[content_desc] = value
    nil
  elsif value["file"]
    Scrivito::Binary.upload(value["file"])
  elsif value["widgets"]
    value["widgets"].map do |widget_json|
      json_to_widget(widget_json, content_desc[:obj_id])
    end.compact
  end
end

def json_to_widget(widget_json, obj_id)
  return unless ruby_class_exists?(widget_json["_obj_class"])
  widget_attr = build_attr(widget_json, obj_id, widget_json["id"])
  Widget.new(widget_attr)
end

def build_links
  $links.each do |content_desc, link_json|
    content = if content_desc[:widget_id]
      Obj.find(content_desc[:obj_id]).widgets[content_desc[:widget_id]]
    else
      Obj.find(content_desc[:obj_id])
    end
    value = if link_json["link"]
      build_link(link_json["link"])
    else
      link_json["links"].map do |lj|
        build_link(lj)
      end
    end
    update_hash = {}
    update_hash[content_desc[:attr_name]] = value
    content.update(update_hash)
  end
end

def build_link(lj)
  if lj["id"]
    lj["obj"] = Obj.find(lj["id"])
    Scrvito::Link.new(lj)
  else
    Scrivito::Link.new(lj)
  end
end

Scrivito::Workspace.find_by_title("import workspace").try(:destroy)
Scrivito::Workspace.current = Scrivito::Workspace.create(title: "import workspace")

import
build_links

