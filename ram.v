module ram #(
    parameter MEM_DEPTH = 256,
    parameter ADDR_SIZE = 8
)(
    input [(ADDR_SIZE+2) - 1 : 0] din,
    input clk,
    input rst_n,
    input rx_valid,

    output reg [ADDR_SIZE - 1 : 0] dout,
    output reg tx_valid
);

//   internal signals
    //RAM
    reg [ADDR_SIZE - 1 : 0] mem [MEM_DEPTH - 1 : 0];

    //read/write address
    reg [ADDR_SIZE - 1 : 0] address;

    always@(posedge clk) begin
        if(!rst_n) begin
            dout <= 0;
            tx_valid <= 0;
        end
        else begin
            casex({(din[ADDR_SIZE + 1 : ADDR_SIZE]), rx_valid})
                //hold din as write address
                3'b001 : begin 
                    address <= din[ADDR_SIZE - 1 : 0]; 
                    dout <= 0;
                    tx_valid <= 0;
                end

                //write in memory
                3'b011 : begin
                    mem[address] <= din[ADDR_SIZE - 1 : 0];
                    dout <= 0;
                    tx_valid <= 0;
                end

                //hold din as read address
                3'b101 : begin 
                    address <= din[ADDR_SIZE - 1 : 0]; 
                    dout <= 0;
                    tx_valid <= 0;
                end

                //read from memory
                3'b11x : begin
                    tx_valid <= 1;
                    dout <= mem[address];
                end

                default : begin
                    dout <= 0;
                    tx_valid <= 0;
                end
            endcase
        end
    end
endmodule