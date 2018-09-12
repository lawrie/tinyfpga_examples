module decoder_7_seg_hex(
  input clk,
  input [3:0] data,
  output reg [6:0] seg
);

always @(posedge clk) begin
 case(data)
  'h0: seg <= 'b1111110;
  'h1: seg <= 'b0000110;
  'h2: seg <= 'b1101101;
  'h3: seg <= 'b1001111;
  'h4: seg <= 'b0110101;
  'h5: seg <= 'b1011011;
  'h6: seg <= 'b1111011;
  'h7: seg <= 'b0001110;
  'h8: seg <= 'b1111111;
  'h9: seg <= 'b1011111;
  'hA: seg <= 'b0111111;
  'hB: seg <= 'b1110011;
  'hC: seg <= 'b1111000;
  'hD: seg <= 'b1100111;
  'hE: seg <= 'b1111001;
  'hF: seg <= 'b0111001;
 endcase
end
endmodule
