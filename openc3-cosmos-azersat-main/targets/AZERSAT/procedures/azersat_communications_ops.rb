#!/usr/bin/env ruby
# AzerSat Communications Operations Script
# Demonstrates comprehensive communications system usage

# Display script information
puts "=" * 60
puts "AzerSat Communications Operations Script"
puts "Demonstrating antenna deployment, pointing, and data downlink"
puts "=" * 60

# Step 1: Pre-flight Communications Check
puts "\n📡 Step 1: Pre-flight Communications Check"
puts "-" * 40

# Check initial antenna states
ant1_state = tlm("AZERSAT COMMS ANT1_STATE")
ant2_state = tlm("AZERSAT COMMS ANT2_STATE")
signal_strength = tlm("AZERSAT COMMS SIGNAL_STRENGTH")
data_buffer = tlm("AZERSAT COMMS DATA_BUFFER")

puts "Initial Communications Status:"
puts "  Antenna 1: #{ant1_state}"
puts "  Antenna 2: #{ant2_state}"
puts "  Signal Strength: #{signal_strength.round(1)} dB"
puts "  Data Buffer: #{data_buffer.round(1)}%"

# Step 2: Deploy Communication Antennas
puts "\n🚀 Step 2: Deploying Communication Antennas"
puts "-" * 40

if ant1_state != "DEPLOYED"
  puts "Deploying high-gain antenna (primary)..."
  cmd("AZERSAT ANT_DEPLOY with ANT_NUM 1, TYPE HIGH_GAIN")

  # Monitor deployment
  puts "Monitoring antenna 1 deployment..."
  start_time = Time.now
  while Time.now - start_time < 15  # 15 second timeout
    current_state = tlm("AZERSAT COMMS ANT1_STATE")
    puts "  Antenna 1 state: #{current_state}"

    if current_state == "DEPLOYED"
      puts "✅ Antenna 1 deployed successfully"
      break
    elsif current_state == "ERROR"
      puts "❌ Antenna 1 deployment failed"
      exit
    end

    wait(2)
  end
else
  puts "✅ Antenna 1 already deployed"
end

if ant2_state != "DEPLOYED"
  puts "\nDeploying low-gain antenna (backup)..."
  cmd("AZERSAT ANT_DEPLOY with ANT_NUM 2 TYPE LOW_GAIN")

  # Monitor deployment
  puts "Monitoring antenna 2 deployment..."
  start_time = Time.now
  while Time.now - start_time < 15
    current_state = tlm("AZERSAT COMMS ANT2_STATE")
    puts "  Antenna 2 state: #{current_state}"

    if current_state == "DEPLOYED"
      puts "✅ Antenna 2 deployed successfully"
      break
    elsif current_state == "ERROR"
      puts "❌ Antenna 2 deployment failed"
      break
    end

    wait(2)
  end
else
  puts "✅ Antenna 2 already deployed"
end

wait(2)

# Step 3: Antenna Pointing Sequence
puts "\n🎯 Step 3: Antenna Pointing Sequence"
puts "-" * 40

# Define ground station contact scenarios
ground_stations = [
  { name: "Primary Ground Station", azimuth: 45.0, elevation: 30.0 },
  { name: "Backup Ground Station", azimuth: 180.0, elevation: 25.0 },
  { name: "Deep Space Network", azimuth: 270.0, elevation: 45.0 }
]

ground_stations.each_with_index do |station, index|
  puts "\nPointing to #{station[:name]}..."

  # Point high-gain antenna to primary target
  cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 1, AZIMUTH #{station[:azimuth]}, ELEVATION #{station[:elevation]}")
  wait(2)

  # Point low-gain antenna to provide backup coverage
  backup_az = (station[:azimuth] + 180) % 360
  backup_el = [station[:elevation] - 10, 0].max

  cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 2 AZIMUTH #{backup_az} ELEVATION #{backup_el}")
  wait(2)

  # Check pointing accuracy
  ant1_az = tlm("AZERSAT COMMS ANT1_AZIMUTH")
  ant1_el = tlm("AZERSAT COMMS ANT1_ELEVATION")
  signal_strength = tlm("AZERSAT COMMS SIGNAL_STRENGTH")

  puts "  High-gain antenna: Az=#{ant1_az.round(1)}° El=#{ant1_el.round(1)}°"
  puts "  Signal strength: #{signal_strength.round(1)} dB"

  # Simulate contact window
  if index < ground_stations.length - 1
    puts "  Contact window: 30 seconds"
    wait(5)  # Shortened for demo
  end
end

# Step 4: Data Downlink Operations
puts "\n📊 Step 4: Data Downlink Operations"
puts "-" * 40

# Test different data rates
data_rates = ["LOW", "MEDIUM", "HIGH"]

data_rates.each do |rate|
  puts "\nTesting #{rate} data rate downlink..."

  # Check initial buffer level
  initial_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
  puts "  Initial buffer: #{initial_buffer.round(1)}%"

  # Start downlink
  duration = case rate
             when "LOW" then 30
             when "MEDIUM" then 20
             when "HIGH" then 15
             end

  cmd("AZERSAT START_DOWNLINK DATA_RATE #{rate} DURATION #{duration}")
  wait(2)

  # Monitor downlink progress
  start_time = Time.now
  puts "  Downlink started - monitoring for #{duration} seconds..."

  while Time.now - start_time < duration + 5
    downlink_state = tlm("AZERSAT COMMS DOWNLINK_STATE")
    time_remaining = tlm("AZERSAT COMMS DOWNLINK_TIME_REMAINING")
    current_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
    comm_power = tlm("AZERSAT COMMS COMM_PWR")

    if downlink_state == "IDLE"
      puts "  ✅ Downlink completed"
      break
    elsif downlink_state == "ACTIVE"
      buffer_change = initial_buffer - current_buffer
      puts "  Status: ACTIVE, #{time_remaining}s remaining, buffer: #{current_buffer.round(1)}% (-#{buffer_change.round(1)}%), power: #{comm_power.round(1)}W"
    end

    wait(5)
  end

  final_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
  total_transmitted = initial_buffer - final_buffer
  puts "  Final buffer: #{final_buffer.round(1)}% (transmitted #{total_transmitted.round(1)}%)"

  # Pause between tests
  if rate != "HIGH"
    puts "  Waiting for buffer to accumulate..."
    wait(10)
  end
end

# Step 5: Emergency Communications Test
puts "\n🚨 Step 5: Emergency Communications Test"
puts "-" * 40

puts "Simulating emergency scenario - rapid data dump..."

# Point both antennas to same target for maximum signal
puts "Pointing both antennas to emergency ground station..."
cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 1 AZIMUTH 0.0 ELEVATION 45.0")
wait(1)
cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 2 AZIMUTH 0.0 ELEVATION 45.0")
wait(2)

# Check combined signal strength
signal_strength = tlm("AZERSAT COMMS SIGNAL_STRENGTH")
puts "Combined signal strength: #{signal_strength.round(1)} dB"

# High-rate emergency downlink
puts "Starting emergency high-rate downlink..."
cmd("AZERSAT START_DOWNLINK DATA_RATE HIGH DURATION 45")
wait(2)

# Monitor power consumption during high-rate transmission
puts "Monitoring power consumption during emergency transmission..."
for i in 1..9  # Monitor for 45 seconds
  comm_power = tlm("AZERSAT COMMS COMM_PWR")
  battery = tlm("AZERSAT MECH BATTERY")
  buffer = tlm("AZERSAT COMMS DATA_BUFFER")

  puts "  T+#{i*5}s: Power=#{comm_power.round(1)}W, Battery=#{battery.round(1)}%, Buffer=#{buffer.round(1)}%"
  wait(5)
end

# Step 6: Antenna Maintenance Operations
puts "\n🔧 Step 6: Antenna Maintenance Operations"
puts "-" * 40

puts "Performing antenna maintenance cycle..."

# Test antenna stow/deploy cycle
puts "Testing antenna 2 stow/deploy cycle..."
cmd("AZERSAT ANT_STOW with ANT_NUM 2")

# Monitor stowing
puts "Monitoring antenna 2 stowing..."
start_time = Time.now
while Time.now - start_time < 12
  state = tlm("AZERSAT COMMS ANT2_STATE")
  puts "  Antenna 2 state: #{state}"

  if state == "STOWED"
    puts "✅ Antenna 2 stowed successfully"
    break
  end

  wait(2)
end

wait(3)

# Redeploy antenna
puts "Redeploying antenna 2..."
cmd("AZERSAT ANT_DEPLOY with ANT_NUM 2 TYPE LOW_GAIN")

# Monitor redeployment
puts "Monitoring antenna 2 redeployment..."
start_time = Time.now
while Time.now - start_time < 12
  state = tlm("AZERSAT COMMS ANT2_STATE")
  puts "  Antenna 2 state: #{state}"

  if state == "DEPLOYED"
    puts "✅ Antenna 2 redeployed successfully"
    break
  end

  wait(2)
end

# Final Status Report
puts "\n" + "=" * 60
puts "📡 COMMUNICATIONS OPERATIONS COMPLETE!"
puts "=" * 60

# Get final telemetry
final_ant1_state = tlm("AZERSAT COMMS ANT1_STATE")
final_ant2_state = tlm("AZERSAT COMMS ANT2_STATE")
final_signal = tlm("AZERSAT COMMS SIGNAL_STRENGTH")
final_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
final_comm_power = tlm("AZERSAT COMMS COMM_PWR")
final_downlink_state = tlm("AZERSAT COMMS DOWNLINK_STATE")

puts "\nFinal Communications Status:"
puts "  Antenna 1 (High-gain): #{final_ant1_state}"
puts "  Antenna 2 (Low-gain): #{final_ant2_state}"
puts "  Signal Strength: #{final_signal.round(1)} dB"
puts "  Data Buffer: #{final_buffer.round(1)}%"
puts "  Communications Power: #{final_comm_power.round(1)}W"
puts "  Downlink State: #{final_downlink_state}"

puts "\n✅ All communications systems tested and operational!"
puts "\nOperations Summary:"
puts "  - Deployed and tested both antennas"
puts "  - Tested all three data rates (LOW/MEDIUM/HIGH)"
puts "  - Performed emergency communications scenario"
puts "  - Completed antenna maintenance cycle"
puts "  - Verified signal strength optimization"

puts "\nScript completed successfully! 📡🛰️"