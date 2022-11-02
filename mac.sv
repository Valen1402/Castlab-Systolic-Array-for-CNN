`timescale 1 ns / 1 ps

module mac #(
  parameter A_BITWIDTH   = 16,
  parameter W_BITWIDTH   = 8,
  parameter P_BITWIDTH   = 40
)
(
  input  logic                                             clk,
  input  logic                                             rst,

  input  logic                                             A_en,
  output logic                                             A_ready,
  input  logic [A_BITWIDTH-1:0]                            A_in,
  output logic [A_BITWIDTH-1:0]                            A_out,

  input  logic                                             W_en,
  output logic                                             W_ready,
  input  logic [W_BITWIDTH-1:0]                            W_in,
  output logic [W_BITWIDTH-1:0]                            W_out,

  input  logic [P_BITWIDTH-1:0]                            P_in,
  output logic [P_BITWIDTH-1:0]                            P_out
);

  always_ff @( posedge clk ) begin
    if (rst) begin
      A_out       <= 0;
      A_ready     <= 0;
      W_out       <= 0;
      W_ready     <= 0;
      P_out       <= 0;
    end

    else begin
      if (W_en) begin
        W_out     <= W_in;
        W_ready   <= 1;
        //$display ("W_in = %d, W_out = %d", W_in, W_out);
      end else begin
        W_ready   <= 0;
      end 
      
      if (A_en) begin
        A_out     <= A_in;
        //$display ("A_in = %d, A_out = %d", A_in, A_out);
        A_ready   <= 1;
        if(W_out[W_BITWIDTH-1] == A_in[A_BITWIDTH-1])
          P_out     <= P_in + W_out * A_in;
        else if (W_out[W_BITWIDTH-1])
          P_out     <= (P_in + {40'hffffffffff, W_out} * A_in);
        else if (A_in[A_BITWIDTH-1])
          P_out     <= (P_in + {40'hffffffffff, A_in} * W_out);

          //$display ("Wout= %d, A_in = %d, Pout = %d", W_out, A_in, P_out);

      end else begin
        A_ready   <= 0;
        A_out     <= 0;
        P_out     <= 0;
      end

    end
  end

endmodule