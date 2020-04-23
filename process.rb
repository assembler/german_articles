require 'rubygems'
require 'bundler'
Bundler.require
require 'ostruct'

data = File.read("#{__dir__}/lexicon.xml")
doc = Nokogiri.XML(data)
nouns = []

def article_of(inf)
  case inf
  when /^N(ame-)?Neut/ then :das
  when /^N(ame-)?Fem/ then :die
  when /^N(ame-)?Masc/ then :der
  end
end

doc.xpath('//BaseStem').each do |stem|
  noun = stem.at_xpath('Lemma').content
  next if noun.empty?

  inf_class = stem.at_xpath('InfClass').content
  article = article_of(inf_class)
  next unless article

  nouns << [noun.downcase, article]
end
total_nouns = nouns.length

endings = Set.new
max_ending_length = 6
nouns.each do |noun, _article|
  max_ending_length.times do |n|
    break if n >= noun.length
    endings.add noun[-n..]
  end
end

colors = { der: :blue, die: :red, das: :green }
report = []
endings.sort.each do |ending|
  stats = { der: 0, die: 0, das: 0 }
  words = []
  matches = 0

  nouns.each do |noun, article|
    next unless noun.end_with?(ending)
    stats[article] += 1
    words << noun
    matches += 1
  end
  next unless matches >= 30

  %i[der die das].detect do |article|
    percent = (100.0 * stats[article] / matches).round
    score = stats[article] / (matches + 1.0)
    next unless score > 0.80

    samples = words.sample(3).map { |w| "#{article} #{w}" }

    report << OpenStruct.new(
      ending: ending, article: article, percent: percent,
      samples: samples, matches: matches, score: score
    )
  end
end


report.sort_by! { |r| -r.score }
report.each do |r|
  color = colors[r.article]
  printf "[%s] [%4d %3d%%] %#{max_ending_length + 2}s :: %s\n".colorize(color),
    r.article, r.matches, r.percent, "-#{r.ending}", r.samples.join(', ')
end
