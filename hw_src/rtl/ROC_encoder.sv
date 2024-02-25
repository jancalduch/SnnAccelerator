//------------------------------------------------------------------------------
//
// "ROC_encoder.sv" - Module that outputs the indexes of pixel values based on the 
//              intensity of the input image. The brighter the pixel the earlier
//              it goes. 
//
//------------------------------------------------------------------------------


module ROC_encoder #(
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

    // From AER
    input logic AERIN_CTRL_BUSY,

    input logic FIRST_INFERENCE_DONE,
    
    // Next index sorted (10-bit AER link)
    output logic [9:0] NEXT_INDEX,
    output logic FOUND_NEXT_INDEX,
    
    // Image sorted
    output logic ENCODER_RDY
);
  //----------------------------------------------------------------------------
	//	PARAMETERS 
	//----------------------------------------------------------------------------

	// FSM states 
  typedef enum logic [3:0] {
    IDLE,
    SORT,
    SEND_AER,
    WAIT_AER
  } state_t;

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  state_t state, nextstate;  

  logic [IMAGE_SIZE_BITS-1:0] pixelID;
  logic [PIXEL_BITS-1:0] intensity;
  logic [IMAGE_SIZE_BITS:0] indices_sent;
  logic [1:0] aer_reset_cnt;

  // AER is 10 bits
  logic [9:0] index;
  logic match_found;


  //----------------------------------------------------------------------------
	//	CONTROL FSM
	//----------------------------------------------------------------------------
    
  // State register
	always @(posedge CLK, posedge RST)
	begin
		if   (RST) state <= IDLE;
		else       state <= nextstate;
	end
    
	// Next state logic
	always @(*)
    case(state)
			IDLE:	
        if (NEW_IMAGE)                                                nextstate = SEND_AER;
        else                                                          nextstate = IDLE;
		  SORT: 
        if (FIRST_INFERENCE_DONE || (indices_sent == IMAGE_SIZE))     nextstate = IDLE;
        else if (match_found)                                         nextstate = SEND_AER;
        else                                                          nextstate = SORT; 
      SEND_AER:                                                       nextstate = WAIT_AER;
      WAIT_AER: 
        if (!AERIN_CTRL_BUSY)
          if (aer_reset_cnt < 2)                                      nextstate = SEND_AER;
          else
            if (FIRST_INFERENCE_DONE || (indices_sent == IMAGE_SIZE)) nextstate = IDLE; 
            else                                                      nextstate = SORT;              
        else                                                          nextstate = WAIT_AER;
      default:    							                                      nextstate = IDLE;
		endcase

  //----------------------------------------------------------------------------
	//	COUNTERS
	//----------------------------------------------------------------------------

  // Counter up for pixel_ID
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                                                                        pixelID <= 0;
    else if (state == IDLE  || ((pixelID == IMAGE_SIZE - 1) && (state == SORT)))    pixelID <= 0;
    else if (!AERIN_CTRL_BUSY && (state == SORT))                                   pixelID <= pixelID + 1;
    else                                                                            pixelID <= pixelID;
  end

  // Counter down for intensity
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                              intensity <= PIXEL_MAX_VALUE;
    else if (state == IDLE)               intensity <= PIXEL_MAX_VALUE;
    else if (pixelID == IMAGE_SIZE - 1)   intensity <= (intensity == 0) ? intensity: intensity - 1;
    else                                  intensity <= intensity;
  end

  // Counter up for aer rst sequence
  always_ff @(posedge CLK, posedge RST)
    if      (RST)                   aer_reset_cnt <= 0;
    else if (state == IDLE)         aer_reset_cnt <= 0;
    else if (state == SEND_AER)     aer_reset_cnt <= (aer_reset_cnt == 3) ? aer_reset_cnt: aer_reset_cnt + 1;
    else                            aer_reset_cnt <= aer_reset_cnt;

  // Counter up for sent values
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                                indices_sent <= 0;
    else if (state == IDLE)                 indices_sent <= 0;
    else if (match_found && state == SORT)  indices_sent <= indices_sent + 1;
    else                                    indices_sent <= indices_sent;   
  end
 
  //----------------------------------------------------------------------------
	//	COMPARATOR
	//----------------------------------------------------------------------------
  always_comb begin
    match_found = (IMAGE[pixelID] == intensity);
  end

  //----------------------------------------------------------------------------
	//	REGISTERS
	//----------------------------------------------------------------------------
  always_ff @(posedge CLK, posedge RST)
    if      (RST)                                   index <= 10'b0;
    else if ((state == IDLE) || aer_reset_cnt < 2)  index <= {1'b0,1'b1,8'hFF};
    else if (match_found)                           index <= {2'b0,pixelID};
    else                                            index <= index;

  //----------------------------------------------------------------------------
	//	OUTPUT
	//----------------------------------------------------------------------------
  assign FOUND_NEXT_INDEX = ((match_found && (state == SORT)) || (state == SEND_AER));
  assign NEXT_INDEX = index;
  assign ENCODER_RDY = (state == IDLE) ? 1'b1: 1'b0;

endmodule 
