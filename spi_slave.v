module spi_slave #(
    parameter ADDR_SIZE = 8,

    parameter IDLE = 3'b000,
    parameter CHK_CMD = 3'b001,
    parameter WRITE = 3'b010,
    parameter READ_ADD = 3'b011,
    parameter READ_DATA = 3'b100
)(
    input MOSI,
    input SS_n,
    input clk,
    input rst_n,

    input [ADDR_SIZE - 1 : 0] tx_data,
    input tx_valid,

    output reg [(ADDR_SIZE+2) - 1 : 0] rx_data,
    output reg rx_valid,
    output reg MISO
);
    (*fsm_encoding = "one_hot" *)

//============  Internal signals    ===========================
    reg [2:0] cs;
    reg [2:0] ns;
    reg read_addr_or_data; //if 0 read address, if 1 read data

//==============================================================
//                  Next state logic
//==============================================================
    always@(cs, SS_n, MOSI) begin
        case(cs)
            IDLE        : begin
                if(SS_n) ns <= IDLE;

                else ns <= CHK_CMD;
            end

            CHK_CMD     : begin
                if(!SS_n && !MOSI) ns <= WRITE;

                else if(!SS_n && MOSI)begin 
                    if(!read_addr_or_data) begin
                        ns <= READ_ADD;
                    end

                    else begin
                        ns <= READ_DATA;
                    end
                end

                else ns <= IDLE;
            end

            WRITE       : begin
                if(!SS_n) ns <= WRITE; 
                else ns<= IDLE;
            end

            READ_ADD    : begin
                if(!SS_n) ns <= READ_ADD; 
                else ns <= IDLE;
            end

            READ_DATA   : begin
                if(!SS_n) ns <= READ_DATA; 
                else ns <= IDLE;
            end

            default     : ns <= IDLE;
        endcase
    end

//==============================================================
//                  State memory
//==============================================================
    always@(posedge clk)begin
        if(!rst_n) cs <= IDLE;
        else cs <= ns;
    end
//=============================================================
//                  Output logic: 
//=============================================================
        
    reg [$clog2(ADDR_SIZE+2) - 1: 0] counter;
    reg [(ADDR_SIZE+2) - 1 : 0] temp; //temp register to parallelize data in

    always@(posedge clk) begin
        if(!rst_n ) begin
            MISO <= 0;
            rx_data <= 0;
            rx_valid <= 0;
            counter <= 0;
            temp <= 0;
            read_addr_or_data <= 0; //should initially be zero, since we must send read address first
        end

    //=======   RAM write/read command:  =========
        else begin
    // they are the same since slave recieve 10 bits serially and resend them to ram, the ram will check if its read or write
            if(cs == WRITE || cs == READ_ADD || cs == READ_DATA) begin

                //serial in parallel out: parallelize MOSI data to send it to ram, happens in all cases of read/write
                temp[(ADDR_SIZE+2) - counter - 1] <= MOSI; //send 10 bits to ram

                //parallel in serial out: if ram asserts tx_valid, serialize tx_data to send it on MISO
                if(tx_valid) MISO <= tx_data[ADDR_SIZE - counter];

                /*Why  [ADDR_SIZE - counter] not [ADDR_SIZE - counter - 1]?
                    in read data state, when 10 bits are sent to ram the counter reaches 9 and restarts at zero.
                    in the next clk the tx_valid =1 , but the counter will have started counting again (counter =1)
                    in this case the first bit to be sent on MISO is tx_data[7] which is correct, not tx_data[6].
                */

                //counter logic
                if(counter == (ADDR_SIZE + 1)) begin 
                    counter <= 0;
                    rx_data <= temp;
                    rx_valid <= 1; //when counter finishes 10 counts correct data will be ready on rx_data
                end

                else begin
                    counter <= counter + 1;
                    rx_valid <= 0;
                end

                //read_addr_or_data signal
                if(cs == READ_ADD) read_addr_or_data <= 1;
                else if(cs == READ_DATA) read_addr_or_data <= 0;

            end

            //if state is IDLE or CHK_CMD
            else begin 
                rx_valid <= 0;
                counter <= 0;
                temp <= 0;
            end
        end
    end 
endmodule