`timescale 1ns/1ps
module tb ();
  initial begin
    $dumpfile("brainfuck_tb.vcd");
    $dumpvars(0, bf);
  end

  reg clk;
  wire led, usbpu, pin1, pin2;

  initial begin
		clk = 1'b0;
	end

  always begin
    #31 clk = !clk;
  end

  initial begin
    repeat(100000) @(posedge clk);

      $finish;
  end

  brainfuck bf (.clk(clk), .PIN_1(pin1), .PIN_2(pin2), .LED(led), .USBPU(usbpu));

endmodule // tb
