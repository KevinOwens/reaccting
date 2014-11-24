require 'sinatra/base'
require 'sinatra/json'
require 'json'
require 'mongoid'
Dir['./models/*.rb'].each { |file| require file }

class Reaccting < Sinatra::Base
  configure :development do 
    set :bind, '0.0.0.0'
    enable :logging, :dump_errors, :run, :sessions
    Mongoid.load!("config/mongoid.yml")
  end

  configure :production do
    require 'newrelic_rpm'
    enable :logging, :dump_errors, :run, :sessions
    Mongoid.load!("config/mongoid.yml")
  end

  ### API ###
  get '/status' do 
    "ok"
  end

  get '/stats' do 
    {count: Sample.count}.to_s
  end

  post '/v1/samples' do 
    if request.form_data?
      data = request.body.string
      boundary, file_info, *data = data.split("\n")
      ending_boundary = data.pop

      data.each_with_index do |sample, idx|
        begin 
          parse_and_store_sample(sample)
        rescue Exception => e
          puts "Error: #{e}"
        end
      end
    end

    200
  end

  private
  def from_milliseconds val
    val.to_i / 1000 
  end

  def parse_and_store_sample sample, timestamp=Time.now
    s = JSON.parse(sample)
    beacons = s["b"].map{|b| {mac: b["mac"], rssi: b["rssi"]}}
    Sample.create({
      device_id: s["d"],
      timestamp: from_milliseconds(s["t"]), 
      gps_accuracy: s["a"],
      lonlat: s["p"],
      beacons: beacons, 
      filename: build_filename(s["d"], timestamp)
    })
  end

  def build_filename device_id, timestamp
    "#{device_id}_#{timestamp.strftime("%Y_%m_%d_%T%z")}"
  end
end
