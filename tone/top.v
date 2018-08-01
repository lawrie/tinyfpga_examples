// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top(
    input CLK,
    output PIN_1,
    output USBPU
);

assign USBPU = 0;

localparam G = 440, Ef = 311, F = 349, D = 294;

reg [31:0] frequency;
reg [31:0] duration = 0;
reg [21:0] beat_counter = 0;
reg [2:0] note_counter = 0;
reg bar_counter = 0;

wire done;

always @(posedge CLK) begin
  if (beat_counter == 0) begin
    note_counter <= note_counter + 1;
    if (note_counter == 7) bar_counter <= bar_counter + 1;
    if (note_counter == 4) begin
      duration <= 400;
      frequency = 1000;
      //frequency <= (bar_counter == 0 ? Ef : D);
    end else if (note_counter > 0 && note_counter < 4) begin
      duration <= 40;
      //frequency <= (bar_counter == 0 ? G : F);
    end else duration <= 0;
  end
  beat_counter <= beat_counter + 1;
  if (done) duration <= 0;
end

tone t(.clk (CLK), .duration(duration), .freq (frequency), .tone_out (PIN_1), .done(done));

endmodule
