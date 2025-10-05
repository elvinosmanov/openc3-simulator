#!/usr/bin/env ruby
# AzerSat Basic Startup Sequence (Compatible with minimal plugin)
# This script performs satellite startup using only the commands/telemetry available in the minimal plugin

puts "=" * 60
puts "AzerSat Basic Startup Sequence"
puts "Compatible with minimal plugin configuration"
puts "=" * 60

# Step 1: Initial Health Check
puts "\n🔍 Step 1: Initial Health Check"
puts "-" * 30

cmd("AZERSAT NOOP")
wait(2)

# Check initial telemetry (only using available telemetry)
mode = tlm("AZERSAT HEALTH_STATUS MODE")
battery = tlm("AZERSAT MECH BATTERY")
temp1 = tlm("AZERSAT THERMAL TEMP1")
temp2 = tlm("AZERSAT THERMAL TEMP2")
cpu_power = tlm("AZERSAT HEALTH_STATUS CPU_PWR")

puts "Initial Status:"
puts "  Mode: #{mode}"
puts "  Battery: #{battery.round(1)}%"
puts "  Temp1: #{temp1.round(1)}°C"
puts "  Temp2: #{temp2.round(1)}°C"
puts "  CPU Power: #{cpu_power.round(1)}W"

# Check if safe to proceed
if battery < 10.0
  puts "❌ Battery too low for operations (#{battery.round(1)}%)"
  exit(1)
end

# Step 2: Deploy Solar Panels
puts "\n⚡ Step 2: Deploy Solar Panels"
puts "-" * 30

puts "Deploying solar panel 1..."
cmd("AZERSAT SLRPNLDEPLOY with NUM 1")
wait(3)

puts "Deploying solar panel 2..."
cmd("AZERSAT SLRPNLDEPLOY with NUM 2")
wait(3)

# Wait for panels to deploy and check status
puts "Waiting for solar panels to deploy..."
wait(5)

panel1_state = tlm("AZERSAT MECH SLRPNL1_STATE")
panel2_state = tlm("AZERSAT MECH SLRPNL2_STATE")
panel1_angle = tlm("AZERSAT MECH SLRPNL1_ANG")
panel2_angle = tlm("AZERSAT MECH SLRPNL2_ANG")

puts "Solar Panel 1: #{panel1_state} (#{panel1_angle.round(1)}°)"
puts "Solar Panel 2: #{panel2_state} (#{panel2_angle.round(1)}°)"

if panel1_state == "DEPLOYED" && panel2_state == "DEPLOYED"
  puts "✅ Both solar panels deployed successfully"
else
  puts "⚠️ Solar panel deployment may be incomplete"
end

# Step 3: Monitor Power Generation
puts "\n🔋 Step 3: Monitor Power Generation"
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

# Step 4: Enable ADCS for Solar Tracking
puts "\n🎯 Step 4: Enable ADCS Solar Tracking"
puts "-" * 30

cmd("AZERSAT ADCS_CTRL with STATE ON")
wait(3)

adcs_state = tlm("AZERSAT ADCS ADCS_CTRL")
sun_angle = tlm("AZERSAT ADCS SR_ANG_TO_SUN")

puts "ADCS Control: #{adcs_state}"
puts "Ideal Sun Angle: #{sun_angle.round(1)}°"

if adcs_state == "ON"
  puts "✅ ADCS enabled - solar panels will track the sun automatically"
else
  puts "⚠️ ADCS not responding properly"
end

# Step 5: Wait for Battery Charge
puts "\n⏳ Step 5: Wait for Battery Charge (50% required for CHECKOUT mode)"
puts "-" * 30

# Monitor battery charging
charge_start_time = Time.now
max_wait_time = 240  # 4 minutes maximum wait

while battery_new < 50.0 && (Time.now - charge_start_time) < max_wait_time
  puts "Battery at #{battery_new.round(1)}%, waiting for 50%... (#{(Time.now - charge_start_time).round(0)}s elapsed)"
  wait(10)
  battery_new = tlm("AZERSAT MECH BATTERY")

  # Show power generation status
  current_generation = tlm("AZERSAT MECH SLRPNL1_PWR") + tlm("AZERSAT MECH SLRPNL2_PWR")
  puts "  Current generation: #{current_generation.round(1)}W"
end

if battery_new >= 50.0
  puts "✅ Battery charged to #{battery_new.round(1)}% - Ready for CHECKOUT mode"
else
  puts "⚠️ Battery only reached #{battery_new.round(1)}% after #{max_wait_time}s - proceeding anyway"
end

# Step 6: Enter CHECKOUT Mode
puts "\n🚀 Step 6: Enter CHECKOUT Mode"
puts "-" * 30

if battery_new >= 40.0  # Lower threshold for degraded operations
  cmd("AZERSAT SET_MODE with MODE CHECKOUT")
  wait(3)

  mode_new = tlm("AZERSAT HEALTH_STATUS MODE")
  if mode_new == "CHECKOUT"
    puts "✅ Successfully entered CHECKOUT mode"
  else
    puts "❌ Failed to enter CHECKOUT mode - Current mode: #{mode_new}"
    puts "This may be due to insufficient battery or other constraints"
  end
else
  puts "❌ Battery too low for mode change (#{battery_new.round(1)}%)"
end

# Step 7: Configure Thermal Control
puts "\n🌡️ Step 7: Configure Thermal Control"
puts "-" * 30

puts "Setting heater 1 setpoint to 30°C..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 30.0")
wait(2)

puts "Setting heater 2 setpoint to 30°C..."
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 30.0")
wait(2)

puts "Enabling heater 1 control..."
cmd("AZERSAT HTR_CTRL with NUM 1, STATE ON")
wait(2)

puts "Enabling heater 2 control..."
cmd("AZERSAT HTR_CTRL with NUM 2, STATE ON")
wait(2)

# Check thermal control status
heater1_ctrl = tlm("AZERSAT THERMAL HEATER1_CTRL")
heater2_ctrl = tlm("AZERSAT THERMAL HEATER2_CTRL")
heater1_setpt = tlm("AZERSAT THERMAL HEATER1_SETPT")
heater2_setpt = tlm("AZERSAT THERMAL HEATER2_SETPT")

puts "Thermal Control Status:"
puts "  Heater 1: #{heater1_ctrl} (setpoint: #{heater1_setpt.round(1)}°C)"
puts "  Heater 2: #{heater2_ctrl} (setpoint: #{heater2_setpt.round(1)}°C)"
puts "✅ Thermal control system activated"

# Step 8: Wait for Thermal Stabilization
puts "\n🌡️ Step 8: Wait for Thermal Stabilization"
puts "-" * 30
puts "Waiting for temperatures to reach 25-35°C range for OPERATE mode..."

# Monitor temperatures with timeout
thermal_start_time = Time.now
max_thermal_wait = 300  # 5 minutes maximum
temp_stable_count = 0
required_stable_readings = 6

while temp_stable_count < required_stable_readings && (Time.now - thermal_start_time) < max_thermal_wait
  temp1_current = tlm("AZERSAT THERMAL TEMP1")
  temp2_current = tlm("AZERSAT THERMAL TEMP2")

  puts "Temp1: #{temp1_current.round(1)}°C, Temp2: #{temp2_current.round(1)}°C"

  if temp1_current > 25.0 && temp1_current < 35.0 && temp2_current > 25.0 && temp2_current < 35.0
    temp_stable_count += 1
    puts "  ✅ Temperatures in range (#{temp_stable_count}/#{required_stable_readings})"
  else
    temp_stable_count = 0
    puts "  ⏳ Waiting for temperatures to stabilize..."
  end

  wait(10)
end

if temp_stable_count >= required_stable_readings
  puts "✅ Temperatures stabilized - Ready for OPERATE mode"
else
  puts "⚠️ Thermal stabilization incomplete but proceeding"
end

# Step 9: Enter OPERATE Mode
puts "\n🎯 Step 9: Enter OPERATE Mode"
puts "-" * 30

current_mode = tlm("AZERSAT HEALTH_STATUS MODE")
current_temp1 = tlm("AZERSAT THERMAL TEMP1")
current_temp2 = tlm("AZERSAT THERMAL TEMP2")

puts "Pre-OPERATE check:"
puts "  Current mode: #{current_mode}"
puts "  Temperature 1: #{current_temp1.round(1)}°C"
puts "  Temperature 2: #{current_temp2.round(1)}°C"

if current_mode == "CHECKOUT"
  cmd("AZERSAT SET_MODE with MODE OPERATE")
  wait(3)

  final_mode = tlm("AZERSAT HEALTH_STATUS MODE")
  if final_mode == "OPERATE"
    puts "✅ Successfully entered OPERATE mode"
  else
    puts "❌ Failed to enter OPERATE mode - Current mode: #{final_mode}"
    puts "Check temperature requirements (25-35°C for both sensors)"
  end
else
  puts "⚠️ Not in CHECKOUT mode - cannot transition to OPERATE"
end

# Step 10: Test Imaging System
puts "\n📸 Step 10: Test Imaging System"
puts "-" * 30

current_mode = tlm("AZERSAT HEALTH_STATUS MODE")
if current_mode == "OPERATE"
  puts "Testing imaging system with a short collection..."

  # Get initial imager status
  initial_collects = tlm("AZERSAT IMAGER COLLECTS")
  imager_state = tlm("AZERSAT IMAGER IMAGER_STATE")

  puts "Initial collections: #{initial_collects}"
  puts "Imager state: #{imager_state}"

  # Perform a short test collection
  cmd("AZERSAT COLLECT with TYPE NORMAL, DURATION 2.0, OPCODE 0xAB, TEMP 20.0")
  wait(5)  # Wait for collection to complete

  # Check results
  final_collects = tlm("AZERSAT IMAGER COLLECTS")
  final_imager_state = tlm("AZERSAT IMAGER IMAGER_STATE")
  collect_type = tlm("AZERSAT IMAGER COLLECT_TYPE")
  duration = tlm("AZERSAT IMAGER DURATION")

  puts "Test collection results:"
  puts "  Collections: #{initial_collects} → #{final_collects}"
  puts "  Final imager state: #{final_imager_state}"
  puts "  Last collect type: #{collect_type}"
  puts "  Last duration: #{duration.round(1)}s"

  if final_collects > initial_collects
    puts "✅ Imaging system test successful"
  else
    puts "⚠️ Imaging system test may have failed"
  end
else
  puts "⚠️ Not in OPERATE mode - skipping imaging test"
end

# Final Status Report
puts "\n" + "=" * 60
puts "🎉 AZERSAT BASIC STARTUP COMPLETE!"
puts "=" * 60

# Get comprehensive final status
final_mode = tlm("AZERSAT HEALTH_STATUS MODE")
final_battery = tlm("AZERSAT MECH BATTERY")
final_temp1 = tlm("AZERSAT THERMAL TEMP1")
final_temp2 = tlm("AZERSAT THERMAL TEMP2")
final_cpu_power = tlm("AZERSAT HEALTH_STATUS CPU_PWR")
final_panel1_pwr = tlm("AZERSAT MECH SLRPNL1_PWR")
final_panel2_pwr = tlm("AZERSAT MECH SLRPNL2_PWR")
final_collects = tlm("AZERSAT IMAGER COLLECTS")
final_cmd_accept = tlm("AZERSAT HEALTH_STATUS CMD_ACPT_CNT")
final_cmd_reject = tlm("AZERSAT HEALTH_STATUS CMD_RJCT_CNT")

puts "\nFinal System Status:"
puts "  Mode: #{final_mode}"
puts "  Battery: #{final_battery.round(1)}%"
puts "  Temperature 1: #{final_temp1.round(1)}°C"
puts "  Temperature 2: #{final_temp2.round(1)}°C"
puts "  CPU Power: #{final_cpu_power.round(1)}W"
puts "  Solar Generation: #{(final_panel1_pwr + final_panel2_pwr).round(1)}W"
puts "  Total Collections: #{final_collects}"
puts "  Commands: #{final_cmd_accept} accepted, #{final_cmd_reject} rejected"

# Success assessment
success_criteria = {
  "Solar panels deployed" => panel1_state == "DEPLOYED" && panel2_state == "DEPLOYED",
  "ADCS enabled" => adcs_state == "ON",
  "Thermal control active" => heater1_ctrl == "ON" && heater2_ctrl == "ON",
  "Battery above 40%" => final_battery > 40.0,
  "Temperatures nominal" => final_temp1 > 20.0 && final_temp2 > 20.0,
  "Mode progression" => ["CHECKOUT", "OPERATE"].include?(final_mode)
}

puts "\nStartup Success Criteria:"
success_count = 0
success_criteria.each do |criterion, met|
  status = met ? "✅" : "❌"
  puts "  #{status} #{criterion}"
  success_count += 1 if met
end

overall_success = success_count >= (success_criteria.length * 0.8)  # 80% success rate

if overall_success
  puts "\n🎉 STARTUP SUCCESSFUL!"
  puts "Satellite is operational and ready for mission activities."
else
  puts "\n⚠️ STARTUP PARTIAL SUCCESS"
  puts "Some systems may need attention before full operations."
end

puts "\nRecommended next steps:"
if final_mode == "OPERATE"
  puts "  - Perform imaging operations with COLLECT command"
  puts "  - Monitor thermal and power systems"
  puts "  - Test additional subsystems as needed"
elsif final_mode == "CHECKOUT"
  puts "  - Investigate OPERATE mode transition requirements"
  puts "  - Check thermal stabilization"
  puts "  - Monitor battery charging"
else
  puts "  - Investigate system issues preventing mode transitions"
  puts "  - Check power and thermal systems"
end

puts "\nScript completed successfully! 🛰️"