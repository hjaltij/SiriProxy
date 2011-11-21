# Copyright (C) 2011 by Hjalti Jakobsson <hjalti@hjaltijakobsson.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rubygems'
require 'tweaksiri'
require 'siriobjectgenerator'
require 'open-uri'
require 'rexml/document'
require 'plugins/plex/plex_library'

#######
# This is a very basic plugin for Plex but I plan on adding to it =)
# Eventually I'd like to have it talk to the SQLite DB that stores all the media information for Plex
# That way you could ask Siri to play the latest episode of i.e. Mythbusters
# Now it only supports pause, play and stop

# Remember to configure the host and port for your Plex Media Server below
######


#These commands are not enabled right now
PLAY_COMMAND = "play"
PAUSE_COMMAND = "pause"
STOP_COMMAND = "stop"

PLEX_HOST = "10.0.1.75" #Change this so it matches your Plex install
PLEX_PORt = 32400

class SiriPlex < SiriPlugin

  #Plex Remote Implementation
  #Needs a lot more functionality

  def initialize()
    @host = PLEX_HOST
    @port = 32400
  end

  def run_playback_command(command)
    uri = "http://#{@host}:#{@port}/system/players/#{@host}/playback/#{command}"
    response = open(uri).read
  end
  
  def play_media(key)
    url_encoded_key = CGI::escape(key)
    uri = "http://#{@host}:#{@port}/system/players/#{@host}/application/playMedia?key=#{url_encoded_key}&path=http://#{@host}:#{@port}#{key}"
    open(uri).read
  end

  def pause()
    run_playback_command(PAUSE_COMMAND)
  end

  def play()
    run_playback_command(PLAY_COMMAND)
  end

  def stop()
    run_playback_command(STOP_COMMAND)
  end

  #plugin implementations:
  def object_from_guzzoni(object, connection)

  object
  end

  #Don't forget to return the object!
  def object_from_client(object, connection)
    object
  end

  def unknown_command(object, connection, command)
    object
  end
  
  def map_siri_numbers_to_int(number)
    ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"].index(number)
  end

  def speech_recognized(object, connection, phrase)

    #We need to do this here because otherwise Siri thinks we are asking it to play music
    #from our iPhone's music library
    
    #At the moment it eats all play/playing commands, since it had a hard time understanding Plex.
    #might just be an issue with my acccent =)
    
    if(phrase.match(/(play|playing) (the)? latest(.+) of(.+)/i))
      
      self.plugin_manager.block_rest_of_session_from_server
      
      response = nil      
      show_title = $4
      
      library = PlexLibrary.new(@host, port)
      show = library.find_show(show_title)      
      episode = library.latest_episode(show)
      
      if(episode != nil)
        play_media(episode.key)
        response = "Playing \"#{episode.title}\""
      else
        response = "I'm sorry but I couldn't find the episode you asked for"
      end
      
      if(response)
        return generate_siri_utterance(connection.lastRefId, response)
      end
      
    elsif(phrase.match(/(play|playing) (.+)\sepisode/i))
      
      self.plugin_manager.block_rest_of_session_from_server
      response = nil      
      library = PlexLibrary.new("10.0.1.75", 32400)
      
      show_title = $2
      if(phrase.match(/episode\s([0-9]+|one|two|three|four|five|six|seven|eight|nine|ten)/))        
        episodeNumber = $1
        
        if(phrase.match(/season\s([0-9]+|one|two|three|four|five|six|seven|eight|nine|ten)/))          
          seasonNumber = $1          
          if(seasonNumber.to_i == 0)
            seasonNumber = map_siri_numbers_to_int(seasonNumber)
          end          
        else
          seasonNumber = 1
        end
        
        show = library.find_show(show_title)
        
        if(episodeNumber.to_i == 0)
          episodeNumber = map_siri_numbers_to_int(episodeNumber)
        end
        
        episode = library.find_episode(show, seasonNumber, episodeNumber)
        
        if(episode != nil)
          play_media(episode.key)
          response = "Playing \"#{episode.title}\""
        else
          response = "I'm sorry but I couldn't find the episode you asked for"
        end
      end

      if(response)
        return generate_siri_utterance(connection.lastRefId, response)
      end
    end

    object
  end

end