module i2c_slave_top(
    inout   i2c_sda,
    input   i2c_clk
);

    parameter I2C_REG_RW_LEN = 10;   // 2byte source_type + 8byte input_source
    parameter I2C_REG_RO_LEN = 3;
    wire [((I2C_REG_RO_LEN*8)-1):0] fpga_version = {8'h0, 8'h1, 8'h0};      // fpga version v0.1.0
    reg  [((I2C_REG_RW_LEN*8)-1):0] i2c_register = 0;

    wire i2c_sda_in = i2c_sda;
    wire  i2c_sda_out;
    assign i2c_sda = i2c_sda_out ? 1'bz : 0;
    reg  [7:0]  i2c_data_in = 0;
    wire [7:0]  i2c_reg_addr;
    wire [7:0]  i2c_data_out;
    wire        i2c_data_transfer_dir;
    wire        i2c_data_transfer_done;

    wire i2c_mod_clk;
    Gowin_OSC osc_u(i2c_mod_clk, 1'b1);

    i2c_slave i2c_slave_u(
        .mod_clk(i2c_mod_clk),
        .i2c_sda_in(i2c_sda_in),
        .i2c_sda_out(i2c_sda_out),
        .i2c_clk(i2c_clk),
        .i2c_data_in(i2c_data_in),
        .i2c_reg_addr(i2c_reg_addr),
        .i2c_data_out(i2c_data_out),
        .i2c_data_transfer_dir(i2c_data_transfer_dir),
        .i2c_data_transfer_done(i2c_data_transfer_done)
    );

    always @ (*) begin
        if (i2c_reg_addr < I2C_REG_RW_LEN) begin
            i2c_data_in <= i2c_register[((i2c_reg_addr)*8)+:8];
        end
        else if (i2c_reg_addr < (I2C_REG_RO_LEN+I2C_REG_RW_LEN)) begin
            i2c_data_in <= fpga_version[((i2c_reg_addr - I2C_REG_RW_LEN)*8)+:8];
        end
        else begin
            i2c_data_in <= 0;
        end
    end

    // reg i2c_reg_addr_r
    always @ (posedge i2c_mod_clk) begin
        if (i2c_data_transfer_dir == 0 && i2c_data_transfer_done) begin
            if (i2c_reg_addr < (I2C_REG_RW_LEN)) begin
                i2c_register[((i2c_reg_addr)*8)+:8] = i2c_data_out;
            end
        end
    end

endmodule
