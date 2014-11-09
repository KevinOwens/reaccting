class Sample
  include Mongoid::Document
  include Mongoid::Timestamps

  field :device_id,     type: String
  field :timestamp,     type: DateTime
  field :gps_accuracy,  type: Float
  field :lonlat,        type: Array
  field :filename,      type: String
  field :beacons,       type: Array
end
