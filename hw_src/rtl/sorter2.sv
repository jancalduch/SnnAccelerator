//------------------------------------------------------------------------------
//
// "sorter.sv" - Module that outputs the indexes of pixel values based on the 
//              intensity of the input image. The brighter the pixel the earlier
//              it goes. 
//
//------------------------------------------------------------------------------


module sorter2 #(
	parameter IMAGE_SIZE      = 5,
  parameter IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter PIXEL_MAX_VALUE = 10,
	parameter PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(
    // Global inputs ----------------------------------
    input  logic           CLK,
    input  logic           RST,

    // Input image
    input logic [PIXEL_BITS-1:0] image [0:IMAGE_SIZE-1],
    input logic new_image,
    
    // Encoded image (sorted index in decreasing pixel value)
    output logic [PIXEL_BITS-1:0] sorted_indexes [0:IMAGE_SIZE-1],
    output logic done
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
    STORE_INDEX,
    COMPARE_SORTED_INDEX,
    DONE

  } state_t;

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  state_t state, nextstate;

  logic [PIXEL_BITS-1:0] intensity;
  logic [IMAGE_SIZE_BITS:0] sorted_index;
  logic [IMAGE_SIZE_BITS:0] pixelID;

  logic dec_intensity; 
  logic inc_pixel_id; 
  logic inc_sorted_index; 
  logic store_index;

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
			IDLE                    :	if (new_image)                      nextstate = INNER_LOOP;
                                else                                nextstate = IDLE;
      INNER_LOOP              : if (pixelID < IMAGE_SIZE)
                                  if (image[pixelID] == intensity)  nextstate = STORE_INDEX;
                                  else                              nextstate = INCREMENT_PIXEL_ID;
                                else                                nextstate = DECREMENT_INTENSITY;
      DECREMENT_INTENSITY     :                                     nextstate = INNER_LOOP;
      INCREMENT_PIXEL_ID      :                                     nextstate = INNER_LOOP;
		  STORE_INDEX             :                                     nextstate = INCREMENT_SORTED_INDEX;
      INCREMENT_SORTED_INDEX  :                                     nextstate = COMPARE_SORTED_INDEX;
      COMPARE_SORTED_INDEX    : if (sorted_index == IMAGE_SIZE)     nextstate = DONE;
                                else                                nextstate = INCREMENT_PIXEL_ID;
      DONE                    :                                     nextstate = IDLE;
      default                 :							                        nextstate = IDLE;
		endcase

  // Counters
  always @(posedge CLK, posedge RST)
    if      (RST)               sorted_index <= 0;
    else if (state == IDLE)     sorted_index <= 0;
    else if (inc_sorted_index)  sorted_index <= sorted_index + 1;
    else                        sorted_index <= sorted_index;

    always @(posedge CLK, posedge RST)
      if      (RST)           pixelID <= 0;
      else if (state == IDLE || state == DECREMENT_INTENSITY) pixelID <= 0;
      else if (inc_pixel_id)  pixelID <= pixelID + 1;
      else                    pixelID <= pixelID;

    always @(posedge CLK, posedge RST)
      if      (RST)               intensity <= PIXEL_MAX_VALUE - 1;
      else if (state == IDLE)     intensity <= PIXEL_MAX_VALUE - 1;
      else if (dec_intensity)     intensity <= intensity - 1;
      else                        intensity <= intensity;
          
  // Output logic      
  always @(*) begin  
      
    if (state == IDLE) begin
      dec_intensity     = 1'b0;
      inc_pixel_id      = 1'b0;
      inc_sorted_index  = 1'b0;
      store_index       = 1'b0;

      done              = 1'b0;
      sorted_indexes = sorted_indexes;
        
    end else if (state == INNER_LOOP) begin
      dec_intensity     = 1'b0;
      inc_pixel_id      = 1'b0;
      inc_sorted_index  = 1'b0;
      store_index       = 1'b0;

      done              = 1'b0;
      sorted_indexes = sorted_indexes;
      
    end else if (state == DECREMENT_INTENSITY) begin
      dec_intensity     = 1'b1;
      inc_pixel_id      = 1'b0;
      inc_sorted_index  = 1'b0;
      store_index       = 1'b0;

      done              = 1'b0;
      sorted_indexes = sorted_indexes;

    end else if (state == INCREMENT_PIXEL_ID) begin
      dec_intensity     = 1'b0;
      inc_pixel_id      = 1'b1;
      inc_sorted_index  = 1'b0;
      store_index       = 1'b0;

      done              = 1'b0;
      sorted_indexes = sorted_indexes;

    end else if (state == INCREMENT_SORTED_INDEX) begin
      dec_intensity     = 1'b0;
      inc_pixel_id      = 1'b0;
      inc_sorted_index  = 1'b1;
      store_index       = 1'b0;

      done              = 1'b0;
      sorted_indexes = sorted_indexes;

    end else if (state == STORE_INDEX) begin
      dec_intensity     = 1'b0;
      inc_pixel_id      = 1'b0;
      inc_sorted_index  = 1'b0;
      store_index       = 1'b1;

      done              = 1'b0;
      sorted_indexes[sorted_index] = pixelID;

    end else if (state == COMPARE_SORTED_INDEX) begin
      dec_intensity     = 1'b0;
      inc_pixel_id      = 1'b0;
      inc_sorted_index  = 1'b0;
      store_index       = 1'b0;

      done              = 1'b0;
      sorted_indexes = sorted_indexes;

    end else if (state == DONE) begin
      dec_intensity     = 1'b0;
      inc_pixel_id      = 1'b0;
      inc_sorted_index  = 1'b0;
      store_index       = 1'b0;

      done              = 1'b1;
      sorted_indexes = sorted_indexes;

    end else begin
      dec_intensity     = 1'b0;
      inc_pixel_id      = 1'b0;
      inc_sorted_index  = 1'b0;
      store_index       = 1'b0;

      done              = 1'b0;
      sorted_indexes = sorted_indexes;

    end
  end

  // Output

endmodule 
