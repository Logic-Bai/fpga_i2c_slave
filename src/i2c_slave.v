module i2c_slave(
    input  mod_clk,
    input  i2c_sda_in,
    output i2c_sda_out,
    input  i2c_clk,
    input  [7:0] i2c_data_in,
    output [7:0] i2c_reg_addr,
    output [7:0] i2c_data_out,
    output i2c_data_transfer_dir,
    output i2c_data_transfer_done
);

parameter I2C_SLAVE_DEVICE_ADDR = 7'h45;
reg i2c_sda_out_ctr = 1;
assign i2c_sda_out = i2c_sda_out_ctr;

reg i2c_data_transfer_en_r = 0;
reg i2c_data_transfer_done_r = 0;

// asyn i2c_clk & i2c_sda to syn signal
wire i2c_clk_pos_edge;
wire i2c_clk_neg_edge;
wire i2c_sda_pos_edge;
wire i2c_sda_neg_edge;

edge_detector i2c_clk_detector(
    .clk(mod_clk),
    .sig(i2c_clk),
    .pos_edge(i2c_clk_pos_edge),
    .neg_edge(i2c_clk_neg_edge)
);

edge_detector i2c_sda_detector(
    .clk(mod_clk),
    .sig(i2c_sda_in),
    .pos_edge(i2c_sda_pos_edge),
    .neg_edge(i2c_sda_neg_edge)
);

// i2c start condition
wire i2c_start = i2c_clk & i2c_sda_neg_edge;
// i2c stop condition
wire i2c_stop = i2c_clk & i2c_sda_pos_edge;
// i2c state machine parameter
reg [2:0]   i2c_state_machine = 0;
parameter   I2C_STAT_IDLE           = 3'd0;   // i2c idle
parameter   I2C_GET_DEVICE_ADDR     = 3'd1;   // i2c get device address
parameter   I2C_GET_REG_ADDR        = 3'd2;   // i2c get register address
parameter   I2C_MASTER_WRITE_REG    = 3'd3;   // i2c write register
parameter   I2C_MASTER_READ_REG     = 3'd4;   // i2c read register
// i2c transfer direction
reg i2c_transfer_direction = 0;
parameter   I2C_MASTER_READ     = 1'd0;   // i2c master read slave
parameter   I2C_MASTER_WRITE    = 1'd0;   // i2c master write slave
// i2c 8bit-regsiter is used to store data
reg [7:0] i2c_slave_input_shift   = 0;
reg [7:0] i2c_slave_output_shift  = 0;
// i2c ack receive status
wire i2c_ack_status = i2c_sda_in;
// i2c register address
reg [7:0] i2c_reg_addr_r = 0;

assign i2c_reg_addr = i2c_reg_addr_r;
assign i2c_data_transfer_done = i2c_data_transfer_done_r;
assign i2c_data_transfer_dir = i2c_transfer_direction;
assign i2c_data_out = i2c_slave_input_shift;

// i2c bit shift count which is used to count to 9, the 9th cnt is ack signal
reg [3:0] i2c_neg_bit_cnt = 4'd0;
reg [3:0] i2c_pos_bit_cnt = 4'd0;
parameter I2C_ACK_BIT_CNT = 4'd9 - 1;

reg i2c_start_status = 0;

// I2C slave state machine
always @ (posedge mod_clk)
begin
    if (i2c_stop) begin
        i2c_state_machine <= I2C_STAT_IDLE;
    end
    else if (i2c_start) begin
        i2c_state_machine <= I2C_GET_DEVICE_ADDR;
    end
    else if (i2c_clk_pos_edge && i2c_pos_bit_cnt == I2C_ACK_BIT_CNT) begin
        if (i2c_ack_status == 1'd0) begin
            case (i2c_state_machine)
                I2C_GET_DEVICE_ADDR: begin
                    if (i2c_slave_input_shift[7:1] == I2C_SLAVE_DEVICE_ADDR) begin
                        // When I2C master is write to I2C slave, the first byte write to slave is slave's register address.
                        if (i2c_slave_input_shift[0]) begin
                            i2c_state_machine <= I2C_MASTER_READ_REG;
                        end
                        else begin
                            i2c_state_machine <= I2C_GET_REG_ADDR;
                        end
                        i2c_transfer_direction <= i2c_slave_input_shift[0];
                    end
                    else begin
                        i2c_state_machine <= I2C_STAT_IDLE;
                    end
                end
                I2C_GET_REG_ADDR: begin
                    i2c_reg_addr_r <= i2c_slave_input_shift;
                    i2c_state_machine <= I2C_MASTER_WRITE_REG;
                end
                I2C_MASTER_WRITE_REG: begin
                    i2c_reg_addr_r <= i2c_reg_addr_r + 1'b1;
                    i2c_state_machine <= I2C_MASTER_WRITE_REG;
                end
                I2C_MASTER_READ_REG: begin
                    i2c_reg_addr_r <= i2c_reg_addr_r + 1'b1;
                    i2c_state_machine <= I2C_MASTER_READ_REG;
                end
                default:
                    i2c_state_machine <= I2C_STAT_IDLE;
            endcase
        end
        else begin
            i2c_state_machine <= I2C_STAT_IDLE;
        end
    end
end

// I2C slave write_done status
always @ (posedge mod_clk) begin
    if (i2c_clk_neg_edge) begin
        if (i2c_neg_bit_cnt == I2C_ACK_BIT_CNT &&
            i2c_state_machine == I2C_MASTER_WRITE_REG) begin
                i2c_data_transfer_done_r <= 1;
        end
        else begin
            i2c_data_transfer_done_r <= 0;
        end
    end
    else if (i2c_clk_pos_edge) begin
        i2c_data_transfer_done_r <= 0;
    end
end

// I2C slave opearate i2c_sda in i2c_clk negative edge
always @ (posedge mod_clk)
begin
    if (i2c_stop) begin
        i2c_neg_bit_cnt <= 4'd0;
        i2c_sda_out_ctr <= 1;
        i2c_start_status <= 0;
    end
    else if (i2c_start) begin
        i2c_neg_bit_cnt <= 4'd0;
        i2c_sda_out_ctr <= 1;
        i2c_start_status <= 1;
    end
    else begin
        // I2C slave data out
        if (i2c_clk_neg_edge &&
            i2c_start_status &&
            i2c_state_machine != I2C_STAT_IDLE) begin
            if (i2c_neg_bit_cnt == I2C_ACK_BIT_CNT) begin
                i2c_neg_bit_cnt <= 0;
                // send ack there
                if (i2c_state_machine == I2C_GET_DEVICE_ADDR) begin
                    // If received data equal device address, send ack
                    if (i2c_slave_input_shift[7:1] == I2C_SLAVE_DEVICE_ADDR) begin
                        i2c_sda_out_ctr <= 0;
                    end
                    else begin
                        i2c_sda_out_ctr <= 1;
                    end
                end
                else if (i2c_state_machine == I2C_GET_REG_ADDR || i2c_state_machine == I2C_MASTER_WRITE_REG) begin
                    i2c_sda_out_ctr <= 0;
                end
                else begin
                    i2c_sda_out_ctr <= 1;
                end
            end
            else if (i2c_neg_bit_cnt == 0) begin
                i2c_neg_bit_cnt <= i2c_neg_bit_cnt + 1'b1;
                i2c_slave_output_shift[7:0] <= i2c_data_in[7:0];
                if (i2c_state_machine == I2C_MASTER_READ_REG) begin
                    i2c_sda_out_ctr <= i2c_data_in[7];
                end
                else begin
                    i2c_sda_out_ctr <= 1;
                end
            end
            else begin
                i2c_neg_bit_cnt <= i2c_neg_bit_cnt + 1'b1;
                if (i2c_state_machine == I2C_MASTER_READ_REG) begin
                    i2c_sda_out_ctr <= i2c_slave_output_shift[7 - i2c_neg_bit_cnt];
                end
                else begin
                    i2c_sda_out_ctr <= 1;
                end
            end
        end
    end
end

// I2C slave opearate i2c_sda in i2c_clk positive edge
always @ (posedge mod_clk)
begin
    if (i2c_stop || i2c_start) begin
        i2c_pos_bit_cnt <= 0;
    end
    else begin
        // I2C slave data in
        if (i2c_clk_pos_edge) begin
            if (i2c_pos_bit_cnt == I2C_ACK_BIT_CNT) begin
                i2c_pos_bit_cnt <= 0;
            end
            else begin
                i2c_pos_bit_cnt <= i2c_pos_bit_cnt + 1'b1;
                i2c_slave_input_shift[7:0] <= {i2c_slave_input_shift[6:0], i2c_sda_in};
            end
        end
    end
end

endmodule
