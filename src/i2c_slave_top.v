module i2c_slave_top(
    inout   i2c_sda,
    input   i2c_clk
);

    parameter REG_READ_ONLY_CNT     = 3;
    parameter REG_WRITE_READ_CNT    = 4;
    wire [23:0] fpga_version = {8'h0, 8'h1, 8'h0};      // fpga version v0.1.0
    // 1st byte 0-7  type;
    // 2nd byte 8-15 type;
    // 3th byte 0-7  source;
    // 4th byte 8-15 source;
    reg  [31:0] i2c_register = {8'h1, 8'h2, 8'h3, 8'h4};

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
        case (i2c_reg_addr)
            0: i2c_data_in <= i2c_register[31: 24];
            1: i2c_data_in <= i2c_register[23: 16];
            2: i2c_data_in <= i2c_register[15: 8];
            3: i2c_data_in <= i2c_register[7: 0];
            4: i2c_data_in <= fpga_version[23: 16];
            5: i2c_data_in <= fpga_version[15: 8];
            6: i2c_data_in <= fpga_version[7: 0];
            default : i2c_data_in <= 0;
        endcase
    end

    // reg i2c_reg_addr_r
    always @ (posedge i2c_mod_clk) begin
        if (i2c_data_transfer_dir == 0 && i2c_data_transfer_done) begin
            case (i2c_reg_addr)
                8'h0: i2c_register[31: 24] = i2c_data_out;
                8'h1: i2c_register[23: 16] = i2c_data_out;
                8'h2: i2c_register[15: 8]  = i2c_data_out;
                8'h3: i2c_register[7: 0]   = i2c_data_out;
            endcase
        end
    end

endmodule
