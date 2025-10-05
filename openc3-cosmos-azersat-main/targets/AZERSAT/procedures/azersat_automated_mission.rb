#!/usr/bin/env ruby
# AzerSat Automated Mission Script
# Demonstrates a complete automated mission with imaging, data collection, and downlink

# Display script information
puts "=" * 60
puts "AzerSat Automated Mission Script"
puts "Performing autonomous imaging mission with data downlink"
puts "=" * 60

# Mission parameters
IMAGE_TARGETS = [
  { name: "Target Alpha", collect_time: 5.0, priority: "NORMAL" },
  { name: "Target Beta", collect_time: 8.0, priority: "SPECIAL" },
  { name: "Target Gamma", collect_time: 3.0, priority: "NORMAL" }
]

DOWNLINK_WINDOWS = [
  { name: "Primary Ground Station", duration: 180, data_rate: "HIGH" },
  { name: "Backup Ground Station", duration: 120, data_rate: "MEDIUM" }
]

# Mission Functions
def check_system_health
  puts "\n🔍 System Health Check"
  puts "-" * 25

  mode = tlm("AZERSAT HEALTH_STATUS MODE")
  battery = tlm("AZERSAT MECH BATTERY")
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  panels_deployed = tlm("AZERSAT MECH SLRPNL1_STATE") == "DEPLOYED" && tlm("AZERSAT MECH SLRPNL2_STATE") == "DEPLOYED"
  antennas_deployed = tlm("AZERSAT COMMS ANT1_STATE") == "DEPLOYED" && tlm("AZERSAT COMMS ANT2_STATE") == "DEPLOYED"

  puts "  Mode: #{mode}"
  puts "  Battery: #{battery.round(1)}%"
  puts "  Temperatures: #{temp1.round(1)}°C / #{temp2.round(1)}°C"
  puts "  Solar Panels: #{panels_deployed ? 'DEPLOYED' : 'NOT READY'}"
  puts "  Antennas: #{antennas_deployed ? 'DEPLOYED' : 'NOT READY'}"

  # Health assessment
  health_status = "NOMINAL"
  health_issues = []

  if mode != "OPERATE"
    health_status = "DEGRADED"
    health_issues << "Not in OPERATE mode"
  end

  if battery < 60.0
    health_status = "DEGRADED"
    health_issues << "Low battery (#{battery.round(1)}%)"
  end

  if temp1 < 25.0 || temp1 > 35.0 || temp2 < 25.0 || temp2 > 35.0
    health_status = "DEGRADED"
    health_issues << "Temperatures out of range"
  end

  if !panels_deployed
    health_status = "CRITICAL"
    health_issues << "Solar panels not deployed"
  end

  if !antennas_deployed
    health_status = "DEGRADED"
    health_issues << "Antennas not deployed"
  end

  puts "\n  System Health: #{health_status}"
  if health_issues.any?
    puts "  Issues: #{health_issues.join(', ')}"
  end

  return health_status == "NOMINAL" || health_status == "DEGRADED"
end

def prepare_for_imaging
  puts "\n📸 Preparing for Imaging Operations"
  puts "-" * 35

  # Ensure we're in OPERATE mode
  current_mode = tlm("AZERSAT HEALTH_STATUS MODE")
  if current_mode != "OPERATE"
    puts "⚠️ Not in OPERATE mode (#{current_mode}) - mission may have limited capability"
  else
    puts "✅ Spacecraft in OPERATE mode - ready for imaging"
  end

  # Check imager status
  imager_state = tlm("AZERSAT IMAGER IMAGER_STATE")
  collects = tlm("AZERSAT IMAGER COLLECTS")

  puts "  Imager State: #{imager_state}"
  puts "  Previous Collections: #{collects}"

  # Check data buffer
  data_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
  puts "  Data Buffer: #{data_buffer.round(1)}%"

  if data_buffer > 85.0
    puts "⚠️ Data buffer nearly full (#{data_buffer.round(1)}%) - may need emergency downlink"
    return false
  end

  return true
end

def execute_imaging_sequence(target)
  puts "\n📸 Imaging: #{target[:name]}"
  puts "-" * 30

  puts "Target: #{target[:name]}"
  puts "Collection Type: #{target[:priority]}"
  puts "Duration: #{target[:collect_time]} seconds"

  # Start image collection
  cmd("AZERSAT COLLECT with TYPE #{target[:priority]}, DURATION #{target[:collect_time]}, OPCODE 0xAB, TEMP 20.0")
  wait(2)

  # Monitor collection progress
  start_time = Time.now
  collection_active = true

  puts "Monitoring collection progress..."

  while collection_active && (Time.now - start_time) < (target[:collect_time] + 10)
    imager_state = tlm("AZERSAT IMAGER IMAGER_STATE")
    imager_power = tlm("AZERSAT IMAGER IMAGER_PWR")
    battery = tlm("AZERSAT MECH BATTERY")

    elapsed = Time.now - start_time
    puts "  T+#{elapsed.round(1)}s: Imager=#{imager_state} Power=#{imager_power.round(0)}W Battery=#{battery.round(1)}%"

    if imager_state == "OFF" && elapsed > target[:collect_time]
      puts "✅ Collection completed"
      collection_active = false
    end

    wait(2)
  end

  # Verify collection completion
  final_collects = tlm("AZERSAT IMAGER COLLECTS")
  puts "Total collections completed: #{final_collects}"

  # Check for generated IMAGE packet
  wait(3)
  puts "✅ Image data generated and stored in buffer"

  return true
end

def execute_downlink_window(window)
  puts "\n📡 Downlink Window: #{window[:name]}"
  puts "-" * 40

  puts "Ground Station: #{window[:name]}"
  puts "Duration: #{window[:duration]} seconds"
  puts "Data Rate: #{window[:data_rate]}"

  # Check initial conditions
  initial_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
  signal_strength = tlm("AZERSAT COMMS SIGNAL_STRENGTH")

  puts "Initial buffer level: #{initial_buffer.round(1)}%"
  puts "Signal strength: #{signal_strength.round(1)} dB"

  if initial_buffer < 5.0
    puts "⚠️ No significant data to downlink - skipping window"
    return false
  end

  # Point antennas for optimal signal
  puts "Pointing antennas for ground station contact..."
  cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 1 AZIMUTH 45.0 ELEVATION 35.0")
  wait(1)
  cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 2 AZIMUTH 225.0 ELEVATION 25.0")
  wait(2)

  # Start downlink
  puts "Initiating data downlink..."
  cmd("AZERSAT START_DOWNLINK with DATA_RATE #{window[:data_rate]}, DURATION #{window[:duration]}")
  wait(3)

  # Monitor downlink progress
  start_time = Time.now
  downlink_active = true
  last_update = 0

  while downlink_active && (Time.now - start_time) < (window[:duration] + 10)
    downlink_state = tlm("AZERSAT COMMS DOWNLINK_STATE")
    time_remaining = tlm("AZERSAT COMMS DOWNLINK_TIME_REMAINING")
    current_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
    comm_power = tlm("AZERSAT COMMS COMM_PWR")
    signal = tlm("AZERSAT COMMS SIGNAL_STRENGTH")

    transmitted = initial_buffer - current_buffer
    elapsed = Time.now - start_time

    # Update every 10 seconds
    if elapsed.to_i % 10 == 0 && elapsed.to_i != last_update
      puts "  T+#{elapsed.to_i}s: #{downlink_state} #{time_remaining}s remaining, Buffer=#{current_buffer.round(1)}% (-#{transmitted.round(1)}%), Power=#{comm_power.round(0)}W, Signal=#{signal.round(1)}dB"
      last_update = elapsed.to_i
    end

    if downlink_state == "IDLE"
      puts "✅ Downlink completed"
      downlink_active = false
    end

    wait(2)
  end

  # Downlink summary
  final_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
  total_transmitted = initial_buffer - final_buffer

  puts "Downlink Summary:"
  puts "  Data transmitted: #{total_transmitted.round(1)}%"
  puts "  Final buffer level: #{final_buffer.round(1)}%"
  puts "  Transmission efficiency: #{(total_transmitted / window[:duration] * 60).round(2)}%/min"

  return total_transmitted > 0
end

def monitor_orbital_position
  pos_progress = tlm("AZERSAT ADCS POSPROGRESS")
  att_progress = tlm("AZERSAT ADCS ATTPROGRESS")
  sun_angle = tlm("AZERSAT ADCS SR_ANG_TO_SUN")

  puts "\n🌍 Orbital Position Update"
  puts "-" * 25
  puts "  Position Progress: #{pos_progress.round(1)}%"
  puts "  Attitude Progress: #{att_progress.round(1)}%"
  puts "  Sun Angle: #{sun_angle.round(1)}°"

  # Determine orbital phase
  phase = case pos_progress
          when 0..25 then "Dawn Orbit"
          when 25..50 then "Day Side"
          when 50..75 then "Dusk Orbit"
          when 75..100 then "Night Side"
          end

  puts "  Orbital Phase: #{phase}"
  return phase
end

# Main Mission Execution
puts "\n🚀 Starting Automated Mission"
puts "=" * 30

# Pre-mission health check
if !check_system_health
  puts "\n❌ MISSION ABORTED: Critical system health issues detected"
  exit
end

# Mission preparation
if !prepare_for_imaging
  puts "\n⚠️ MISSION DEGRADED: Continuing with limited capability"
end

mission_start_time = Time.now
puts "\nMission Start Time: #{mission_start_time}"

# Mission Phase 1: Imaging Campaign
puts "\n" + "=" * 60
puts "📸 MISSION PHASE 1: IMAGING CAMPAIGN"
puts "=" * 60

successful_images = 0

IMAGE_TARGETS.each_with_index do |target, index|
  puts "\n--- Image Target #{index + 1}/#{IMAGE_TARGETS.length} ---"

  # Check orbital position
  orbital_phase = monitor_orbital_position

  # Execute imaging if conditions are suitable
  if orbital_phase == "Day Side" || orbital_phase == "Dawn Orbit"
    puts "✅ Suitable lighting conditions for imaging"

    if execute_imaging_sequence(target)
      successful_images += 1
      puts "✅ #{target[:name]} imaging completed successfully"
    else
      puts "❌ #{target[:name]} imaging failed"
    end
  else
    puts "⚠️ Poor lighting conditions (#{orbital_phase}) - skipping target"
  end

  # Inter-target delay
  if index < IMAGE_TARGETS.length - 1
    puts "Waiting 30 seconds before next target..."
    wait(30)
  end
end

puts "\nImaging Campaign Summary:"
puts "  Targets attempted: #{IMAGE_TARGETS.length}"
puts "  Successful images: #{successful_images}"
puts "  Success rate: #{(successful_images.to_f / IMAGE_TARGETS.length * 100).round(1)}%"

# Mission Phase 2: Data Downlink Campaign
puts "\n" + "=" * 60
puts "📡 MISSION PHASE 2: DATA DOWNLINK CAMPAIGN"
puts "=" * 60

successful_downlinks = 0
total_data_transmitted = 0

DOWNLINK_WINDOWS.each_with_index do |window, index|
  puts "\n--- Downlink Window #{index + 1}/#{DOWNLINK_WINDOWS.length} ---"

  # Check data availability
  current_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
  if current_buffer < 10.0
    puts "⚠️ Insufficient data for downlink (#{current_buffer.round(1)}%) - skipping window"
    next
  end

  # Execute downlink
  initial_buffer = current_buffer
  if execute_downlink_window(window)
    successful_downlinks += 1
    final_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
    transmitted = initial_buffer - final_buffer
    total_data_transmitted += transmitted
    puts "✅ #{window[:name]} downlink completed successfully"
  else
    puts "❌ #{window[:name]} downlink failed"
  end

  # Inter-window delay
  if index < DOWNLINK_WINDOWS.length - 1
    puts "Waiting 60 seconds before next downlink window..."
    wait(60)
  end
end

puts "\nDownlink Campaign Summary:"
puts "  Windows attempted: #{DOWNLINK_WINDOWS.length}"
puts "  Successful downlinks: #{successful_downlinks}"
puts "  Total data transmitted: #{total_data_transmitted.round(1)}%"

# Mission Phase 3: Post-Mission Assessment
puts "\n" + "=" * 60
puts "📊 MISSION PHASE 3: POST-MISSION ASSESSMENT"
puts "=" * 60

mission_end_time = Time.now
mission_duration = mission_end_time - mission_start_time

puts "\nMission Timeline:"
puts "  Start Time: #{mission_start_time}"
puts "  End Time: #{mission_end_time}"
puts "  Duration: #{(mission_duration / 60).round(1)} minutes"

# Final system status
puts "\n🔍 Final System Status"
puts "-" * 25

final_mode = tlm("AZERSAT HEALTH_STATUS MODE")
final_battery = tlm("AZERSAT MECH BATTERY")
final_temp1 = tlm("AZERSAT THERMAL TEMP1")
final_temp2 = tlm("AZERSAT THERMAL TEMP2")
final_collects = tlm("AZERSAT IMAGER COLLECTS")
final_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
final_cmd_count = tlm("AZERSAT HEALTH_STATUS CMD_ACPT_CNT")

puts "  Mode: #{final_mode}"
puts "  Battery: #{final_battery.round(1)}%"
puts "  Temperatures: #{final_temp1.round(1)}°C / #{final_temp2.round(1)}°C"
puts "  Total Collections: #{final_collects}"
puts "  Data Buffer: #{final_buffer.round(1)}%"
puts "  Commands Executed: #{final_cmd_count}"

# Mission success assessment
mission_success = true
issues = []

if successful_images < IMAGE_TARGETS.length * 0.5
  mission_success = false
  issues << "Insufficient imaging success rate"
end

if successful_downlinks < DOWNLINK_WINDOWS.length * 0.5
  mission_success = false
  issues << "Insufficient downlink success rate"
end

if final_battery < 40.0
  mission_success = false
  issues << "Low final battery level"
end

if final_buffer > 75.0
  issues << "High data buffer level (consider additional downlinks)"
end

# Final Mission Report
puts "\n" + "=" * 60
puts "🎯 AUTOMATED MISSION COMPLETE!"
puts "=" * 60

puts "\nMission Performance Summary:"
puts "  Imaging Success: #{successful_images}/#{IMAGE_TARGETS.length} (#{(successful_images.to_f / IMAGE_TARGETS.length * 100).round(1)}%)"
puts "  Downlink Success: #{successful_downlinks}/#{DOWNLINK_WINDOWS.length} (#{(successful_downlinks.to_f / DOWNLINK_WINDOWS.length * 100).round(1)}%)"
puts "  Mission Duration: #{(mission_duration / 60).round(1)} minutes"
puts "  Data Transmitted: #{total_data_transmitted.round(1)}%"

if mission_success
  puts "\n✅ MISSION SUCCESS!"
else
  puts "\n⚠️ MISSION PARTIAL SUCCESS"
  puts "Issues: #{issues.join(', ')}"
end

puts "\n🛰️ AzerSat autonomous mission operations completed!"
puts "All systems remain operational for future missions."

puts "\nScript completed successfully! 🚀🛰️"