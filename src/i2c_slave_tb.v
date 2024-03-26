`timescale 1ns/1ns

module i2c_slave_tb();

// module i2c_slave(
//     input mod_clk,
//     inout i2c_sda,
//     input i2c_clk,
//     input  [7:0] i2c_data_in,
//     output [7:0] i2c_reg_addr,
//     output [7:0] i2c_data_out,
//     output i2c_data_transfer_dir,
//     output i2c_data_transfer_done,
//     output i2c_reg_addr_changed,
//     input  i2c_reg_data_ready
// );

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

    i2c_slave i2c_slave_u(
        .mod_clk(mod_clk),
        .i2c_sda(i2c_sda_wire),
        .i2c_clk(i2c_clk),
        .i2c_data_in(i2c_data_in),
        .i2c_reg_addr(i2c_reg_addr),
        .i2c_data_out(i2c_data_out),
        .i2c_data_transfer_dir(i2c_data_transfer_dir),
        .i2c_data_transfer_done(i2c_data_transfer_done),
        .i2c_reg_addr_changed(i2c_reg_addr_changed),
        .i2c_reg_data_ready(i2c_reg_data_ready)
    );

    initial mod_clk = 1;
    always#10 mod_clk = ~mod_clk;

    parameter DATA_TO_SEND = 4;

    integer i;
    integer j;
    reg [(8*DATA_TO_SEND-1):0] byte_data_array = {(8'h45 << 1), 8'h4, 8'h1, 8'h23};
    reg [7:0] byte_data;

    initial begin
        i2c_clk = 1;
        i2c_sda = 1;
        #100 i2c_clk = 1;
        i2c_sda = 0;

        for(j = (DATA_TO_SEND - 1); j >= 0; j = j - 1) begin
            byte_data = byte_data_array[((j + 1)*8-1)-:8];
            for(i = 7; i >= 0; i = i - 1) begin
            // send one bit
            #100 i2c_clk = 0;
            #100 i2c_sda = byte_data[i];
            #100 i2c_clk = 1;
            end
            // send one ack
            #100 i2c_clk = 0;
            #100 i2c_sda = 1;
            #100 i2c_clk = 1;
        end

        // i2c stop condition
        #100 i2c_clk = 0;
        #100 i2c_sda = 0;
        #100 i2c_clk = 1;
        #100 i2c_sda = 1;
        #100
        $stop;
    end

endmodule
