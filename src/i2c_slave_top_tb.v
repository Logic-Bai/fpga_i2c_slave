`timescale 1ns/1ns

module i2c_slave_tb();

    reg mod_clk;
    reg i2c_clk;
    reg i2c_sda;
    wire i2c_sda_wire;
    assign i2c_sda_wire = i2c_sda ? 1'bz : 0;
    pullup(i2c_sda_wire);

    reg [7:0] i2c_data_in;
    wire [7:0] i2c_reg_addr;
    wire [7:0] i2c_data_out;
    wire i2c_data_transfer_dir;
    wire i2c_data_transfer_done;
    wire i2c_reg_addr_changed;
    reg i2c_reg_data_ready;

    i2c_slave_top i2c_slave_top_u(
        .i2c_sda(i2c_sda_wire),
        .i2c_clk(i2c_clk)
    );

    initial mod_clk = 1;
    always#20 mod_clk = ~mod_clk;

    parameter DATA_TO_SEND = 6;
    parameter DATA_TO_READ = 10;

    integer i;
    integer j;
    reg [(8*DATA_TO_SEND-1):0] byte_write_data_array = {(8'h45 << 1), 8'h0, 8'h8, 8'h8, 8'h8, 8'h1};
    reg [(8*DATA_TO_READ-1):0] byte_read_data_array = {(8'h45 << 1), 8'h0, ((8'h45 << 1) + 8'h1), 8'h0, 8'h1, 8'h08, 8'h23, 8'h45, 16'h0};
    reg [7:0] byte_data;

    initial begin
        i2c_reg_data_ready = 0;
        /******************** code segement start for i2c write *************************/
        // i2c start condition
        #100 i2c_clk = 1;
        i2c_sda = 1;
        #5000 i2c_sda = 0;
        #5000 i2c_clk = 0;

        // i2c_slave write process
        for(j = (DATA_TO_SEND - 1); j >= 0; j = j - 1) begin
            byte_data = byte_write_data_array[((j + 1)*8-1)-:8];
            for(i = 7; i >= 0; i = i - 1) begin
                // send one bit
                #2000 i2c_sda = byte_data[i];
                #3000 i2c_clk = 1;
                #5000 i2c_clk = 0;
            end
            #3000 i2c_sda = 1;
            // send one ack
            #5000 i2c_clk = 1;
            #5000 i2c_clk = 0;
        end

        // i2c stop condition
        i2c_sda = 0;
        #5000 i2c_clk = 1;
        #5000 i2c_sda = 1;
        /******************** code segement end for i2c write *************************/

        // i2c start condition
        #100 i2c_clk = 1;
        i2c_sda = 1;
        #5000 i2c_sda = 0;
        #5000 i2c_clk = 0;

        // i2c master set register address
        for(j = (DATA_TO_READ); j >= (DATA_TO_READ - 1); j = j - 1) begin
            byte_data = byte_read_data_array[(j*8-1)-:8];
            for(i = 7; i >= 0; i = i - 1) begin
                // send one bit
                #2000 i2c_sda = byte_data[i];
                #3000 i2c_clk = 1;
                #5000 i2c_clk = 0;
            end
            #3000 i2c_sda = 1;
            // send one ack
            #5000 i2c_clk = 1;
            #5000 i2c_clk = 0;
        end

        // i2c restart
        #5000 i2c_clk = 1;
        #3000 i2c_sda = 0;
        #2000 i2c_clk = 0;

        // send device address
        byte_data = byte_read_data_array[((DATA_TO_READ - 2)*8-1)-:8];
        for(i = 7; i >= 0; i = i - 1) begin
            // send one bit
            #2000 i2c_sda = byte_data[i];
            #3000 i2c_clk = 1;
            #5000 i2c_clk = 0;
        end
        #3000 i2c_sda = 1;
        // send one ack
        #5000 i2c_clk = 1;
        #5000 i2c_clk = 0;

        for(j = (DATA_TO_READ - 3); j >= 2; j = j - 1) begin
            for(i = 7; i >= 0; i = i - 1) begin
                // read one bit
                #5000 i2c_clk = 1;
                #5000 i2c_clk = 0;
            end
            // send one ack
            i2c_sda = 0;
            #5000 i2c_clk = 1;
            #5000 i2c_clk = 0;
            i2c_sda = 1;
        end

        for(i = 7; i >= 0; i = i - 1) begin
            // read one bit
            #5000 i2c_clk = 1;
            #5000 i2c_clk = 0;
        end

        // send NAK in the end byte
        #5000 i2c_clk = 1;
        #5000 i2c_clk = 0;

        // i2c stop condition
        i2c_sda = 0;
        #5000 i2c_clk = 1;
        #5000 i2c_sda = 1;

        #5000
        $stop;
    end

endmodule
