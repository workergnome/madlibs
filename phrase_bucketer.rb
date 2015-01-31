require 'engtagger'

class PhraseBucketer

  attr_reader :phrase_buckets, :name

  NOUN_WILDCARD = "--NOUN--"

  def initialize(name)
    @name = name
    @tgr = EngTagger.new   
    @phrase_buckets = {1 => [], 2 => [], 3 => [], 4 => [], 5 =>[]}
  end

  def add_text(text)
    phrases = text.gsub(/["”\(\)]/," ").gsub("\n"," ").split(/[\.\:\!\?;]/).collect do |s|
      phrase =  s.strip
      tagged_phrase = @tgr.add_tags(phrase)
      nouns = @tgr.get_nouns(tagged_phrase)
      
      nouns.each do |noun,val|
        phrase.gsub!(" #{noun} ", " #{NOUN_WILDCARD} ")
      end if nouns
      phrase_words = phrase.split(" ")
      if phrase_words.count(NOUN_WILDCARD) < 6 && 
         phrase_words.count > 5 && 
         phrase_words.count(NOUN_WILDCARD) > 0 &&
         phrase[0] =~ /[A-Z]/
         @phrase_buckets[phrase_words.count(NOUN_WILDCARD)].push phrase
         phrase
      else
        nil
      end
    end.compact
  end

end