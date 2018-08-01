// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    input PIN_2,
    output USBPU,
    output PIN_1
);

  // Disable USB
  assign USBPU = 0;

  wire clk = CLK;
  reg [3:0] reg_div_en;
  reg [31:0] reg_div_di;
  wire [31:0] reg_div_do;
  reg [31:0] reg_dat_di;
  wire [31:0] reg_dat_do;
  reg reg_dat_re, reg_dat_we;
  wire reg_dat_wait;
  reg speed_set = 0;
  reg wait_for_send;

  // Generate reset signal
  reg [5:0] reset_cnt = 0;
  wire resetn = &reset_cnt;

  always @(posedge clk) begin
    reset_cnt <= reset_cnt + !resetn;
  end

  // Set the uart speed to 115200
  always @(posedge clk) begin
    if (resetn && !speed_set) begin
      reg_div_en <= 4'b1111;
      reg_div_di <= 32'd139; // 16Mhz / 115200
      speed_set <= 1;
    end else reg_div_en <= 4'b0000;
  end

  // Create the text string
  reg [7:0] text [0:12];

  initial begin
  text[0]  <= "H";
  text[1]  <= "e";
  text[2]  <= "l";
  text[3]  <= "l";
  text[4]  <= "o";
  text[5]  <= " ";
  text[6]  <= "W";
  text[7]  <= "o";
  text[8]  <= "r";
  text[9]  <= "l";
  text[10] <= "d";
  text[11] <= "!";
  text[12] <= "\n";
  end

  // Send characters about every second
  reg [22:0] delay_count;
  reg [3:0] char_count;

  always @(posedge clk) begin
    delay_count <= delay_count + 1;
    if  (speed_set && !wait_for_send) begin
      if (&delay_count) begin
        if (char_count == 12) char_count <= 0;
        else char_count <= char_count + 1;
        reg_dat_di <= text[char_count];
        reg_dat_we <= 1;
        wait_for_send <= 1;
      end
    end else if (!reg_dat_wait) begin
      reg_dat_we <= 0;
      wait_for_send <= 0;
    end
  end

// uart from picosoc
  simpleuart uart (
    .clk         (clk),
    .resetn      (resetn),

    .ser_tx      (PIN_1),
    .ser_rx      (PIN_2),

    .reg_div_we  (reg_div_en),
    .reg_div_di  (reg_div_di),
    .reg_div_do  (reg_div_do),

    .reg_dat_we  (reg_dat_we),
    .reg_dat_re  (reg_dat_re),
    .reg_dat_di  (reg_dat_di),
    .reg_dat_do  (reg_dat_do),
    .reg_dat_wait(reg_dat_wait)
  );

endmodule
