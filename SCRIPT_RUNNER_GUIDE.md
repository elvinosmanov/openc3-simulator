# AzerSat Script Runner Examples Guide

## 🚀 **5 Complete Working Scripts for OpenC3 Script Runner**

I've created comprehensive example scripts that demonstrate AzerSat satellite operations perfectly. These scripts showcase all functionality including the new communications system.

## 📁 **Available Scripts**

### **1. 🛰️ azersat_startup_sequence.rb**
**Complete satellite initialization from SAFE to OPERATE mode**

**What it does:**
- Performs initial health check
- Deploys solar panels and antennas
- Monitors power generation
- Waits for battery charge
- Configures thermal control system
- Enables ADCS solar tracking
- Points communication antennas
- Waits for thermal stabilization
- Enters OPERATE mode
- Starts initial data downlink

**Duration:** ~15-20 minutes (includes realistic wait times)
**Use when:** Fresh satellite startup or after major anomaly

### **2. 📡 azersat_communications_ops.rb**
**Comprehensive communications system demonstration**

**What it does:**
- Deploys and tests both antennas
- Demonstrates antenna pointing to different ground stations
- Tests all three data rates (LOW/MEDIUM/HIGH)
- Simulates emergency communications scenario
- Performs antenna maintenance cycle
- Monitors signal strength optimization

**Duration:** ~10-15 minutes
**Use when:** Testing communications functionality or training operators

### **3. 🌡️ azersat_thermal_management.rb**
**Thermal control system operation and optimization**

**What it does:**
- Assesses initial thermal status
- Configures automatic thermal control
- Monitors thermal stabilization
- Performs thermal stress testing
- Demonstrates power-optimized thermal control
- Shows mode-dependent thermal settings
- Simulates thermal emergency scenarios

**Duration:** ~12-18 minutes
**Use when:** Thermal system testing or anomaly investigation

### **4. 🎯 azersat_automated_mission.rb**
**Complete autonomous mission with imaging and data downlink**

**What it does:**
- Performs system health checks
- Executes imaging campaign (3 targets)
- Monitors orbital position for optimal timing
- Conducts data downlink campaign (2 ground stations)
- Provides mission success assessment
- Generates comprehensive mission report

**Duration:** ~20-25 minutes
**Use when:** Demonstrating complete mission operations

### **5. 🔧 azersat_troubleshooting.rb**
**Diagnostic procedures and anomaly recovery**

**What it does:**
- Comprehensive system diagnostic
- Safe mode recovery procedures
- Thermal anomaly recovery
- Communications failure recovery
- Power shortage recovery
- Emergency data dump procedures

**Duration:** ~8-15 minutes (depends on issues found)
**Use when:** System anomalies or training troubleshooting procedures

## 🎮 **How to Use in OpenC3 Script Runner**

### **Step 1: Access Script Runner**
1. Open OpenC3: http://localhost:2900
2. Go to **Tools → Script Runner**
3. Click **Browse** to select script files

### **Step 2: Load Scripts**
1. Navigate to: `openc3-cosmos-fakesat-main/targets/AZERSAT/procedures/`
2. Select desired script (e.g., `azersat_startup_sequence.rb`)
3. Click **Open**

### **Step 3: Execute Scripts**
1. Click **Start** to begin script execution
2. Monitor progress in the output window
3. Watch telemetry updates in real-time
4. Use **Stop** if needed to halt execution

### **Step 4: Monitor Telemetry**
**Recommended telemetry displays:**
- `AZERSAT HEALTH_STATUS` - Command counters, mode, CPU power (100Hz)
- `AZERSAT COMMS` - Communications status - **NEW!** (100Hz)
- `AZERSAT THERMAL` - Temperature sensors and heater control (100Hz)
- `AZERSAT MECH` - Solar panels and battery status (100Hz)
- `AZERSAT IMAGER` - Imaging operations and power (100Hz)
- `AZERSAT ADCS` - Position, attitude, star tracker data (10Hz)
- `AZERSAT EVENT` - Command responses and event messages (as needed)
- `AZERSAT IMAGE` - Image data packets (sent after collection completes)

**Note:** All telemetry packets run at 100Hz except ADCS (10Hz) and EVENT/IMAGE (asynchronous)

## 🎯 **Recommended Script Sequence**

### **For New Users:**
1. **azersat_startup_sequence.rb** - Learn basic operations
2. **azersat_communications_ops.rb** - Understand communications
3. **azersat_thermal_management.rb** - Master thermal control

### **For Training:**
1. **azersat_automated_mission.rb** - Complete mission demo
2. **azersat_troubleshooting.rb** - Anomaly handling

### **For Development:**
- Use any script as a starting point
- Modify parameters and procedures
- Add custom mission scenarios

## ⚙️ **Script Features**

### **Realistic Timing:**
- **Antenna deployment:** 10 seconds
- **Solar panel deployment:** Immediate
- **Thermal stabilization:** 2-5 minutes
- **Data downlink:** Variable rates
- **Mode transitions:** Immediate with validation

### **Error Handling:**
- **Command validation:** Scripts check for valid responses
- **Timeout protection:** Scripts won't hang indefinitely
- **Status monitoring:** Continuous telemetry checking
- **Graceful degradation:** Scripts adapt to failures

### **Educational Value:**
- **Step-by-step explanations:** Each action is explained
- **Status reporting:** Continuous progress updates
- **Problem identification:** Scripts highlight issues
- **Best practices:** Demonstrates proper procedures

## 🔍 **What to Watch For**

### **During Startup Script:**
- Solar panel deployment
- Battery charging progress
- Temperature stabilization (watch for 25-35°C range)
- Mode transitions (SAFE → CHECKOUT → OPERATE)
- Antenna deployment and pointing

### **During Communications Script:**
- Signal strength changes with antenna configuration
- Data buffer levels during transmission
- Power consumption during downlink
- Antenna state transitions

### **During Mission Script:**
- Orbital position effects on imaging
- Data accumulation and transmission
- Power management throughout mission
- Success/failure criteria assessment

## 🚨 **Common Issues and Solutions**

### **Script Stops or Hangs:**
- Check if satellite is responding to commands
- Verify telemetry is updating
- Use Script Runner **Stop** button if needed

### **Mode Transition Failures:**
- **SAFE → CHECKOUT:** Need battery ≥50%
- **CHECKOUT → OPERATE:** Need temperatures 25-35°C
- Wait longer for thermal stabilization

### **Communications Issues:**
- Ensure antennas are deployed
- Check signal strength
- Verify ground station pointing

### **Power Issues:**
- Deploy solar panels first
- Enable ADCS for solar tracking
- Monitor battery level closely

## 📊 **Performance Metrics**

### **Startup Script Success Criteria:**
- ✅ All deployments complete
- ✅ Battery >50%
- ✅ Temperatures 25-35°C
- ✅ OPERATE mode achieved
- ✅ Communications established

### **Mission Script Success Criteria:**
- ✅ >50% imaging targets successful
- ✅ >50% downlink windows successful
- ✅ Final battery >40%
- ✅ All systems operational

## 🛠️ **Customization Tips**

### **Modify Timing:**
```ruby
wait(30)  # Change wait times as needed
```

### **Change Parameters:**
```ruby
cmd("AZERSAT HTR_SETPT NUM:1 SETPT:25.0")  # Adjust setpoints
```

### **Add Custom Checks:**
```ruby
battery = tlm("AZERSAT MECH BATTERY")
if battery < 40.0
  puts "⚠️ Low battery warning"
end
```

### **Create Mission Variants:**
- Modify target lists
- Change downlink schedules
- Add emergency scenarios
- Create custom procedures

## ✅ **Verification Checklist**

**Before running scripts:**
- [ ] AzerSat plugin installed and loaded
- [ ] OpenC3 COSMOS running
- [ ] Telemetry Viewer open for monitoring
- [ ] Script Runner accessible

**After running scripts:**
- [ ] All commands accepted
- [ ] Expected telemetry changes observed
- [ ] No error messages in EVENT telemetry
- [ ] System in expected final state

These scripts provide complete, working examples of AzerSat operations and serve as excellent training tools for understanding satellite operations with OpenC3 COSMOS! 🛰️📡