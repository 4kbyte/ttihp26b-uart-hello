# Copyright (c) 2026 Rom DuPlain (@4kbyte)
# SPDX-License-Identifier: Apache-2.0

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer

CLOCK_PERIOD_NS = 20
GATES = os.getenv("GATES") == "yes"
CLOCK_HZ = int(os.getenv("CLOCK_HZ", "50000000" if GATES else "50000"))
BAUD_RATE = int(os.getenv("BAUD_RATE", "115200" if GATES else "115"))
CLKS_PER_BIT = (CLOCK_HZ + (BAUD_RATE // 2)) // BAUD_RATE
BIT_TIME_NS = CLOCK_PERIOD_NS * CLKS_PER_BIT
INTER_MESSAGE_DELAY_NS = int(os.getenv("INTER_MESSAGE_DELAY_NS", "1000000"))
MESSAGE = b"Hello, TinyTapeout!\r\n"


async def reset_design(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1


async def read_uart_byte(tx):
    await FallingEdge(tx)
    await Timer(BIT_TIME_NS // 2, unit="ns")
    assert tx.value == 0, "UART start bit must be low"

    value = 0
    for bit_index in range(8):
        await Timer(BIT_TIME_NS, unit="ns")
        value |= int(tx.value) << bit_index

    await Timer(BIT_TIME_NS, unit="ns")
    assert tx.value == 1, "UART stop bit must be high"
    return value


async def start_clock(dut):
    clock = Clock(dut.clk, CLOCK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())


@cocotb.test()
async def test_uart_message_and_repeat(dut):
    await start_clock(dut)
    await reset_design(dut)

    assert dut.uio_out.value == 0
    assert dut.uio_oe.value == 0
    assert (int(dut.uo_out.value) & 0xEF) == 0

    received = bytes([await read_uart_byte(dut.uart_tx) for _ in MESSAGE])
    assert received == MESSAGE

    if not GATES:
        repeat_wait_start = cocotb.utils.get_sim_time(unit="ns")
        assert await read_uart_byte(dut.uart_tx) == MESSAGE[0]
        repeat_wait_ns = (
            cocotb.utils.get_sim_time(unit="ns") - repeat_wait_start
        )
        expected_wait_ns = INTER_MESSAGE_DELAY_NS + (10 * BIT_TIME_NS)
        assert abs(repeat_wait_ns - expected_wait_ns) <= (2 * CLOCK_PERIOD_NS)


@cocotb.test()
async def test_uart_bit_period(dut):
    await start_clock(dut)
    await reset_design(dut)

    assert await read_uart_byte(dut.uart_tx) == ord("H")

    await FallingEdge(dut.uart_tx)
    start_time = cocotb.utils.get_sim_time(unit="ns")
    await RisingEdge(dut.uart_tx)
    elapsed_ns = cocotb.utils.get_sim_time(unit="ns") - start_time

    tolerance_ns = CLOCK_PERIOD_NS if GATES else 0
    assert abs(elapsed_ns - BIT_TIME_NS) <= tolerance_ns


@cocotb.test()
async def test_reset_aborts_frame_and_restarts_message(dut):
    await start_clock(dut)
    await reset_design(dut)

    await FallingEdge(dut.uart_tx)
    await Timer(BIT_TIME_NS // 2, unit="ns")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    await Timer(CLOCK_PERIOD_NS // 2, unit="ns")

    assert dut.uart_tx.value == 1

    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    assert await read_uart_byte(dut.uart_tx) == ord("H")
