data.raw["gui-style"].default["ltnc_entry_sprite"] = {
    type   = "image_style",
    parent = "image",
    size = 32,
    left_padding=2,
    stretch_image_to_widget_size = true,
  }
  
  data.raw["gui-style"].default["ltnc_entry_label"] = {
    type   = "label_style",
    parent = "caption_label",
    horizontally_stretchable = "on",
  }
  
  data.raw["gui-style"].default["ltnc_entry_text"] = {
    type   = "textbox_style",
    parent = "short_number_textfield",
    horizontal_align = "right",
    horizontally_stretchable = "off",
  }
  
  data.raw["gui-style"].default["ltnc_entry_checkbox"] = {
    type   = "checkbox_style",
    parent = "checkbox",
    left_margin = 34,
    horizontally_stretchable = "off",
  }