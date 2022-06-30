// Friden EC-130 flip-flop model
// Kyle Owen - 22 June 2022

module ff (
    input clk,
    input rst_l,
    input set_l,
    input tog_p,
    input rst_p,
    input set_p,
    output q,
    output q_n
);

reg prev_rst_p;
reg prev_set_p;
reg prev_tog_p;

reg q_int;
assign q = q_int;
assign q_n = !q_int;

// completely synchronous design to make synthesis easier
//
// this does not accurately capture the SR flip-flop nature
// of the real thing, in that both outputs will be asserted
// if both set and reset inputs are asserted, but this does
// not seem to have any ill effects in the design of the
// EC-130

always @(posedge clk) begin
    prev_rst_p <= rst_p;
    prev_set_p <= set_p;
    prev_tog_p <= tog_p;

    if (rst_l) begin
        q_int <= 1'b0;
    end
    else if (set_l) begin
        q_int <= 1'b1;
    end
    else if (!prev_rst_p && rst_p) begin
        q_int <= 1'b0;
    end
    else if (!prev_set_p && set_p) begin
        q_int <= 1'b1;
    end
    else if (!prev_tog_p && tog_p) begin
        q_int <= !q_int;
    end
end

endmodule
