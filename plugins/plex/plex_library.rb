require 'plugins/plex/plex_show'
require 'plugins/plex/plex_season'
require 'plugins/plex/plex_episode'

class PlexLibrary
  def initialize(host, port)
    @host = host
    @port = port
  end
  
  def base_path
    "http://#{@host}:#{@port}"
  end
  
  def xml_doc_for_path(path)
    uri = "#{base_path}#{path}"
    xml_data = open(uri).read
    doc = REXML::Document.new(xml_data)
  end
  
  def all_shows
    doc = xml_doc_for_path("/library/sections/2/all")
    shows = []

    doc.elements.each('MediaContainer/Directory') do |ele|
      shows << PlexShow.new(ele.attribute("key").value, ele.attribute("title").value)
    end

    return shows
  end
  
  def show_seasons(show)
    
    if(show.key != nil)
      uri = "http://#{@host}:#{@port}#{show.key}"
      
      xml_data = open(uri).read
      doc = REXML::Document.new(xml_data)
      seasons = []
      
      doc.elements.each('MediaContainer/Directory') do |ele|
        if(ele.attribute("key").value !~ /allLeaves/)
          seasons << PlexSeason.new(ele.attribute("key").value, ele.attribute("title").value, ele.attribute("index").value)
        end
      end
      
      return seasons
    end
    
  end
  
  def show_episodes(show)
    if(show != nil && show.key != nil)
      doc = xml_doc_for_path(show.key)
      episodes = []
      
      key = nil
      
      doc.elements.each('MediaContainer/Directory') do |ele|
        if(ele.attribute("key").value =~ /allLeaves/)
          key = ele.attribute("key")
        end
      end
      
      if(key == nil && doc.elements.size > 0)
        doc.elements.each('MediaContainer/Directory') do |ele|
          key = ele.attribute("key")
        end
      end
      
      episodes_doc = xml_doc_for_path(key)
      
      episodes_doc.elements.each('MediaContainer/Video') do |video_element|
        parentIndex = video_element.attribute("parentIndex") ? video_element.attribute("parentIndex").value : 1
        episodes << PlexEpisode.new(video_element.attribute("key").value, video_element.attribute("title").value, parentIndex, video_element.attribute("index").value)
      end
      
      return episodes
    end
  end
  
  def find_show(title)    
    splitted = title.split(" ").join("|")    
    shows = all_shows    
    shows.detect {|s| s.title.match(/#{splitted}/i)}
  end
  
  def find_episode(show, season_index, episode_index)
    if(show != nil)
      episodes = show_episodes(show)
      episodes.find {|e| e.episode_index == episode_index && e.season_index == season_index}
    end
  end
  
  def latest_episode(show)
    show_episodes(show).sort.last
  end
  
end