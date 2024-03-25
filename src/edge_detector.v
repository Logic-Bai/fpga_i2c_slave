module edge_detector(
    input clk,
    input sig,
    output pos_edge,
    output neg_edge
);

reg sig_dly_0;        // internal signal to store the delay version of signal
reg sig_dly_1;        // internal signal to store the delay version of signal
reg sig_dly_2;        // internal signal to store the delay version of signal
reg sig_dly_3;        // internal signal to store the delay version of signal

always @ (posedge clk)
begin
    sig_dly_0 <= sig;
    sig_dly_1 <= sig_dly_0;
    sig_dly_2 <= sig_dly_1;
    sig_dly_3 <= sig_dly_2;
end

assign pos_edge = sig_dly_2 & (~sig_dly_3);
assign neg_edge = (~sig_dly_2) & sig_dly_3;

endmodule
