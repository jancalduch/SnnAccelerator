//------------------------------------------------------------------------------
//
// "sorter.sv" - Module that outputs the indexes of pixel values based on the 
//              intensity of the input image. The brighter the pixel the earlier
//              it goes. 
//
//------------------------------------------------------------------------------


module sorter #(
	parameter IMAGE_SIZE      = 256,
  parameter IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter PIXEL_MAX_VALUE = 255,
	parameter PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(
    // Global inputs ----------------------------------
    input  logic           CLK,
    input  logic           RST,

    // Input image
    input logic [PIXEL_BITS:0] IMAGE [0:IMAGE_SIZE-1],
    input logic NEW_IMAGE,

    // From AER
    input logic AERIN_CTRL_BUSY,

    input logic INFERENCE_DONE,
    
    // Next index sorted
    output logic [IMAGE_SIZE_BITS+1:0] NEXT_INDEX,
    output logic FOUND_NEXT_INDEX,
    
    // Image sorted
    output logic IMAGE_ENCODED
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

  logic [IMAGE_SIZE_BITS:0] pixelID;
  logic [PIXEL_BITS:0] intensity;
  logic [IMAGE_SIZE_BITS:0] indices_sent;
  logic [1:0] aer_reset_cnt;

  logic [PIXEL_BITS:0] index;
  logic found_index;
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
        if (NEW_IMAGE)                                          nextstate = SEND_AER;
        else                                                    nextstate = IDLE;
		  SORT: 
        if (INFERENCE_DONE || (indices_sent == IMAGE_SIZE))     nextstate = IDLE;
        else if (match_found)                                   nextstate = SEND_AER;
        else                                                    nextstate = SORT; 
      SEND_AER:                                                 nextstate = WAIT_AER;
      WAIT_AER: 
        if (!AERIN_CTRL_BUSY)
          if (aer_reset_cnt < 2)                                nextstate = SEND_AER;
          else
            if (INFERENCE_DONE || (indices_sent == IMAGE_SIZE)) nextstate = IDLE; 
            else                                                nextstate = SORT;              
        else                                                    nextstate = WAIT_AER;
      default:    							                                nextstate = IDLE;
		endcase

  //----------------------------------------------------------------------------
	//	COUNTERS
	//----------------------------------------------------------------------------

  // Counter up for pixel_ID
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                                                pixelID <= 0;
    else if (state == IDLE  || ((pixelID == PIXEL_MAX_VALUE) && (state == SORT)))  pixelID <= 0;
    else if (!AERIN_CTRL_BUSY && (state == SORT))           pixelID <= pixelID + 1;
    else                                                    pixelID <= pixelID;
  end

  // Counter down for intensity
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                              intensity <= PIXEL_MAX_VALUE;
    else if (state == IDLE)               intensity <= PIXEL_MAX_VALUE;
    else if (pixelID == PIXEL_MAX_VALUE)  intensity <= (intensity == 0) ? intensity: intensity - 1;
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
    if      (RST)                           index <= 0;
    else if (aer_reset_cnt < 2)             index <= {1'b0,1'b1,8'hFF};
    else if (match_found)                   index <= pixelID;
    else                                    index <= index;

  //----------------------------------------------------------------------------
	//	OUTPUT
	//----------------------------------------------------------------------------
  assign FOUND_NEXT_INDEX = ((match_found && (state == SORT)) || (state == SEND_AER));
  assign NEXT_INDEX = index;
  assign IMAGE_ENCODED = (state == IDLE) ? 1'b1: 1'b0;

endmodule 
