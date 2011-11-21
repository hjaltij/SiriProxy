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

#######
# This is a very basic plugin for Plex but I plan on adding to it =)
# Eventually I'd like to have it talk to the SQLite DB that stores all the media information for Plex
# That way you could ask Siri to play the latest episode of i.e. Mythbusters
# Now it only supports pause, play and stop

# Remember to configure the host and port for your Plex Media Server below
######

PLAY_COMMAND = "play"
PAUSE_COMMAND = "pause"
STOP_COMMAND = "stop"

class SiriPlex < SiriPlugin

  #Plex Remote Implementation
  #Needs a lot more functionality

  def initialize()
    @host = "YOUR PLEX HOST"
    @port = "YOUR PLEX PORT" #default port is 32400
  end

  def run_playback_command(command)
    uri = "http://#{@host}:#{@port}/system/players/#{@host}/playback/#{command}"
    response = open(uri).read
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

  def speech_recognized(object, connection, phrase)

    #We need to do this here because otherwise Siri thinks we are asking it to play music
    #from our iPhone's music library

    if(phrase.match(/plex/i))
      response = nil

      if(phrase.match(/pause/i))
        self.plugin_manager.block_rest_of_session_from_server	
        pause()
        response = "Pausing Plex"
      elsif(phrase.match(/play/i) || phrase.match(/resume/i))
        self.plugin_manager.block_rest_of_session_from_server	
        play()
        response = "Playing Plex"
      elsif(phrase.match(/stop/i))
        self.plugin_manager.block_rest_of_session_from_server	
        stop()
        response = "Stopping Plex"
      end

      if(response)
        return generate_siri_utterance(connection.lastRefId, response)
      end
    end

    object
  end

end