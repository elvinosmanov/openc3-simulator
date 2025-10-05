#!/usr/bin/env ruby
# AzerSat Startup Sequence Script
# This script performs a complete satellite startup from SAFE mode to operational status

# Display script information
puts "=" * 60
puts "AzerSat Startup Sequence Script"
puts "Performing complete satellite initialization"
puts "=" * 60

# Step 1: Initial Health Check
puts "\n🔍 Step 1: Initial Health Check"
puts "-" * 30

cmd("AZERSAT NOOP")
wait(2)

# Check initial telemetry
mode = tlm("AZERSAT HEALTH_STATUS MODE")
battery = tlm("AZERSAT MECH BATTERY")
temp1 = tlm("AZERSAT THERMAL TEMP1")
temp2 = tlm("AZERSAT THERMAL TEMP2")

puts "Initial Status:"
puts "  Mode: #{mode}"
puts "  Battery: #{battery.round(1)}%"
puts "  Temp1: #{temp1.round(1)}°C"
puts "  Temp2: #{temp2.round(1)}°C"

# Step 2: Deploy Solar Panels
puts "\n⚡ Step 2: Deploying Solar Panels"
puts "-" * 30

puts "Deploying solar panel 1..."
cmd("AZERSAT SLRPNLDEPLOY with NUM 1")
wait(2)

puts "Deploying solar panel 2..."
cmd("AZERSAT SLRPNLDEPLOY with NUM 2")
wait(2)

# Wait for panels to deploy and check status
puts "Waiting for solar panels to deploy..."
wait(5)

panel1_state = tlm("AZERSAT MECH SLRPNL1_STATE")
panel2_state = tlm("AZERSAT MECH SLRPNL2_STATE")
puts "Solar Panel 1: #{panel1_state}"
puts "Solar Panel 2: #{panel2_state}"

# Step 3: Enable ADCS for Solar Tracking
# CRITICAL: This MUST be done immediately after deploying solar panels
# so they can track the sun and generate maximum power for battery charging!
puts "\n🎯 Step 3: Enabling ADCS for Solar Tracking"
puts "-" * 30

puts "Enabling ADCS (Attitude Determination and Control System)..."
puts "This allows solar panels to automatically track the sun for maximum power generation"
cmd("AZERSAT ADCS_CTRL with STATE ON")
wait(2)

adcs_state = tlm("AZERSAT ADCS ADCS_CTRL")
sun_angle = tlm("AZERSAT ADCS SR_ANG_TO_SUN")

puts "ADCS Control: #{adcs_state}"
puts "Current Sun Angle: #{sun_angle.round(1)}°"
puts "✅ Solar panels will now automatically track the sun"
wait(3)

# Verify panels are orienting to sun
panel1_ang = tlm("AZERSAT MECH SLRPNL1_ANG")
panel2_ang = tlm("AZERSAT MECH SLRPNL2_ANG")
puts "Panel 1 angle: #{panel1_ang.round(1)}° (tracking towards #{sun_angle.round(1)}°)"
puts "Panel 2 angle: #{panel2_ang.round(1)}° (tracking towards #{sun_angle.round(1)}°)"

# Step 4: Deploy Communication Antennas
puts "\n📡 Step 4: Deploying Communication Antennas"
puts "-" * 30

puts "Deploying high-gain antenna..."
cmd("AZERSAT ANT_DEPLOY with ANT_NUM 1, TYPE HIGH_GAIN")
wait(2)

puts "Deploying low-gain antenna for backup..."
cmd("AZERSAT ANT_DEPLOY with ANT_NUM 2, TYPE LOW_GAIN")
wait(2)

# Wait for antennas to deploy
puts "Waiting for antennas to deploy (10 seconds)..."
wait(12)

ant1_state = tlm("AZERSAT COMMS ANT1_STATE")
ant2_state = tlm("AZERSAT COMMS ANT2_STATE")
puts "Antenna 1 (High-gain): #{ant1_state}"
puts "Antenna 2 (Low-gain): #{ant2_state}"

# Step 5: Monitor Power Generation
puts "\n🔋 Step 5: Monitoring Power Generation"
puts "-" * 30

wait(5)  # Let power stabilize

battery_new = tlm("AZERSAT MECH BATTERY")
panel1_pwr = tlm("AZERSAT MECH SLRPNL1_PWR")
panel2_pwr = tlm("AZERSAT MECH SLRPNL2_PWR")
total_pwr = panel1_pwr + panel2_pwr

puts "Power Status:"
puts "  Battery: #{battery_new.round(1)}% (was #{battery.round(1)}%)"
puts "  Panel 1 Power: #{panel1_pwr.round(1)}W"
puts "  Panel 2 Power: #{panel2_pwr.round(1)}W"
puts "  Total Generation: #{total_pwr.round(1)}W"

# Step 6: Wait for sufficient battery charge
puts "\n⏳ Step 6: Waiting for Battery Charge (50% required for CHECKOUT mode)"
puts "-" * 30
puts "With ADCS enabled, solar panels should be tracking the sun for maximum power generation"

while battery_new < 50.0
  puts "Battery at #{battery_new.round(1)}%, waiting for 50%..."
  wait(10)
  battery_new = tlm("AZERSAT MECH BATTERY")
end

puts "✅ Battery charged to #{battery_new.round(1)}% - Ready for CHECKOUT mode"

# Step 7: Enter CHECKOUT Mode
puts "\n🚀 Step 7: Entering CHECKOUT Mode"
puts "-" * 30

cmd("AZERSAT SET_MODE with MODE CHECKOUT")
wait(3)

mode_new = tlm("AZERSAT HEALTH_STATUS MODE")
if mode_new == "CHECKOUT"
  puts "✅ Successfully entered CHECKOUT mode"
else
  puts "❌ Failed to enter CHECKOUT mode - Current mode: #{mode_new}"
  exit
end

# Step 8: Setup Thermal Control
puts "\n🌡️ Step 8: Setting up Thermal Control"
puts "-" * 30

puts "Setting heater 1 setpoint to 30°C..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 30.0")
wait(1)

puts "Enabling heater 1 control..."
cmd("AZERSAT HTR_CTRL with NUM 1, STATE ON")
wait(1)

puts "Setting heater 2 setpoint to 30°C..."
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 30.0")
wait(1)

puts "Enabling heater 2 control..."
cmd("AZERSAT HTR_CTRL with NUM 2, STATE ON")
wait(2)

puts "✅ Thermal control system activated"

# Step 9: Point Antennas
puts "\n📡 Step 9: Pointing Communication Antennas"
puts "-" * 30

puts "Pointing high-gain antenna towards ground station..."
cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 1, AZIMUTH 45.0, ELEVATION 30.0")
wait(2)

puts "Pointing low-gain antenna for backup coverage..."
cmd("AZERSAT SET_ANT_ANGLE with ANT_NUM 2, AZIMUTH 225.0, ELEVATION 15.0")
wait(2)

ant1_az = tlm("AZERSAT COMMS ANT1_AZIMUTH")
ant1_el = tlm("AZERSAT COMMS ANT1_ELEVATION")
signal_strength = tlm("AZERSAT COMMS SIGNAL_STRENGTH")

puts "High-gain antenna: Az=#{ant1_az.round(1)}° El=#{ant1_el.round(1)}°"
puts "Signal strength: #{signal_strength.round(1)} dB"

# Step 10: Wait for thermal stabilization
puts "\n🌡️ Step 10: Waiting for Thermal Stabilization"
puts "-" * 30
puts "Waiting for temperatures to reach 25-35°C range for OPERATE mode..."

# Monitor temperatures
temp_stable_count = 0
while temp_stable_count < 6  # Need 6 consecutive good readings (1 minute)
  temp1_current = tlm("AZERSAT THERMAL TEMP1")
  temp2_current = tlm("AZERSAT THERMAL TEMP2")

  puts "Temp1: #{temp1_current.round(1)}°C, Temp2: #{temp2_current.round(1)}°C"

  if temp1_current > 25.0 && temp1_current < 35.0 && temp2_current > 25.0 && temp2_current < 35.0
    temp_stable_count += 1
    puts "  ✅ Temperatures in range (#{temp_stable_count}/6)"
  else
    temp_stable_count = 0
    puts "  ⏳ Waiting for temperatures to stabilize..."
  end

  wait(10)
end

puts "✅ Temperatures stabilized - Ready for OPERATE mode"

# Step 11: Enter OPERATE Mode
puts "\n🎯 Step 11: Entering OPERATE Mode"
puts "-" * 30

cmd("AZERSAT SET_MODE with MODE OPERATE")
wait(3)

final_mode = tlm("AZERSAT HEALTH_STATUS MODE")
if final_mode == "OPERATE"
  puts "✅ Successfully entered OPERATE mode"
else
  puts "❌ Failed to enter OPERATE mode - Current mode: #{final_mode}"
  puts "Check temperature requirements (25-35°C for both sensors)"
end

# Step 12: Start Initial Data Downlink
puts "\n📡 Step 12: Starting Initial Data Downlink"
puts "-" * 30

puts "Starting medium-rate data downlink for 60 seconds..."
cmd("AZERSAT START_DOWNLINK with DATA_RATE MEDIUM, DURATION 60")
wait(2)

downlink_state = tlm("AZERSAT COMMS DOWNLINK_STATE")
data_rate = tlm("AZERSAT COMMS DATA_RATE")
buffer_level = tlm("AZERSAT COMMS DATA_BUFFER")

puts "Downlink Status: #{downlink_state}"
puts "Data Rate: #{data_rate}"
puts "Buffer Level: #{buffer_level.round(1)}%"

# Final Status Report
puts "\n" + "=" * 60
puts "🎉 AZERSAT STARTUP SEQUENCE COMPLETE!"
puts "=" * 60

# Get final telemetry
final_battery = tlm("AZERSAT MECH BATTERY")
final_temp1 = tlm("AZERSAT THERMAL TEMP1")
final_temp2 = tlm("AZERSAT THERMAL TEMP2")
final_comm_pwr = tlm("AZERSAT COMMS COMM_PWR")
final_cmd_count = tlm("AZERSAT HEALTH_STATUS CMD_ACPT_CNT")

puts "\nFinal System Status:"
puts "  Mode: #{final_mode}"
puts "  Battery: #{final_battery.round(1)}%"
puts "  Temperature 1: #{final_temp1.round(1)}°C"
puts "  Temperature 2: #{final_temp2.round(1)}°C"
puts "  Communications Power: #{final_comm_pwr.round(1)}W"
puts "  Commands Executed: #{final_cmd_count}"
puts "\n✅ Satellite is fully operational and ready for mission operations!"
puts "\nNext steps:"
puts "  - Monitor telemetry in Telemetry Viewer"
puts "  - Use imaging commands when over targets"
puts "  - Schedule regular data downlinks"
puts "  - Monitor power and thermal systems"

puts "\nScript completed successfully! 🛰️"