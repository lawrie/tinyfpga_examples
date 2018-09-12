module display_7_seg_hex(
  input clk,
  input [7:0] value,
  output [6:0] seg,
  output reg digit
);

reg [3:0] data;
reg posn;
reg [23:0] prescaler;

decoder_7_seg_hex decoder(.clk (clk), .seg(seg), .data(data));

always @(posedge clk) begin
  prescaler <= prescaler + 1;
  if (prescaler == 8000) begin // 1khz
    prescaler <= 0;
    posn <= posn + 1;
    if (posn == 1) begin
      data <= value[3:0];
      digit <= 0;
    end else if (posn == 0) begin
      data <= value[7:4];
      digit <= 1;
    end
  end
end
endmodule
