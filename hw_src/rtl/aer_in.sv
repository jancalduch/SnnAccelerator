module aer_in #(
	parameter IMAGE_SIZE      = 256,
  parameter IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter PIXEL_MAX_VALUE = 255,
	parameter PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(

  // Global input ----------------------------------- 
  input  wire           CLK,
  input  wire           RST,
    
  // Pixel ID data input -----------------------------
  input  wire [  9:0]   NEXT_INDEX,

  // Input from sorter --------------------------
  input  wire           FOUND_NEXT_INDEX,
  
  // Output to sorter ---------------------------
  output reg            AERIN_CTRL_BUSY,
    
	// Input 10-bit AER link --------------------------
	output reg  [  9:0]   AERIN_ADDR, 
	output reg  	        AERIN_REQ,
	input  wire 	        AERIN_ACK
);

  reg            AERIN_ACK_sync_int, AERIN_ACK_sync, AERIN_ACK_sync_del; 
  wire           AERIN_ACK_sync_negedge;
  
  // Sync barrier
  always @(posedge CLK, posedge RST) begin
    if (RST) begin
      AERIN_ACK_sync_int <= 1'b0;
      AERIN_ACK_sync	    <= 1'b0;
      AERIN_ACK_sync_del <= 1'b0;
    end
    else begin
      AERIN_ACK_sync_int <= AERIN_ACK;
      AERIN_ACK_sync	    <= AERIN_ACK_sync_int;
      AERIN_ACK_sync_del <= AERIN_ACK_sync;
    end
	end
  
  assign AERIN_ACK_sync_negedge = ~AERIN_ACK_sync & AERIN_ACK_sync_del;
    
    
  // Input AER interface
  always @(posedge CLK, posedge RST) begin
    if (RST) begin
      AERIN_ADDR             <= 10'b0;
      AERIN_REQ              <= 1'b0;
      AERIN_CTRL_BUSY        <= 1'b0;
    end else begin
      if (FOUND_NEXT_INDEX && ~AERIN_ACK_sync) begin
        AERIN_ADDR      <= NEXT_INDEX;
        AERIN_REQ       <= 1'b1;
        AERIN_CTRL_BUSY <= 1'b1;
      end else if (AERIN_ACK_sync) begin
        AERIN_REQ       <= 1'b0;
        AERIN_CTRL_BUSY <= 1'b1;
      end else if (AERIN_ACK_sync_negedge) begin
        AERIN_REQ       <= 1'b0;
        AERIN_CTRL_BUSY <= 1'b0;
      end
    end
	end


endmodule 
