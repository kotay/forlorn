module GentlemanHelper
  def gentleman_show_view(gentleman)
    name = gentleman.short_type.underscore
    if File.exists?(Rails.root.join("app", "views", "gentlemen", "gentleman_views", name, "_show.html.erb"))
      File.join("gentlemen", "gentleman_views", name, "show")
    end
  end

  def gentleman_show_class(gentleman)
    gentleman.short_type.underscore.dasherize
  end
end