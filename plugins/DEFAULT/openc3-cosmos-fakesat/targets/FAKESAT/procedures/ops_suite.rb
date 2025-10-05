require 'openc3/script/suite.rb'
load_utility 'FAKESAT/lib/fake_sat.rb'

class CollectGroup < OpenC3::Group
  def script_normal_collect
    puts "Running #{OpenC3::Group.current_suite}:#{OpenC3::Group.current_group}:#{OpenC3::Group.current_script}"
    OpenC3::Group.puts "Perform Normal Collect"

    cmd_cnt = tlm("FAKESAT HEALTH_STATUS CMD_ACPT_CNT")
    collect_cnt = tlm("FAKESAT IMAGER COLLECTS")
    cmd("FAKESAT COLLECT with TYPE NORMAL, DURATION 5")
    wait_check("FAKESAT HEALTH_STATUS CMD_ACPT_CNT == #{cmd_cnt + 1}", 5)
    wait_check("FAKESAT IMAGER COLLECTS == #{collect_cnt + 1}", 5)
    wait_check("FAKESAT IMAGER COLLECT_TYPE == 'NORMAL'", 5)
  end

  def script_special_collect
    puts "Running #{OpenC3::Group.current_suite}:#{OpenC3::Group.current_group}:#{OpenC3::Group.current_script}"
    OpenC3::Group.puts "Perform Special Collect"

    cmd_cnt = tlm("FAKESAT HEALTH_STATUS CMD_ACPT_CNT")
    collect_cnt = tlm("FAKESAT IMAGER COLLECTS")
    cmd("FAKESAT COLLECT with TYPE SPECIAL, DURATION 5")
    wait_check("FAKESAT HEALTH_STATUS CMD_ACPT_CNT == #{cmd_cnt + 1}", 5)
    wait_check("FAKESAT IMAGER COLLECTS == #{collect_cnt + 1}", 5)
    wait_check("FAKESAT IMAGER COLLECT_TYPE == 'SPECIAL'", 5)
  end
end

class ModeGroup < OpenC3::Group
  def script_safe
    fakesat = FakeSat.new
    fakesat.safe
  end
  def script_checkout
    fakesat = FakeSat.new
    fakesat.checkout
  end
  def script_operate
    fakesat = FakeSat.new
    fakesat.operate
  end
end

class OpsSuite < OpenC3::Suite
  def initialize
    super()
    add_group('CollectGroup')
    add_group('ModeGroup')
  end
end
