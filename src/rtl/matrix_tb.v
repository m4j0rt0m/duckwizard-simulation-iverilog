
`default_nettype none

module matrix_tb();

  /* includes */
  `include "matrix.vh"

  /* simulation parameters */
  localparam SIM_CYCLES = 1000;

  /* local parameters */
  localparam MAX_VALUE = `MAX_VALUE;
  localparam NUM_X     = `NUM_X;
  localparam NUM_Y     = `NUM_Y;
  localparam NUM_WIDTH = $clog2(MAX_VALUE+1);
  localparam X_IDX     = $clog2(NUM_X);
  localparam Y_IDX     = $clog2(NUM_Y);

  /* ctrl flow */
  reg                   clk;
  reg                   arstn;

  /* indexes */
  reg   [X_IDX-1:0]     x_idx;
  reg   [Y_IDX-1:0]     y_idx;
  wire  [X_IDX-1:0]     x_idx_int;
  wire  [Y_IDX-1:0]     y_idx_int;

  /* output value */
  wire  [NUM_WIDTH-1:0] matrix_value;
  wire                  valid;

  /* initialization */
  initial begin
    clk = 0;
    arstn = 0;
    x_idx = 0;
    y_idx = 0;
    `ifdef __VCD__
      $dumpfile("matrix_tb.vcd");
      $dumpvars();
    `endif
    $display("Starting simulation...");
    $monitor("[reset = %b] [valid = %b] y = %d, x = %d, value = %d", arstn, valid, y_idx_int, x_idx_int, matrix_value);
    #SIM_CYCLES;
    $display("End of simulation");
    $finish;
  end

  /* clock and reset */
  always #10  clk = ~clk;
  always #100 arstn = 1;

  /* index generation */
  always @ (posedge clk, negedge arstn) begin
    if(~arstn) begin
      x_idx <= 0;
      y_idx <= 0;
    end
    else begin
      if(x_idx == (NUM_X-1)) begin
        if(y_idx == (NUM_Y-1))
          y_idx <= 0;
        else
          y_idx <= y_idx + 1;
        x_idx <= 0;
      end
      else
        x_idx <= x_idx + 1;
    end
  end

  /* dut */
  matrix
    dut (
      /* ctrl flow */
      .clk_i          (clk),
      .arstn_i        (arstn),

      /* indexes */
      .x_idx_i        (x_idx),
      .y_idx_i        (y_idx),
      .x_idx_o        (x_idx_int),
      .y_idx_o        (y_idx_int),

      /* output value */
      .matrix_value_o (matrix_value),
      .valid_o        (valid)
    );


endmodule

`default_nettype wire
