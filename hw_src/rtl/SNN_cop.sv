module SNN_cop #(
  parameter N                   = pa_SnnAccelerator::N,
  parameter M                   = pa_SnnAccelerator::M,

  parameter int FIFO_DEPTH      = pa_SnnAccelerator::FIFO_DEPTH,
  parameter int FIFO_ADDRESS    = pa_SnnAccelerator::FIFO_ADDRESS,
  parameter int FIFO_WIDTH      = pa_SnnAccelerator::FIFO_WIDTH,

  parameter int IMAGE_SIZE      = pa_SnnAccelerator::IMAGE_SIZE,
  parameter int IMAGE_SIZE_BITS = pa_SnnAccelerator::IMAGE_SIZE_BITS,
  parameter int PIXEL_MAX_VALUE = pa_SnnAccelerator::PIXEL_MAX_VALUE,
  parameter int PIXEL_BITS      = pa_SnnAccelerator::PIXEL_BITS,

  parameter int AXI_DATA_WIDTH  = pa_SnnAccelerator::AXI_DATA_WIDTH,
  parameter int AXI_ADDR_WIDTH  = pa_SnnAccelerator::AXI_ADDR_WIDTH
  )(
    // Global input     --------------------------------------------------------
    input  wire           CLK,
    input  wire           RST,

    // SPI slave        --------------------------------------------------------
    input  wire           SCK,
    input  wire           MOSI,
    output wire           MISO,

    // Debug -------------------------------------------------------------------
    output wire           SCHED_FULL,

    // AXI Write ---------------------------------------------------------------
    input logic [AXI_ADDR_WIDTH-1:0]  AWADDR,       // Write address
    input logic [2:0]                 AWPROT,       // Write protection signals
    input logic                       AWVALID,      // Write address valid
    output logic                      AWREADY,      // Write address ready

    input logic [AXI_DATA_WIDTH-1:0]  WDATA,        // Write data
    input logic [3:0]                 WSTRB,        // Write byte strobes
    input logic                       WVALID,       // Write data valid
    output logic                      WREADY,       // Write data ready

    output logic [1:0]                BRESP,        // Write response
    output logic                      BVALID,       // Write response valid
    input logic                       BREADY,       // Write response ready

    // AXI Read ----------------------------------------------------------------
    input logic [AXI_ADDR_WIDTH-1:0]  ARADDR,       // Read address
    input logic [2:0]                 ARPROT,       // Read protection signals
    input logic                       ARVALID,      // Read address valid
    output logic                      ARREADY,      // Read address ready

    output logic [AXI_DATA_WIDTH-1:0] RDATA,        // Read data
    output logic [1:0]                RRESP,        // Read response
    output logic                      RVALID,       // Read data valid
    input logic                       RREADY,       // Read data ready

    // Interrupt to CPU --------------------------------------------------------
    output logic                      COPROCESSOR_RDY // Coprocessor finsihed and ready for new image
  );

  //----------------------------------------------------------------------------
  //  Internal logic
  //----------------------------------------------------------------------------

  // Output 8-bit AER
  logic [  M-1:0] AEROUT_ADDR;
  logic           AEROUT_REQ;
  logic           AEROUT_ACK;

  // Input 10-bit AER
  logic [M + 1:0] AERIN_ADDR;
  logic           AERIN_REQ;
  logic           AERIN_ACK;

  // READY signals
  logic           ENCODER_RDY;
  logic           DECODER_RDY;
  logic           INFERENCE_RDY; 

  // SNN input signals
  logic [PIXEL_BITS-1:0]  IMAGE [0:IMAGE_SIZE-1];
  logic                   NEW_IMAGE;

  // SNN output signals
  logic [ M-1:0]          INFERED_DIGIT;

  // --------------------------------
  // -- AXI Slave Interface
  // --------------------------------
  S_AXI4l_interface #(
    .N                    ( N                     ),
    .M                    ( M                     ),
    .AXI_DATA_WIDTH       ( AXI_DATA_WIDTH        ),
    .AXI_ADDR_WIDTH       ( AXI_ADDR_WIDTH        ),  
    .IMAGE_SIZE           ( IMAGE_SIZE            ),
    .IMAGE_SIZE_BITS      ( IMAGE_SIZE_BITS       ),
    .PIXEL_MAX_VALUE      ( PIXEL_MAX_VALUE       ),
    .PIXEL_BITS           ( PIXEL_BITS            )
  ) u_S_AXI4l_interface (
    .ACLK             (CLK),
    .ARESETN          (!RST),

    .AWADDR           (AWADDR),
    .AWPROT           (),
    .AWVALID          (AWVALID),
    .AWREADY          (AWREADY),

    .WDATA            (WDATA),
    .WSTRB            (WSTRB),
    .WVALID           (WVALID),
    .WREADY           (WREADY),

    .BRESP            (BRESP),
    .BVALID           (BVALID),
    .BREADY           (BREADY),

    .ARADDR           (ARADDR),
    .ARPROT           (),
    .ARVALID          (ARVALID),
    .ARREADY          (ARREADY),

    .RDATA            (RDATA),
    .RRESP            (RRESP),
    .RVALID           (RVALID),
    .RREADY           (RREADY),

    .INFERED_DIGIT    (INFERED_DIGIT),

    .IMAGE            (IMAGE),
    .NEW_IMAGE        (NEW_IMAGE)
  );


  // --------------------------------
  // -- tinyODIN
  // --------------------------------
    
  tinyODIN #(
    .N                (N),
    .M                (M),
    .FIFO_DEPTH       (FIFO_DEPTH),
    .FIFO_ADDRESS     (FIFO_ADDRESS),
    .FIFO_WIDTH       (FIFO_WIDTH)
    ) u_Core(
      .CLK            (CLK),
      .RST            (RST),

      // SPI slave        -------------------------------
      .SCK            (SCK),
      .MOSI           (MOSI),
      .MISO           (MISO),

      // Input 10-bit AER -------------------------------
      .AERIN_ADDR     (AERIN_ADDR),
      .AERIN_REQ      (AERIN_REQ),
      .AERIN_ACK      (AERIN_ACK),

      // Output 8-bit AER -------------------------------
      .AEROUT_ADDR    (AEROUT_ADDR),
      .AEROUT_REQ     (AEROUT_REQ),
      .AEROUT_ACK     (AEROUT_ACK),

      // Debug ------------------------------------------
      .SCHED_FULL     (SCHED_FULL)
  );

  // --------------------------------
  // -- Input interface
  // --------------------------------

  input_interface #(
    .IMAGE_SIZE           ( IMAGE_SIZE            ),
    .IMAGE_SIZE_BITS      ( IMAGE_SIZE_BITS       ),
    .PIXEL_MAX_VALUE      ( PIXEL_MAX_VALUE       ),
    .PIXEL_BITS           ( PIXEL_BITS            )
  ) u_input_interface (
    // Global input
    .CLK                  ( CLK                   ),
    .RST                  ( RST                   ),

    // Input image 
    .IMAGE                ( IMAGE                 ),
    .NEW_IMAGE            ( NEW_IMAGE             ),

    .INFERENCE_RDY        ( INFERENCE_RDY  ),

    // Image sorted
    .ENCODER_RDY          ( ENCODER_RDY           ),

    // AER link
    .AERIN_ADDR           ( AERIN_ADDR            ),
    .AERIN_REQ            ( AERIN_REQ             ),
    .AERIN_ACK            ( AERIN_ACK             )
  );

  // --------------------------------
  // -- Output interface
  // --------------------------------
  decoder #(
    .N              (N),
    .M              (M)
    ) u_decoder (
    // Global input
    .CLK            (CLK),
    .RST            (RST),

    // Control signals 
    .NEW_IMAGE      (NEW_IMAGE),

    // AER link
    .AEROUT_ADDR    (AEROUT_ADDR),
    .AEROUT_REQ     (AEROUT_REQ),
    .AEROUT_ACK     (AEROUT_ACK),

    // Outputs
    .INFERENCE_RDY  (INFERENCE_RDY),
    .DECODER_RDY    (DECODER_RDY),
    .INFERED_DIGIT  (INFERED_DIGIT)
  ); 

  //----------------------------------------------------------------------------
  //  OUTPUT LOGIC
  //----------------------------------------------------------------------------
  assign COPROCESSOR_RDY = ENCODER_RDY & DECODER_RDY;
endmodule