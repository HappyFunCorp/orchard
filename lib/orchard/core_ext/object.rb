class Object

  # Coped from activesupport because it's useful but doesn't justify pulling in
  # activesupport dependencies:
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end

end
