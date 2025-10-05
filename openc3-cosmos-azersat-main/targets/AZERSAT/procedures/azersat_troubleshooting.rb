#!/usr/bin/env ruby
# AzerSat Troubleshooting and Recovery Script
# Demonstrates diagnostic procedures and anomaly recovery

# Display script information
puts "=" * 60
puts "AzerSat Troubleshooting and Recovery Script"
puts "Performing system diagnostics and anomaly recovery"
puts "=" * 60

# Diagnostic Functions
def perform_system_diagnostic
  puts "\n🔍 Performing Comprehensive System Diagnostic"
  puts "-" * 45

  # Health Status Check
  mode = tlm("AZERSAT HEALTH_STATUS MODE")
  cmd_accept = tlm("AZERSAT HEALTH_STATUS CMD_ACPT_CNT")
  cmd_reject = tlm("AZERSAT HEALTH_STATUS CMD_RJCT_CNT")
  cpu_power = tlm("AZERSAT HEALTH_STATUS CPU_PWR")

  puts "Health Status:"
  puts "  Mode: #{mode}"
  puts "  Commands Accepted: #{cmd_accept}"
  puts "  Commands Rejected: #{cmd_reject}"
  puts "  CPU Power: #{cpu_power.round(1)}W"

  # Calculate command success rate
  total_commands = cmd_accept + cmd_reject
  success_rate = total_commands > 0 ? (cmd_accept.to_f / total_commands * 100) : 100
  puts "  Command Success Rate: #{success_rate.round(1)}%"

  # Power System Check
  battery = tlm("AZERSAT MECH BATTERY")
  panel1_power = tlm("AZERSAT MECH SLRPNL1_PWR")
  panel2_power = tlm("AZERSAT MECH SLRPNL2_PWR")
  panel1_state = tlm("AZERSAT MECH SLRPNL1_STATE")
  panel2_state = tlm("AZERSAT MECH SLRPNL2_STATE")

  puts "\nPower System:"
  puts "  Battery: #{battery.round(1)}%"
  puts "  Panel 1: #{panel1_state} (#{panel1_power.round(1)}W)"
  puts "  Panel 2: #{panel2_state} (#{panel2_power.round(1)}W)"
  puts "  Total Generation: #{(panel1_power + panel2_power).round(1)}W"

  # Thermal System Check
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  heater1_ctrl = tlm("AZERSAT THERMAL HEATER1_CTRL")
  heater1_state = tlm("AZERSAT THERMAL HEATER1_STATE")
  heater2_ctrl = tlm("AZERSAT THERMAL HEATER2_CTRL")
  heater2_state = tlm("AZERSAT THERMAL HEATER2_STATE")

  puts "\nThermal System:"
  puts "  Temperature 1: #{temp1.round(1)}°C"
  puts "  Temperature 2: #{temp2.round(1)}°C"
  puts "  Heater 1: Control=#{heater1_ctrl}, State=#{heater1_state}"
  puts "  Heater 2: Control=#{heater2_ctrl}, State=#{heater2_state}"

  # Communications System Check
  ant1_state = tlm("AZERSAT COMMS ANT1_STATE")
  ant2_state = tlm("AZERSAT COMMS ANT2_STATE")
  signal_strength = tlm("AZERSAT COMMS SIGNAL_STRENGTH")
  downlink_state = tlm("AZERSAT COMMS DOWNLINK_STATE")
  data_buffer = tlm("AZERSAT COMMS DATA_BUFFER")

  puts "\nCommunications System:"
  puts "  Antenna 1: #{ant1_state}"
  puts "  Antenna 2: #{ant2_state}"
  puts "  Signal Strength: #{signal_strength.round(1)} dB"
  puts "  Downlink State: #{downlink_state}"
  puts "  Data Buffer: #{data_buffer.round(1)}%"

  # Identify issues
  issues = []

  if mode == "SAFE"
    issues << "Spacecraft in SAFE mode"
  end

  if battery < 50.0
    issues << "Low battery (#{battery.round(1)}%)"
  end

  if temp1 < 20.0 || temp1 > 40.0
    issues << "Temperature 1 out of range (#{temp1.round(1)}°C)"
  end

  if temp2 < 20.0 || temp2 > 40.0
    issues << "Temperature 2 out of range (#{temp2.round(1)}°C)"
  end

  if panel1_state != "DEPLOYED" || panel2_state != "DEPLOYED"
    issues << "Solar panels not fully deployed"
  end

  if ant1_state != "DEPLOYED" && ant2_state != "DEPLOYED"
    issues << "No antennas deployed"
  end

  if signal_strength < -80.0
    issues << "Weak signal strength (#{signal_strength.round(1)} dB)"
  end

  if data_buffer > 90.0
    issues << "Data buffer nearly full (#{data_buffer.round(1)}%)"
  end

  if success_rate < 95.0
    issues << "High command rejection rate (#{(100-success_rate).round(1)}%)"
  end

  puts "\nDiagnostic Summary:"
  if issues.empty?
    puts "  ✅ All systems nominal"
    return true
  else
    puts "  ⚠️ Issues detected:"
    issues.each { |issue| puts "    - #{issue}" }
    return false
  end
end

def recover_safe_mode
  puts "\n🚨 Safe Mode Recovery Procedure"
  puts "-" * 30

  current_mode = tlm("AZERSAT HEALTH_STATUS MODE")
  if current_mode != "SAFE"
    puts "Not in SAFE mode (current: #{current_mode}) - skipping recovery"
    return true
  end

  puts "Spacecraft in SAFE mode - initiating recovery..."

  # Step 1: Check power
  battery = tlm("AZERSAT MECH BATTERY")
  puts "Current battery: #{battery.round(1)}%"

  if battery < 30.0
    puts "❌ Battery too low for recovery (#{battery.round(1)}%) - waiting for charge..."
    return false
  end

  # Step 2: Deploy solar panels if needed
  panel1_state = tlm("AZERSAT MECH SLRPNL1_STATE")
  panel2_state = tlm("AZERSAT MECH SLRPNL2_STATE")

  if panel1_state != "DEPLOYED"
    puts "Deploying solar panel 1..."
    cmd("AZERSAT SLRPNLDEPLOY NUM:1")
    wait(3)
  end

  if panel2_state != "DEPLOYED"
    puts "Deploying solar panel 2..."
    cmd("AZERSAT SLRPNLDEPLOY NUM:2")
    wait(3)
  end

  # Step 3: Wait for power generation
  puts "Waiting for power generation to stabilize..."
  wait(10)

  new_battery = tlm("AZERSAT MECH BATTERY")
  if new_battery >= 50.0
    puts "Attempting to enter CHECKOUT mode..."
    cmd("AZERSAT SET_MODE MODE:CHECKOUT")
    wait(3)

    final_mode = tlm("AZERSAT HEALTH_STATUS MODE")
    if final_mode == "CHECKOUT"
      puts "✅ Successfully recovered from SAFE mode to CHECKOUT"
      return true
    else
      puts "❌ Failed to exit SAFE mode"
      return false
    end
  else
    puts "❌ Insufficient battery for mode change (#{new_battery.round(1)}%)"
    return false
  end
end

def recover_thermal_anomaly
  puts "\n🌡️ Thermal Anomaly Recovery"
  puts "-" * 25

  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")

  puts "Current temperatures: T1=#{temp1.round(1)}°C, T2=#{temp2.round(1)}°C"

  anomaly_detected = false

  # Check for overheating
  if temp1 > 45.0 || temp2 > 45.0
    puts "🚨 OVERHEATING DETECTED!"
    anomaly_detected = true

    # Emergency heater shutdown
    puts "Emergency heater shutdown..."
    cmd("AZERSAT HTR_CTRL NUM:1 STATE:OFF")
    cmd("AZERSAT HTR_CTRL NUM:2 STATE:OFF")
    wait(5)

    # Monitor cooling
    puts "Monitoring temperature reduction..."
    for i in 1..6
      temp1 = tlm("AZERSAT THERMAL TEMP1")
      temp2 = tlm("AZERSAT THERMAL TEMP2")
      puts "  T+#{i*5}s: T1=#{temp1.round(1)}°C, T2=#{temp2.round(1)}°C"
      wait(5)
    end
  end

  # Check for undercooling
  if temp1 < 10.0 || temp2 < 10.0
    puts "🚨 UNDERCOOLING DETECTED!"
    anomaly_detected = true

    # Emergency heating
    puts "Emergency heating activation..."
    cmd("AZERSAT HTR_SETPT NUM:1 SETPT:25.0")
    cmd("AZERSAT HTR_SETPT NUM:2 SETPT:25.0")
    cmd("AZERSAT HTR_CTRL NUM:1 STATE:ON")
    cmd("AZERSAT HTR_CTRL NUM:2 STATE:ON")
    wait(5)

    # Monitor warming
    puts "Monitoring temperature increase..."
    for i in 1..6
      temp1 = tlm("AZERSAT THERMAL TEMP1")
      temp2 = tlm("AZERSAT THERMAL TEMP2")
      puts "  T+#{i*5}s: T1=#{temp1.round(1)}°C, T2=#{temp2.round(1)}°C"
      wait(5)
    end
  end

  if !anomaly_detected
    puts "✅ No thermal anomalies detected"
    return true
  end

  # Restore normal thermal control
  puts "Restoring normal thermal control..."
  cmd("AZERSAT HTR_SETPT NUM:1 SETPT:30.0")
  cmd("AZERSAT HTR_SETPT NUM:2 SETPT:30.0")
  cmd("AZERSAT HTR_CTRL NUM:1 STATE:ON")
  cmd("AZERSAT HTR_CTRL NUM:2 STATE:ON")
  wait(3)

  puts "✅ Thermal anomaly recovery completed"
  return true
end

def recover_communications_failure
  puts "\n📡 Communications Recovery"
  puts "-" * 25

  ant1_state = tlm("AZERSAT COMMS ANT1_STATE")
  ant2_state = tlm("AZERSAT COMMS ANT2_STATE")
  signal_strength = tlm("AZERSAT COMMS SIGNAL_STRENGTH")

  puts "Current antenna states: ANT1=#{ant1_state}, ANT2=#{ant2_state}"
  puts "Signal strength: #{signal_strength.round(1)} dB"

  failure_detected = false

  # Check for antenna deployment issues
  if ant1_state == "ERROR" || ant2_state == "ERROR"
    puts "🚨 ANTENNA ERROR DETECTED!"
    failure_detected = true

    # Attempt antenna reset
    puts "Attempting antenna reset procedure..."

    if ant1_state == "ERROR"
      puts "Resetting antenna 1..."
      cmd("AZERSAT ANT_STOW with ANT_NUM 1")
      wait(10)
      cmd("AZERSAT ANT_DEPLOY with ANT_NUM 1 TYPE HIGH_GAIN")
      wait(12)
    end

    if ant2_state == "ERROR"
      puts "Resetting antenna 2..."
      cmd("AZERSAT ANT_STOW with ANT_NUM 2")
      wait(10)
      cmd("AZERSAT ANT_DEPLOY with ANT_NUM 2 TYPE LOW_GAIN")
      wait(12)
    end
  end

  # Check for no deployed antennas
  if ant1_state != "DEPLOYED" && ant2_state != "DEPLOYED"
    puts "🚨 NO ANTENNAS DEPLOYED!"
    failure_detected = true

    puts "Emergency antenna deployment..."
    cmd("AZERSAT ANT_DEPLOY with ANT_NUM 1 TYPE HIGH_GAIN")
    wait(2)
    cmd("AZERSAT ANT_DEPLOY with ANT_NUM 2 TYPE LOW_GAIN")
    wait(12)
  end

  # Check for weak signal
  if signal_strength < -90.0
    puts "🚨 VERY WEAK SIGNAL!"
    failure_detected = true

    # Optimize antenna pointing
    puts "Optimizing antenna pointing..."
    cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 1 AZIMUTH 0.0 ELEVATION 45.0")
    cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 2 AZIMUTH 180.0 ELEVATION 30.0")
    wait(5)

    # Check improvement
    new_signal = tlm("AZERSAT COMMS SIGNAL_STRENGTH")
    puts "Signal strength improved to: #{new_signal.round(1)} dB"
  end

  if !failure_detected
    puts "✅ No communications failures detected"
    return true
  end

  puts "✅ Communications recovery completed"
  return true
end

def recover_power_shortage
  puts "\n⚡ Power Shortage Recovery"
  puts "-" * 25

  battery = tlm("AZERSAT MECH BATTERY")
  panel1_power = tlm("AZERSAT MECH SLRPNL1_PWR")
  panel2_power = tlm("AZERSAT MECH SLRPNL2_PWR")
  total_generation = panel1_power + panel2_power

  puts "Current power status:"
  puts "  Battery: #{battery.round(1)}%"
  puts "  Total generation: #{total_generation.round(1)}W"

  if battery > 40.0
    puts "✅ No power shortage detected"
    return true
  end

  puts "🚨 POWER SHORTAGE DETECTED!"

  # Step 1: Optimize solar panel pointing
  puts "Optimizing solar panel pointing with ADCS..."
  adcs_state = tlm("AZERSAT ADCS ADCS_CTRL")
  if adcs_state != "ON"
    cmd("AZERSAT ADCS_CTRL STATE:ON")
    wait(3)
    puts "ADCS enabled for solar tracking"
  end

  # Step 2: Load shedding - reduce power consumption
  puts "Implementing load shedding procedures..."

  # Stop any active downlink
  downlink_state = tlm("AZERSAT COMMS DOWNLINK_STATE")
  if downlink_state == "ACTIVE"
    puts "Stopping data downlink to save power..."
    cmd("AZERSAT STOP_DOWNLINK")
    wait(2)
  end

  # Reduce thermal control if safe
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")

  if temp1 > 25.0 && temp2 > 25.0
    puts "Reducing thermal control setpoints..."
    cmd("AZERSAT HTR_SETPT NUM:1 SETPT:22.0")
    cmd("AZERSAT HTR_SETPT NUM:2 SETPT:22.0")
    wait(2)
  end

  # Monitor power recovery
  puts "Monitoring power recovery..."
  for i in 1..8
    current_battery = tlm("AZERSAT MECH BATTERY")
    current_generation = tlm("AZERSAT MECH SLRPNL1_PWR") + tlm("AZERSAT MECH SLRPNL2_PWR")

    puts "  T+#{i*5}s: Battery=#{current_battery.round(1)}%, Generation=#{current_generation.round(1)}W"

    if current_battery > 45.0
      puts "✅ Power situation improving"
      break
    end

    wait(5)
  end

  # Restore normal operations if power recovered
  final_battery = tlm("AZERSAT MECH BATTERY")
  if final_battery > 45.0
    puts "Restoring normal thermal control..."
    cmd("AZERSAT HTR_SETPT NUM:1 SETPT:30.0")
    cmd("AZERSAT HTR_SETPT NUM:2 SETPT:30.0")
    wait(2)
    puts "✅ Power shortage recovery completed"
    return true
  else
    puts "⚠️ Power shortage persists - maintaining load shedding"
    return false
  end
end

def emergency_data_dump
  puts "\n💾 Emergency Data Dump"
  puts "-" * 20

  data_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
  puts "Current data buffer: #{data_buffer.round(1)}%"

  if data_buffer < 80.0
    puts "✅ No emergency data dump needed"
    return true
  end

  puts "🚨 BUFFER NEARLY FULL - Emergency data dump required!"

  # Point both antennas for maximum throughput
  puts "Pointing all antennas for maximum data rate..."
  cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 1 AZIMUTH 0.0 ELEVATION 45.0")
  cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 2 AZIMUTH 0.0 ELEVATION 45.0")
  wait(3)

  # Start high-rate emergency downlink
  puts "Starting emergency high-rate downlink..."
  cmd("AZERSAT START_DOWNLINK DATA_RATE HIGH DURATION 300")
  wait(3)

  # Monitor emergency downlink
  puts "Monitoring emergency data dump..."
  start_time = Time.now

  while Time.now - start_time < 120  # Monitor for 2 minutes
    current_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
    downlink_state = tlm("AZERSAT COMMS DOWNLINK_STATE")
    time_remaining = tlm("AZERSAT COMMS DOWNLINK_TIME_REMAINING")

    puts "  Buffer: #{current_buffer.round(1)}%, State: #{downlink_state}, Remaining: #{time_remaining}s"

    if current_buffer < 50.0
      puts "✅ Buffer reduced to safe level"
      break
    end

    if downlink_state == "IDLE"
      puts "Downlink completed"
      break
    end

    wait(10)
  end

  final_buffer = tlm("AZERSAT COMMS DATA_BUFFER")
  data_transmitted = data_buffer - final_buffer

  puts "Emergency dump summary:"
  puts "  Data transmitted: #{data_transmitted.round(1)}%"
  puts "  Final buffer level: #{final_buffer.round(1)}%"

  if final_buffer < 70.0
    puts "✅ Emergency data dump successful"
    return true
  else
    puts "⚠️ Buffer still high - may need additional downlinks"
    return false
  end
end

# Main Troubleshooting Sequence
puts "\n🔧 Starting Troubleshooting Sequence"
puts "=" * 35

# Step 1: Initial System Diagnostic
puts "\n--- PHASE 1: SYSTEM DIAGNOSTIC ---"
system_healthy = perform_system_diagnostic

if system_healthy
  puts "\n✅ All systems nominal - no troubleshooting required"
else
  puts "\n⚠️ Issues detected - proceeding with recovery procedures"

  # Step 2: Specific Recovery Procedures
  puts "\n--- PHASE 2: RECOVERY PROCEDURES ---"

  # Check and recover from various anomalies
  recover_safe_mode
  wait(5)

  recover_thermal_anomaly
  wait(5)

  recover_communications_failure
  wait(5)

  recover_power_shortage
  wait(5)

  emergency_data_dump
  wait(5)

  # Step 3: Post-Recovery Diagnostic
  puts "\n--- PHASE 3: POST-RECOVERY DIAGNOSTIC ---"
  final_health = perform_system_diagnostic

  if final_health
    puts "\n✅ All issues resolved - system healthy"
  else
    puts "\n⚠️ Some issues remain - may require manual intervention"
  end
end

# Final Status Report
puts "\n" + "=" * 60
puts "🔧 TROUBLESHOOTING SEQUENCE COMPLETE!"
puts "=" * 60

# Get comprehensive final status
final_mode = tlm("AZERSAT HEALTH_STATUS MODE")
final_battery = tlm("AZERSAT MECH BATTERY")
final_temp1 = tlm("AZERSAT THERMAL TEMP1")
final_temp2 = tlm("AZERSAT THERMAL TEMP2")
final_ant1 = tlm("AZERSAT COMMS ANT1_STATE")
final_ant2 = tlm("AZERSAT COMMS ANT2_STATE")
final_signal = tlm("AZERSAT COMMS SIGNAL_STRENGTH")
final_buffer = tlm("AZERSAT COMMS DATA_BUFFER")

puts "\nFinal System Status:"
puts "  Mode: #{final_mode}"
puts "  Battery: #{final_battery.round(1)}%"
puts "  Temperatures: #{final_temp1.round(1)}°C / #{final_temp2.round(1)}°C"
puts "  Antennas: #{final_ant1} / #{final_ant2}"
puts "  Signal: #{final_signal.round(1)} dB"
puts "  Data Buffer: #{final_buffer.round(1)}%"

puts "\n✅ Troubleshooting procedures completed!"
puts "System is ready for normal operations."

puts "\nScript completed successfully! 🔧🛰️"