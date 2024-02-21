//------------------------------------------------------------------------------
//
// "sorter.sv" - Module that outputs the indexes of pixel values based on the 
//              intensity of the input image. The brighter the pixel the earlier
//              it goes. 
//
//------------------------------------------------------------------------------


module sorter4 #(
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
    output logic [PIXEL_BITS:0] NEXT_INDEX,
    output logic FOUND_NEXT_INDEX,
    
    // Image sorted
    output logic IMAGE_ENCODED
);
    
  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  logic [IMAGE_SIZE_BITS:0] pixelID;
  logic [PIXEL_BITS:0] intensity;
  logic [IMAGE_SIZE_BITS:0] indices_sent;

  logic [PIXEL_BITS:0] index;
  logic found_index;
  logic match_found;

  //----------------------------------------------------------------------------
	//	COUNTERS
	//----------------------------------------------------------------------------

  // Counter up for pixel_ID
  always_ff @(posedge CLK or posedge RST)
    begin
      if (RST)
        pixelID <= 0;
      else 
        if (!AEROUT_CTRL_BUSY)
          pixelID <= (pixelID == IMAGE_SIZE - 1) ? 0 : pixelID + 1;
    end

  // Counter down for intensity
  always_ff @(posedge CLK or posedge RST)
    begin
      if (RST)
        intensity <= PIXEL_MAX_VALUE;
      else 
        if (pixelID == IMAGE_SIZE - 1)
          intensity <= (intensity == 0) ? PIXEL_MAX_VALUE : intensity - 1;
    end

  // Counter up for sent values
  always_ff @(posedge CLK or posedge RST)
    begin
      if (RST)
        indices_sent <= 0;
      else if (match_found)
        indices_sent <= (indices_sent == IMAGE_SIZE - 1) ? 8'b0 : indices_sent + 1;
    end
 
  //----------------------------------------------------------------------------
	//	COMPARATOR
	//----------------------------------------------------------------------------
  assign match_found = (IMAGE[pixelID] == intensity);

  //----------------------------------------------------------------------------
	//	REGISTERS
	//----------------------------------------------------------------------------
  always_ff @(posedge CLK or posedge RST)
    begin
      if (RST) begin
        index <= 0;
      end
      else if (found_index) begin
        index <= pixelID;
      end
    end

  always_ff @(posedge CLK or posedge RST)
    begin
      if (RST) begin
        found_index <= 0;
      end
      else begin
        if (IMAGE[pixelID] == intensity) begin
          found_index <= 1;
        end
        else begin
          found_index <= 0;
        end
      end
    end

  //----------------------------------------------------------------------------
	//	OUTPUT
	//----------------------------------------------------------------------------
  assign IMAGE_ENCODED = (indices_sent == IMAGE_SIZE) ? 1'b1: 1'b0;
  assign FOUND_NEXT_INDEX = found_index;
  assign NEXT_INDEX = index;

endmodule 
