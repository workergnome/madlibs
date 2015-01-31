require 'engtagger'

class PhraseBucketer

  attr_reader :phrase_buckets, :name

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
    @name = name
    @tgr = EngTagger.new   
    @phrase_buckets = {1 => [], 2 => []}
  end


  def substitute_periods(text)
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
    modified
  end

  def add_text(text)
    text = substitute_periods(text)
    punctuations = text.scan(/[\.\!\?;]/)
    phrases = text.gsub(/["”\(\)]/," ").gsub("\n"," ").split(/[\.\!\?;]/).collect.with_index do |s,i|
      s = s.strip.gsub(FAKE_PERIOD,".")
      phrase =  s.strip
      tagged_phrase = @tgr.add_tags(phrase)
      nouns = @tgr.get_nouns(tagged_phrase)
      proper = @tgr.get_proper_nouns(tagged_phrase)

      if proper && proper.count > 0
        next
      end
      
      nouns.each do |noun,val|
        phrase.gsub!(" #{noun} ", " #{NOUN_WILDCARD} ")
      end if nouns
      phrase_words = phrase.split(" ")
      if phrase_words.count(NOUN_WILDCARD) < 3 && 
         phrase_words.count > 5 && 
         phrase_words.count(NOUN_WILDCARD) > 0 &&
         phrase_words.count < 14 && 
         phrase[0] =~ /[A-Z]/
         @phrase_buckets[phrase_words.count(NOUN_WILDCARD)].push(phrase + (punctuations[i].gsub(";","."))) rescue nil
         phrase
      else
        nil
      end
    end.compact
  end

end