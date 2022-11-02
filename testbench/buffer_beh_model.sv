/////////////////////////////////////////////////////////////////////
//
// Title: buffer_beh_model
// Author: Seongmin Hong
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

interface buffer_beh_model  #(
  parameter WIDTH                       = 128,
  parameter HEIGHT                      = 128,
  parameter CHANNEL                     = 3  ,
  parameter BITWIDTH                    = 8  ,
  parameter PORT                        = 27 ,
  parameter FILE_NAME                   = "../../sources/dataset/input_feature.bmp"
)
(
  input  logic                          clk,
  input  logic                          rst,
  input  logic [PORT-1:0][BITWIDTH-1:0] i_data,
  input  logic [PORT-1:0]               i_valid,
  output logic [PORT-1:0][BITWIDTH-1:0] o_data,
  output logic [PORT-1:0]               o_valid
);

localparam WIDTH_PAD = (WIDTH%4 != 0)? WIDTH + (4-WIDTH%4) : WIDTH; // Padding

integer i, j;
integer x, y, c;
integer fd;
integer code;
integer bmp_width, bmp_height, bmp_bitdepth;

logic [7:0] bmp_header [0:53];
logic [7:0] pixel_data [0:(WIDTH+3)*(HEIGHT+3)*CHANNEL]; // 3: padding margin
logic [7:0] dummy_data [0:1023]; 
logic [HEIGHT-1:0][WIDTH-1:0][CHANNEL-1:0][7:0] data_array;
logic [HEIGHT*WIDTH*CHANNEL-1:0][7:0] data_list;
logic [WIDTH*HEIGHT-1:0][PORT-1:0][7:0] patch; // im2col

integer width, height;

integer err_cnt;
logic err;
logic [7:0] golden_data;
logic [BITWIDTH-1:0] i_data_t;
logic [BITWIDTH-1:0] i_data_relu;
logic [7:0] i_data_truc;

/////////////////////////////////////////////////////////////////////

task automatic init ();
begin
  o_data  = 0;
  o_valid = 0;
end
endtask

/////////////////////////////////////////////////////////////////////

task automatic mem_load ();
begin

  fd = $fopen(FILE_NAME, "rb");
  if (!fd) begin
    $display("File Open Error");
  end
  $display("File Open Successful: %s", FILE_NAME);

  code=$fread(bmp_header, fd);
  bmp_width = {bmp_header[21],bmp_header[20],bmp_header[19],bmp_header[18]};
  bmp_height = {bmp_header[25],bmp_header[24],bmp_header[23],bmp_header[22]};
  bmp_bitdepth = {bmp_header[29],bmp_header[28]};

  $display("bmp_width: %0d, bmp_height: %0d, bmp_bitdepth: %0d", bmp_width, bmp_height, bmp_bitdepth);

  if (bmp_width != WIDTH || bmp_height != HEIGHT || bmp_bitdepth != CHANNEL*8) begin
    $display("Image Size Error"); 
  end

  if (bmp_bitdepth == 8) begin
    code=$fread(dummy_data, fd);
  end

  code=$fread(pixel_data, fd);

  for (y=0 ; y<HEIGHT ; y=y+1) begin // y-filp
    for (x=0 ; x<WIDTH ; x=x+1) begin
      for (c=0 ; c<CHANNEL ; c=c+1) begin
        data_array[(HEIGHT-1)-y][x][c] = pixel_data[CHANNEL*(WIDTH_PAD*y+x)+c]; 
      end
    end
  end

  $fclose(fd);

end
endtask

/////////////////////////////////////////////////////////////////////

task automatic if_start ();
begin

  $display("Input Feature Start");

  // im2col
  for (y=0 ; y<HEIGHT ; y=y+1) begin
    for (x=0 ; x<WIDTH ; x=x+1) begin
      for (c=0 ; c<CHANNEL ; c=c+1) begin // 0:R, 1:G, 2:B
        patch[WIDTH*y+x][9*c+0] = (y==0 || x==0      )? 0 : data_array[y-1][x-1][c];
        patch[WIDTH*y+x][9*c+1] = (y==0              )? 0 : data_array[y-1][x  ][c];
        patch[WIDTH*y+x][9*c+2] = (y==0 || x==WIDTH-1)? 0 : data_array[y-1][x+1][c];

        patch[WIDTH*y+x][9*c+3] = (x==0       )? 0 : data_array[y  ][x-1][c];
        patch[WIDTH*y+x][9*c+4] =                    data_array[y  ][x  ][c];
        patch[WIDTH*y+x][9*c+5] = (x==WIDTH-1 )? 0 : data_array[y  ][x+1][c];

        patch[WIDTH*y+x][9*c+6] = (y==HEIGHT-1 || x==0      )? 0 : data_array[y+1][x-1][c];
        patch[WIDTH*y+x][9*c+7] = (y==HEIGHT-1              )? 0 : data_array[y+1][x  ][c];
        patch[WIDTH*y+x][9*c+8] = (y==HEIGHT-1 || x==WIDTH-1)? 0 : data_array[y+1][x+1][c];
      end
    end
  end

  @(posedge clk);
  #1;
  o_data  = 0;
  o_valid = 0;

  // data out
  for (i=0 ; i<WIDTH*HEIGHT+PORT ; i=i+1) begin
    @(posedge clk);
    #1;
    for (j=0 ; j<PORT ; j=j+1) begin // data align
      if (BITWIDTH >= 8) begin
        o_data[j]  = (i-j<0 || i-j>=WIDTH*HEIGHT)? 0 : {{BITWIDTH-8{1'b0}}, patch[i-j][j]}; // zero padding
        o_valid[j] = (i-j<0 || i-j>=WIDTH*HEIGHT)? 0 : 1;
      end
      else begin
        o_data[j]  = (i-j<0 || i-j>=WIDTH*HEIGHT)? 0 : patch[i-j][j][7-:BITWIDTH]; // truncated
        o_valid[j] = (i-j<0 || i-j>=WIDTH*HEIGHT)? 0 : 1;
      end
    end
  end

  @(posedge clk);
  #1;
  o_data  = 0;
  o_valid = 0;

end
endtask

/////////////////////////////////////////////////////////////////////

task automatic k_prefetch ();
begin

  $display("Prefetch Start");

  // reshape to list
  for (c=0 ; c<CHANNEL ; c=c+1) begin // 0:R, 1:G, 2:B
    for (y=0 ; y<HEIGHT ; y=y+1) begin
      for (x=0 ; x<WIDTH ; x=x+1) begin
        data_list[(HEIGHT*WIDTH*c)+(WIDTH*y)+x] = data_array[y][x][c];
      end
    end
  end

  @(posedge clk);
  #1;
  o_data  = 0;
  o_valid = 0;

  // data out
  for (i=0 ; i<HEIGHT*WIDTH*CHANNEL ; i=i+1) begin
    @(posedge clk);
    #1;
    o_data  = data_list[HEIGHT*WIDTH*CHANNEL-1-i]; // x-flip
    o_valid = 1;
  end

  @(posedge clk);
  #1;
  o_data  = 0;
  o_valid = 0;

end
endtask

/////////////////////////////////////////////////////////////////////

task automatic of_err_check();
begin

  err_cnt = 0;
  err = 0;

  $display("Error Check Start");

  for (y=0 ; y<HEIGHT ; y=y+1) begin
    for (x=0 ; x<WIDTH ; x=x+1) begin
      for (c=0 ; c<CHANNEL ; c=c+1) begin 
        @(posedge clk);
        #1; 

        err = 0;
        wait(i_valid);
        #1;
       
        i_data_t    = i_data; 
        i_data_relu = (i_data_t[BITWIDTH-1]==1)? 0 : i_data_t;
        i_data_truc = (i_data_relu[BITWIDTH-1 -: BITWIDTH-8]!=0)? {8{1'b1}} : i_data_relu[7:0];

        golden_data = data_array[y][x][c];

        if(i_data_truc != golden_data)begin // Error
          err_cnt = err_cnt +1;
          err = 1;
          $display("Error Count: %0d", err_cnt);
          //$display("Error Count: %0d, %b # %b, i_data_t = %b", err_cnt, i_data_truc, golden_data, i_data_t);

        end
        #1;

      end
    end
  end
  
  $display("Error Count Result: %0d", err_cnt);

  if (err_cnt==0) 
    $display("Successfully Completed");

end
endtask

endinterface
