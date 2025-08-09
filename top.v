module top #(
    parameter ADDR_SIZE = 8,
    parameter MEM_DEPTH = 256
    )(  
    input SS_n,
    input clk,
    input rst_n,
    input MOSI,

    output MISO
    );
    wire [ADDR_SIZE - 1 : 0] tx_data;
    wire tx_valid;

    wire [(ADDR_SIZE+2) - 1 : 0] rx_data;
    wire rx_valid;

    spi_slave #(.ADDR_SIZE(ADDR_SIZE))
        spi(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .MISO(MISO), .MOSI(MOSI), 
            .rx_data(rx_data), .rx_valid(rx_valid),
            .tx_data(tx_data), .tx_valid(tx_valid));

    ram #(.MEM_DEPTH(MEM_DEPTH), .ADDR_SIZE(ADDR_SIZE))
        ram(.clk(clk), .rst_n(rst_n), 
            .din(rx_data), .rx_valid(rx_valid),
            .dout(tx_data), .tx_valid(tx_valid));

endmodule