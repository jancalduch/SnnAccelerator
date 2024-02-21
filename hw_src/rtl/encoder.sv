module encoder #(
	parameter IMAGE_SIZE      = 5,
  parameter IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter PIXEL_MAX_VALUE = 10,
	parameter PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(
    // Global inputs ----------------------------------
    input  logic           CLK,
    input  logic           RST,

    // Input image
    input logic [PIXEL_BITS:0] IMAGE [0:IMAGE_SIZE-1],
    input logic NEW_IMAGE,
       
    // Image sorted
    output logic IMAGE_ENCODED,

    // Output 8-bit AER -------------------------------
    output wire [IMAGE_SIZE_BITS:0] AEROUT_ADDR,
    output wire 	        AEROUT_REQ,
    input  wire 	        AEROUT_ACK
);
    
  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  logic AEROUT_CTRL_BUSY;

  logic [IMAGE_SIZE_BITS:0] NEXT_INDEX;
  logic FOUND_NEXT_INDEX;

  //----------------------------------------------------------------------------
  //	MODULE INSTANTIATION
  //----------------------------------------------------------------------------
  
  // Sorter
  sorter3 #(
    IMAGE_SIZE,
    IMAGE_SIZE_BITS,
    PIXEL_MAX_VALUE,
    PIXEL_BITS
  ) u_sorter (
    // Global input
    .CLK              ( CLK               ),
    .RST              ( RST               ),

    // Input image 
    .IMAGE            ( IMAGE             ),
    .NEW_IMAGE        ( NEW_IMAGE         ),

    // From AER
    .AEROUT_CTRL_BUSY ( AEROUT_CTRL_BUSY  ),

    // Next index sorted
    .NEXT_INDEX       ( NEXT_INDEX        ),
    .FOUND_NEXT_INDEX ( FOUND_NEXT_INDEX  ),

    // Image sorted
    .IMAGE_ENCODED    ( IMAGE_ENCODED     )
  );

  // Output AER
  aer_out_enc #(
    IMAGE_SIZE,
    IMAGE_SIZE_BITS,
    PIXEL_MAX_VALUE,
    PIXEL_BITS
  ) aer_out_enc_0 (

    // Global input ----------------------------------- 
    .CLK(CLK),
    .RST(RST),
    
    // Pixel ID data input -----------------------------
    .NEXT_INDEX(NEXT_INDEX),
    
    // Input from sorter --------------------------
    .FOUND_NEXT_INDEX(FOUND_NEXT_INDEX),
    
    // Output to sorter ---------------------------
    .AEROUT_CTRL_BUSY(AEROUT_CTRL_BUSY),
    
    // Output 8-bit AER link --------------------------
    .AEROUT_ADDR(AEROUT_ADDR),
    .AEROUT_REQ(AEROUT_REQ),
    .AEROUT_ACK(AEROUT_ACK)
  );
  
endmodule 