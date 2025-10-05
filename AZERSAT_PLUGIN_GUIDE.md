# OpenC3 COSMOS AzerSat Plugin Guide

## Overview
The AzerSat plugin is a complete simulated satellite system that demonstrates OpenC3 COSMOS functionality. It includes commands, telemetry, and a realistic simulation that responds to commands and generates telemetry data.

## Plugin Structure
```
openc3-cosmos-azersat/
├── plugin.txt                    # Main plugin configuration
├── targets/AZERSAT/
│   ├── target.txt                # Target configuration
│   ├── cmd_tlm/
│   │   ├── cmds.txt             # Command definitions
│   │   ├── tlm.txt              # Telemetry definitions
│   │   ├── _ccsds_cmd.txt       # CCSDS command header template
│   │   └── _ccsds_tlm.txt       # CCSDS telemetry header template
│   ├── lib/
│   │   └── sim_sat.rb           # Simulation logic
│   ├── data/
│   │   ├── position.bin         # Position data for simulation
│   │   └── attitude.bin         # Attitude data for simulation
│   ├── procedures/              # Test procedures
│   ├── tables/                  # Table definitions
│   └── screens/                 # GUI screens
```

## 🔨 Build & Install

### Build the Plugin
```bash
# Build the gem
gem build openc3-cosmos-azersat.gemspec

# Result: openc3-cosmos-azersat-[version].gem
```

### Install the Plugin
```bash
# Start OpenC3
./openc3.sh start

# Install via web interface
# Go to: http://localhost:2900/tools/admin
# Upload: openc3-cosmos-azersat-[version].gem

# Or install via CLI
./openc3.sh cli load openc3-cosmos-azersat-[version].gem
```

## 🚀 Available Commands (17 total)

### System Commands
1. **AZERSAT NOOP** - No operation (basic connectivity test)
2. **AZERSAT CLEAR** - Clear counters (hazardous)
3. **AZERSAT SET_MODE MODE:[SAFE/CHECKOUT/OPERATE]** - Change spacecraft mode

### Imaging Commands
4. **AZERSAT COLLECT TYPE:[NORMAL/SPECIAL] DURATION:[seconds] OPCODE:[hex] TEMP:[celsius]** - Start image collection
5. **AZERSAT ABORT** - Abort current collection

### Solar Panel Commands
6. **AZERSAT SLRPNLDEPLOY NUM:[1/2]** - Deploy solar array panel
7. **AZERSAT SLRPNLSTOW NUM:[1/2]** - Stow solar array panel
8. **AZERSAT SLRPNLANG NUM:[1/2] ANG:[0-360]** - Set solar array panel angle

### Thermal Commands
9. **AZERSAT HTR_CTRL NUM:[1/2] STATE:[ON/OFF]** - Heater control
10. **AZERSAT HTR_STATE NUM:[1/2] STATE:[ON/OFF]** - Heater state
11. **AZERSAT HTR_SETPT NUM:[1/2] SETPT:[-100 to 100]** - Set heater setpoint

### ADCS Commands
12. **AZERSAT ADCS_CTRL STATE:[ON/OFF]** - ADCS control of solar panel angle

### 🆕 Communications Commands
13. **AZERSAT ANT_DEPLOY ANT_NUM:[1/2] TYPE:[HIGH_GAIN/LOW_GAIN]** - Deploy communication antenna (~10 seconds)
14. **AZERSAT ANT_STOW ANT_NUM:[1/2]** - Stow communication antenna (~8 seconds)
15. **AZERSAT START_DOWNLINK DATA_RATE:[LOW/MEDIUM/HIGH] DURATION:[seconds]** - Start data downlink
16. **AZERSAT STOP_DOWNLINK** - Stop active data downlink
17. **AZERSAT SET_ANT_ANGLE ANT_NUM:[1/2] AZIMUTH:[0-360] ELEVATION:[0-90]** - Point antenna


## 📡 Telemetry Packets (8 types)

### AZERSAT HEALTH_STATUS (100Hz)
- CMD_ACPT_CNT: Command accept counter
- CMD_RJCT_CNT: Command reject counter
- MODE: Spacecraft mode (SAFE/CHECKOUT/OPERATE)
- CPU_PWR: CPU power consumption (Watts)

### AZERSAT THERMAL (100Hz)
- TEMP1, TEMP2: Temperature sensors (Celsius)
- HEATER1/2_CTRL: Heater control states (ON/OFF)
- HEATER1/2_STATE: Heater actual states (ON/OFF)
- HEATER1/2_SETPT: Heater setpoints (Celsius)
- HEATER1/2_PWR: Heater power consumption (Watts)

### AZERSAT ADCS (10Hz - Position/Attitude Updates)
- POSX, POSY, POSZ: Position coordinates
- VELX, VELY, VELZ: Velocity vectors
- Q1, Q2, Q3, Q4: Quaternion parameters
- BIASX, BIASY, BIASZ: Rate biases
- STAR1ID-STAR5ID: Star tracker IDs
- POSPROGRESS, ATTPROGRESS: File progress
- SR_ANG_TO_SUN: Ideal solar array angle
- ADCS_CTRL: ADCS control state

### AZERSAT MECH (100Hz)
- SLRPNL1/2_ANG: Solar panel angles (degrees)
- SLRPNL1/2_STATE: Solar panel states (STOWED/DEPLOYED)
- SLRPNL1/2_PWR: Solar panel power generation (Watts)
- BATTERY: Battery percentage (0-100%)

### AZERSAT IMAGER (100Hz)
- COLLECTS: Number of collections commanded (increments per COLLECT command)
- DURATION: Most recent collection duration (seconds)
- COLLECT_TYPE: Most recent collection type (NORMAL/SPECIAL)
- IMAGER_STATE: Current imager state (OFF/ON)
- IMAGER_PWR: Imager power consumption (0W when OFF, 200W when ON)

### 🆕 AZERSAT COMMS (100Hz)
- ANT1/2_STATE: Antenna deployment status (STOWED/DEPLOYING/DEPLOYED/STOWING)
- ANT1/2_TYPE: Antenna type (LOW_GAIN/HIGH_GAIN)
- ANT1/2_AZIMUTH: Antenna azimuth pointing angle (0-360 degrees)
- ANT1/2_ELEVATION: Antenna elevation pointing angle (0-90 degrees)
- DOWNLINK_STATE: Data downlink status (IDLE/ACTIVE)
- DATA_RATE: Current transmission rate (LOW/MEDIUM/HIGH)
- DATA_BUFFER: Data buffer level (0-100%)
- SIGNAL_STRENGTH: Ground station signal strength (dBm)
- COMM_PWR: Communications power consumption (Watts)
- DOWNLINK_TIME_REMAINING: Countdown timer for active downlink (seconds)

### AZERSAT EVENT (As needed)
- MESSAGE: Event message text

### AZERSAT IMAGE (Generated after collection)
- BYTES: First bytes of image
- IMAGE: Image data block

## 🎯 Quick Test Sequence

```bash
# 1. Basic connectivity
AZERSAT NOOP

# 2. Deploy power and communications
AZERSAT SLRPNLDEPLOY NUM:1
AZERSAT SLRPNLDEPLOY NUM:2
AZERSAT ANT_DEPLOY ANT_NUM:1 TYPE:HIGH_GAIN
AZERSAT ANT_DEPLOY ANT_NUM:2 TYPE:LOW_GAIN

# 3. Wait for battery to charge, then enter checkout
AZERSAT SET_MODE MODE:CHECKOUT

# 4. Set up thermal control
AZERSAT HTR_SETPT NUM:1 SETPT:30.0
AZERSAT HTR_CTRL NUM:1 STATE:ON

# 5. Enable ADCS for automatic sun tracking
AZERSAT ADCS_CTRL STATE:ON

# 6. Point antennas and start data downlink
AZERSAT SET_ANT_ANGLE ANT_NUM:1 AZIMUTH:45.0 ELEVATION:30.0
AZERSAT START_DOWNLINK DATA_RATE:MEDIUM DURATION:60

# 7. Enter operate mode (requires good temperatures)
AZERSAT SET_MODE MODE:OPERATE

# 8. Take an image
AZERSAT COLLECT TYPE:NORMAL DURATION:3.0 OPCODE:0xAB TEMP:20.0
```

## 🌐 Web Interface URLs

- **OpenC3 Main**: http://localhost:2900
- **Command Sender**: http://localhost:2900/tools/cmdsender
- **Telemetry Viewer**: http://localhost:2900/tools/tlmviewer
- **Limits Monitor**: http://localhost:2900/tools/limitsmonitor
- **Command History**: http://localhost:2900/tools/cmdhistory
- **Admin/Plugins**: http://localhost:2900/tools/admin

## ✅ Recent Changes

**Renamed from FakeSat to AzerSat:**
- ✅ Updated plugin configuration
- ✅ Renamed target from FAKESAT to AZERSAT
- ✅ Updated all command/telemetry references
- ✅ Updated gemspec and README
- ✅ Updated procedure files
- ✅ Built new gem: `openc3-cosmos-azersat-[version].gem`

## 🔄 Simulation Features

### Realistic Behaviors:
- **Power Management**: Solar panels generate power based on angle to sun
- **Thermal Control**: Heaters respond to setpoints with hysteresis
- **Mode Dependencies**: Some commands only work in specific modes
- **Battery Simulation**: Power consumption affects battery level
- **Attitude/Position**: Real orbital data from binary files

### Command Interactions:
- ADCS can automatically control solar panel angles
- Battery level affects mode transitions
- Temperature limits affect mode changes
- Power consumption affects battery life

The AzerSat plugin is now ready for use with OpenC3 COSMOS!