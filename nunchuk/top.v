module top(
    input clk,
    output [6:0] seg,
    output digit,
    input button,
    inout sda,
    inout scl,
    output usbpu
);
    // Disable USB
    assign usbpu = 0;
    reg [7:0] v;
    wire PB, pressed;

    SB_IO #(
      .PIN_TYPE(6'b 1010_01),
      .PULLUP(1'b 1)
    ) pbin (
      .PACKAGE_PIN(button),
      .D_IN_0(PB)
    );

    PushButton_Debouncer pb1 (.clk(clk), .PB(PB),  .PB_down(pressed));

    always @(posedge clk) if (pressed) v <= v + 1;

    // Display value as hex
    display_7_seg_hex seghex (.clk(clk), .value(status[7:0]), .seg(seg), .digit(digit));

    wire enable;
    reg read;
    reg [31:0] data = 0, status;
    reg started = 0;
    reg [23:0] reset_timer = 0;
    wire reset = !(&reset_timer);
    reg [23:0] counter;

    always @(posedge clk) begin
      if (reset) reset_timer <= reset_timer + 1;
      else begin
        enable <= 0;
        counter <= counter + 1;
        if (counter == {23{1'b1}}) begin
          data[31] <= 1'b1;
          data[30:24] <= 7'h52;
          data[23:16] <= (started ? 8'h00 : 8'h40);
          data[15:8] <= 8'h00;
          read <= 0;
          enable <= 1;
          if (!started) started <= 1;
        end else if (!status[31] && counter == 0) begin
          data <= 0;
          data[0] <= 1;
          data[23:17] <= 7'h52;
          enable <= 1;
          read <= 1;
        end
      end
    end

    I2C_master #(.freq(16)) nunchuk (
      .sys_clock(clk),
      .SDA(sda),
      .SCL(scl),
      .reset(reset),
      .ctrl_data(data),
      .wr_ctrl(enable),
      .read(read),
      .status (status)
      );
endmodule
