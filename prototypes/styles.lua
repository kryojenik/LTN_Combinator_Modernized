--require("__flib__.gui")
local styles = data.raw["gui-style"].default

styles["ltnc_entry_sprite"] = {
    type   = "image_style",
    parent = "image",
    size = 32,
    left_padding=2,
    stretch_image_to_widget_size = true,
  }
  
  styles["ltnc_entry_label"] = {
    type   = "label_style",
    parent = "caption_label",
    horizontally_stretchable = "on",
  }
  
    styles["signal_count"] = {
    type = "label_style",
    parent = "count_label",
    size = 36,
    width = 36,
    horizontal_align = "right",
    vertical_align = "bottom",
    right_padding = 2,
  }
  
  styles["ltnc_entry_text"] = {
    type   = "textbox_style",
    parent = "short_number_textfield",
    horizontal_align = "right",
    horizontally_stretchable = "off",
  }
  
  styles["ltnc_entry_checkbox"] = {
    type   = "checkbox_style",
    parent = "checkbox",
    left_margin = 34,
    horizontally_stretchable = "off",
  }

  styles["ltnc_net_id_button"] = {
    type = "button_style",
    parent = "flib_standalone_slot_button_grey",
    size = 28,
    font = "default-small",
  }
  
  styles["ltnc_net_id_button_pressed"] = {
    type = "button_style",
    parent = "flib_selected_standalone_slot_button_grey",
    size = 28,
    font = "default-small",
  }