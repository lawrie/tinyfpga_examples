module top (
  input clk_16MHz,
  output shiftout_clock,
  output shiftout_latch,
  output shiftout_data)

reg [7:0] shift_reg;

assign shiftout_data = shift_reg[7];
assign shiftout_clock = clk_16Mhz;
assign shiftout_latch = 0;

reg [2:0] bit_counter = 0;
reg data_out <= 8'42;

always @posedge(shiftout_clock) begin
  shift_reg <= shift_reg << 1;
  bit_counter <= bit_counter + 1;
  if (bit_counter == 7) shift_reg <= data_out;
end

endmodule
