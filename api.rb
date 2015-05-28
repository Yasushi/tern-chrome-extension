#!/usr/bin/ruby

require 'nokogiri'
require 'open-uri'
require 'json'
require 'time'

TProperty=Struct.new(:type, :name)
TParameter=Struct.new(:type, :name)
TType=Struct.new(:name, :props, :link)
TMethod=Struct.new(:fullname, :params, :return, :link, :doc)
TEvent=Struct.new(:fullname, :link)

def url(path)
  'https://developer.chrome.com/extensions/' + path
end

index=Nokogiri(open(url('api_index')))
stables=index.xpath('//h2[@id="stable_apis"]')[0].next_element.next_element.xpath("./tr/td[1]/a/@href").map(&:text)

version=index.xpath('//h2[@id="stable_apis"]')[0].next_element.next_element.xpath("./tr/td[3]").map(&:text).map(&:to_i).sort.last

puts "Chrome version: #{version}"

defs=stables.map do |name|
#defs=stables.grep(/alarms/).map do |name|
  pkgurl=url(name)
  pkg=Nokogiri(open(pkgurl))
  caution=pkg.css('p.caution')
  if not caution.empty?
    puts caution.map(&:text)
    puts "#{name} skip"
    next
  end
  pkg.css("div.api-reference").xpath('./div').map do |api|
    h3=api.xpath('./h3')[0]
    id=h3.attributes['id'].text
    link="#{pkgurl}##{id}"
    case id
    # when /^type-.*?Type/
    #   # ignore enum
    when /^type-/
      typename=h3.text.chomp
      props=api.xpath("./table/tr[starts-with(@id, 'property-#{typename}-')]").map {|prop| prop.xpath('./td').map(&:text).map(&:strip).map{|s|s.gsub(/[\n\t ]{2,}/,' ')}}.map{|s| TProperty.new(s[0], s[1])}
      TType.new(typename, props, link)
    when /^method-/
      summary=api.xpath("./div[@class='summary']")[0].text.strip.sub(/\(.*\)/, '').split(' ')
      ret=summary.length==2 ? summary[0] : nil
      fullname=summary[-1].split('.')
      description=api.xpath("./div[@class='description']/p").map(&:text).map(&:strip).join.sub(/\A([^.]+\.).*/m, "\\1")
      params=api.xpath("./div/table/tr[starts-with(@id, 'property-#{fullname[-1]}-')]").map {|prop| prop.xpath('./td').map(&:text).map(&:strip).map{|s|s.gsub(/[\n\t ]{2,}/,' ').sub(/\A([^.]+\.).*/m, "\\1")}}.map{|s| TParameter.new(s[0], s[1])}
      TMethod.new(fullname, params, ret, link, description)
    when /^event-/
      fullname=api.css("div.summary").text.strip.sub(/\(.*\)/, '').split('.')
      TEvent.new(fullname, link)
    else
      raise "unknown #{id} #{link}"
    end
  end
end.flatten

def _name(n)
  if /\A\(optional\) (.+)\z/ =~ n
    "#{$1}?"
  else
    n
  end
end

def _type(t)
  case t
  when "double"
    "number"
  when "object", / or /, "any"
    "?"
  when "Window"
    "window"
  when /array of (\w+)/
    "[#{_type($1)}]"
  when TMethod
    args=t.params.map{|pr|_name(pr.name)+": "+_type(pr.type)}.join(', ')
    "fn(#{args})" +(t.return ? " -> #{_type(t.return)}":"")
  else
    t
  end
end

r={
  "!name" => "chrome-extension",
  "!define" => {},
  "chrome" => {}
}

defs.select{|d| d.is_a?(TType)}.each do |d|
  r['!define'][d.name] = d.props.map{|pr|
    {
      pr.name.sub(/\A\(optional\) (.+)\z/,"\\1") => {
        "!type" => _type(pr.type),
        "!doc" => pr.name
     }
    }
  }
end

defs.select{|d| d.is_a?(TMethod)}.each do |d|
  m=d.fullname.inject(r){|r,n| r[n]||={}}
  m["!type"]=_type(d)
  m["!url"]=d.link
  m["!doc"]=d.doc
end

defs.select{|d| d.is_a?(TEvent)}.each do |d|
  m=d.fullname.inject(r){|r,n| r[n]||={}}
  m["!type"]="fn(callback: ?)"
  m["!url"]=d.link
end

open("chrome-extension.json","w"){|f| f.write(JSON.generate(r,indent:''))}
