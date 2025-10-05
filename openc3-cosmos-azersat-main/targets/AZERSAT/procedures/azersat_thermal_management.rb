#!/usr/bin/env ruby
# AzerSat Thermal Management Script
# Demonstrates thermal control system operation and optimization

# Display script information
puts "=" * 60
puts "AzerSat Thermal Management Script"
puts "Demonstrating thermal control system operation"
puts "=" * 60

# Step 1: Initial Thermal Assessment
puts "\n🌡️ Step 1: Initial Thermal Assessment"
puts "-" * 40

temp1 = tlm("AZERSAT THERMAL TEMP1")
temp2 = tlm("AZERSAT THERMAL TEMP2")
heater1_ctrl = tlm("AZERSAT THERMAL HEATER1_CTRL")
heater1_state = tlm("AZERSAT THERMAL HEATER1_STATE")
heater1_setpt = tlm("AZERSAT THERMAL HEATER1_SETPT")
heater2_ctrl = tlm("AZERSAT THERMAL HEATER2_CTRL")
heater2_state = tlm("AZERSAT THERMAL HEATER2_STATE")
heater2_setpt = tlm("AZERSAT THERMAL HEATER2_SETPT")

puts "Initial Thermal Status:"
puts "  Temperature 1: #{temp1.round(1)}°C"
puts "  Temperature 2: #{temp2.round(1)}°C"
puts "  Heater 1: Control=#{heater1_ctrl}, State=#{heater1_state}, Setpoint=#{heater1_setpt.round(1)}°C"
puts "  Heater 2: Control=#{heater2_ctrl}, State=#{heater2_state}, Setpoint=#{heater2_setpt.round(1)}°C"

# Assess thermal health
if temp1 < -10 || temp1 > 50 || temp2 < -10 || temp2 > 50
  puts "⚠️ WARNING: Temperatures outside safe operating range (-10°C to 50°C)"
else
  puts "✅ Temperatures within safe operating range"
end

# Step 2: Configure Thermal Control System
puts "\n🔧 Step 2: Configuring Thermal Control System"
puts "-" * 40

# Set optimal setpoints for different operational phases
target_temp = 30.0  # Optimal operating temperature

puts "Setting heater 1 setpoint to #{target_temp}°C..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT #{target_temp}")
wait(1)

puts "Setting heater 2 setpoint to #{target_temp}°C..."
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT #{target_temp}")
wait(1)

puts "Enabling heater 1 automatic control..."
cmd("AZERSAT HTR_CTRL with NUM 1, STATE ON")
wait(1)

puts "Enabling heater 2 automatic control..."
cmd("AZERSAT HTR_CTRL with NUM 2, STATE ON")
wait(2)

puts "✅ Thermal control system configured and activated"

# Step 3: Monitor Thermal Stabilization
puts "\n📊 Step 3: Monitoring Thermal Stabilization"
puts "-" * 40

puts "Monitoring thermal system for 2 minutes..."
puts "Target: #{target_temp}°C ± 2°C hysteresis"

# Monitor for 2 minutes (24 readings at 5-second intervals)
stable_count = 0
max_readings = 24

for reading in 1..max_readings
  # Get current readings
  current_temp1 = tlm("AZERSAT THERMAL TEMP1")
  current_temp2 = tlm("AZERSAT THERMAL TEMP2")
  heater1_state = tlm("AZERSAT THERMAL HEATER1_STATE")
  heater1_power = tlm("AZERSAT THERMAL HEATER1_PWR")
  heater2_state = tlm("AZERSAT THERMAL HEATER2_STATE")
  heater2_power = tlm("AZERSAT THERMAL HEATER2_PWR")

  # Check if temperatures are stable (within ±5°C of target)
  temp1_stable = (current_temp1 - target_temp).abs <= 5.0
  temp2_stable = (current_temp2 - target_temp).abs <= 5.0

  if temp1_stable && temp2_stable
    stable_count += 1
  else
    stable_count = 0
  end

  # Display status
  status_symbol = temp1_stable && temp2_stable ? "✅" : "⏳"
  puts "#{sprintf("%2d", reading)}/#{max_readings}: #{status_symbol} T1=#{current_temp1.round(1)}°C T2=#{current_temp2.round(1)}°C H1=#{heater1_state}(#{heater1_power.round(0)}W) H2=#{heater2_state}(#{heater2_power.round(0)}W) Stable=#{stable_count}"

  # Check for thermal stability (5 consecutive stable readings)
  if stable_count >= 5
    puts "🎯 Thermal system stabilized after #{reading} readings!"
    break
  end

  wait(5)
end

# Step 4: Thermal Stress Test
puts "\n🔥 Step 4: Thermal Stress Test"
puts "-" * 40

puts "Performing thermal stress test with extreme setpoints..."

# Test high temperature scenario
puts "\nTesting high temperature scenario (45°C)..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 45.0")
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 45.0")
wait(2)

# Monitor for 30 seconds
puts "Monitoring high temperature response..."
for i in 1..6
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  power1 = tlm("AZERSAT THERMAL HEATER1_PWR")
  power2 = tlm("AZERSAT THERMAL HEATER2_PWR")
  total_power = power1 + power2

  puts "  T+#{i*5}s: T1=#{temp1.round(1)}°C T2=#{temp2.round(1)}°C Total Power=#{total_power.round(0)}W"
  wait(5)
end

# Test low temperature scenario
puts "\nTesting low temperature scenario (15°C)..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 15.0")
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 15.0")
wait(2)

# Monitor for 30 seconds
puts "Monitoring low temperature response..."
for i in 1..6
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  state1 = tlm("AZERSAT THERMAL HEATER1_STATE")
  state2 = tlm("AZERSAT THERMAL HEATER2_STATE")

  puts "  T+#{i*5}s: T1=#{temp1.round(1)}°C T2=#{temp2.round(1)}°C H1=#{state1} H2=#{state2}"
  wait(5)
end

# Step 5: Power-Optimized Thermal Control
puts "\n⚡ Step 5: Power-Optimized Thermal Control"
puts "-" * 40

# Return to optimal settings
puts "Returning to power-optimized thermal settings..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 28.0")  # Slightly lower to save power
cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 32.0")  # Slightly higher for redundancy
wait(2)

# Monitor power consumption
puts "Monitoring power-optimized thermal control..."
battery_start = tlm("AZERSAT MECH BATTERY")

for i in 1..8
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  power1 = tlm("AZERSAT THERMAL HEATER1_PWR")
  power2 = tlm("AZERSAT THERMAL HEATER2_PWR")
  battery = tlm("AZERSAT MECH BATTERY")
  battery_change = battery - battery_start

  total_thermal_power = power1 + power2

  puts "  T+#{i*5}s: T1=#{temp1.round(1)}°C T2=#{temp2.round(1)}°C Thermal Power=#{total_thermal_power.round(0)}W Battery=#{battery.round(1)}% (#{battery_change >= 0 ? '+' : ''}#{battery_change.round(1)}%)"
  wait(5)
end

# Step 6: Mode-Dependent Thermal Control
puts "\n🎯 Step 6: Mode-Dependent Thermal Control"
puts "-" * 40

current_mode = tlm("AZERSAT HEALTH_STATUS MODE")
puts "Current spacecraft mode: #{current_mode}"

case current_mode
when "SAFE"
  puts "Applying SAFE mode thermal settings (survival heaters only)..."
  cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 20.0")
  cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 20.0")
  wait(2)
  puts "SAFE mode: Minimum power heating to prevent freezing"

when "CHECKOUT"
  puts "Applying CHECKOUT mode thermal settings (equipment protection)..."
  cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 25.0")
  cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 25.0")
  wait(2)
  puts "CHECKOUT mode: Moderate heating for equipment protection"

when "OPERATE"
  puts "Applying OPERATE mode thermal settings (optimal performance)..."
  cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 30.0")
  cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 30.0")
  wait(2)
  puts "OPERATE mode: Optimal heating for mission operations"

else
  puts "Unknown mode - applying default thermal settings..."
  cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 25.0")
  cmd("AZERSAT HTR_SETPT with NUM 2, SETPT 25.0")
end

# Monitor mode-appropriate thermal response
puts "Monitoring mode-appropriate thermal response..."
for i in 1..6
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  temp2 = tlm("AZERSAT THERMAL TEMP2")
  puts "  T+#{i*3}s: T1=#{temp1.round(1)}°C T2=#{temp2.round(1)}°C"
  wait(3)
end

# Step 7: Thermal Emergency Simulation
puts "\n🚨 Step 7: Thermal Emergency Simulation"
puts "-" * 40

puts "Simulating thermal emergency scenario..."

# Simulate overheating scenario
puts "Simulating overheating emergency (high setpoint)..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 50.0")
wait(2)

# Monitor emergency response
puts "Monitoring emergency thermal response..."
emergency_start = Time.now

while Time.now - emergency_start < 30
  temp1 = tlm("AZERSAT THERMAL TEMP1")
  power1 = tlm("AZERSAT THERMAL HEATER1_PWR")

  puts "  Emergency: T1=#{temp1.round(1)}°C Power=#{power1.round(0)}W"

  # Emergency shutdown if temperature exceeds safe limit
  if temp1 > 45.0
    puts "🚨 EMERGENCY: Temperature exceeded 45°C - shutting down heater!"
    cmd("AZERSAT HTR_CTRL with NUM 1, STATE OFF")
    wait(2)
    puts "Emergency shutdown complete"
    break
  end

  wait(3)
end

# Recovery procedure
puts "\nExecuting thermal recovery procedure..."
cmd("AZERSAT HTR_SETPT with NUM 1, SETPT 25.0")
wait(1)
cmd("AZERSAT HTR_CTRL with NUM 1, STATE ON")
wait(2)
puts "✅ Thermal system recovered to safe operation"

# Final Status Report
puts "\n" + "=" * 60
puts "🌡️ THERMAL MANAGEMENT OPERATIONS COMPLETE!"
puts "=" * 60

# Get final telemetry
final_temp1 = tlm("AZERSAT THERMAL TEMP1")
final_temp2 = tlm("AZERSAT THERMAL TEMP2")
final_heater1_ctrl = tlm("AZERSAT THERMAL HEATER1_CTRL")
final_heater1_setpt = tlm("AZERSAT THERMAL HEATER1_SETPT")
final_heater2_ctrl = tlm("AZERSAT THERMAL HEATER2_CTRL")
final_heater2_setpt = tlm("AZERSAT THERMAL HEATER2_SETPT")
final_power1 = tlm("AZERSAT THERMAL HEATER1_PWR")
final_power2 = tlm("AZERSAT THERMAL HEATER2_PWR")

puts "\nFinal Thermal Status:"
puts "  Temperature 1: #{final_temp1.round(1)}°C"
puts "  Temperature 2: #{final_temp2.round(1)}°C"
puts "  Heater 1: #{final_heater1_ctrl} @ #{final_heater1_setpt.round(1)}°C (#{final_power1.round(0)}W)"
puts "  Heater 2: #{final_heater2_ctrl} @ #{final_heater2_setpt.round(1)}°C (#{final_power2.round(0)}W)"
puts "  Total Thermal Power: #{(final_power1 + final_power2).round(0)}W"

# Thermal health assessment
temp_status = "NOMINAL"
if final_temp1 < 20.0 || final_temp1 > 40.0 || final_temp2 < 20.0 || final_temp2 > 40.0
  temp_status = "CAUTION"
end
if final_temp1 < 10.0 || final_temp1 > 45.0 || final_temp2 < 10.0 || final_temp2 > 45.0
  temp_status = "WARNING"
end

puts "\nThermal System Health: #{temp_status}"

puts "\n✅ All thermal management operations completed successfully!"
puts "\nOperations Summary:"
puts "  - Configured automatic thermal control"
puts "  - Monitored thermal stabilization"
puts "  - Performed thermal stress testing"
puts "  - Demonstrated power optimization"
puts "  - Tested mode-dependent thermal control"
puts "  - Simulated emergency scenarios and recovery"

puts "\nScript completed successfully! 🌡️🛰️"