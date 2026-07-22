module ApplicationHelper
  # Helper method to get error class for form fields
  def field_error_class(object, field)
    object.errors[field].any? ? "is-invalid" : ""
  end

  # Helper method to display field error message
  def field_error_message(object, field)
    if object.errors[field].any?
      content_tag :div, class: "invalid-feedback d-block" do
        object.errors[field].first
      end
    end
  end
end
