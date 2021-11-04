#!/bin/ruby
require 'test/unit'
require File.expand_path('../boot',__FILE__)

class TestEtlPipline < Test::Unit::TestCase

  class SampleETL < ActiveRecord::Base
    include  EtlPipline
  end

  class SampleETL2 < ActiveRecord::Base
    include EtlPipline
    self.seg_name = 'seg_hour'
  end


  def test_set_seg_name()
    assert_equal SampleETL.seg_name, 'seg_date'
    assert_equal SampleETL2.seg_name, 'seg_hour'
  end
end
