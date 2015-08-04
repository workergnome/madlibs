require_relative 'phrase_bucketer.rb'

MAX_TEXTS = 100

corpuses = []

dirs = Dir['./texts/*/']
dirs.each do |d|
  name = d.split("/").last
  bucketer = PhraseBucketer.new(name)
  corpus = Dir.glob("#{d}*.txt")
  next if corpus.empty?
  corpus.shuffle.each_with_index do |text,i|
    next if i > MAX_TEXTS
    bucketer.add_text(File.read(text))
  end
  corpuses.push(bucketer)
end

Dir.mkdir "output" unless Dir.exists? ("output")
corpuses.each do |bucket|
  bucket.phrase_buckets.each do |k,v|
    File.open("output/#{bucket.name}_#{k}.txt", "w") do |file|
      v.each {|line| file.puts line.gsub(/\s{2,}/," ")}
    end 
  end
  File.open("output/#{bucket.name}_removed_nouns.txt", "w") do |file|
    bucket.removed_nouns.each do |noun|
      file.puts noun
    end
  end   
  # bucket.tagged_phrase_buckets.each do |k,v|
  #   File.open("output/tagged_#{bucket.name}_#{k}.txt", "w") do |file|
  #     v.each {|line| file.puts line }
  #   end 
  # end
end