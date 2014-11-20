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
    {
      count: Sample.count, 
      last_file: Sample.last.try(:filename)
    }.to_s
  end

  post '/v1/samples' do 
    puts "REQUEST Accept: #{request.accept}"
    puts "REQUEST BODY: #{request.body.read}"
    puts "MEDIA TYPE: #{request.media_type}"
    if request.form_data?
      filename = request.body.read.try(:original_filename)
      data = File.read(request.body)

      puts "FILENAME: #{filename}"
      puts "DATA: #{data}"

      data.split("\n").each do |sample|
        s = JSON.parse(sample)
        puts "Sample: #{s}"
        beacons = s["beacon"].map{|b| {mac: b["mac"], rssi: b["rssi"]}}

        Sample.create({
          device_id: s["imei"],
          timestamp: from_milliseconds(s["timestamp"]), 
          gps_accuracy: s["gps_accuracy"],
          lonlat: [s["long"], s["lat"]], 
          beacons: beacons, 
          filename: filename
        })
      end
    end

    200
  end

  private
  def from_milliseconds val
    val.to_i / 1000 
  end
end
