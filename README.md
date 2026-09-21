![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# TTIHP26b UART Hello World

A one-tile Tiny Tapeout design that continuously transmits:

```text
Hello, TinyTapeout!
```

The output is 115200 baud, 8 data bits, no parity, and one stop bit on
`uo_out[4]`, which maps to the Tiny Tapeout demoboard's USB UART. A one-second
idle interval separates complete messages so the output remains easy to
observe.

## Run the tests

```sh
cd test
make -B
```

See [datasheet](docs/info.md) for devkit bring-up.
