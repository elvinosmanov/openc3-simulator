# AzerSat Communications System Test Guide

## 🆕 NEW FEATURES ADDED

### **5 New Commands:**
1. **ANT_DEPLOY** - Deploy communication antennas (HIGH_GAIN/LOW_GAIN)
2. **ANT_STOW** - Stow communication antennas
3. **START_DOWNLINK** - Start data downlink with configurable rates
4. **STOP_DOWNLINK** - Stop active downlink
5. **SET_ANT_ANGLE** - Point antennas with azimuth/elevation control

### **1 New Telemetry Packet:**
- **AZERSAT COMMS** - Complete communications status monitoring

## 🔨 INSTALLATION

```bash
# Build the updated plugin
gem build openc3-cosmos-azersat.gemspec
# Latest: openc3-cosmos-azersat-0.0.0.20251005141153.gem

# Install in OpenC3
# Upload via: http://localhost:2900/tools/admin

# Or via Docker/CLI
./openc3.sh cli plugininstall openc3-cosmos-azersat-0.0.0.20251005141153.gem
```

## ✅ What's New in This Version

### **Added:**
- ✅ COMMS telemetry packet (14 fields at 100Hz)
- ✅ 5 Communications commands (ANT_DEPLOY, ANT_STOW, SET_ANT_ANGLE, START_DOWNLINK, STOP_DOWNLINK)
- ✅ Enhanced event logging for ALL commands (success + failure messages)
- ✅ COMMS packet initialization and telemetry rate

### **Removed (Cleanup):**
- ❌ TABLE_LOAD command (dead code)
- ❌ SET_TEST_TEMP command (debug-only)
- ❌ TABLE_DATA telemetry field
- ❌ TEST_TEMP telemetry field

### **Fixed:**
- ✅ Color definitions (BLUE → YELLOW, only GREEN/YELLOW/RED supported)

## 🧪 STEP-BY-STEP TESTING

### **Test 1: Basic Antenna Operations**

**Deploy High-Gain Antenna:**
```bash
AZERSAT ANT_DEPLOY ANT_NUM:1 TYPE:HIGH_GAIN
```
- ✅ **Watch:** `AZERSAT COMMS ANT1_STATE` changes: STOWED → DEPLOYING → DEPLOYED (10 seconds)
- ✅ **Watch:** `AZERSAT COMMS ANT1_TYPE` shows HIGH_GAIN
- ✅ **Watch:** `AZERSAT COMMS COMM_PWR` increases by 50W when deployed

**Deploy Low-Gain Antenna:**
```bash
AZERSAT ANT_DEPLOY ANT_NUM:2 TYPE:LOW_GAIN
```
- ✅ **Watch:** `AZERSAT COMMS ANT2_STATE` changes: STOWED → DEPLOYING → DEPLOYED (10 seconds)
- ✅ **Watch:** `AZERSAT COMMS ANT2_TYPE` shows LOW_GAIN
- ✅ **Watch:** `AZERSAT COMMS COMM_PWR` increases by 20W more

**Point Antennas:**
```bash
AZERSAT SET_ANT_ANGLE ANT_NUM:1 AZIMUTH:45.0 ELEVATION:30.0
AZERSAT SET_ANT_ANGLE ANT_NUM:2 AZIMUTH:180.0 ELEVATION:-10.0
```
- ✅ **Watch:** `AZERSAT COMMS ANT1_AZIMUTH` = 45.0°
- ✅ **Watch:** `AZERSAT COMMS ANT1_ELEVATION` = 30.0°
- ✅ **Watch:** `AZERSAT COMMS ANT2_AZIMUTH` = 180.0°
- ✅ **Watch:** `AZERSAT COMMS ANT2_ELEVATION` = -10.0°

### **Test 2: Data Downlink Operations**

**Start High-Rate Downlink:**
```bash
AZERSAT START_DOWNLINK DATA_RATE:HIGH DURATION:60
```
- ✅ **Watch:** `AZERSAT COMMS DOWNLINK_STATE` = ACTIVE
- ✅ **Watch:** `AZERSAT COMMS DATA_RATE` = HIGH
- ✅ **Watch:** `AZERSAT COMMS DOWNLINK_TIME_REMAINING` counts down from 60
- ✅ **Watch:** `AZERSAT COMMS DATA_BUFFER` decreases faster (high rate transmission)
- ✅ **Watch:** `AZERSAT COMMS COMM_PWR` increases by 75W during transmission

**Monitor Data Buffer Behavior:**
- **During Downlink:** Buffer decreases (data being sent)
- **When Idle:** Buffer slowly increases (data accumulating)
- **Range:** 0-100%

### **Test 3: Signal Strength Simulation**

**Monitor Signal Quality:**
- ✅ **Watch:** `AZERSAT COMMS SIGNAL_STRENGTH` varies with orbital position
- **No Antennas:** ~-60 dB (poor)
- **Low-gain deployed:** ~-55 dB (better)
- **High-gain deployed:** ~-45 dB (good)
- **Both deployed:** ~-30 dB (excellent)

**Orbital Variation:** Signal strength oscillates ±18dB simulating ground station contact windows

### **Test 4: Error Conditions**

**Try Invalid Operations:**
```bash
# Should REJECT - antenna not deployed
AZERSAT SET_ANT_ANGLE ANT_NUM:1 AZIMUTH:0.0 ELEVATION:0.0

# Should REJECT - antenna already deployed
AZERSAT ANT_DEPLOY ANT_NUM:1 TYPE:HIGH_GAIN

# Should REJECT - no antennas deployed
AZERSAT START_DOWNLINK DATA_RATE:LOW DURATION:30
```
- ✅ **Watch:** `AZERSAT EVENT MESSAGE` for error messages
- ✅ **Watch:** `AZERSAT HEALTH_STATUS CMD_RJCT_CNT` increments

### **Test 5: Power System Integration**

**Monitor Power Consumption:**
- ✅ **Watch:** `AZERSAT MECH BATTERY` level with communications active
- **Antenna Power:** HIGH_GAIN = 50W, LOW_GAIN = 20W
- **Transmission Power:** LOW = 10W, MEDIUM = 25W, HIGH = 75W
- **Total:** Up to 145W additional load during high-rate downlink

**Power Management Test:**
1. Deploy both antennas (70W baseline)
2. Start high-rate downlink (+75W = 145W total)
3. Watch battery drain faster
4. Stop downlink to reduce power

### **Test 6: Realistic Operations Scenario**

**Complete Communications Session:**
```bash
# 1. Deploy antennas for redundancy
AZERSAT ANT_DEPLOY ANT_NUM:1 TYPE:HIGH_GAIN
AZERSAT ANT_DEPLOY ANT_NUM:2 TYPE:LOW_GAIN

# 2. Wait for deployment, then point antennas
AZERSAT SET_ANT_ANGLE ANT_NUM:1 AZIMUTH:0.0 ELEVATION:45.0
AZERSAT SET_ANT_ANGLE ANT_NUM:2 AZIMUTH:180.0 ELEVATION:0.0

# 3. Start medium-rate downlink
AZERSAT START_DOWNLINK DATA_RATE:MEDIUM DURATION:120

# 4. Monitor data transmission and power
# Watch data buffer decrease and power consumption

# 5. Emergency stop if needed
AZERSAT STOP_DOWNLINK

# 6. Stow antennas when done
AZERSAT ANT_STOW ANT_NUM:1
AZERSAT ANT_STOW ANT_NUM:2
```

## 📊 KEY TELEMETRY TO MONITOR

### **AZERSAT COMMS Packet:**
- **ANT1_STATE, ANT2_STATE** - Antenna deployment status
- **ANT1_TYPE, ANT2_TYPE** - Antenna type (HIGH_GAIN/LOW_GAIN)
- **ANT1_AZIMUTH, ANT1_ELEVATION** - Antenna pointing angles
- **DOWNLINK_STATE** - Data transmission status
- **DATA_BUFFER** - Percentage of data buffer filled
- **SIGNAL_STRENGTH** - Ground station link quality
- **COMM_PWR** - Communications power consumption
- **DOWNLINK_TIME_REMAINING** - Countdown timer

### **Power Impact:**
- **AZERSAT MECH BATTERY** - Watch power drain during comms operations

## 🎯 REALISTIC SIMULATION FEATURES

### **Timing Realism:**
- **Antenna deployment:** 10 seconds
- **Antenna stowing:** 8 seconds
- **State transitions:** STOWED ↔ DEPLOYING ↔ DEPLOYED ↔ STOWING

### **Data Management:**
- **Buffer accumulation:** +0.05%/second when idle
- **Data transmission rates:**
  - LOW: -0.025%/second
  - MEDIUM: -0.05%/second
  - HIGH: -0.1%/second

### **Power Consumption:**
- **Antenna power:** Always consumed when deployed
- **Transmission power:** Only during active downlink
- **Realistic values:** Based on actual satellite systems

### **Signal Modeling:**
- **Ground station contact windows:** Simulated via orbital variation
- **Antenna gain effects:** High-gain provides +15dB, low-gain +5dB
- **Range:** -100dB (no contact) to -10dB (excellent)

## ✅ SUCCESS CRITERIA

**Communications system is working correctly if:**
1. ✅ Antennas deploy/stow with proper timing
2. ✅ Antenna pointing commands work when deployed
3. ✅ Downlink starts only with deployed antennas
4. ✅ Data buffer decreases during transmission
5. ✅ Signal strength varies with antenna configuration
6. ✅ Power consumption reflects communications activity
7. ✅ Error messages appear for invalid operations
8. ✅ Timed operations complete automatically

The AzerSat communications system now provides realistic satellite communication operations for training and mission planning!