//------------------------------------------------------------------------------
//
// "sorter.sv" - Module that outputs the indexes of pixel values based on the 
//              intensity of the input image. The brighter the pixel the earlier
//              it goes. 
//
//------------------------------------------------------------------------------


module sorter3 #(
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

    // From AER
    input logic AEROUT_CTRL_BUSY,
    
    // Next index sorted
    output logic [IMAGE_SIZE_BITS:0] NEXT_INDEX,
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
    INNER_LOOP,
    DECREMENT_INTENSITY,
    INCREMENT_PIXEL_ID,
    INCREMENT_SORTED_INDEX,
    SEND_AER,
    COMPARE_SORTED_INDEX,
    WAIT_AER,
    DONE

  } state_t;

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  state_t state, nextstate;

  logic [PIXEL_BITS:0] intensity;
  logic [IMAGE_SIZE_BITS:0] sorted_index;
  logic [IMAGE_SIZE_BITS:0] pixelID;

  logic dec_intensity; 
  logic inc_pixel_id; 
  logic inc_sorted_index;

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
			IDLE                    :	if (NEW_IMAGE)                      nextstate = INNER_LOOP;
                                else                                nextstate = IDLE;
      INNER_LOOP              : if (pixelID < IMAGE_SIZE)
                                  if (IMAGE[pixelID] == intensity)  nextstate = SEND_AER;
                                  else                              nextstate = INCREMENT_PIXEL_ID;
                                else                                nextstate = DECREMENT_INTENSITY;
      DECREMENT_INTENSITY     :                                     nextstate = INNER_LOOP;
      INCREMENT_PIXEL_ID      :                                     nextstate = INNER_LOOP;
		  SEND_AER                :                                     nextstate = WAIT_AER;
      WAIT_AER                : if (!AEROUT_CTRL_BUSY)              nextstate = INCREMENT_SORTED_INDEX;
                                else                                nextstate = WAIT_AER;
      INCREMENT_SORTED_INDEX  :                                     nextstate = COMPARE_SORTED_INDEX;
      COMPARE_SORTED_INDEX    : if (sorted_index == IMAGE_SIZE)     nextstate = DONE;
                                else                                nextstate = INCREMENT_PIXEL_ID;
      DONE                    :                                     nextstate = IDLE;
      default                 :							                        nextstate = IDLE;
		endcase

  // Counters
  always_ff @(posedge CLK, posedge RST)
    if      (RST)               sorted_index <= 0;
    else if (state == IDLE)     sorted_index <= 0;
    else if (inc_sorted_index)  sorted_index <= sorted_index + 1;
    else                        sorted_index <= sorted_index;

  always_ff @(posedge CLK, posedge RST)
    if      (RST)           pixelID <= 0;
    else if (state == IDLE || state == DECREMENT_INTENSITY) pixelID <= 0;
    else if (inc_pixel_id)  pixelID <= pixelID + 1;
    else                    pixelID <= pixelID;

  always_ff @(posedge CLK, posedge RST)
    if      (RST)               intensity <= PIXEL_MAX_VALUE;
    else if (state == IDLE)     intensity <= PIXEL_MAX_VALUE;
    else if (dec_intensity)     intensity <= intensity - 1;
    else                        intensity <= intensity;
          
  // Output logic      
  always @(*) begin  
      
    if (state == IDLE) begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b0;
      
      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b0;
        
    end else if (state == INNER_LOOP) begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b0;

      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b0;
      
    end else if (state == DECREMENT_INTENSITY) begin
      dec_intensity     <= 1'b1; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b0;
      
      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b0;

    end else if (state == INCREMENT_PIXEL_ID) begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b1; 
      inc_sorted_index  <= 1'b0;

      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b0;

    end else if (state == INCREMENT_SORTED_INDEX) begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b1;

      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b0;

    end else if (state == WAIT_AER) begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b0;

      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b0;

    end else if (state == SEND_AER) begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b0;

      FOUND_NEXT_INDEX  <= 1'b1;
      IMAGE_ENCODED     <= 1'b0;

    end else if (state == COMPARE_SORTED_INDEX) begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b0;

      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b0;

    end else if (state == DONE) begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b0;

      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b1;

    end else begin
      dec_intensity     <= 1'b0; 
      inc_pixel_id      <= 1'b0; 
      inc_sorted_index  <= 1'b0;

      FOUND_NEXT_INDEX  <= 1'b0;
      IMAGE_ENCODED     <= 1'b0; 

    end
  end

  // Output
  always_ff @(posedge CLK, posedge RST)
    if      (RST)       NEXT_INDEX <= 0;
    else if (IMAGE[pixelID] == intensity)  NEXT_INDEX <= pixelID;

endmodule 
