module brainfuck(
  input clk,
  output PIN_1,
  input PIN_2,
  output LED,
  output USBPU
);

//  program state data
wire [7:0] i, d;

reg [10:0] ptr = 0;
reg [10:0] pc = 0;
reg [3:0] state = WELCOME;
reg [3:0] depth = 0;

// Extra optional output
reg print_program = 0;
reg print_welcome = 0;
reg print_code = 0;

// Disable USB
assign USBPU = 0;

// Set LED when halted
assign LED = state == HALTED;

// uart control
reg [7:0] reg_dat_di;
wire [7:0] reg_dat_do;
reg reg_dat_re, reg_dat_we;
wire reg_dat_wait;

// states
localparam WELCOME=0, PRINT_PROGRAM=1, STARTING = 2,
           EXECUTING = 3, SKIPPING_FORWARDS=4,
           SKIPPING_BACKWARDS = 5, WAITING_FOR_INPUT = 6,
           WAITING_FOR_OUTPUT = 7, HALTED = 8;

// Wire up new program state
wire [10:0] new_ptr = (state == EXECUTING && (i == "<")) ? ptr-1 :
                     (state == EXECUTING && (i == ">")) ? ptr+1 :
                     ptr;

wire [7:0] new_d = (state == EXECUTING && i == "+") ? d+1 :
                   (state == EXECUTING && i == "-") ? d-1 :
                   d;

wire [10:0] new_pc = (state == PRINT_PROGRAM || state == STARTING) ? pc :
                    (state == SKIPPING_BACKWARDS && (i != "[" || depth > 0)) ? pc-1 :
                    (state == EXECUTING && i == "]" && d > 0) ? pc-1 :
                    pc+1;

// Generate reset signal
reg [5:0] reset_cnt = 0;
wire resetn = &reset_cnt;

always @(posedge clk) begin
  reset_cnt <= reset_cnt + !resetn;
end

 // Create the welcome message
reg [7:0] text [0:9];
reg [3:0] char_count;

initial begin
text[0]  <= "B";
text[1]  <= "r";
text[2]  <= "a";
text[3]  <= "i";
text[4]  <= "n";
text[5]  <= "f";
text[6]  <= "u";
text[7]  <= "c";
text[8]  <= "k";
text[9] <= ":";
end

// More control of uart
reg wait_for_send = 0;

// Print the welcome message
always @(posedge clk) begin
  if (resetn && state == WELCOME) begin
    if (print_welcome) begin
      if (!wait_for_send) begin
        if (char_count == 10) state <= PRINT_PROGRAM;
        else begin
          char_count <= char_count + 1;
          reg_dat_we <= 1;
        end
        reg_dat_di <= text[char_count];
        wait_for_send <= 1;
      end else if (!reg_dat_wait) begin
        reg_dat_we <= 0;
        wait_for_send <= 0;
      end
    end else state <= PRINT_PROGRAM;
  end

  // Print the program
  if (state == PRINT_PROGRAM) begin
    if (print_program) begin
      if (!wait_for_send) begin
        if (i == 8'hff) begin // end of program
          pc <= 0;
          ptr <= 0;
          state <= STARTING;
        end else begin
          reg_dat_we <= 1;
          reg_dat_di <= i;
          wait_for_send <= 1;
          pc <= pc + 1;
        end
      end else if (!reg_dat_wait) begin
        reg_dat_we <= 0;
        wait_for_send <= 0;
      end
    end else begin
      state <= STARTING;
    end
  end

  if (state == STARTING) begin
    state  <= EXECUTING;
    if (print_code) begin
      reg_dat_we <= 1;
      reg_dat_di <= i;
      wait_for_send <= 1;
    end
  end

  if (state == HALTED && !reg_dat_wait) begin
    reg_dat_we <= 0;
    wait_for_send <= 0;
  end

  // Print the executing program
  if ( state >= EXECUTING && state < HALTED) begin
    if (!wait_for_send) begin
      // Initiate print of instruction
      if (i != 8'hff && print_code) begin
        reg_dat_we <= 1;
        reg_dat_di <= i;
        wait_for_send <= 1;
      end

      // Execute the program
      if (state <= SKIPPING_BACKWARDS) begin
        pc <= new_pc;
        ptr <= new_ptr;
      end

      // State machine
      case (state)
      SKIPPING_FORWARDS:
        begin
          if (i == "[") depth <= depth + 1;
          else if (i == "]") begin
            if (depth == 0) state <= EXECUTING;
            else depth <= depth - 1;
          end
        end
      SKIPPING_BACKWARDS:
        begin
          if (i == "]") depth <= depth + 1;
          else if (i == "[") begin
            if (depth == 0) state <= EXECUTING;
            else depth <= depth -1;
          end
        end
      EXECUTING:
        begin
          if (i == 8'hff) begin
            state <= HALTED;
            ptr <= 0;
            pc <= 0;
          end else if (i == "[" && d == 0) begin
            depth <= 0;
            state <= SKIPPING_FORWARDS;
          end else if (i == "]" && d > 0) begin
            depth <= 0;
            state <= SKIPPING_BACKWARDS;
          end else if (i == ".") begin
            state <= WAITING_FOR_OUTPUT;
            reg_dat_we <= 1;
            reg_dat_di <= d;
            wait_for_send <= 1;
          end else if (i == ",") begin
            state <= WAITING_FOR_INPUT;
            reg_dat_re <= 1;
          end
        end
      WAITING_FOR_OUTPUT:
        if (!reg_dat_wait) begin
          state <= EXECUTING;
          reg_dat_we <= 0;
          wait_for_send <= 0;
        end
      WAITING_FOR_INPUT:
        state <= EXECUTING;
      endcase
    end else if (!reg_dat_wait) begin
      reg_dat_we <= 0;
      wait_for_send <= 0;
    end
  end
end

// Program code
rom code (.clk(clk), .pc(new_pc),
          .en(state >= PRINT_PROGRAM && state <= SKIPPING_BACKWARDS), .i(i));

// RAM
ram data (.clk(clk), .p_in(ptr), .d_in(new_d),
          .en(state >= STARTING && state <= SKIPPING_BACKWARDS),
          .we(state >= EXECUTING && state <= SKIPPING_BACKWARDS),
          .p_out(new_ptr), .d_out(d));

// uart from picosoc
simpleuart uart (
  .clk         (clk),
  .resetn      (resetn),

  .ser_tx      (PIN_1),
  .ser_rx      (PIN_2),

  .cfg_divider(139), // 115200 baud
  .reg_dat_we  (reg_dat_we),
  .reg_dat_re  (reg_dat_re),
  .reg_dat_di  (reg_dat_di),
  .reg_dat_do  (reg_dat_do),
  .reg_dat_wait(reg_dat_wait)
);

endmodule

module rom(
  input clk,
  input [10:0] pc,
  input en,
  output reg [7:0] i
);

reg [7:0] code [0:2047];

initial $readmemh("program.hex", code);

always @(posedge clk) if (en) begin
  i <= code[pc];
end
endmodule

module ram(
  input clk,
  input [10:0] p_in,
  input [10:0] p_out,
  input en,
  input we,
  input [7:0] d_in,
  output reg [7:0] d_out
);

reg [7:0] mem [0:2047];

always @(posedge clk) if (en) begin
  if (we) mem[p_in] <= d_in;
  d_out <= mem[p_out];
end
endmodule
