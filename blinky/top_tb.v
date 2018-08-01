`timescale 1ns/1ps
module tb ();
  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, t);
  end

  reg clk;
  wire led, usbpu;

  initial begin
		clk = 1'b0;
	end

  always begin
    #31 clk = !clk;
  end

  initial begin
    repeat(16000000) @(posedge clk);

      $finish;
  end

  top t (.CLK(clk), .LED(led), .USBPU(usbpu));

endmodule // tb
