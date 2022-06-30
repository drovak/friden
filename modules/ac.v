// Friden EC-130 AC gate model
// Kyle Owen - 22 June 2022

module ac (
    input clk,
    input en, // resistor input
    input trans, // capacitor input
    output out
);

reg [3:0] _cnt;

// count thresholds arbitrarily chosen until they work...
always @(posedge clk) begin
    // if enable is high and transfer input is low...
    if (en && !trans) begin
        if (_cnt < 9) begin
            _cnt <= _cnt + 1; // charge capacitor
        end
    end
    else begin
        if (_cnt > 0) begin
            _cnt <= _cnt - 1; // otherwise, discharge capacitor
        end
    end
end

// output is high when capacitor is sufficiently charged
// and transfer input is high
assign out = (trans && (_cnt > 3));

endmodule
