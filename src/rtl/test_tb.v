module test_tb();

  reg   clk_i;
  reg   arstn_i;
  wire  led_o;

  localparam SIM_CYCLES = 200032770;
  localparam CLK_TOGGLE = 10;
  localparam RST_CYCLES = 100;
  localparam CNT_WIDTH  = 16;
  localparam CLK_PERIOD = CLK_TOGGLE * 2;
  localparam CNT_TICKS  = (SIM_CYCLES - RST_CYCLES) / CLK_PERIOD;
  localparam CNT_TOGGLE = CNT_TICKS / (2*(2**CNT_WIDTH));

  reg led_edge;
  reg [31:0] cnt_toggle;

  initial begin
    clk_i = 0;
    arstn_i = 0;
    $display("Starting simulation...");
    $display(" -- simulation time : %16d", SIM_CYCLES);
    $display(" -- number of ticks : %16d", CNT_TICKS);
    $display(" -- count must be   : %16d", CNT_TOGGLE);
    $display(" -- max count       : %16d\n", (2**CNT_WIDTH));
    $monitor("[%t] rst = %b , led = %b , toggles = %d", $stime, arstn_i, led_o, cnt_toggle);
    `ifdef __VCD__
    $dumpfile("test_tb.vcd");
    $dumpvars();
    `endif
    #SIM_CYCLES;
    $display("\n[+] result count   = %16d", cnt_toggle);
    $display("[+] expected count = %16d", CNT_TOGGLE);
    $display("\nFinished simulation: %s\n", (cnt_toggle == CNT_TOGGLE) ? "PASSED" : "FAILED");
    $finish;
  end

  always #CLK_PERIOD clk_i   = ~clk_i;
  always #RST_CYCLES arstn_i = 1;

  always @ (led_o, arstn_i) begin
    if(~arstn_i) begin
      led_edge    = 0;
      cnt_toggle  = 0;
    end
    else if(led_edge != led_o) begin
      led_edge    = led_o;
      cnt_toggle  = cnt_toggle + 1;
    end
  end

  test
    # (
        .CNT_WIDTH (CNT_WIDTH)
      )
    dut (
        .clk_i    (clk_i),
        .arstn_i  (arstn_i),
        .led_o    (led_o)
      );

endmodule
