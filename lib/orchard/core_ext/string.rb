class String
  def projectize
    gsub(/\s/,'').downcase
  end

  def strip_email
    gsub(/\s*<[^>]*>\s*/,'')
  end
end
