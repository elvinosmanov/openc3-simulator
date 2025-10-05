# encoding: ascii-8bit

# Copyright 2022 OpenC3, Inc.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# Simulates the AzerSat satellite used in COSMOS User Training

require 'openc3'

module OpenC3
  MAX_PWR_WATT_SECONDS = 100000
  INIT_PWR_WATT_SECONDS = 60000
  HYSTERESIS = 2.0

  # Simulated satellite for the training. Populates several packets and cycles
  # the telemetry to simulate a real satellite.
  class SimSat < SimulatedTarget
    def initialize(target_name)
      super(target_name)

      @target = System.targets[target_name]
      position_filename = File.join(@target.dir, 'data', 'position.bin')
      attitude_filename = File.join(@target.dir, 'data', 'attitude.bin')
      @position_file = File.open(position_filename, 'rb')
      @attitude_file = File.open(attitude_filename, 'rb')
      @position_file_size = File.size(position_filename)
      @attitude_file_size = File.size(attitude_filename)
      @position_file_bytes_read = 0
      @attitude_file_bytes_read = 0

      @pos_packet = Structure.new(:BIG_ENDIAN)
      @pos_packet.append_item('DAY', 16, :UINT)
      @pos_packet.append_item('MSOD', 32, :UINT)
      @pos_packet.append_item('USOMS', 16, :UINT)
      @pos_packet.append_item('POSX', 32, :FLOAT)
      @pos_packet.append_item('POSY', 32, :FLOAT)
      @pos_packet.append_item('POSZ', 32, :FLOAT)
      @pos_packet.append_item('SPARE1', 16, :UINT)
      @pos_packet.append_item('SPARE2', 32, :UINT)
      @pos_packet.append_item('SPARE3', 16, :UINT)
      @pos_packet.append_item('VELX', 32, :FLOAT)
      @pos_packet.append_item('VELY', 32, :FLOAT)
      @pos_packet.append_item('VELZ', 32, :FLOAT)
      @pos_packet.append_item('SPARE4', 32, :UINT)
      @pos_packet.enable_method_missing

      @att_packet = Structure.new(:BIG_ENDIAN)
      @att_packet.append_item('DAY', 16, :UINT)
      @att_packet.append_item('MSOD', 32, :UINT)
      @att_packet.append_item('USOMS', 16, :UINT)
      @att_packet.append_item('Q1', 32, :FLOAT)
      @att_packet.append_item('Q2', 32, :FLOAT)
      @att_packet.append_item('Q3', 32, :FLOAT)
      @att_packet.append_item('Q4', 32, :FLOAT)
      @att_packet.append_item('BIASX', 32, :FLOAT)
      @att_packet.append_item('BIASY', 32, :FLOAT)
      @att_packet.append_item('BIASZ', 32, :FLOAT)
      @att_packet.append_item('SPARE', 32, :FLOAT)
      @att_packet.enable_method_missing

      # Initialize fixed parts of packets
      packet = @tlm_packets['HEALTH_STATUS']
      packet.enable_method_missing
      packet.CcsdsSeqFlags = 'NOGROUP'
      packet.CcsdsLength = packet.buffer.length - 7

      packet = @tlm_packets['THERMAL']
      packet.enable_method_missing
      packet.CcsdsSeqFlags = 'NOGROUP'
      packet.CcsdsLength = packet.buffer.length - 7

      packet = @tlm_packets['EVENT']
      packet.enable_method_missing
      packet.CcsdsSeqFlags = 'NOGROUP'
      packet.CcsdsLength   = packet.buffer.length - 7

      packet = @tlm_packets['ADCS']
      packet.enable_method_missing
      packet.CcsdsSeqFlags = 'NOGROUP'
      packet.CcsdsLength   = packet.buffer.length - 7

      packet = @tlm_packets['IMAGE']
      packet.enable_method_missing
      packet.CcsdsSeqFlags = 'NOGROUP'
      packet.image = ("\x05" * 10000) + "The Secret is Astral Body"
      packet.CcsdsLength = packet.buffer.length - 7

      packet = @tlm_packets['MECH']
      packet.enable_method_missing
      packet.CcsdsSeqFlags = 'NOGROUP'
      packet.CcsdsLength = packet.buffer.length - 7

      packet = @tlm_packets['IMAGER']
      packet.enable_method_missing
      packet.CcsdsSeqFlags = 'NOGROUP'
      packet.CcsdsLength = packet.buffer.length - 7

      packet = @tlm_packets['COMMS']
      packet.enable_method_missing
      packet.CcsdsSeqFlags = 'NOGROUP'
      packet.CcsdsLength = packet.buffer.length - 7

      @get_count = 0
      @queue = Queue.new

      # ADCS
      @trackStars = Array.new
      @trackStars[0] = 1237
      @trackStars[1] = 1329
      @trackStars[2] = 1333
      @trackStars[3] = 1139
      @trackStars[4] = 1161
      @trackStars[5] = 682
      @trackStars[6] = 717
      @trackStars[7] = 814
      @trackStars[8] = 583
      @trackStars[9] = 622
      @adcs_ctrl = 'OFF'
      @sr_ang_to_sun = 0

      # HEALTH_STATUS
      @cmd_acpt_cnt = 0
      @cmd_rjct_cnt = 0
      @mode = 'SAFE'
      @cpu_pwr = 100

      # THERMAL
      @temp1 = 0
      @temp2 = 0
      @heater1_ctrl = 'OFF'
      @heater1_state = 'OFF'
      @heater1_setpt = 0.0
      @heater1_pwr = 0.0
      @heater2_ctrl = 'OFF'
      @heater2_state = 'OFF'
      @heater2_setpt = 0.0
      @heater2_pwr = 0.0

      # MECH
      @slrpnl1_ang = 180.0
      @slrpnl2_ang = 180.0
      @slrpnl1_state = 'STOWED'
      @slrpnl2_state = 'STOWED'
      @slrpnl1_pwr = 0.0
      @slrpnl2_pwr = 0.0
      @pwr_watt_seconds = INIT_PWR_WATT_SECONDS
      @battery = (@pwr_watt_seconds.to_f / MAX_PWR_WATT_SECONDS.to_f) * 100.0

      # IMAGER
      @collects = 0
      @duration = 10
      @collect_type = 'NORMAL'
      @imager_state = 'OFF'
      @imager_pwr = 0.0
      @collect_end_time = nil

      # COMMUNICATIONS
      @ant1_state = 'STOWED'
      @ant1_type = 'HIGH_GAIN'
      @ant1_azimuth = 0.0
      @ant1_elevation = 0.0
      @ant2_state = 'STOWED'
      @ant2_type = 'LOW_GAIN'
      @ant2_azimuth = 0.0
      @ant2_elevation = 0.0
      @downlink_state = 'IDLE'
      @data_rate = 'LOW'
      @data_buffer = 50.0  # Start at 50% buffer
      @signal_strength = -50.0
      @comm_pwr = 0.0
      @downlink_time_remaining = 0
      @downlink_end_time = nil
      @ant1_deploy_end_time = nil
      @ant2_deploy_end_time = nil
    end

    def set_rates
      # Set telemetry packet rates (packets per second)
      set_rate('ADCS', 10)           # Position/attitude data at 10 Hz
      set_rate('HEALTH_STATUS', 100) # Health status at 100 Hz
      set_rate('THERMAL', 100)       # Thermal data at 100 Hz
      set_rate('MECH', 100)          # Mechanical systems at 100 Hz
      set_rate('IMAGER', 100)        # Imager status at 100 Hz
      set_rate('COMMS', 100)         # Communications status at 100 Hz
    end

    def accept_cmd(message = nil)
      if message
        event_packet = @tlm_packets['EVENT']
        event_packet.message = message
        time = Time.now
        event_packet.timesec = time.tv_sec
        event_packet.timeus  = time.tv_usec
        event_packet.ccsdsseqcnt += 1
        @queue << event_packet.dup
      end
      @cmd_acpt_cnt += 1
    end

    def reject_cmd(message)
      event_packet = @tlm_packets['EVENT']
      event_packet.message = message
      time = Time.now
      event_packet.timesec = time.tv_sec
      event_packet.timeus  = time.tv_usec
      event_packet.ccsdsseqcnt += 1
      @queue << event_packet.dup
      @cmd_rjct_cnt += 1
    end

    def write(packet)
      name = packet.packet_name.upcase

      case name
      when 'NOOP'
        accept_cmd("NOOP command received - no operation performed")

      when 'COLLECT'
        if @mode == 'OPERATE'
          @collects += 1
          @duration = packet.read('duration')
          @collect_type = packet.read("type")
          @collect_end_time = Time.now + @duration
          accept_cmd("Started #{@collect_type} image collection for #{@duration} seconds (total collects: #{@collects})")
        else
          reject_cmd("Mode must be OPERATE to collect images")
        end

      when 'ABORT'
        @collect_end_time = nil
        accept_cmd("Image collection aborted")

      when 'CLEAR'
        prev_collects = @collects
        prev_accepts = @cmd_acpt_cnt
        prev_rejects = @cmd_rjct_cnt
        @collects = 0
        @cmd_acpt_cnt = 0
        @cmd_rjct_cnt = 0
        accept_cmd("Counters cleared (collects: #{prev_collects}→0, accepts: #{prev_accepts}→0, rejects: #{prev_rejects}→0)")

      when 'SET_MODE'
        mode = packet.read('mode')
        prev_mode = @mode
        case mode
        when 'SAFE'
          @mode = mode
          accept_cmd("Mode changed from #{prev_mode} to #{mode}")
        when 'CHECKOUT'
          if @battery >= 50.0
            @mode = mode
            accept_cmd("Mode changed from #{prev_mode} to #{mode} (battery: #{@battery.round(1)}%)")
          else
            reject_cmd("Cannot enter checkout if battery < 50.0%")
          end
        when 'OPERATE'
          if @temp1 < 35.0 and @temp1 > 25.0 and @temp2 < 35.0 and @temp2 > 25.0
            @mode = mode
            accept_cmd("Mode changed from #{prev_mode} to #{mode} (temp1: #{@temp1.round(1)}°C, temp2: #{@temp2.round(1)}°C)")
          else
            reject_cmd("Cannot enter OPERATE unless temperatures are stable near 30.0")
          end
        else
          reject_cmd("Invalid Mode: #{mode}")
        end

      when 'SLRPNLDEPLOY'
        num = packet.read('NUM')
        case num
        when 1
          @slrpnl1_state = 'DEPLOYED'
          accept_cmd("Solar array #{num} deployed (power generation enabled)")
        when 2
          @slrpnl2_state = 'DEPLOYED'
          accept_cmd("Solar array #{num} deployed (power generation enabled)")
        else
          reject_cmd("Invalid Solar Array Number: #{num}")
        end

      when 'SLRPNLSTOW'
        num = packet.read('NUM')
        case num
        when 1
          @slrpnl1_state = 'STOWED'
          accept_cmd("Solar array #{num} stowed (power generation disabled)")
        when 2
          @slrpnl2_state = 'STOWED'
          accept_cmd("Solar array #{num} stowed (power generation disabled)")
        else
          reject_cmd("Invalid Solar Array Number: #{num}")
        end

      when 'SLRPNLANG'
        num = packet.read('NUM')
        ang = packet.read('ANG')
        case num
        when 1
          case ang
          when 0..360
            @slrpnl1_ang = ang
            accept_cmd("Solar array #{num} angle set to #{ang.round(1)}° (current sun angle: #{@sr_ang_to_sun.round(1)}°)")
          else
            reject_cmd("Invalid Solar Array Angle: #{ang}")
          end
        when 2
          case ang
          when 0..360
            @slrpnl2_ang = ang
            accept_cmd("Solar array #{num} angle set to #{ang.round(1)}° (current sun angle: #{@sr_ang_to_sun.round(1)}°)")
          else
            reject_cmd("Invalid Solar Array Angle: #{ang}")
          end
        else
          reject_cmd("Invalid Solar Array Number: #{num}")
        end

      when 'HTR_CTRL'
        num = packet.read('NUM')
        state = packet.read('STATE')
        case num
        when 1
          case state
          when 'ON', 'OFF'
            @heater1_ctrl = state
            accept_cmd("Heater #{num} control set to #{state} (current temp: #{@temp1.round(1)}°C, setpoint: #{@heater1_setpt.round(1)}°C)")
          else
            reject_cmd("Invalid Heater Control: #{state}")
          end
        when 2
          case state
          when 'ON', 'OFF'
            @heater2_ctrl = state
            accept_cmd("Heater #{num} control set to #{state} (current temp: #{@temp2.round(1)}°C, setpoint: #{@heater2_setpt.round(1)}°C)")
          else
            reject_cmd("Invalid Heater Control: #{state}")
          end
        else
          reject_cmd("Invalid Heater Number: #{num}")
        end

      when 'HTR_STATE'
        num = packet.read('NUM')
        state = packet.read('STATE')
        case num
        when 1
          case state
          when 'ON', 'OFF'
            @heater1_state = state
            accept_cmd("Heater #{num} state manually set to #{state} (power: #{state == 'ON' ? '300W' : '0W'})")
          else
            reject_cmd("Invalid Heater State: #{state}")
          end
        when 2
          case state
          when 'ON', 'OFF'
            @heater2_state = state
            accept_cmd("Heater #{num} state manually set to #{state} (power: #{state == 'ON' ? '300W' : '0W'})")
          else
            reject_cmd("Invalid Heater State: #{state}")
          end
        else
          reject_cmd("Invalid Heater Number: #{num}")
        end

      when 'HTR_SETPT'
        num = packet.read('NUM')
        setpt = packet.read('SETPT')
        case num
        when 1
          case setpt
          when -100..100
            prev_setpt = @heater1_setpt
            @heater1_setpt = setpt
            accept_cmd("Heater #{num} setpoint changed from #{prev_setpt.round(1)}°C to #{setpt.round(1)}°C")
          else
            reject_cmd("Invalid Heater Setpoint: #{setpt}")
          end
        when 2
          case setpt
          when -100..100
            prev_setpt = @heater2_setpt
            @heater2_setpt = setpt
            accept_cmd("Heater #{num} setpoint changed from #{prev_setpt.round(1)}°C to #{setpt.round(1)}°C")
          else
            reject_cmd("Invalid Heater Setpoint: #{setpt}")
          end
        else
          reject_cmd("Invalid Heater Number: #{num}")
        end

      when 'ADCS_CTRL'
        state = packet.read('STATE')
        case state
        when 'ON', 'OFF'
          @adcs_ctrl = state
          accept_cmd("ADCS control set to #{state} (solar array auto-pointing #{state == 'ON' ? 'enabled' : 'disabled'})")
        else
          reject_cmd("Invalid ADCS Control: #{state}")
        end

      when 'ANT_DEPLOY'
        ant_num = packet.read('ANT_NUM')
        ant_type = packet.read('TYPE')
        case ant_num
        when 1
          if @ant1_state == 'STOWED'
            @ant1_state = 'DEPLOYING'
            @ant1_type = ant_type
            @ant1_deploy_end_time = Time.now + 10.0  # 10 seconds to deploy
            accept_cmd("Deploying antenna #{ant_num}")
          else
            reject_cmd("Antenna #{ant_num} not in STOWED state")
          end
        when 2
          if @ant2_state == 'STOWED'
            @ant2_state = 'DEPLOYING'
            @ant2_type = ant_type
            @ant2_deploy_end_time = Time.now + 10.0  # 10 seconds to deploy
            accept_cmd("Deploying antenna #{ant_num}")
          else
            reject_cmd("Antenna #{ant_num} not in STOWED state")
          end
        else
          reject_cmd("Invalid Antenna Number: #{ant_num}")
        end

      when 'ANT_STOW'
        ant_num = packet.read('ANT_NUM')
        case ant_num
        when 1
          if @ant1_state == 'DEPLOYED'
            @ant1_state = 'STOWING'
            @ant1_deploy_end_time = Time.now + 8.0  # 8 seconds to stow
            accept_cmd("Stowing antenna #{ant_num}")
          else
            reject_cmd("Antenna #{ant_num} not in DEPLOYED state")
          end
        when 2
          if @ant2_state == 'DEPLOYED'
            @ant2_state = 'STOWING'
            @ant2_deploy_end_time = Time.now + 8.0  # 8 seconds to stow
            accept_cmd("Stowing antenna #{ant_num}")
          else
            reject_cmd("Antenna #{ant_num} not in DEPLOYED state")
          end
        else
          reject_cmd("Invalid Antenna Number: #{ant_num}")
        end

      when 'START_DOWNLINK'
        if @ant1_state == 'DEPLOYED' or @ant2_state == 'DEPLOYED'
          data_rate = packet.read('DATA_RATE')
          duration = packet.read('DURATION')
          @data_rate = data_rate
          @downlink_state = 'ACTIVE'
          @downlink_time_remaining = duration
          @downlink_end_time = Time.now + duration
          accept_cmd("Starting downlink for #{duration} seconds")
        else
          reject_cmd("No antennas deployed for downlink")
        end

      when 'STOP_DOWNLINK'
        if @downlink_state == 'ACTIVE'
          @downlink_state = 'IDLE'
          @downlink_end_time = nil
          @downlink_time_remaining = 0
          accept_cmd("Downlink stopped")
        else
          reject_cmd("No active downlink to stop")
        end

      when 'SET_ANT_ANGLE'
        ant_num = packet.read('ANT_NUM')
        azimuth = packet.read('AZIMUTH')
        elevation = packet.read('ELEVATION')
        case ant_num
        when 1
          if @ant1_state == 'DEPLOYED'
            @ant1_azimuth = azimuth
            @ant1_elevation = elevation
            accept_cmd("Set antenna #{ant_num} angle to Az:#{azimuth}° El:#{elevation}°")
          else
            reject_cmd("Antenna #{ant_num} not deployed")
          end
        when 2
          if @ant2_state == 'DEPLOYED'
            @ant2_azimuth = azimuth
            @ant2_elevation = elevation
            accept_cmd("Set antenna #{ant_num} angle to Az:#{azimuth}° El:#{elevation}°")
          else
            reject_cmd("Antenna #{ant_num} not deployed")
          end
        else
          reject_cmd("Invalid Antenna Number: #{ant_num}")
        end
      end
    end

    def graceful_kill
    end

    def get_pending_packets(count_100hz)
      pending_packets = super(count_100hz)
      while @queue.length > 0
        pending_packets << @queue.pop
      end
      pending_packets
    end

    def read(count_100hz, time)
      pending_packets = get_pending_packets(count_100hz)

      pending_packets.each do |packet|
        case packet.packet_name
        when 'ADCS'
          # Read 44 Bytes for Position Data
          pos_data = nil
          begin
            pos_data = @position_file.read(44)
            @position_file_bytes_read += 44
          rescue
            # Do Nothing
          end

          if pos_data.nil? or pos_data.length == 0
            # Assume end of file - close and reopen
            @position_file.close
            @position_file = File.open(File.join(@target.dir, 'data', 'position.bin'), 'rb')
            pos_data = @position_file.read(44)
            @position_file_bytes_read = 44
          end

          @pos_packet.buffer = pos_data
          packet.posx = @pos_packet.posx
          packet.posy = @pos_packet.posy
          packet.posz = @pos_packet.posz
          packet.velx = @pos_packet.velx
          packet.vely = @pos_packet.vely
          packet.velz = @pos_packet.velz

          # Read 40 Bytes for Attitude Data
          att_data = nil
          begin
            att_data = @attitude_file.read(40)
            @attitude_file_bytes_read += 40
          rescue
            # Do Nothing
          end

          if att_data.nil? or att_data.length == 0
            @attitude_file.close
            @attitude_file = File.open(File.join(@target.dir, 'data', 'attitude.bin'), 'rb')
            att_data = @attitude_file.read(40)
            @attitude_file_bytes_read = 40
          end

          @att_packet.buffer = att_data
          packet.q1 = @att_packet.q1
          packet.q2 = @att_packet.q2
          packet.q3 = @att_packet.q3
          packet.q4 = @att_packet.q4
          packet.biasx = @att_packet.biasx
          packet.biasy = @att_packet.biasy
          packet.biasy = @att_packet.biasz

          packet.star1id = @trackStars[((@get_count / 100) + 0) % 10]
          packet.star2id = @trackStars[((@get_count / 100) + 1) % 10]
          packet.star3id = @trackStars[((@get_count / 100) + 2) % 10]
          packet.star4id = @trackStars[((@get_count / 100) + 3) % 10]
          packet.star5id = @trackStars[((@get_count / 100) + 4) % 10]

          packet.posprogress = (@position_file_bytes_read.to_f / @position_file_size.to_f) * 100.0
          packet.attprogress = (@attitude_file_bytes_read.to_f / @attitude_file_size.to_f) * 100.0
          @sr_ang_to_sun = packet.posprogress * 3.6
          packet.sr_ang_to_sun = @sr_ang_to_sun
          packet.adcs_ctrl = @adcs_ctrl

          packet.timesec = time.tv_sec
          packet.timeus  = time.tv_usec
          packet.ccsdsseqcnt += 1

        when 'HEALTH_STATUS'
          packet.timesec = time.tv_sec
          packet.timeus  = time.tv_usec
          packet.ccsdsseqcnt += 1

          packet.cmd_acpt_cnt = @cmd_acpt_cnt
          packet.cmd_rjct_cnt = @cmd_rjct_cnt
          packet.mode = @mode
          packet.cpu_pwr = @cpu_pwr

        when 'THERMAL'
          packet.timesec = time.tv_sec
          packet.timeus  = time.tv_usec
          packet.ccsdsseqcnt += 1

          if @heater1_ctrl == 'ON'
            if @temp1 < (@heater1_setpt - HYSTERESIS)
              @heater1_state = 'ON'
            elsif @temp1 > (@heater1_setpt + HYSTERESIS)
              @heater1_state = 'OFF'
            end
          end

          if @heater2_ctrl == 'ON'
            if @temp2 < (@heater2_setpt - HYSTERESIS)
              @heater2_state = 'ON'
            elsif @temp2 > (@heater2_setpt + HYSTERESIS)
              @heater2_state = 'OFF'
            end
          end

          if @heater1_state == 'ON'
            @heater1_pwr = 300
            @temp1 += 0.5
            if @temp1 > 50.0
              @temp1 = 50.0
            end
          else
            @heater1_pwr = 0
            @temp1 -= 0.1
            if @temp1 < -20.0
              @temp1 = -20.0
            end
          end

          if @heater2_state == 'ON'
            @heater2_pwr = 300
            @temp2 += 0.5
            if @temp2 > 100.0
              @temp2 = 100.0
            end
          else
            @heater2_pwr = 0
            @temp2 -= 0.1
            if @temp2 < -20.0
              @temp2 = -20.0
            end
          end

          packet.heater1_ctrl = @heater1_ctrl
          packet.heater1_state = @heater1_state
          packet.heater1_setpt = @heater1_setpt
          packet.heater1_pwr = @heater1_pwr
          packet.heater2_ctrl = @heater2_ctrl
          packet.heater2_state = @heater2_state
          packet.heater2_setpt = @heater2_setpt
          packet.heater2_pwr = @heater2_pwr
          packet.temp1 = @temp1
          packet.temp2 = @temp2

        when 'MECH'
          if @adcs_ctrl == 'ON'
            @slrpnl1_ang = @sr_ang_to_sun
            @slrpnl2_ang = @sr_ang_to_sun
          end

          delta_ang = (@sr_ang_to_sun - @slrpnl1_ang).abs
          if delta_ang > 180.0
            delta_ang = 360 - delta_ang
          end
          if @slrpnl1_state == 'DEPLOYED'
            @slrpnl1_pwr = 500 * (1 - (delta_ang / 180.0))
          else
            @slrpnl1_pwr = 0
          end

          delta_ang = (@sr_ang_to_sun - @slrpnl2_ang).abs
          if delta_ang > 180.0
            delta_ang = 360 - delta_ang
          end
          if @slrpnl2_state == 'DEPLOYED'
            @slrpnl2_pwr = 500 * (1 - (delta_ang / 180.0))
          else
            @slrpnl2_pwr = 0
          end

          incoming_pwr = @slrpnl1_pwr + @slrpnl2_pwr # Upto 1000 per second

          used_pwr = @cpu_pwr + @imager_pwr + @heater1_pwr + @heater2_pwr + @comm_pwr # Up to 900 per second + comms
          delta_pwr = incoming_pwr - used_pwr
          @pwr_watt_seconds += delta_pwr
          if @pwr_watt_seconds < 0
            @pwr_watt_seconds = 100
          elsif @pwr_watt_seconds > MAX_PWR_WATT_SECONDS
            @pwr_watt_seconds = MAX_PWR_WATT_SECONDS
          end
          @battery = (@pwr_watt_seconds.to_f / MAX_PWR_WATT_SECONDS.to_f) * 100.0
          if @battery < 50.0
            @mode = 'SAFE'
          end

          packet.timesec = time.tv_sec
          packet.timeus = time.tv_usec
          packet.ccsdsseqcnt += 1
          packet.slrpnl1_ang = @slrpnl1_ang
          packet.slrpnl2_ang = @slrpnl2_ang
          packet.slrpnl1_state = @slrpnl1_state
          packet.slrpnl2_state = @slrpnl2_state
          packet.slrpnl1_pwr = @slrpnl1_pwr
          packet.slrpnl2_pwr = @slrpnl2_pwr
          packet.battery = @battery

        when 'IMAGER'
          if @collect_end_time
            if @collect_end_time < Time.now
              @imager_state = 'OFF'
              @collect_end_time = nil
              @imager_pwr = 0
              image_packet = @tlm_packets['IMAGE']
              time = Time.now
              image_packet.timesec = time.tv_sec
              image_packet.timeus  = time.tv_usec
              image_packet.ccsdsseqcnt += 1
              @queue << image_packet.dup
            else
              @imager_state = 'ON'
              @imager_pwr = 200
            end
          else
            @imager_pwr = 0
          end

          packet.timesec = time.tv_sec
          packet.timeus = time.tv_usec
          packet.ccsdsseqcnt += 1
          packet.collects = @collects
          packet.duration = @duration
          packet.collect_type = @collect_type
          packet.imager_state = @imager_state
          packet.imager_pwr = @imager_pwr

        when 'COMMS'
          # Handle antenna deployment timing
          if @ant1_deploy_end_time and Time.now >= @ant1_deploy_end_time
            if @ant1_state == 'DEPLOYING'
              @ant1_state = 'DEPLOYED'
            elsif @ant1_state == 'STOWING'
              @ant1_state = 'STOWED'
            end
            @ant1_deploy_end_time = nil
          end

          if @ant2_deploy_end_time and Time.now >= @ant2_deploy_end_time
            if @ant2_state == 'DEPLOYING'
              @ant2_state = 'DEPLOYED'
            elsif @ant2_state == 'STOWING'
              @ant2_state = 'STOWED'
            end
            @ant2_deploy_end_time = nil
          end

          # Handle downlink timing and data buffer
          if @downlink_end_time and Time.now >= @downlink_end_time
            @downlink_state = 'IDLE'
            @downlink_end_time = nil
            @downlink_time_remaining = 0
          elsif @downlink_state == 'ACTIVE'
            @downlink_time_remaining = [@downlink_end_time - Time.now, 0].max.to_i

            # Simulate data transmission (reduce buffer during downlink)
            data_rate_multiplier = case @data_rate
                                   when 'LOW' then 0.5
                                   when 'MEDIUM' then 1.0
                                   when 'HIGH' then 2.0
                                   else 0.5
                                   end
            @data_buffer -= 0.1 * data_rate_multiplier
            @data_buffer = [@data_buffer, 0.0].max
          else
            # Data accumulates when not downlinking
            @data_buffer += 0.05
            @data_buffer = [@data_buffer, 100.0].min
          end

          # Simulate signal strength based on antenna configuration and orbital position
          base_signal = -60.0
          if @ant1_state == 'DEPLOYED' and @ant1_type == 'HIGH_GAIN'
            base_signal += 15.0
          elsif @ant1_state == 'DEPLOYED'
            base_signal += 5.0
          end
          if @ant2_state == 'DEPLOYED' and @ant2_type == 'HIGH_GAIN'
            base_signal += 15.0
          elsif @ant2_state == 'DEPLOYED'
            base_signal += 5.0
          end

          # Add orbital noise
          orbital_noise = ((@get_count % 360) * 0.1) - 18.0
          @signal_strength = base_signal + orbital_noise

          # Calculate communications power consumption
          @comm_pwr = 0.0
          if @ant1_state == 'DEPLOYED'
            @comm_pwr += (@ant1_type == 'HIGH_GAIN') ? 50.0 : 20.0
          end
          if @ant2_state == 'DEPLOYED'
            @comm_pwr += (@ant2_type == 'HIGH_GAIN') ? 50.0 : 20.0
          end
          if @downlink_state == 'ACTIVE'
            transmit_power = case @data_rate
                           when 'LOW' then 10.0
                           when 'MEDIUM' then 25.0
                           when 'HIGH' then 75.0
                           else 10.0
                           end
            @comm_pwr += transmit_power
          end

          packet.timesec = time.tv_sec
          packet.timeus = time.tv_usec
          packet.ccsdsseqcnt += 1
          packet.ant1_state = @ant1_state
          packet.ant1_type = @ant1_type
          packet.ant1_azimuth = @ant1_azimuth
          packet.ant1_elevation = @ant1_elevation
          packet.ant2_state = @ant2_state
          packet.ant2_type = @ant2_type
          packet.ant2_azimuth = @ant2_azimuth
          packet.ant2_elevation = @ant2_elevation
          packet.downlink_state = @downlink_state
          packet.data_rate = @data_rate
          packet.data_buffer = @data_buffer
          packet.signal_strength = @signal_strength
          packet.comm_pwr = @comm_pwr
          packet.downlink_time_remaining = @downlink_time_remaining

        end
      end

      @get_count += 1
      pending_packets
    end
  end
end
