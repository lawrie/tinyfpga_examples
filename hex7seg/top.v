// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top(
    input clk,
    output [6:0] seg,
    output digit,
    output usbpu
);
    // Disable USB
    assign usbpu = 0;

    // Display value as hex
    display_7_seg_hex seghex (.clk(clk), .value(8'hef), .seg(seg), .digit(digit));
endmodule
