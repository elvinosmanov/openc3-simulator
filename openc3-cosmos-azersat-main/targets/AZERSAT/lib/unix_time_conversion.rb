# encoding: ascii-8bit

# Copyright 2022 OpenC3, Inc.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt

# Converts TIMESEC and TIMEUS to a Ruby Time object

require 'openc3/conversions/conversion'

module OpenC3
  class UnixTimeConversion < Conversion
    def initialize
      super()
      @converted_type = :RUBY_TIME
    end

    # Converts the packet time to a Ruby Time object
    #
    # @param value [Object] The current value
    # @param packet [Packet] The packet being processed
    # @param buffer [String] The raw buffer being processed
    # @return [Time] The converted time
    def call(value, packet, buffer)
      timesec = packet.read('TIMESEC', :RAW, buffer)
      timeus = packet.read('TIMEUS', :RAW, buffer)
      return Time.at(timesec, timeus)
    end

    # @return [String] The name of the class followed by the time format
    def to_s
      return "#{self.class.to_s.split('::')[-1]} Unix Time"
    end

    # @return [Hash] Configuration hash
    def to_config
      config = super()
      return config
    end
  end
end