package pa_SnnAccelerator;

  // -- Common
  localparam int N            = 256;                    // Maximum number of neurons
  localparam int M            = $clog2(N);              // Bits to represent all neurons: log2(N)

  localparam int FIFO_DEPTH   = N/2;                    // Maximum number of FIFO positions (N/2 in this case)
  localparam int FIFO_ADDRESS = $clog2(N/2);            // Bits to represent all FIFO positions: log2(FIFO_DEPTH)
  localparam int FIFO_WIDTH   = 12;                     // Length of each of the data in the FIFO

  localparam int IMAGE_SIZE      = 256;                  // Size fo the image to infer
  localparam int IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE);
  localparam int PIXEL_MAX_VALUE = 255;                  // Maximum value fo each pixel
	localparam int PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE);

  localparam int AXI_DATA_WIDTH   = 32;       // Width of the AXI data buses
  localparam int AXI_ADDR_WIDTH   = 32;       // Width of the AXI address buses

endpackage

