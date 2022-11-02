/////////////////////////////////////////////////////////////////////
//
// Title: tb_conv_top.sv
// Author: Seongmin Hong
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

//`define DEBUG

module tb_conv_top ();

`ifdef DEBUG
parameter IF_WIDTH      = 4;
parameter IF_HEIGHT     = 4;
parameter OF_WIDTH      = 4;
parameter OF_HEIGHT     = 4;
parameter IF_FILE_NAME  = "/home/members/yi/quang/quang_lab3/conv_release/sources/dataset/debug_input_feature";
parameter K_FILE_NAME   = "/home/members/yi/quang/quang_lab3/conv_release/sources/dataset/debug_kernel";
parameter OF_FILE_NAME  = "/home/members/yi/quang/quang_lab3/conv_release/sources/dataset/debug_output_feature";
`else
parameter IF_WIDTH      = 128;
parameter IF_HEIGHT     = 128;
parameter OF_WIDTH      = 128;
parameter OF_HEIGHT     = 128;
parameter IF_FILE_NAME  = "/home/members/yi/quang/quang_lab3/conv_release/sources/dataset/input_feature";
parameter K_FILE_NAME   = "/home/members/yi/quang/quang_lab3/conv_release/sources/dataset/kernel";
parameter OF_FILE_NAME  = "/home/members/yi/quang/quang_lab3/conv_release/sources/dataset/output_feature";
`endif

parameter IF_CHANNEL    = 3;
parameter IF_BITWIDTH   = 16;
parameter IF_FRAC_BIT   = 8;
parameter IF_PORT       = 27;

parameter K_WIDTH       = 3;
parameter K_HEIGHT      = 3;
parameter K_CHANNEL     = 3;
parameter K_BITWIDTH    = 8;
parameter K_FRAC_BIT    = 6;
parameter K_PORT        = 1;
parameter K_NUM         = 3;

parameter OF_CHANNEL    = 1;
parameter OF_BITWIDTH   = 16;
parameter OF_FRAC_BIT   = 8;
parameter OF_PORT       = 1;
parameter OF_NUM        = 3;

parameter CLK_FREQ     = 100;

/////////////////////////////////////////////////////////////////////

logic clk;
logic rst;
logic if_start;
logic k_prefetch;
logic of_done;
logic [IF_PORT-1:0][IF_BITWIDTH-1:0]              if_i_data;
logic [IF_PORT-1:0]                               if_i_valid;
logic [K_NUM-1:0][K_PORT-1:0][K_BITWIDTH-1:0]     k_i_data;
logic [K_NUM-1:0][K_PORT-1:0]                     k_i_valid;
logic [OF_NUM-1:0][OF_PORT-1:0][OF_BITWIDTH-1:0]  of_o_data;
logic [OF_NUM-1:0][OF_PORT-1:0]                   of_o_valid;

/////////////////////////////////////////////////////////////////////

function [7:0] decimal_to_ascii (input [31:0] num_in);
  logic [7:0] num_1000, num_100, num_10, num_1;
  num_1000 = num_in / 1000;
  num_in   = num_in % 1000;

  num_100  = num_in / 100;
  num_in   = num_in % 100;

  num_10   = num_in / 10;
  num_1    = num_in % 10;

  num_1000 = "0" + num_1000;
  num_100  = "0" + num_100;
  num_10   = "0" + num_10;
  num_1    = "0" + num_1 ;

  // decimal_to_ascii = {num_1000, num_100, num_10, num_1};
  decimal_to_ascii = num_1;
endfunction

/////////////////////////////////////////////////////////////////////
// Clock

initial begin
  clk = 0;
  forever begin
    clk = #((1000/CLK_FREQ)/2) ~clk;
  end
end

/////////////////////////////////////////////////////////////////////
// Testbench Environment

localparam IF_FILE_NAME_BMP = {IF_FILE_NAME, ".bmp"};

buffer_beh_model #(
  .WIDTH     ( IF_WIDTH         ),
  .HEIGHT    ( IF_HEIGHT        ),
  .CHANNEL   ( IF_CHANNEL       ),
  .BITWIDTH  ( IF_BITWIDTH      ),
  .PORT      ( IF_PORT          ),
  .FILE_NAME ( IF_FILE_NAME_BMP )
) 
if_buffer_beh_model (
  .clk       ( clk              ),
  .rst       ( rst              ),
  .i_data    (                  ), // No Write
  .i_valid   (                  ), // No Write
  .o_data    ( if_i_data        ),
  .o_valid   ( if_i_valid       )
);

genvar i, j;
generate 
  for ( i=0 ; i<K_NUM ; i=i+1 ) begin : loop_k

    localparam K_FILE_NAME_BMP = {K_FILE_NAME, decimal_to_ascii(i), ".bmp"};

    buffer_beh_model #(
      .WIDTH     ( K_WIDTH         ),
      .HEIGHT    ( K_HEIGHT        ),
      .CHANNEL   ( K_CHANNEL       ),
      .BITWIDTH  ( K_BITWIDTH      ),
      .PORT      ( K_PORT          ),
      .FILE_NAME ( K_FILE_NAME_BMP )
    ) 
    k_buffer_beh_model (
      .clk       ( clk             ),
      .rst       ( rst             ),
      .i_data    (                 ), // No Write
      .i_valid   (                 ), // No Write
      .o_data    ( k_i_data  [i]   ),
      .o_valid   ( k_i_valid [i]   )
    );

  end
  for ( j=0 ; j<OF_NUM ; j=j+1 ) begin : loop_of

    localparam OF_FILE_NAME_BMP = {OF_FILE_NAME, decimal_to_ascii(j), ".bmp"};

    buffer_beh_model #(
      .WIDTH     ( OF_WIDTH         ),
      .HEIGHT    ( OF_HEIGHT        ),
      .CHANNEL   ( OF_CHANNEL       ),
      .BITWIDTH  ( OF_BITWIDTH      ),
      .PORT      ( OF_PORT          ),
      .FILE_NAME ( OF_FILE_NAME_BMP )
    ) 
    of_buffer_beh_model (
      .clk       ( clk              ),
      .rst       ( rst              ),
      .i_data    ( of_o_data  [j]   ), 
      .i_valid   ( of_o_valid [j]   ), 
      .o_data    (                  ), // No Read
      .o_valid   (                  )  // No Read
    );

  end
endgenerate

/////////////////////////////////////////////////////////////////////
// ********** User Logic **********

conv_top #(
  .IF_WIDTH     ( IF_WIDTH        ),
  .IF_HEIGHT    ( IF_HEIGHT       ),
  .IF_CHANNEL   ( IF_CHANNEL      ),
  .IF_BITWIDTH  ( IF_BITWIDTH     ),
  .IF_FRAC_BIT  ( IF_FRAC_BIT     ),
  .IF_PORT      ( IF_PORT         ),

  .K_WIDTH      ( K_WIDTH         ),
  .K_HEIGHT     ( K_HEIGHT        ),
  .K_CHANNEL    ( K_CHANNEL       ),
  .K_BITWIDTH   ( K_BITWIDTH      ),
  .K_FRAC_BIT   ( K_FRAC_BIT      ),
  .K_PORT       ( K_PORT          ),
  .K_NUM        ( K_NUM           ),
 
  .OF_WIDTH     ( OF_WIDTH        ),
  .OF_HEIGHT    ( OF_HEIGHT       ),
  .OF_CHANNEL   ( OF_CHANNEL      ),
  .OF_BITWIDTH  ( OF_BITWIDTH     ),
  .OF_FRAC_BIT  ( OF_FRAC_BIT     ),
  .OF_PORT      ( OF_PORT         ),
  .OF_NUM       ( OF_NUM          )
) 
u_conv_top (
  .clk          ( clk             ),
  .rst          ( rst             ),

  .if_start     ( if_start        ),
  .k_prefetch   ( k_prefetch      ),
  .of_done      ( of_done         ),

  .if_i_data    ( if_i_data       ), 
  .if_i_valid   ( if_i_valid      ), 
  .k_i_data     ( k_i_data        ),
  .k_i_valid    ( k_i_valid       ),
  .of_o_data    ( of_o_data       ),
  .of_o_valid   ( of_o_valid      )
);

/////////////////////////////////////////////////////////////////////

initial begin

  rst        = 1;
  if_start   = 0;
  k_prefetch = 0;

  repeat(10) @(posedge clk);
  #1;
  rst = 0;

  if_buffer_beh_model.init;
  loop_k[0].k_buffer_beh_model.init;
  loop_k[1].k_buffer_beh_model.init;
  loop_k[2].k_buffer_beh_model.init;

  if_buffer_beh_model.mem_load;
  loop_k[0].k_buffer_beh_model.mem_load;
  loop_k[1].k_buffer_beh_model.mem_load;
  loop_k[2].k_buffer_beh_model.mem_load;
 
  // --------------------------------------------
  // iteration 
  repeat(2) begin 
    
    if_start   = 0;
    k_prefetch = 0;

    // kernel prefetch
    @(posedge clk);
    #1;
    k_prefetch = 1;
    @(posedge clk);
    #1;
    k_prefetch = 0;

    fork 
      loop_k[0].k_buffer_beh_model.k_prefetch;
      loop_k[1].k_buffer_beh_model.k_prefetch;
      loop_k[2].k_buffer_beh_model.k_prefetch;
    join

    repeat(100) @(posedge clk);

    // input feature start
    @(posedge clk);
    #1;
    if_start = 1;
    @(posedge clk);
    #1;
    if_start = 0;

    if_buffer_beh_model.if_start;

    wait(of_done);
    #1000;

  end

  #1000;
  $stop;

end

initial begin

  repeat(10) @(posedge clk);

  loop_of[0].of_buffer_beh_model.mem_load;
  loop_of[1].of_buffer_beh_model.mem_load;
  loop_of[2].of_buffer_beh_model.mem_load;

  // --------------------------------------------
  // iteration 
  repeat(2) begin
  
    // output feature error check
    fork
      loop_of[0].of_buffer_beh_model.of_err_check;
      loop_of[1].of_buffer_beh_model.of_err_check;
      loop_of[2].of_buffer_beh_model.of_err_check;
    join

  end

end

/////////////////////////////////////////////////////////////////////
endmodule
