`timescale 1 ns / 1 ps

module tb_mac();

  parameter A_BITWIDTH   = 16;
  parameter W_BITWIDTH   = 8;
  parameter P_BITWIDTH   = 40;
  parameter CLK_FREQ     = 100;

  logic                                              clk;
  logic                                              rst;

  logic [2:0]                                             A_en;
  logic [2:0]                                             A_ready;
  logic [2:0] [A_BITWIDTH-1:0]                            A_in;
  logic [2:0] [A_BITWIDTH-1:0]                            A_out;

  logic                                              W_en;
  logic [2:0]                                             W_ready;
  logic [W_BITWIDTH-1:0]                            W_in;
  logic [2:0] [W_BITWIDTH-1:0]                            W_out;

  logic [2:0] [P_BITWIDTH-1:0]                            P_in;
  logic [2:0] [P_BITWIDTH-1:0]                            P_out;
  int i;


  initial begin
    clk = 0;
    forever begin
      clk = #((1000/CLK_FREQ)/2) ~clk;
    end
  end

  mac u_mac_0 (clk, rst, A_en[0], A_ready[0], A_in[0], A_out[0],
                  W_en, W_ready[0], W_in, W_out[0], P_in[0] , P_out[0]);
  mac u_mac_1 (clk, rst, A_en[1], A_ready[1], A_in[1], A_out[1],
                  (W_en & W_ready[0]), W_ready[1], W_out[0], W_out[1], P_out[0] , P_out[1]);
  mac u_mac_2 (clk, rst, A_en[2], A_ready[2], A_in[2], A_out[2],
                  (W_en & W_ready[1]), W_ready[2], W_out[1], W_out[2] , P_out[1] , P_out[2]);
  initial begin
    rst = 1;
    repeat(5) @(posedge clk);
    #1;
    rst = 0;
    #10
    //prefetch
    W_en <= 1;
    W_in <= {1'b0, 1'b1, 6'b111100};
    #10 W_in <= {1'b1, 1'b0, 6'b110010};
    #10 W_in <= {1'b1, 1'b1, 6'b111000};
    #10
    W_en <= 0;
    $display ("sign %b Wo[0]= %d, sign %b Wo[1]= %d, sign %b Wo[2]= %d ",
      W_out[0][7], W_out[0][6:0], W_out[1][7], W_out[1][6:0], W_out[2][7], W_out[2][6:0]);

    // convol
    #10
    A_en[0] <= 1;
    A_in[0] <= {1'b0, 7'b0001101, 8'b10111001};
    P_in[0] <= 0;
    #10;
    A_en[0] <= 0;
    A_en[1] <= 1;
    A_in[1] <= {1'b0, 7'b0000111, 8'b11100011};
    #10;
    A_en[1] <= 0;
    A_en[2] <= 1;
    A_in[2] <= {1'b0, 7'b0000111, 8'b11100111};
    #10;
    A_en[2] <= 0;
    #10;
    $display ("sign %b Ao[0] = %d, sign %b Ao[1] = %d, sign %b Ao[2] = %d",
      A_out[0][15], A_out[0][14:0], A_out[1][15], A_out[1][14:0], A_out[2][15], A_out[2][14:0]);
    $display ("sign %b Po[0] = %d, sign %b Po[1] = %d, sign %b Po[2] = %d",
      P_out[0][39], P_out[0][38:0], P_out[1][39], P_out[1][38:0], P_out[2][39], P_out[2][38:0]);
  end

endmodule