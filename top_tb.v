module top_tb();
    parameter ADDR_SIZE = 8;
    parameter MEM_DEPTH = 256;

    reg SS_n;
    reg clk;
    reg rst_n;
    reg MOSI;

    wire MISO;
    reg[ADDR_SIZE - 1 : 0] temp_data; //used in checking that correct values are sent and recieved spi and ram.
    reg[ADDR_SIZE - 1 : 0] temp_address; //used to store write address

    top #(.ADDR_SIZE(ADDR_SIZE), .MEM_DEPTH(MEM_DEPTH))
        dut(.SS_n(SS_n), .clk(clk), .rst_n(rst_n), .MOSI(MOSI), .MISO(MISO));

    initial begin
        clk <= 0;
        forever #5 clk <= ~clk;
    end

    integer i;
    initial begin
    // 1.check reset
        rst_n = 0;
        MOSI = 0;
        SS_n = 1;

        temp_data = 0;
        temp_address = 0;

        for ( i = 0; i < MEM_DEPTH ; i = i + 1) begin
            dut.ram.mem[i] = 8'h00; // Initialize each location to 0
        end
        
        repeat(2) @(negedge clk); //since rst is syn, and clk starts with negedge, wait for the next negedge to avoid instant change of rst
        rst_n = 1;
        
        if(MISO != 0) begin
            $display("rst failed, MISO = %b", MISO);
            $stop;
        end
        else $display("rst succeded, MISO = %b", MISO);
        $display("-----------------------------------");

        @(negedge clk);

    // 2.check ram write address command

        SS_n = 0; //start comm
        @(negedge clk); //wait for fsm to transit to chk_cmd
        MOSI = 0; //write

        //send 00 on MOSI which means write address
        @(negedge clk);
        MOSI = 0;
        @(negedge clk);
        MOSI = 0;
        @(negedge clk);

        //send 8 bits of address
        for(i = 0 ; i < 8; i = i+1)begin
            MOSI = $random;
            temp_address[ADDR_SIZE - i - 1] = MOSI; //store write address
            $display("Sending write address, bit number %0d, MOSI = %b", 8-i, MOSI);
            @(negedge clk);
        end

        //end communication
        SS_n = 1;
        $display("-----------------------------------");

        @(negedge clk);

    // 3. check ram write data command

        SS_n = 0; //start comm
        @(negedge clk); //wait for fsm to transit to chk_cmd
        MOSI = 0; //write

        //send 01 on MOSI which means write data
        @(negedge clk);
        MOSI = 0;
        @(negedge clk);
        MOSI = 1;
        @(negedge clk);    

        //send 8 bits of data
        for(i = 0 ; i < 8; i = i+1)begin
            MOSI = $random;
            temp_data[ADDR_SIZE - i - 1] = MOSI; //store write data
            $display("Sending write data, bit number %0d, MOSI = %b", 8-i, MOSI);
            @(negedge clk);
        end

        //end communication
        SS_n = 1;
        $display("-----------------------------------");

        @(negedge clk);
    
    // 4. check ram read address
        SS_n = 0; //start comm
        @(negedge clk); //wait for fsm to transit to chk_cmd
        MOSI = 1; //read

        //send 10 on MOSI which means read address
        @(negedge clk);
        MOSI = 1;
        @(negedge clk);
        MOSI = 0; 
        @(negedge clk);       

        //send 8 bits of address
        for(i = 0 ; i < 8; i = i+1)begin
            MOSI = temp_address[ADDR_SIZE - i - 1];
            $display("Sending read address, bit number %0d, MOSI = %b", 8-i, MOSI);
            @(negedge clk);
        end

        //end communication
        SS_n = 1;
        $display("-----------------------------------");
    
        @(negedge clk);
    
    // 5. check ram read data
        SS_n = 0; //start comm
        @(negedge clk); //wait for fsm to transit to chk_cmd
        MOSI = 1; //read

        //send 11 on MOSI which means read data
        @(negedge clk);
        MOSI = 1;
        @(negedge clk);
        MOSI = 1;
        @(negedge clk);       

        //send dummy data
        for(i = 0 ; i < 8; i = i+1)begin
            MOSI = $random; //send dummy values
            $display("Sending data, bit number %0d, MOSI = %b", 8-i, MOSI);            
            @(negedge clk);
        end
        //after sending dummy data to spi, in the next clk cycle spi will send them to ram.
        //the last negedge clk in the previuos for loop assures that.

        //ram checks the first two bits to find them 11, then the in the *next clk* tx_valid is asserted and 8 bits will be sent
        //wait for a clk cycle
        @(negedge clk);

        //when spi checks tx_valid, in the *next clk* cycle MISO data will be sent
        //wait for another clk cycle
        @(negedge clk);


        for(i = 0 ; i < 8 ; i = i+1)begin
            $display("Recieving read data, bit number %0d, MISO = %b", 8-i, MISO);
            if(temp_data[ADDR_SIZE - i - 1] != MISO) begin
                $display("Error, read data is incorrect. MISO = %b, expected = %b", MISO, temp_data[ADDR_SIZE - i - 1]);
            end
            else $display("Pass, read data is correct. MISO = %b, expected = %b", MISO, temp_data[ADDR_SIZE - i - 1]);
            @(negedge clk);
        end

        //end communication
        SS_n = 1;
        @(negedge clk);

        $display("-----------------------------------");
        $stop;
    end

    initial begin
        $readmemb("mem.dat", dut.ram.mem);
    end

endmodule