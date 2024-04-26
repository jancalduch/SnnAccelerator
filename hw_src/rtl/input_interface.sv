module input_interface #(
	parameter IMAGE_SIZE      = 256,
  parameter IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter PIXEL_MAX_VALUE = 255,
	parameter PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(
    // Global inputs ----------------------------------
    input  logic           CLK,
    input  logic           RST,

    // Input image
    input logic [PIXEL_BITS-1:0] IMAGE [0:IMAGE_SIZE-1],
    input logic NEW_IMAGE,
       
    // Control signal
    input logic INFERENCE_RDY,
    
    // Image sorted
    output logic ENCODER_RDY,

    // Input 10-bit AER -------------------------------
    output wire [9:0]     AERIN_ADDR,
    output wire 	        AERIN_REQ,
    input  wire 	        AERIN_ACK
);
    
  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  logic AERIN_CTRL_BUSY;

  // 10-bit input AER link
  logic [9:0] NEXT_INDEX;
  logic FOUND_NEXT_INDEX;

  //----------------------------------------------------------------------------
  //	MODULE INSTANTIATION
  //----------------------------------------------------------------------------
  
  // encoder
  // encoder_buffer #(
  ROC_encoder #(
    IMAGE_SIZE,
    IMAGE_SIZE_BITS,
    PIXEL_MAX_VALUE,
    PIXEL_BITS
  ) u_encoder (
    // Global input
    .CLK                  ( CLK                   ),
    .RST                  ( RST                   ),

    // Input image 
    .IMAGE                ( IMAGE                 ),
    .NEW_IMAGE            ( NEW_IMAGE             ),

    .INFERENCE_RDY        ( INFERENCE_RDY         ),
    
    // From AER
    .AERIN_CTRL_BUSY      ( AERIN_CTRL_BUSY       ),

    // Next index sorted
    .NEXT_INDEX           ( NEXT_INDEX            ),
    .FOUND_NEXT_INDEX     ( FOUND_NEXT_INDEX      ),

    // Image sorted
    .ENCODER_RDY          ( ENCODER_RDY           )
  );

  // Input AER
  aer_in #(
    IMAGE_SIZE,
    IMAGE_SIZE_BITS,
    PIXEL_MAX_VALUE,
    PIXEL_BITS
  ) aer_in_0 (

    // Global input ----------------------------------- 
    .CLK              ( CLK               ),
    .RST              ( RST               ),
    
    // Pixel ID data input -----------------------------
    .NEXT_INDEX       ( NEXT_INDEX        ),
    
    // Input from sorter --------------------------
    .FOUND_NEXT_INDEX ( FOUND_NEXT_INDEX  ),
    
    // Output to sorter ---------------------------
    .AERIN_CTRL_BUSY  ( AERIN_CTRL_BUSY   ),
    
    // Intput 10-bit AER link --------------------------
    .AERIN_ADDR       ( AERIN_ADDR        ),
    .AERIN_REQ        ( AERIN_REQ         ),
    .AERIN_ACK        ( AERIN_ACK         )
  );
  
endmodule 
