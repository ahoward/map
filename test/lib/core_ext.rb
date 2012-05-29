class Object
  def blank?
    nil? or empty?
  end
end

class String
  def underscore
    self
  end
end
