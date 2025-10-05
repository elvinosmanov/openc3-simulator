set_line_delay(1)
screen_def = '
  SCREEN AUTO AUTO 0.1 FIXED
  VERTICAL
    VERTICALBOX
      LABELVALUE FAKESAT HEALTH_STATUS MODE
    END
  END
'
# Here we pass in the screen definition as a string
local_screen("TESTING", screen_def)
prompt("Watch the screen for mode changes ...")

cmd("FAKESAT SET_MODE with MODE SAFE")
wait_check("FAKESAT HEALTH_STATUS MODE == 'SAFE'", 5)

# Call set_tlm twice to ensure it gets processed as real tlm flows
set_tlm("FAKESAT HEALTH_STATUS MODE = 'OPERATE'")
wait 0.2
set_tlm("FAKESAT HEALTH_STATUS MODE = 'OPERATE'")
wait 5 # Should see PacketViewer briefly
# This check fails as we receive data and revert back to 'SAFE'
check("FAKESAT HEALTH_STATUS MODE == 'OPERATE'")
# set_tlm back to SAFE to restore in the disconnected version
set_tlm("FAKESAT HEALTH_STATUS MODE = 'SAFE'")
set_tlm("FAKESAT HEALTH_STATUS MODE = 0", type: :RAW)

override_tlm("FAKESAT HEALTH_STATUS MODE = 'OPERATE'")
wait 2
# By default it overrides all the value types with the value
# This includes types that might not make sense like :RAW
check("FAKESAT HEALTH_STATUS MODE == 'OPERATE'", type: :RAW)
check("FAKESAT HEALTH_STATUS MODE == 'OPERATE'", type: :CONVERTED)
check("FAKESAT HEALTH_STATUS MODE == 'OPERATE'", type: :FORMATTED)
check("FAKESAT HEALTH_STATUS MODE == 'OPERATE'", type: :WITH_UNITS)
wait
# Clear the overrides
normalize_tlm("FAKESAT HEALTH_STATUS MODE")
wait_check("FAKESAT HEALTH_STATUS MODE == 0", 5, type: :RAW)
wait_check("FAKESAT HEALTH_STATUS MODE == 'SAFE'", 5) # default CONVERTED
wait_check("FAKESAT HEALTH_STATUS MODE == 'SAFE'", 5, type: :FORMATTED)
wait_check("FAKESAT HEALTH_STATUS MODE == 'SAFE'", 5, type: :WITH_UNITS)
wait

# Packet Viewer shows all telemetry zeroed except MODE
# Call inject_tlm twice to ensure it gets processed as real tlm flows
inject_tlm("FAKESAT", "HEALTH_STATUS", { "MODE" => "OPERATE" })
wait 0.2
inject_tlm("FAKESAT", "HEALTH_STATUS", { "MODE" => "OPERATE" })
wait 2
# With flowing tlm, the next received packet overwrites so we're back
wait_check("FAKESAT HEALTH_STATUS MODE == 'SAFE'", 2)
