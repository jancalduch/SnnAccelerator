//------------------------------------------------------------------------------
//
// "encoder_buffer.sv" - Module that chooses the next value to send to the AER.
//
//------------------------------------------------------------------------------


module encoder_buffer #(
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

    input logic INFERENCE_RDY,
    
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
    CHOOSE_VALUE,
    SEND_AER,
    WAIT_AER
  } state_t;

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  state_t state, nextstate;  
  
  // Counters
  logic [IMAGE_SIZE_BITS-1:0] pixelID;
  logic [1:0] aer_reset_cnt;

  // Combinatorial wires
  logic [9:0] index;  // AER is 10 bits

  //----------------------------------------------------------------------------
	//	CONTROL FSM
	//----------------------------------------------------------------------------
    
  // State register
	always_ff @(posedge CLK, posedge RST) begin
		if   (RST) state <= IDLE;
		else       state <= nextstate;
	end
    
	// Next state logic
	always_comb begin
    case(state)
			IDLE:	
        if (NEW_IMAGE)                                    nextstate = SEND_AER;
        else                                              nextstate = IDLE;
    
      CHOOSE_VALUE: 
        if (INFERENCE_RDY || (pixelID == IMAGE_SIZE))     nextstate = IDLE;
        else                                              nextstate = SEND_AER;
  
      SEND_AER:                                           nextstate = WAIT_AER;
      
      WAIT_AER: 
        if (!AERIN_CTRL_BUSY)
          if (aer_reset_cnt < 2)                          nextstate = SEND_AER;
          else
            if (INFERENCE_RDY || (pixelID == IMAGE_SIZE)) nextstate = IDLE; 
            else                                          nextstate = CHOOSE_VALUE;              
        else                                              nextstate = WAIT_AER;
      default:    							                          nextstate = IDLE;
		endcase
  end

  //----------------------------------------------------------------------------
	//	COUNTERS
	//----------------------------------------------------------------------------

  // Counter up for pixelID
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                                                                          
      pixelID <= 0;
    else if (state == IDLE) 
      pixelID <= 0;
    else if (!AERIN_CTRL_BUSY && state == CHOOSE_VALUE)                                
      pixelID <= (pixelID == IMAGE_SIZE) ? pixelID : pixelID + 1;
    else                                                                              
      pixelID <= pixelID;
  end

  // Counter up for aer rst sequence
  always_ff @(posedge CLK, posedge RST)
    if      (RST)                   aer_reset_cnt <= 0;
    else if (state == IDLE)         aer_reset_cnt <= 0;
    else if (state == SEND_AER)     aer_reset_cnt <= (aer_reset_cnt == 3) ? aer_reset_cnt: aer_reset_cnt + 1;
    else                            aer_reset_cnt <= aer_reset_cnt;
 
  //----------------------------------------------------------------------------
	//	COMBINATORIAL LOGIC
	//----------------------------------------------------------------------------
  
  //----------------------------------------------------------------------------
	//	REGISTERS
	//----------------------------------------------------------------------------  
  // Output value
  always_ff @(posedge CLK, posedge RST) begin
    if      (RST)                                   index <= 10'b0;
    else if ((state == IDLE) || aer_reset_cnt < 2)  index <= {1'b0,1'b1,8'hFF};
    else if (state == CHOOSE_VALUE)                 index <= {2'b0,IMAGE[pixelID]};
    else                                            index <= index;
  end
  //----------------------------------------------------------------------------
	//	OUTPUT
	//----------------------------------------------------------------------------
  assign FOUND_NEXT_INDEX = (state == CHOOSE_VALUE) || (state == SEND_AER);
  assign NEXT_INDEX = index;
  assign ENCODER_RDY = (state == IDLE) ? 1'b1: 1'b0;

endmodule 