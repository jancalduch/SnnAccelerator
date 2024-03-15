//------------------------------------------------------------------------------
//
// "ROC_encoder.sv" - Module that outputs the indexes of pixel values based on the 
//              intensity of the input image. The brighter the pixel the earlier
//              it goes. Implementing count sort algorithm.
//
//------------------------------------------------------------------------------


module ROC_encoder2 #(
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
    FREQUENCY,
    CUMULATIVE_SUM,
    SORT,
    CHOOSE_VALUE,
    SEND_AER,
    WAIT_AER
  } state_t;

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  state_t state, nextstate;  

  // Register to store the count of each intensity value
  logic [PIXEL_BITS-1:0] frequency [0:PIXEL_MAX_VALUE];
  // Sorted image
  logic [PIXEL_BITS-1:0] sorted_image [0:IMAGE_SIZE-1];
  
  // Counters
  logic [IMAGE_SIZE_BITS-1:0] pixelID;
  logic [PIXEL_BITS-1:0] intensity;
  logic [IMAGE_SIZE_BITS:0] indices_sent;
  logic [1:0] aer_reset_cnt;

  // Combinatorial wires
  logic [9:0] index;  // AER is 10 bits
  logic [PIXEL_BITS-1:0] pixel_value;

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
        if (NEW_IMAGE)                                            nextstate = SEND_AER;
        else                                                      nextstate = IDLE;
		  
      FREQUENCY: 
        if (pixelID == IMAGE_SIZE - 1)                            nextstate = CUMULATIVE_SUM;
        else                                                      nextstate = FREQUENCY;
      
      CUMULATIVE_SUM: 
        if (intensity == 0)                                       nextstate = SORT;
        else                                                      nextstate = CUMULATIVE_SUM;                        
     
      SORT: 
        if (pixelID == 0)                                         nextstate = CHOOSE_VALUE;
        else                                                      nextstate = SORT; 
    
      CHOOSE_VALUE: 
        if (FIRST_INFERENCE_DONE || (pixelID == IMAGE_SIZE - 1))  nextstate = IDLE;
        else                                                      nextstate = SEND_AER;
  
      SEND_AER:                                                   nextstate = WAIT_AER;
      
      WAIT_AER: 
        if (!AERIN_CTRL_BUSY)
          if (aer_reset_cnt < 2)                                  nextstate = SEND_AER;
          else if (aer_reset_cnt == 2)                            nextstate = FREQUENCY;
          else
            if (FIRST_INFERENCE_DONE || (pixelID == IMAGE_SIZE-1))  nextstate = IDLE; 
            else                                                  nextstate = CHOOSE_VALUE;              
        else                                                      nextstate = WAIT_AER;
      default:    							                                  nextstate = IDLE;
		endcase
  end

  //----------------------------------------------------------------------------
	//	COUNTERS
	//----------------------------------------------------------------------------

  // Counter up for pixel_ID
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                                                                          
      pixelID <= 0;
    else if (state == IDLE  || ((pixelID == IMAGE_SIZE - 1) && state == SORT)) 
      pixelID <= 0;
    else if (state == FREQUENCY || (!AERIN_CTRL_BUSY && state == CHOOSE_VALUE))                                
      pixelID <= (pixelID == IMAGE_SIZE - 1) ? pixelID : pixelID + 1;
    else if (state == SORT)                                
      pixelID <= pixelID - 1;
    else                                                                              
      pixelID <= pixelID;
  end

  // Counter down for intensity
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                              intensity <= PIXEL_MAX_VALUE;
    else if (state == IDLE)               intensity <= PIXEL_MAX_VALUE;
    else if (state == CUMULATIVE_SUM)     intensity <= (intensity == 0) ? intensity: intensity - 1;
    else                                  intensity <= intensity;
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
  // Mutiplexer
  always_comb begin
    pixel_value = IMAGE[pixelID];
  end
  //----------------------------------------------------------------------------
	//	REGISTERS
	//----------------------------------------------------------------------------
  // Output value
  always_ff @(posedge CLK, posedge RST)
    if      (RST)                                   index <= 10'b0;
    else if ((state == IDLE) || aer_reset_cnt < 2)  index <= {1'b0,1'b1,8'hFF};
    else if (state == CHOOSE_VALUE)                 index <= {2'b0,sorted_image[pixelID]};
    else                                            index <= index;

  
  // Register to store the count of each intensity value
  always_ff @(posedge CLK, posedge RST)
    if (RST || state == IDLE) begin
      foreach (frequency[i]) 
        frequency[i] <= 0;
    end else if (state == FREQUENCY)                           
      frequency[pixel_value] <= frequency[pixel_value] + 1;
    else if (state == CUMULATIVE_SUM)                           
      frequency[intensity] <= frequency[intensity] + frequency[intensity+1];
    else if (state == SORT)
      frequency[pixel_value] <= frequency[pixel_value] - 1;
    else 
      frequency <= frequency;

  // Register to store the sorted image
  always_ff @(posedge CLK, posedge RST)
    if (RST || state == IDLE) begin
      foreach (sorted_image[i]) 
        sorted_image[i] <= 0;
    end else if (state == SORT)                           
      sorted_image[frequency[pixel_value] - 1] <= pixelID;
    else 
      frequency <= frequency;

  //----------------------------------------------------------------------------
	//	OUTPUT
	//----------------------------------------------------------------------------
  assign FOUND_NEXT_INDEX = (state == CHOOSE_VALUE) || (state == SEND_AER);
  assign NEXT_INDEX = index;
  assign ENCODER_RDY = (state == IDLE) ? 1'b1: 1'b0;

endmodule 
