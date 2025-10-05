# Note hex 0x20 is ASCII space ' ' character
data = "\x20" * 10
cmd(f"AZERSAT TABLE_LOAD with DATA {data}")
cmd("AZERSAT", "TABLE_LOAD", {"DATA": data})
wait(2)  # Allow telemetry to change
# Can't use check for binary data so we grab the data
# and check simply using comparison
block = tlm("AZERSAT HEALTH_STATUS TABLE_DATA")
if data != block:
    raise RuntimeError("TABLE_DATA not updated correctly!")
