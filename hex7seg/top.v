module top(
    input clk,
    output [6:0] seg,
    output digit,
    input button,
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
    display_7_seg_hex seghex (.clk(clk), .value(v), .seg(seg), .digit(digit));
endmodule
