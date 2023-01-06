import cocotb

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

class Testbench:
    def __init__(self, dut):
        self._dut = dut
        self._clk = dut.clk
        self._cen = dut.clk_en
        self._clk_g = dut.clk_g
        self.cycle_count = 0

        self._clk.setimmediatevalue(0)
        self._cen.setimmediatevalue(0)

        self._clk_thread = cocotb.start_soon(Clock(dut.clk, 5, 'ns').start())
        self._scbd = cocotb.start_soon(self.cycle_counter())

    async def cycles(self, value: int) -> None:
        await ClockCycles(self._clk, value)

    @property
    def enable_clock(self):
        self._cen.value = 1

    @property
    def disable_clock(self):
        self._cen.value = 0

    async def cycle_counter(self):
        while True:
            await RisingEdge(self._clk_g)
            self.cycle_count += 1


@cocotb.test()
async def test_this(dut):
    tb = Testbench(dut)

    # Wait until the GSR is deasserted
    await tb.cycles(50)

    tb.enable_clock
    await tb.cycles(5)
    tb.disable_clock
    await tb.cycles(5)

    assert tb.cycle_count == 5, "merde! cycle_count=%s" % tb.cycle_count

