module aer_out_enc #(
	parameter IMAGE_SIZE      = 5,
  parameter IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter PIXEL_MAX_VALUE = 10,
	parameter PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(

  // Global input ----------------------------------- 
  input  wire           CLK,
  input  wire           RST,
    
  // Pixel ID data input -----------------------------
  input  wire [  IMAGE_SIZE_BITS:0] NEXT_INDEX,

  // Input from sorter --------------------------
  input  wire           FOUND_NEXT_INDEX,
  
  // Output to sorter ---------------------------
  output reg            AEROUT_CTRL_BUSY,
    
	// Output 8-bit AER link --------------------------
	output reg  [  IMAGE_SIZE_BITS:0] AEROUT_ADDR, 
	output reg  	      AEROUT_REQ,
	input  wire 	      AEROUT_ACK
);

  reg            AEROUT_ACK_sync_int, AEROUT_ACK_sync, AEROUT_ACK_sync_del; 
  wire           AEROUT_ACK_sync_negedge;
  
  // Sync barrier
  always @(posedge CLK, posedge RST) begin
    if (RST) begin
      AEROUT_ACK_sync_int <= 1'b0;
      AEROUT_ACK_sync	    <= 1'b0;
      AEROUT_ACK_sync_del <= 1'b0;
    end
    else begin
      AEROUT_ACK_sync_int <= AEROUT_ACK;
      AEROUT_ACK_sync	    <= AEROUT_ACK_sync_int;
      AEROUT_ACK_sync_del <= AEROUT_ACK_sync;
    end
	end
  
  assign AEROUT_ACK_sync_negedge = ~AEROUT_ACK_sync & AEROUT_ACK_sync_del;
    
    
  // Output AER interface
  always @(posedge CLK, posedge RST) begin
    if (RST) begin
      AEROUT_ADDR             <= 8'b0;
      AEROUT_REQ              <= 1'b0;
      AEROUT_CTRL_BUSY        <= 1'b0;
    end else begin
      if (FOUND_NEXT_INDEX && ~AEROUT_ACK_sync) begin
        AEROUT_ADDR      <= NEXT_INDEX;
        AEROUT_REQ       <= 1'b1;
        AEROUT_CTRL_BUSY <= 1'b1;
      end else if (AEROUT_ACK_sync) begin
        AEROUT_REQ       <= 1'b0;
        AEROUT_CTRL_BUSY <= 1'b1;
      end else if (AEROUT_ACK_sync_negedge) begin
        AEROUT_REQ       <= 1'b0;
        AEROUT_CTRL_BUSY <= 1'b0;
      end
    end
	end


endmodule 
