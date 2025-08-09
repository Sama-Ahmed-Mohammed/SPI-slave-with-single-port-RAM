vlib work
vlog ram.v spi_slave.v top.v top_tb.v
vsim -voptargs=+acc work.top_tb
add wave top_tb/clk
add wave top_tb/rst_n
add wave top_tb/MOSI
add wave top_tb/SS_n
add wave top_tb/MISO
add wave top_tb/dut/spi/tx_data
add wave top_tb/dut/spi/rx_data
add wave top_tb/dut/spi/rx_valid
add wave top_tb/dut/spi/tx_valid

run -all
