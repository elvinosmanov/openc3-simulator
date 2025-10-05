# 1. Basic connectivity
AZERSAT NOOP

# 2. Deploy panels for power
AZERSAT SLRPNLDEPLOY NUM:1
AZERSAT SLRPNLDEPLOY NUM:2

# 3. Wait for battery to charge, then enter checkout
AZERSAT SET_MODE MODE:CHECKOUT

# 4. Set up thermal control
AZERSAT HTR_SETPT NUM:1 SETPT:30.0
AZERSAT HTR_CTRL NUM:1 STATE:ON

# 5. Enable ADCS for automatic sun tracking
AZERSAT ADCS_CTRL STATE:ON

# 6. Enter operate mode (requires good temperatures)
AZERSAT SET_MODE MODE:OPERATE

# 7. Take an image
AZERSAT COLLECT TYPE:NORMAL DURATION:3.0 OPCODE:0xAB TEMP:20.0

# 8. Test our new command
AZERSAT SET_TEST_TEMP NEW_TEMP:42.0