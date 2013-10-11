class Fixnum
  def projectize
    self.to_s.gsub(/\s/,'').downcase
  end
end
