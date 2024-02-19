//------------------------------------------------------------------------------
//
// "sorter.sv" - Module that outputs the indexes of pixel values based on the 
//              intensity of the input image. The brighter the pixel the earlier
//              it goes. 
//
//------------------------------------------------------------------------------


module sorter #(
	parameter IMAGE_SIZE      = 5,
  parameter IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter PIXEL_MAX_VALUE = 10,
	parameter PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(
    // Global inputs ----------------------------------
    input  logic           CLK,
    input  logic           RST,

    // Input image
    input logic [PIXEL_BITS:0] image [0:IMAGE_SIZE-1],
    input logic new_image,
    
    // Encoded image (sorted index in decreasing pixel value)
    output logic [PIXEL_BITS:0] sorted_indexes [0:IMAGE_SIZE-1],
    output logic done
);
    
  //----------------------------------------------------------------------------
	//	PARAMETERS 
	//----------------------------------------------------------------------------

	// FSM states 
  typedef enum logic [3:0] {
    IDLE,
    INNER_LOOP,
    STORE_INDEX,
    DECREMENT_INTENSITY
  } state_t;

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  state_t state;
  logic [PIXEL_BITS:0] intensity;
  logic [IMAGE_SIZE_BITS:0] sorted_index;
  logic [IMAGE_SIZE_BITS:0] pixelID;

  //----------------------------------------------------------------------------
  //	FSM
  //----------------------------------------------------------------------------

  always_ff @(posedge CLK, posedge RST) begin
    if (RST) begin
      state         <= IDLE;
      sorted_index  <= 0;
      intensity     <= PIXEL_MAX_VALUE;
      pixelID       <= 0;
      done          <= 0;
    end else begin
      case (state)
        
        IDLE: begin
          sorted_index  <= 0;
          intensity     <= PIXEL_MAX_VALUE;
          pixelID       <= 0;
          done          <= 0;
          if (new_image) begin
            state       <= INNER_LOOP;
          end
        end

        INNER_LOOP: begin
          if (pixelID < IMAGE_SIZE) begin
            if (image[pixelID] == intensity) begin
              state <= STORE_INDEX;
            end else begin
              pixelID <= pixelID + 1;
            end
          end else begin
            state <= DECREMENT_INTENSITY;
          end
        end

        STORE_INDEX: begin
          sorted_indexes[sorted_index] <= pixelID;
          sorted_index <= sorted_index + 1;
          if (sorted_index == IMAGE_SIZE - 1) begin
            done  <= 1;
            state <= IDLE;
          end else begin
            pixelID <= pixelID + 1;
            state <= INNER_LOOP;
          end
        end

        // OUTER LOOP
        DECREMENT_INTENSITY: begin
          intensity <= intensity - 1;
          pixelID <= 0;
          state <= INNER_LOOP;
        end

        default: state <= IDLE;

      endcase
    end
end

endmodule 
