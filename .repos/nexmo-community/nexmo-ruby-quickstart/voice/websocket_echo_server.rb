require 'dotenv'
require 'faye/websocket'
require 'json'
require 'sinatra'
require 'thin'

Dotenv.load

FROM_NUMBER = ENV['FROM_NUMBER']

# See https://developer.nexmo.com/concepts/guides/webhooks for more instructions

Faye::WebSocket.load_adapter('thin')

get '/' do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env)

    ws.on(:open) do |event|
      puts 'client connected'
    end

    ws.on(:message) do |event|
      #Check if message is Binary or Text
      if event.data.is_a? Array
        #Echo the binary message back to where it came from
        ws.send(event.data)
      else
        puts event.data
      end
    end

    ws.on(:close) do |event|
      puts 'client disconnected'
      ws = nil
    end

    ws.on(:error) do |event|
      puts 'client error'
      puts event.message
    end

    ws.rack_response
  end
end

get '/ncco' do
  content_type :json
  [
    {
      "action": "connect",
      "eventUrl": [
        "#{base_url}/events"
      ],
      "from": "#{FROM_NUMBER}",
      "endpoint": [
        {
          "type": "websocket",
          "uri": "ws://#{request.env['HTTP_HOST']}/socket",
          "content-type": "audio/l16;rate=16000"
        }
      ]
    }
  ].to_json
end

post '/event' do
  puts params
end

def base_url
  @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
end
