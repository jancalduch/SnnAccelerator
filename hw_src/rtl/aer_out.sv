module aer_out #(
  parameter N = pa_SnnAccelerator::N,
  parameter M = pa_SnnAccelerator::M
)(

  // Global input -----------------------------------
  input  wire           CLK,
  input  wire           RST,

  // Data to send ---------------------------
  input logic [PIXEL_BITS-1:0] image [0:IMAGE_SIZE-1],

  // Output to sorter ---------------------------
  output logic            AEROUT_CTRL_BUSY,

  // Output 8-bit AER link --------------------------
  output reg  [  M-1:0] AERIN_ADDR,
  output reg            AERIN_REQ,
  input  wire           AERIN_ACK
  );


  reg            AERIN_ACK_sync_int, AERIN_ACK_sync, AERIN_ACK_sync_del;
  wire           AERIN_ACK_sync_negedge;

  logic CTRL_AEROUT_SEND;
  

  // Sync barrier
  always @(posedge CLK, posedge RST) begin
    if (RST) begin
      AERIN_ACK_sync_int <= 1'b0;
      AERIN_ACK_sync     <= 1'b0;
      AERIN_ACK_sync_del <= 1'b0;
    end
    else begin
      AERIN_ACK_sync_int <= AERIN_ACK;
      AERIN_ACK_sync     <= AERIN_ACK_sync_int;
      AERIN_ACK_sync_del <= AERIN_ACK_sync;
    end
  end
  
  assign AERIN_ACK_sync_negedge = ~AERIN_ACK_sync & AERIN_ACK_sync_del;

  // Output AER interface
  always @(posedge CLK, posedge RST) begin
    if (RST) begin
      AERIN_ADDR             <= 8'b0;
      AERIN_REQ              <= 1'b0;
      AEROUT_CTRL_BUSY       <= 1'b0;
    end else begin
      if ((CTRL_AEROUT_SEND) && ~AERIN_ACK_sync) begin
        AERIN_ADDR        <= image[ctrl_cnt];
        AERIN_REQ         <= 1'b1;
        AEROUT_CTRL_BUSY  <= 1'b1;
      end else if (AERIN_ACK_sync) begin
        AERIN_REQ         <= 1'b0;
        AEROUT_CTRL_BUSY  <= 1'b1;
      end else if (AERIN_ACK_sync_negedge) begin
        AERIN_REQ         <= 1'b0;
        AEROUT_CTRL_BUSY  <= 1'b0;
      end
    end
  end


  always @(posedge CLK, posedge RST)
    if      (RST)               ctrl_cnt <= 32'd0;
    else if (!AEROUT_CTRL_BUSY) ctrl_cnt <= ctrl_cnt + 32'd1;
    else                        ctrl_cnt <= ctrl_cnt;

endmodule
