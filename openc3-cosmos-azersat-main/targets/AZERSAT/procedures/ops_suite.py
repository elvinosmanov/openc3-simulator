from openc3.script.suite import Suite, Group

load_utility("AZERSAT/lib/fake_sat.py")


class CollectGroup(Group):
    def script_normal_collect(self):
        print(
            f"Running {Group.current_suite()}:{Group.current_group()}:{Group.current_script()}"
        )
        Group.print("Perform Normal Collect")

        cmd_cnt = tlm("AZERSAT HEALTH_STATUS CMD_ACPT_CNT")
        collect_cnt = tlm("AZERSAT IMAGER COLLECTS")
        cmd("AZERSAT COLLECT with TYPE NORMAL, DURATION 5")
        wait_check(f"AZERSAT HEALTH_STATUS CMD_ACPT_CNT == {cmd_cnt + 1}", 5)
        wait_check(f"AZERSAT IMAGER COLLECTS == {collect_cnt + 1}", 5)
        wait_check("AZERSAT IMAGER COLLECT_TYPE == 'NORMAL'", 5)

    def script_special_collect(self):
        print(
            f"Running {Group.current_suite()}:{Group.current_group()}:{Group.current_script()}"
        )
        Group.print("Perform Special Collect")

        cmd_cnt = tlm("AZERSAT HEALTH_STATUS CMD_ACPT_CNT")
        collect_cnt = tlm("AZERSAT IMAGER COLLECTS")
        cmd("AZERSAT COLLECT with TYPE SPECIAL, DURATION 5")
        wait_check(f"AZERSAT HEALTH_STATUS CMD_ACPT_CNT == {cmd_cnt + 1}", 5)
        wait_check(f"AZERSAT IMAGER COLLECTS == {collect_cnt + 1}", 5)
        wait_check("AZERSAT IMAGER COLLECT_TYPE == 'SPECIAL'", 5)


class ModeGroup(Group):
    def script_safe(self):
        azersat = FakeSat()
        azersat.safe()

    def script_checkout(self):
        azersat = FakeSat()
        azersat.checkout()

    def script_operate(self):
        azersat = FakeSat()
        azersat.operate()


class OpsSuite(Suite):
    def __init__(self):
        self.add_group(CollectGroup)
        self.add_group(ModeGroup)
