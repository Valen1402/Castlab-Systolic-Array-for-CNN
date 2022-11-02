/////////////////////////////////////////////////////////////////////
//
// Title: conv_top.sv
// Author: Seongmin Hong
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module conv_top #(
  parameter IF_WIDTH     = 128,
  parameter IF_HEIGHT    = 128,
  parameter IF_CHANNEL   = 3,
  parameter IF_BITWIDTH  = 16,
  parameter IF_FRAC_BIT  = 8,
  parameter IF_PORT      = 27,

  parameter K_WIDTH      = 3,
  parameter K_HEIGHT     = 3,
  parameter K_CHANNEL    = 3,
  parameter K_BITWIDTH   = 8,
  parameter K_FRAC_BIT   = 6,
  parameter K_PORT       = 1,
  parameter K_NUM        = 3,

  parameter OF_WIDTH     = 128,
  parameter OF_HEIGHT    = 128,
  parameter OF_CHANNEL   = 3,
  parameter OF_BITWIDTH  = 16,
  parameter OF_FRAC_BIT  = 8,
  parameter OF_PORT      = 1,
  parameter OF_NUM       = 3
)
(
  input  logic                                             clk,
  input  logic                                             rst,

  input  logic                                             if_start,
  input  logic                                             k_prefetch,
  output logic                                             of_done,

  input  logic [IF_PORT-1:0][IF_BITWIDTH-1:0]              if_i_data,   // 27x16
  input  logic [IF_PORT-1:0]                               if_i_valid,  // 27
  input  logic [K_NUM-1:0][K_PORT-1:0][K_BITWIDTH-1:0]     k_i_data,    // 3 x1 x8
  input  logic [K_NUM-1:0][K_PORT-1:0]                     k_i_valid,   // 3 x1
  output logic [OF_NUM-1:0][OF_PORT-1:0][OF_BITWIDTH-1:0]  of_o_data,   // 3 x1 x16
  output logic [OF_NUM-1:0][OF_PORT-1:0]                   of_o_valid   // 3 x1
);

/////////////////////////////////////////////////////////////////////

localparam A_BITWIDTH  = IF_BITWIDTH;               // 16
localparam A_FRAC_BIT  = IF_FRAC_BIT;               // 8
localparam W_BITWIDTH  = K_BITWIDTH;                // 8
localparam W_FRAC_BIT  = K_FRAC_BIT;                // 6
localparam P_BITWIDTH  = A_BITWIDTH*2 + W_BITWIDTH; // 40 = 16*2 + 8
localparam P_FRAC_BIT  = A_FRAC_BIT + W_FRAC_BIT;   // 14

/////////////////////////////////////////////////////////////////////
logic [IF_PORT-1:0][IF_CHANNEL-1:0][A_BITWIDTH-1:0]        A_data; 
logic [IF_PORT-1:0][IF_CHANNEL-1:0]                        A_ready; //27x3
logic [IF_PORT-1:0][IF_CHANNEL-1:0][W_BITWIDTH-1:0]        W_data;
logic [IF_PORT-1:0][IF_CHANNEL-1:0]                        W_ready;
logic [IF_PORT-1:0][IF_CHANNEL-1:0][P_BITWIDTH-1:0]        P_data;
logic [P_BITWIDTH-1:0]                                     bias;

/////////////////////////////////////////////////////////////////////
//// col 1
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_0_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[0]), .A_ready(A_ready[0][0]), .A_in(if_i_data[0]), .A_out(A_data[0][0]),
          .W_en(k_i_valid[0][0]), .W_ready(W_ready[0][0]), .W_in(k_i_data[0][0]), .W_out(W_data[0][0]),
          .P_in(bias), .P_out(P_data[0][0]));
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_1_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[1]), .A_ready(A_ready[1][0]), .A_in(if_i_data[1]), .A_out(A_data[1][0]),
          .W_en(k_i_valid[0][0] & W_ready[0][0]), .W_ready(W_ready[1][0]), .W_in(W_data[0][0]), .W_out(W_data[1][0]),
          .P_in(P_data[0][0]), .P_out(P_data[1][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_2_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[2]), .A_ready(A_ready[2][0]), .A_in(if_i_data[2]), .A_out(A_data[2][0]),
          .W_en(k_i_valid[0][0] & W_ready[1][0]), .W_ready(W_ready[2][0]), .W_in(W_data[1][0]), .W_out(W_data[2][0]),
          .P_in(P_data[1][0]), .P_out(P_data[2][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_3_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[3]), .A_ready(A_ready[3][0]), .A_in(if_i_data[3]), .A_out(A_data[3][0]),
          .W_en(k_i_valid[0][0] & W_ready[2][0]), .W_ready(W_ready[3][0]), .W_in(W_data[2][0]), .W_out(W_data[3][0]),
          .P_in(P_data[2][0]), .P_out(P_data[3][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_4_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[4]), .A_ready(A_ready[4][0]), .A_in(if_i_data[4]), .A_out(A_data[4][0]),
          .W_en(k_i_valid[0][0] & W_ready[3][0]), .W_ready(W_ready[4][0]), .W_in(W_data[3][0]), .W_out(W_data[4][0]),
          .P_in(P_data[3][0]), .P_out(P_data[4][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_5_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[5]), .A_ready(A_ready[5][0]), .A_in(if_i_data[5]), .A_out(A_data[5][0]),
          .W_en(k_i_valid[0][0] & W_ready[4][0]), .W_ready(W_ready[5][0]), .W_in(W_data[4][0]), .W_out(W_data[5][0]),
          .P_in(P_data[4][0]), .P_out(P_data[5][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_6_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[6]), .A_ready(A_ready[6][0]), .A_in(if_i_data[6]), .A_out(A_data[6][0]),
          .W_en(k_i_valid[0][0] & W_ready[5][0]), .W_ready(W_ready[6][0]), .W_in(W_data[5][0]), .W_out(W_data[6][0]),
          .P_in(P_data[5][0]), .P_out(P_data[6][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_7_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[7]), .A_ready(A_ready[7][0]), .A_in(if_i_data[7]), .A_out(A_data[7][0]),
          .W_en(k_i_valid[0][0] & W_ready[6][0]), .W_ready(W_ready[7][0]), .W_in(W_data[6][0]), .W_out(W_data[7][0]),
          .P_in(P_data[6][0]), .P_out(P_data[7][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_8_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[8]), .A_ready(A_ready[8][0]), .A_in(if_i_data[8]), .A_out(A_data[8][0]),
          .W_en(k_i_valid[0][0] & W_ready[7][0]), .W_ready(W_ready[8][0]), .W_in(W_data[7][0]), .W_out(W_data[8][0]),
          .P_in(P_data[7][0]), .P_out(P_data[8][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_9_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[9]), .A_ready(A_ready[9][0]), .A_in(if_i_data[9]), .A_out(A_data[9][0]),
          .W_en(k_i_valid[0][0] & W_ready[8][0]), .W_ready(W_ready[9][0]), .W_in(W_data[8][0]), .W_out(W_data[9][0]),
          .P_in(P_data[8][0]), .P_out(P_data[9][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_10_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[10]), .A_ready(A_ready[10][0]), .A_in(if_i_data[10]), .A_out(A_data[10][0]),
          .W_en(k_i_valid[0][0] & W_ready[9][0]), .W_ready(W_ready[10][0]), .W_in(W_data[9][0]), .W_out(W_data[10][0]),
          .P_in(P_data[9][0]), .P_out(P_data[10][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_11_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[11]), .A_ready(A_ready[11][0]), .A_in(if_i_data[11]), .A_out(A_data[11][0]),
          .W_en(k_i_valid[0][0] & W_ready[10][0]), .W_ready(W_ready[11][0]), .W_in(W_data[10][0]), .W_out(W_data[11][0]),
          .P_in(P_data[10][0]), .P_out(P_data[11][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_12_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[12]), .A_ready(A_ready[12][0]), .A_in(if_i_data[12]), .A_out(A_data[12][0]),
          .W_en(k_i_valid[0][0] & W_ready[11][0]), .W_ready(W_ready[12][0]), .W_in(W_data[11][0]), .W_out(W_data[12][0]),
          .P_in(P_data[11][0]), .P_out(P_data[12][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_13_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[13]), .A_ready(A_ready[13][0]), .A_in(if_i_data[13]), .A_out(A_data[13][0]),
          .W_en(k_i_valid[0][0] & W_ready[12][0]), .W_ready(W_ready[13][0]), .W_in(W_data[12][0]), .W_out(W_data[13][0]),
          .P_in(P_data[12][0]), .P_out(P_data[13][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_14_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[14]), .A_ready(A_ready[14][0]), .A_in(if_i_data[14]), .A_out(A_data[14][0]),
          .W_en(k_i_valid[0][0] & W_ready[13][0]), .W_ready(W_ready[14][0]), .W_in(W_data[13][0]), .W_out(W_data[14][0]),
          .P_in(P_data[13][0]), .P_out(P_data[14][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_15_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[15]), .A_ready(A_ready[15][0]), .A_in(if_i_data[15]), .A_out(A_data[15][0]),
          .W_en(k_i_valid[0][0] & W_ready[14][0]), .W_ready(W_ready[15][0]), .W_in(W_data[14][0]), .W_out(W_data[15][0]),
          .P_in(P_data[14][0]), .P_out(P_data[15][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_16_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[16]), .A_ready(A_ready[16][0]), .A_in(if_i_data[16]), .A_out(A_data[16][0]),
          .W_en(k_i_valid[0][0] & W_ready[15][0]), .W_ready(W_ready[16][0]), .W_in(W_data[15][0]), .W_out(W_data[16][0]),
          .P_in(P_data[15][0]), .P_out(P_data[16][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_17_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[17]), .A_ready(A_ready[17][0]), .A_in(if_i_data[17]), .A_out(A_data[17][0]),
          .W_en(k_i_valid[0][0] & W_ready[16][0]), .W_ready(W_ready[17][0]), .W_in(W_data[16][0]), .W_out(W_data[17][0]),
          .P_in(P_data[16][0]), .P_out(P_data[17][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_18_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[18]), .A_ready(A_ready[18][0]), .A_in(if_i_data[18]), .A_out(A_data[18][0]),
          .W_en(k_i_valid[0][0] & W_ready[17][0]), .W_ready(W_ready[18][0]), .W_in(W_data[17][0]), .W_out(W_data[18][0]),
          .P_in(P_data[17][0]), .P_out(P_data[18][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_19_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[19]), .A_ready(A_ready[19][0]), .A_in(if_i_data[19]), .A_out(A_data[19][0]),
          .W_en(k_i_valid[0][0] & W_ready[18][0]), .W_ready(W_ready[19][0]), .W_in(W_data[18][0]), .W_out(W_data[19][0]),
          .P_in(P_data[18][0]), .P_out(P_data[19][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_20_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[20]), .A_ready(A_ready[20][0]), .A_in(if_i_data[20]), .A_out(A_data[20][0]),
          .W_en(k_i_valid[0][0] & W_ready[19][0]), .W_ready(W_ready[20][0]), .W_in(W_data[19][0]), .W_out(W_data[20][0]),
          .P_in(P_data[19][0]), .P_out(P_data[20][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_21_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[21]), .A_ready(A_ready[21][0]), .A_in(if_i_data[21]), .A_out(A_data[21][0]),
          .W_en(k_i_valid[0][0] & W_ready[20][0]), .W_ready(W_ready[21][0]), .W_in(W_data[20][0]), .W_out(W_data[21][0]),
          .P_in(P_data[20][0]), .P_out(P_data[21][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_22_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[22]), .A_ready(A_ready[22][0]), .A_in(if_i_data[22]), .A_out(A_data[22][0]),
          .W_en(k_i_valid[0][0] & W_ready[21][0]), .W_ready(W_ready[22][0]), .W_in(W_data[21][0]), .W_out(W_data[22][0]),
          .P_in(P_data[21][0]), .P_out(P_data[22][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_23_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[23]), .A_ready(A_ready[23][0]), .A_in(if_i_data[23]), .A_out(A_data[23][0]),
          .W_en(k_i_valid[0][0] & W_ready[22][0]), .W_ready(W_ready[23][0]), .W_in(W_data[22][0]), .W_out(W_data[23][0]),
          .P_in(P_data[22][0]), .P_out(P_data[23][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_24_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[24]), .A_ready(A_ready[24][0]), .A_in(if_i_data[24]), .A_out(A_data[24][0]),
          .W_en(k_i_valid[0][0] & W_ready[23][0]), .W_ready(W_ready[24][0]), .W_in(W_data[23][0]), .W_out(W_data[24][0]),
          .P_in(P_data[23][0]), .P_out(P_data[24][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_25_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[25]), .A_ready(A_ready[25][0]), .A_in(if_i_data[25]), .A_out(A_data[25][0]),
          .W_en(k_i_valid[0][0] & W_ready[24][0]), .W_ready(W_ready[25][0]), .W_in(W_data[24][0]), .W_out(W_data[25][0]),
          .P_in(P_data[24][0]), .P_out(P_data[25][0]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_26_0 ( .clk (clk), .rst(rst),
          .A_en(if_i_valid[26]), .A_ready(A_ready[26][0]), .A_in(if_i_data[26]), .A_out(A_data[26][0]),
          .W_en(k_i_valid[0][0] & W_ready[25][0]), .W_ready(W_ready[26][0]), .W_in(W_data[25][0]), .W_out(W_data[26][0]),
          .P_in(P_data[25][0]), .P_out(P_data[26][0]) );



//// col 2
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_0_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[0][0]), .A_ready(A_ready[0][1]), .A_in(A_data[0][0]), .A_out(A_data[0][1]),
          .W_en(k_i_valid[1][0]), .W_ready(W_ready[0][1]), .W_in(k_i_data[1][0]), .W_out(W_data[0][1]),
          .P_in(bias), .P_out(P_data[0][1]));
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_1_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[1][0]), .A_ready(A_ready[1][1]), .A_in(A_data[1][0]), .A_out(A_data[1][1]),
          .W_en(k_i_valid[1][0] & W_ready[0][1]), .W_ready(W_ready[1][1]), .W_in(W_data[0][1]), .W_out(W_data[1][1]),
          .P_in(P_data[0][1]), .P_out(P_data[1][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_2_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[2][0]), .A_ready(A_ready[2][1]), .A_in(A_data[2][0]), .A_out(A_data[2][1]),
          .W_en(k_i_valid[1][0] & W_ready[1][1]), .W_ready(W_ready[2][1]), .W_in(W_data[1][1]), .W_out(W_data[2][1]),
          .P_in(P_data[1][1]), .P_out(P_data[2][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_3_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[3][0]), .A_ready(A_ready[3][1]), .A_in(A_data[3][0]), .A_out(A_data[3][1]),
          .W_en(k_i_valid[1][0] & W_ready[2][1]), .W_ready(W_ready[3][1]), .W_in(W_data[2][1]), .W_out(W_data[3][1]),
          .P_in(P_data[2][1]), .P_out(P_data[3][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_4_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[4][0]), .A_ready(A_ready[4][1]), .A_in(A_data[4][0]), .A_out(A_data[4][1]),
          .W_en(k_i_valid[1][0] & W_ready[3][1]), .W_ready(W_ready[4][1]), .W_in(W_data[3][1]), .W_out(W_data[4][1]),
          .P_in(P_data[3][1]), .P_out(P_data[4][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_5_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[5][0]), .A_ready(A_ready[5][1]), .A_in(A_data[5][0]), .A_out(A_data[5][1]),
          .W_en(k_i_valid[1][0] & W_ready[4][1]), .W_ready(W_ready[5][1]), .W_in(W_data[4][1]), .W_out(W_data[5][1]),
          .P_in(P_data[4][1]), .P_out(P_data[5][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_6_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[6][0]), .A_ready(A_ready[6][1]), .A_in(A_data[6][0]), .A_out(A_data[6][1]),
          .W_en(k_i_valid[1][0] & W_ready[5][1]), .W_ready(W_ready[6][1]), .W_in(W_data[5][1]), .W_out(W_data[6][1]),
          .P_in(P_data[5][1]), .P_out(P_data[6][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_7_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[7][0]), .A_ready(A_ready[7][1]), .A_in(A_data[7][0]), .A_out(A_data[7][1]),
          .W_en(k_i_valid[1][0] & W_ready[6][1]), .W_ready(W_ready[7][1]), .W_in(W_data[6][1]), .W_out(W_data[7][1]),
          .P_in(P_data[6][1]), .P_out(P_data[7][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_8_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[8][0]), .A_ready(A_ready[8][1]), .A_in(A_data[8][0]), .A_out(A_data[8][1]),
          .W_en(k_i_valid[1][0] & W_ready[7][1]), .W_ready(W_ready[8][1]), .W_in(W_data[7][1]), .W_out(W_data[8][1]),
          .P_in(P_data[7][1]), .P_out(P_data[8][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_9_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[9][0]), .A_ready(A_ready[9][1]), .A_in(A_data[9][0]), .A_out(A_data[9][1]),
          .W_en(k_i_valid[1][0] & W_ready[8][1]), .W_ready(W_ready[9][1]), .W_in(W_data[8][1]), .W_out(W_data[9][1]),
          .P_in(P_data[8][1]), .P_out(P_data[9][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_10_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[10][0]), .A_ready(A_ready[10][1]), .A_in(A_data[10][0]), .A_out(A_data[10][1]),
          .W_en(k_i_valid[1][0] & W_ready[9][1]), .W_ready(W_ready[10][1]), .W_in(W_data[9][1]), .W_out(W_data[10][1]),
          .P_in(P_data[9][1]), .P_out(P_data[10][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_11_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[11][0]), .A_ready(A_ready[11][1]), .A_in(A_data[11][0]), .A_out(A_data[11][1]),
          .W_en(k_i_valid[1][0] & W_ready[10][1]), .W_ready(W_ready[11][1]), .W_in(W_data[10][1]), .W_out(W_data[11][1]),
          .P_in(P_data[10][1]), .P_out(P_data[11][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_12_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[12][0]), .A_ready(A_ready[12][1]), .A_in(A_data[12][0]), .A_out(A_data[12][1]),
          .W_en(k_i_valid[1][0] & W_ready[11][1]), .W_ready(W_ready[12][1]), .W_in(W_data[11][1]), .W_out(W_data[12][1]),
          .P_in(P_data[11][1]), .P_out(P_data[12][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_13_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[13][0]), .A_ready(A_ready[13][1]), .A_in(A_data[13][0]), .A_out(A_data[13][1]),
          .W_en(k_i_valid[1][0] & W_ready[12][1]), .W_ready(W_ready[13][1]), .W_in(W_data[12][1]), .W_out(W_data[13][1]),
          .P_in(P_data[12][1]), .P_out(P_data[13][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_14_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[14][0]), .A_ready(A_ready[14][1]), .A_in(A_data[14][0]), .A_out(A_data[14][1]),
          .W_en(k_i_valid[1][0] & W_ready[13][1]), .W_ready(W_ready[14][1]), .W_in(W_data[13][1]), .W_out(W_data[14][1]),
          .P_in(P_data[13][1]), .P_out(P_data[14][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_15_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[15][0]), .A_ready(A_ready[15][1]), .A_in(A_data[15][0]), .A_out(A_data[15][1]),
          .W_en(k_i_valid[1][0] & W_ready[14][1]), .W_ready(W_ready[15][1]), .W_in(W_data[14][1]), .W_out(W_data[15][1]),
          .P_in(P_data[14][1]), .P_out(P_data[15][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_16_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[16][0]), .A_ready(A_ready[16][1]), .A_in(A_data[16][0]), .A_out(A_data[16][1]),
          .W_en(k_i_valid[1][0] & W_ready[15][1]), .W_ready(W_ready[16][1]), .W_in(W_data[15][1]), .W_out(W_data[16][1]),
          .P_in(P_data[15][1]), .P_out(P_data[16][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_17_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[17][0]), .A_ready(A_ready[17][1]), .A_in(A_data[17][0]), .A_out(A_data[17][1]),
          .W_en(k_i_valid[1][0] & W_ready[16][1]), .W_ready(W_ready[17][1]), .W_in(W_data[16][1]), .W_out(W_data[17][1]),
          .P_in(P_data[16][1]), .P_out(P_data[17][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_18_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[18][0]), .A_ready(A_ready[18][1]), .A_in(A_data[18][0]), .A_out(A_data[18][1]),
          .W_en(k_i_valid[1][0] & W_ready[17][1]), .W_ready(W_ready[18][1]), .W_in(W_data[17][1]), .W_out(W_data[18][1]),
          .P_in(P_data[17][1]), .P_out(P_data[18][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_19_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[19][0]), .A_ready(A_ready[19][1]), .A_in(A_data[19][0]), .A_out(A_data[19][1]),
          .W_en(k_i_valid[1][0] & W_ready[18][1]), .W_ready(W_ready[19][1]), .W_in(W_data[18][1]), .W_out(W_data[19][1]),
          .P_in(P_data[18][1]), .P_out(P_data[19][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_20_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[20][0]), .A_ready(A_ready[20][1]), .A_in(A_data[20][0]), .A_out(A_data[20][1]),
          .W_en(k_i_valid[1][0] & W_ready[19][1]), .W_ready(W_ready[20][1]), .W_in(W_data[19][1]), .W_out(W_data[20][1]),
          .P_in(P_data[19][1]), .P_out(P_data[20][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_21_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[21][0]), .A_ready(A_ready[21][1]), .A_in(A_data[21][0]), .A_out(A_data[21][1]),
          .W_en(k_i_valid[1][0] & W_ready[20][1]), .W_ready(W_ready[21][1]), .W_in(W_data[20][1]), .W_out(W_data[21][1]),
          .P_in(P_data[20][1]), .P_out(P_data[21][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_22_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[22][0]), .A_ready(A_ready[22][1]), .A_in(A_data[22][0]), .A_out(A_data[22][1]),
          .W_en(k_i_valid[1][0] & W_ready[21][1]), .W_ready(W_ready[22][1]), .W_in(W_data[21][1]), .W_out(W_data[22][1]),
          .P_in(P_data[21][1]), .P_out(P_data[22][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_23_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[23][0]), .A_ready(A_ready[23][1]), .A_in(A_data[23][0]), .A_out(A_data[23][1]),
          .W_en(k_i_valid[1][0] & W_ready[22][1]), .W_ready(W_ready[23][1]), .W_in(W_data[22][1]), .W_out(W_data[23][1]),
          .P_in(P_data[22][1]), .P_out(P_data[23][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_24_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[24][0]), .A_ready(A_ready[24][1]), .A_in(A_data[24][0]), .A_out(A_data[24][1]),
          .W_en(k_i_valid[1][0] & W_ready[23][1]), .W_ready(W_ready[24][1]), .W_in(W_data[23][1]), .W_out(W_data[24][1]),
          .P_in(P_data[23][1]), .P_out(P_data[24][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_25_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[25][0]), .A_ready(A_ready[25][1]), .A_in(A_data[25][0]), .A_out(A_data[25][1]),
          .W_en(k_i_valid[1][0] & W_ready[24][1]), .W_ready(W_ready[25][1]), .W_in(W_data[24][1]), .W_out(W_data[25][1]),
          .P_in(P_data[24][1]), .P_out(P_data[25][1]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_26_1 ( .clk (clk), .rst(rst),
          .A_en(A_ready[26][0]), .A_ready(A_ready[26][1]), .A_in(A_data[26][0]), .A_out(A_data[26][1]),
          .W_en(k_i_valid[1][0] & W_ready[25][1]), .W_ready(W_ready[26][1]), .W_in(W_data[25][1]), .W_out(),
          .P_in(P_data[25][1]), .P_out(P_data[26][1]) );



//// col 3
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_0_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[0][1]), .A_ready(), .A_in(A_data[0][1]), .A_out(),
          .W_en(k_i_valid[2][0]), .W_ready(W_ready[0][2]), .W_in(k_i_data[2][0]), .W_out(W_data[0][2]),
          .P_in(bias), .P_out(P_data[0][2]));
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_1_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[1][1]), .A_ready(), .A_in(A_data[1][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[0][2]), .W_ready(W_ready[1][2]), .W_in(W_data[0][2]), .W_out(W_data[1][2]),
          .P_in(P_data[0][2]), .P_out(P_data[1][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_2_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[2][1]), .A_ready(), .A_in(A_data[2][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[1][2]), .W_ready(W_ready[2][2]), .W_in(W_data[1][2]), .W_out(W_data[2][2]),
          .P_in(P_data[1][2]), .P_out(P_data[2][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_3_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[3][1]), .A_ready(), .A_in(A_data[3][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[2][2]), .W_ready(W_ready[3][2]), .W_in(W_data[2][2]), .W_out(W_data[3][2]),
          .P_in(P_data[2][2]), .P_out(P_data[3][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_4_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[4][1]), .A_ready(), .A_in(A_data[4][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[3][2]), .W_ready(W_ready[4][2]), .W_in(W_data[3][2]), .W_out(W_data[4][2]),
          .P_in(P_data[3][2]), .P_out(P_data[4][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_5_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[5][1]), .A_ready(), .A_in(A_data[5][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[4][2]), .W_ready(W_ready[5][2]), .W_in(W_data[4][2]), .W_out(W_data[5][2]),
          .P_in(P_data[4][2]), .P_out(P_data[5][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_6_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[6][1]), .A_ready(), .A_in(A_data[6][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[5][2]), .W_ready(W_ready[6][2]), .W_in(W_data[5][2]), .W_out(W_data[6][2]),
          .P_in(P_data[5][2]), .P_out(P_data[6][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_7_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[7][1]), .A_ready(), .A_in(A_data[7][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[6][2]), .W_ready(W_ready[7][2]), .W_in(W_data[6][2]), .W_out(W_data[7][2]),
          .P_in(P_data[6][2]), .P_out(P_data[7][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_8_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[8][1]), .A_ready(), .A_in(A_data[8][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[7][2]), .W_ready(W_ready[8][2]), .W_in(W_data[7][2]), .W_out(W_data[8][2]),
          .P_in(P_data[7][2]), .P_out(P_data[8][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_9_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[9][1]), .A_ready(), .A_in(A_data[9][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[8][2]), .W_ready(W_ready[9][2]), .W_in(W_data[8][2]), .W_out(W_data[9][2]),
          .P_in(P_data[8][2]), .P_out(P_data[9][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_10_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[10][1]), .A_ready(), .A_in(A_data[10][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[9][2]), .W_ready(W_ready[10][2]), .W_in(W_data[9][2]), .W_out(W_data[10][2]),
          .P_in(P_data[9][2]), .P_out(P_data[10][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_11_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[11][1]), .A_ready(), .A_in(A_data[11][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[10][2]), .W_ready(W_ready[11][2]), .W_in(W_data[10][2]), .W_out(W_data[11][2]),
          .P_in(P_data[10][2]), .P_out(P_data[11][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_12_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[12][1]), .A_ready(), .A_in(A_data[12][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[11][2]), .W_ready(W_ready[12][2]), .W_in(W_data[11][2]), .W_out(W_data[12][2]),
          .P_in(P_data[11][2]), .P_out(P_data[12][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_13_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[13][1]), .A_ready(), .A_in(A_data[13][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[12][2]), .W_ready(W_ready[13][2]), .W_in(W_data[12][2]), .W_out(W_data[13][2]),
          .P_in(P_data[12][2]), .P_out(P_data[13][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_14_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[14][1]), .A_ready(), .A_in(A_data[14][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[13][2]), .W_ready(W_ready[14][2]), .W_in(W_data[13][2]), .W_out(W_data[14][2]),
          .P_in(P_data[13][2]), .P_out(P_data[14][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_15_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[15][1]), .A_ready(), .A_in(A_data[15][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[14][2]), .W_ready(W_ready[15][2]), .W_in(W_data[14][2]), .W_out(W_data[15][2]),
          .P_in(P_data[14][2]), .P_out(P_data[15][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_16_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[16][1]), .A_ready(), .A_in(A_data[16][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[15][2]), .W_ready(W_ready[16][2]), .W_in(W_data[15][2]), .W_out(W_data[16][2]),
          .P_in(P_data[15][2]), .P_out(P_data[16][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_17_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[17][1]), .A_ready(), .A_in(A_data[17][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[16][2]), .W_ready(W_ready[17][2]), .W_in(W_data[16][2]), .W_out(W_data[17][2]),
          .P_in(P_data[16][2]), .P_out(P_data[17][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_18_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[18][1]), .A_ready(), .A_in(A_data[18][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[17][2]), .W_ready(W_ready[18][2]), .W_in(W_data[17][2]), .W_out(W_data[18][2]),
          .P_in(P_data[17][2]), .P_out(P_data[18][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_19_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[19][1]), .A_ready(), .A_in(A_data[19][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[18][2]), .W_ready(W_ready[19][2]), .W_in(W_data[18][2]), .W_out(W_data[19][2]),
          .P_in(P_data[18][2]), .P_out(P_data[19][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_20_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[20][1]), .A_ready(), .A_in(A_data[20][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[19][2]), .W_ready(W_ready[20][2]), .W_in(W_data[19][2]), .W_out(W_data[20][2]),
          .P_in(P_data[19][2]), .P_out(P_data[20][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_21_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[21][1]), .A_ready(), .A_in(A_data[21][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[20][2]), .W_ready(W_ready[21][2]), .W_in(W_data[20][2]), .W_out(W_data[21][2]),
          .P_in(P_data[20][2]), .P_out(P_data[21][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_22_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[22][1]), .A_ready(), .A_in(A_data[22][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[21][2]), .W_ready(W_ready[22][2]), .W_in(W_data[21][2]), .W_out(W_data[22][2]),
          .P_in(P_data[21][2]), .P_out(P_data[22][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_23_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[23][1]), .A_ready(), .A_in(A_data[23][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[22][2]), .W_ready(W_ready[23][2]), .W_in(W_data[22][2]), .W_out(W_data[23][2]),
          .P_in(P_data[22][2]), .P_out(P_data[23][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_24_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[24][1]), .A_ready(), .A_in(A_data[24][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[23][2]), .W_ready(W_ready[24][2]), .W_in(W_data[23][2]), .W_out(W_data[24][2]),
          .P_in(P_data[23][2]), .P_out(P_data[24][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_25_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[25][1]), .A_ready(), .A_in(A_data[25][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[24][2]), .W_ready(W_ready[25][2]), .W_in(W_data[24][2]), .W_out(W_data[25][2]),
          .P_in(P_data[24][2]), .P_out(P_data[25][2]) );
mac #( .A_BITWIDTH (A_BITWIDTH), .W_BITWIDTH (W_BITWIDTH), .P_BITWIDTH (P_BITWIDTH))
mac_26_2 ( .clk (clk), .rst(rst),
          .A_en(A_ready[26][1]), .A_ready(A_ready[26][2]), .A_in(A_data[26][1]), .A_out(),
          .W_en(k_i_valid[2][0] & W_ready[25][2]), .W_ready(W_ready[26][2]), .W_in(W_data[25][2]), .W_out(W_data[26][2]),
          .P_in(P_data[25][2]), .P_out(P_data[26][2]) );

/////////////////////////////////////////////////////////////////////
int i, j;
logic prefetching;
logic convolving;

always_ff @( posedge clk ) begin

  if(rst) begin
    /*
    for (i=0; i< 27; i++) begin
      for(j=0; j< 3; j++) begin
        A_ready[i][j] <= 0;
        A_data[i][j]  <= 0;
        W_ready[i][j] <= 0;
        W_data[i][j]  <= 0;
        P_data[i][j]  <= 0;
      end
    end
    */
    bias              <= 0;
    of_done           <= 0;
    of_o_valid        <= {0,0,0};
    of_o_data         <= {0,0,0};
    prefetching       <= 0;
    convolving        <= 0;

  end else begin

    if(k_prefetch) begin
      prefetching     <= 1;

    end else if (if_start) begin
      convolving      <= 1;
      prefetching     <= 0;

    end else if (prefetching) begin

    end else if (convolving) begin
      if(A_ready[26][0]) begin
        of_o_valid[0] <= 1;
        of_o_data[0]  <= {P_data[26][0][P_BITWIDTH-1], P_data[26][0][P_BITWIDTH-20:6]};
      end else
        of_o_valid[0] <= 0;

      if(A_ready[26][1]) begin
        of_o_valid[1] <= 1;
        of_o_data[1]  <= {P_data[26][1][P_BITWIDTH-1], P_data[26][1][P_BITWIDTH-20:6]};
      end else
        of_o_valid[1] <= 0;

      if(A_ready[26][2]) begin
        of_o_valid[2] <= 1;
        of_o_data[2]  <= {P_data[26][2][P_BITWIDTH-1], P_data[26][2][P_BITWIDTH-20:6]};
        if(~A_ready[26][1]) 
          of_done <= 1;
      end else
        of_o_valid[2] <= 0;
    end
  end 
    
  if (of_done) begin
    bias            <= 0;
    of_done         <= 0;
    convolving      <= 0;
    of_o_data       <= {0,0,0};
  end

end



endmodule