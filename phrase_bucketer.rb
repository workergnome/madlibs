require 'engtagger'

class PhraseBucketer

  attr_reader :phrase_buckets, :name, :tagged_phrase_buckets, :removed_nouns

  NOUN_WILDCARD = "--NOUN--"

  # A character used to stand in for a period during parsing.  Only used internally.
  FAKE_PERIOD = "\u2024"

  TITLES = [ "Mme.", "Mlle.", "Mr.", "Mrs.", "M.", "Col.", "Sgt.", "Dr.", "Capt.","Hon.", "Prof."]
  NAME_SUFFIXES = ["Esq.","Ph.D","Jr.", "Sr."]

  # A list of abbreviations.  A "." following any of these will not signify a new period.
  ABBREVIATIONS  = TITLES + NAME_SUFFIXES + [
                    "no.", "No.", "anon.", 'ca.', 'lot.', "illus.", "Miss.",
                    "Co.", "inc.", "Inc.", 
                    "Ltd.", "Dept.", 
                    "P.",  "DC.", "D.C.",
                    "Thos.",
                    'Ave.', "St.", "Rd.",
                    'Jan.', "Feb.", "Mar.", "Apr.", "Jun.", "Jul.", "Aug.", "Sept.", "Sep.", "Oct.", "Nov.", "Dec."]

  def initialize(name)
    @removed_nouns = []
    @name = name
    @tgr = EngTagger.new   
    @phrase_buckets = {1 => [], 2 => []}
    @tagged_phrase_buckets = {1=> [], 2 => []}
  end


  def substitute_periods(text)
    begin
      modified = text.gsub(/b\.\s?(\d{4})/, "b#{FAKE_PERIOD} \\1") || text  # born
      modified.gsub!(/d\.\s?(\d{4})/, "d#{FAKE_PERIOD} \\1")   # died
      initials = modified.scan(/(?:^|\s|\()((?:[A-Zc]\.)+)/) # initials, circas
      initials.each do |i|
        modified.gsub!(i[0],i[0].gsub(".",FAKE_PERIOD,))
      end
      ABBREVIATIONS.each do |title|
       mod_title = title.gsub('.','\.')
       modified.gsub!(/\b#{mod_title}/, mod_title.gsub('\.',FAKE_PERIOD))
      end
      return modified
    rescue => e
      puts "Problem : #{e}"
      return nil
    end
  end

  def add_text(text)
    return [] if text.nil?
    text = substitute_periods(text)
    return [] if text.nil?
    punctuations = text.scan(/[\.\!\?;]/)
    phrases = text.gsub(/["”\(\)]/," ").gsub("\n"," ").split(/[\.\!\?;]/).collect.with_index do |s,i|
      s = s.strip.gsub(FAKE_PERIOD,".")
      phrase =  s.strip
      tagged_readable_phrase = @tgr.get_readable(phrase)
      tagged_phrase = @tgr.add_tags(phrase)
      nouns = @tgr.get_nouns(tagged_phrase)
      proper = @tgr.get_proper_nouns(tagged_phrase)

      if proper && proper.count > 0
        next
      end
      
      nouns.each do |noun,val|
        s = NOUN_WILDCARD
        s += "s" if tagged_readable_phrase.include?(" #{noun}/NNS ")        
        phrase.gsub!(" #{noun} ", " #{s} ")
        @removed_nouns.push noun
      end if nouns
      phrase_words = phrase.split(" ")
      number_of_nouns = (phrase.split(NOUN_WILDCARD).count) -1
#      puts phrase, number_of_nouns
      if number_of_nouns < 3 && 
         phrase_words.count > 5 && 
         number_of_nouns > 0 &&
         phrase_words.count < 14 && 
         phrase[0] =~ /[A-Z]/
         @phrase_buckets[number_of_nouns].push(phrase + (punctuations[i].gsub(";","."))) rescue nil
         phrase
      else
        nil
      end
    end.compact.uniq
    @removed_nouns = @removed_nouns.compact.uniq.sort
  end
end