require_relative 'test_helper'

class ReacctingTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Reaccting
  end

  def test_file_path
    File.dirname(__FILE__) + '/data_sample.txt'
  end

  def uploaded_file
    Rack::Test::UploadedFile.new(test_file_path)
  end

  def test_status
    get '/status'
    assert_equal 200, last_response.status
    assert_equal "ok", last_response.body
  end

  def test_stats
    load_db; dump_sample_collection; assert_equal 0, Sample.count
    header 'Content-Type', 'multipart/form-data; boundary=----------------------------0715f70eb17843a6b17832b3d38fe558'
    post '/v1/samples', uploaded_file

    get '/stats'
    assert_equal 200, last_response.status
    assert_equal "{:count=>6}", last_response.body

    dump_sample_collection; assert_equal Sample.count, 0
  end

  def test_samples_post
    #make sure the db is connected and empty
    load_db; dump_sample_collection; assert_equal 0, Sample.count

    #set the header/content-type to form-data and make the POST
    header 'Content-Type', 'multipart/form-data; boundary=----------------------------0715f70eb17843a6b17832b3d38fe558'
    post '/v1/samples', uploaded_file
    assert_equal 200, last_response.status

    #assert that the samples got stored
    assert_equal 6, Sample.count

    #assert that all the values got set properly
    s = Sample.first

    assert_equal "862308023701042", s.device_id
    assert_equal 1416563994, s.timestamp.to_i
    assert_equal 12.0, s.gps_accuracy
    assert_equal [10.8810131,-1.0885678], s.lonlat
    assert_equal [], s.beacons
    assert_equal false, s.filename.nil?
    refute_nil s.updated_at
    refute_nil s.created_at

    #dump the collection and make sure its empty
    dump_sample_collection; assert_equal Sample.count, 0
  end

  private
  def load_db
    Mongoid.load!("config/mongoid.yml")
  end

  def dump_sample_collection
    Sample.delete_all
  end
end
