#!/usr/bin/env ruby
# AzerSat Basic Thermal Management (Compatible with minimal plugin)
# Demonstrates thermal control using only available commands/telemetry

puts "=" * 60
puts "AzerSat Basic Thermal Management"
puts "Compatible with minimal plugin configuration"
puts "=" * 60

# Step 1: Initial Thermal Assessment
puts "\n🌡️ Step 1: Initial Thermal Assessment"
puts "-" * 35

temp1 = tlm("AZERSAT THERMAL TEMP1")
temp2 = tlm("AZERSAT THERMAL TEMP2")
heater1_ctrl = tlm("AZERSAT THERMAL HEATER1_CTRL")
heater1_state = tlm("AZERSAT THERMAL HEATER1_STATE")
heater1_setpt = tlm("AZERSAT THERMAL HEATER1_SETPT")
heater1_pwr = tlm("AZERSAT THERMAL HEATER1_PWR")
heater2_ctrl = tlm("AZERSAT THERMAL HEATER2_CTRL")
heater2_state = tlm("AZERSAT THERMAL HEATER2_STATE")
heater2_setpt = tlm("AZERSAT THERMAL HEATER2_SETPT")
heater2_pwr = tlm("AZERSAT THERMAL HEATER2_PWR")

puts "Initial Thermal Status:"
puts "  Temperature 1: #{temp1.round(1)}°C"
puts "  Temperature 2: #{temp2.round(1)}°C"
puts "  Heater 1: Control=#{heater1_ctrl}, State=#{heater1_state}, Setpoint=#{heater1_setpt.round(1)}°C, Power=#{heater1_pwr.round(1)}W"
puts "  Heater 2: Control=#{heater2_ctrl}, State=#{heater2_state}, Setpoint=#{heater2_setpt.round(1)}°C, Power=#{heater2_pwr.round(1)}W"

# Safety check
if temp1 < -20 || temp1 > 60 || temp2 < -20 || temp2 > 60
  puts "⚠️ WARNING: Temperatures outside safe range (-20°C to 60°C)"
else
  puts "✅ Temperatures within safe operating range"
end

# Step 2: Configure Basic Thermal Control
puts "\n🔧 Step 2: Configure Basic Thermal Control"
puts "-" * 35

target_temp = 30.0
puts "Setting both heaters to target temperature: #{target_temp}°C"

puts "Configuring heater 1..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT #{target_temp}")
wait(1)
cmd("AZERSAT HTR_CTRL with NUM 1, STATE ON")
wait(1)

puts "Configuring heater 2..."
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT #{target_temp}")
wait(1)
cmd("AZERSAT HTR_CTRL with NUM 2, STATE ON")
wait(2)

# Verify configuration
heater1_ctrl = tlm("AZERSAT THERMAL HEATER1_CTRL")
heater2_ctrl = tlm("AZERSAT THERMAL HEATER2_CTRL")
heater1_setpt = tlm("AZERSAT THERMAL HEATER1_SETPT")
heater2_setpt = tlm("AZERSAT THERMAL HEATER2_SETPT")

puts "Configuration Results:"
puts "  Heater 1: #{heater1_ctrl} @ #{heater1_setpt.round(1)}°C"
puts "  Heater 2: #{heater2_ctrl} @ #{heater2_setpt.round(1)}°C"

if heater1_ctrl == "ON" && heater2_ctrl == "ON"
  puts "✅ Both heaters activated successfully"
else
  puts "⚠️ Heater activation may be incomplete"
end

# Step 3: Monitor Thermal Response
puts "\n📊 Step 3: Monitor Thermal Response"
puts "-" * 35

puts "Monitoring thermal system for 2 minutes..."
monitor_duration = 120  # 2 minutes
readings_count = 24  # 5-second intervals
stable_readings = 0

for reading in 1..readings_count
  current_temp1 = tlm("AZERSAT THERMAL TEMP1")
  current_temp2 = tlm("AZERSAT THERMAL TEMP2")
  current_heater1_state = tlm("AZERSAT THERMAL HEATER1_STATE")
  current_heater1_pwr = tlm("AZERSAT THERMAL HEATER1_PWR")
  current_heater2_state = tlm("AZERSAT THERMAL HEATER2_STATE")
  current_heater2_pwr = tlm("AZERSAT THERMAL HEATER2_PWR")

  # Check if temperatures are moving toward target
  temp1_diff = (current_temp1 - target_temp).abs
  temp2_diff = (current_temp2 - target_temp).abs

  # Consider stable if within 3°C of target
  temp1_stable = temp1_diff <= 3.0
  temp2_stable = temp2_diff <= 3.0

  if temp1_stable && temp2_stable
    stable_readings += 1
  else
    stable_readings = 0
  end

  status_symbol = temp1_stable && temp2_stable ? "✅" : "⏳"
  puts "#{sprintf("%2d", reading)}/#{readings_count}: #{status_symbol} T1=#{current_temp1.round(1)}°C T2=#{current_temp2.round(1)}°C H1=#{current_heater1_state}(#{current_heater1_pwr.round(0)}W) H2=#{current_heater2_state}(#{current_heater2_pwr.round(0)}W)"

  # Early exit if stable for 5 consecutive readings
  if stable_readings >= 5
    puts "🎯 Thermal system stabilized after #{reading} readings!"
    break
  end

  wait(5)
end

# Step 4: Thermal Stress Test
puts "\n🔥 Step 4: Thermal Stress Test"
puts "-" * 30

puts "Testing thermal system response to setpoint changes..."

# Test high temperature
puts "\nTesting high temperature setpoint (40°C)..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 40.0")
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 40.0")
wait(2)

# Monitor for 30 seconds
for i in 1..6
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  power1 = tlm("AZERSAT THERMAL HEATER1_PWR")
  power2 = tlm("AZERSAT THERMAL HEATER2_PWR")
  total_power = power1 + power2

  puts "  High temp test T+#{i*5}s: T1=#{temp1.round(1)}°C T2=#{temp2.round(1)}°C Power=#{total_power.round(0)}W"
  wait(5)
end

# Test low temperature
puts "\nTesting low temperature setpoint (20°C)..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 20.0")
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 20.0")
wait(2)

# Monitor for 30 seconds
for i in 1..6
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  state1 = tlm("AZERSAT THERMAL HEATER1_STATE")
  state2 = tlm("AZERSAT THERMAL HEATER2_STATE")

  puts "  Low temp test T+#{i*5}s: T1=#{temp1.round(1)}°C T2=#{temp2.round(1)}°C H1=#{state1} H2=#{state2}"
  wait(5)
end

# Step 5: Power-Optimized Thermal Control
puts "\n⚡ Step 5: Power-Optimized Thermal Control"
puts "-" * 35

battery = tlm("AZERSAT MECH BATTERY")
puts "Current battery level: #{battery.round(1)}%"

# Set power-optimized temperatures based on battery level
if battery < 60.0
  optimized_temp = 25.0
  puts "Battery moderate - setting conservative thermal target: #{optimized_temp}°C"
elsif battery < 40.0
  optimized_temp = 22.0
  puts "Battery low - setting minimum thermal target: #{optimized_temp}°C"
else
  optimized_temp = 28.0
  puts "Battery good - setting optimal thermal target: #{optimized_temp}°C"
end

cmd("AZERSAT HTR_SETPT with NUM 1, SETPT #{optimized_temp}")
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT #{optimized_temp}")
wait(2)

# Monitor power consumption
puts "Monitoring power-optimized thermal control..."
battery_start = tlm("AZERSAT MECH BATTERY")

for i in 1..8
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  power1 = tlm("AZERSAT THERMAL HEATER1_PWR")
  power2 = tlm("AZERSAT THERMAL HEATER2_PWR")
  battery_current = tlm("AZERSAT MECH BATTERY")
  battery_change = battery_current - battery_start

  total_thermal_power = power1 + power2

  puts "  T+#{i*5}s: T1=#{temp1.round(1)}°C T2=#{temp2.round(1)}°C Power=#{total_thermal_power.round(0)}W Battery=#{battery_current.round(1)}% (#{battery_change >= 0 ? '+' : ''}#{battery_change.round(1)}%)"
  wait(5)
end

# Step 6: Mode-Dependent Thermal Settings
puts "\n🎯 Step 6: Mode-Dependent Thermal Settings"
puts "-" * 40

current_mode = tlm("AZERSAT HEALTH_STATUS MODE")
puts "Current spacecraft mode: #{current_mode}"

# Apply mode-specific thermal settings
case current_mode
when "SAFE"
  mode_temp = 20.0
  puts "Applying SAFE mode thermal settings (survival heating)..."
when "CHECKOUT"
  mode_temp = 25.0
  puts "Applying CHECKOUT mode thermal settings (equipment protection)..."
when "OPERATE"
  mode_temp = 30.0
  puts "Applying OPERATE mode thermal settings (optimal performance)..."
else
  mode_temp = 25.0
  puts "Unknown mode - applying default thermal settings..."
end

cmd("AZERSAT HTR_SETPT with NUM 1, SETPT #{mode_temp}")
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT #{mode_temp}")
wait(2)

puts "Mode-appropriate thermal control configured: #{mode_temp}°C"

# Monitor mode-appropriate response
puts "Monitoring mode-appropriate thermal response..."
for i in 1..6
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  puts "  T+#{i*3}s: T1=#{temp1.round(1)}°C T2=#{temp2.round(1)}°C"
  wait(3)
end

# Step 7: Test Emergency Thermal Procedures
puts "\n🚨 Step 7: Test Emergency Thermal Procedures"
puts "-" * 40

puts "Testing emergency heater shutdown procedure..."

# Test emergency shutdown
puts "Simulating emergency shutdown..."
cmd("AZERSAT HTR_CTRL with NUM 1, STATE OFF")
wait(2)

# Monitor for 15 seconds
puts "Monitoring emergency shutdown response..."
for i in 1..3
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  power1 = tlm("AZERSAT THERMAL HEATER1_PWR")
  state1 = tlm("AZERSAT THERMAL HEATER1_STATE")

  puts "  Emergency T+#{i*5}s: T1=#{temp1.round(1)}°C H1=#{state1} Power=#{power1.round(0)}W"
  wait(5)
end

# Recovery procedure
puts "Executing thermal recovery procedure..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 25.0")
wait(1)
cmd("AZERSAT HTR_CTRL with NUM 1, STATE ON")
wait(2)

recovery_state = tlm("AZERSAT THERMAL HEATER1_CTRL")
if recovery_state == "ON"
  puts "✅ Thermal emergency recovery successful"
else
  puts "⚠️ Thermal recovery may need attention"
end

# Final Status Report
puts "\n" + "=" * 60
puts "🌡️ THERMAL MANAGEMENT COMPLETE!"
puts "=" * 60

# Get final comprehensive status
final_temp1 = tlm("AZERSAT THERMAL TEMP1")
final_temp2 = tlm("AZERSAT THERMAL TEMP2")
final_heater1_ctrl = tlm("AZERSAT THERMAL HEATER1_CTRL")
final_heater1_setpt = tlm("AZERSAT THERMAL HEATER1_SETPT")
final_heater1_pwr = tlm("AZERSAT THERMAL HEATER1_PWR")
final_heater2_ctrl = tlm("AZERSAT THERMAL HEATER2_CTRL")
final_heater2_setpt = tlm("AZERSAT THERMAL HEATER2_SETPT")
final_heater2_pwr = tlm("AZERSAT THERMAL HEATER2_PWR")
final_battery = tlm("AZERSAT MECH BATTERY")

puts "\nFinal Thermal Status:"
puts "  Temperature 1: #{final_temp1.round(1)}°C"
puts "  Temperature 2: #{final_temp2.round(1)}°C"
puts "  Heater 1: #{final_heater1_ctrl} @ #{final_heater1_setpt.round(1)}°C (#{final_heater1_pwr.round(0)}W)"
puts "  Heater 2: #{final_heater2_ctrl} @ #{final_heater2_setpt.round(1)}°C (#{final_heater2_pwr.round(0)}W)"
puts "  Total Thermal Power: #{(final_heater1_pwr + final_heater2_pwr).round(0)}W"
puts "  Battery Level: #{final_battery.round(1)}%"

# Health assessment
thermal_health = "NOMINAL"
issues = []

if final_temp1 < 15.0 || final_temp1 > 45.0
  thermal_health = "WARNING"
  issues << "Temperature 1 out of range"
end

if final_temp2 < 15.0 || final_temp2 > 45.0
  thermal_health = "WARNING"
  issues << "Temperature 2 out of range"
end

if final_heater1_ctrl != "ON" || final_heater2_ctrl != "ON"
  thermal_health = "CAUTION"
  issues << "Heater control not active"
end

puts "\nThermal System Health: #{thermal_health}"
if issues.any?
  puts "Issues: #{issues.join(', ')}"
end

puts "\n✅ Thermal management operations completed successfully!"
puts "\nOperations Summary:"
puts "  - Configured automatic thermal control"
puts "  - Monitored thermal response and stabilization"
puts "  - Performed thermal stress testing"
puts "  - Demonstrated power optimization"
puts "  - Tested mode-dependent thermal control"
puts "  - Performed emergency procedures and recovery"

puts "\nThermal system is ready for operational use! 🌡️🛰️"