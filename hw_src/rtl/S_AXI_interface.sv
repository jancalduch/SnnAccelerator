/* Slave Interface for AXI4-Lite.
  Write Registers:
    0-255:  image_data
    256:    image_fully_received
  Read Registers:
    0:      infered_data
*/


module S_AXI_interface #(
  parameter integer AXI_DATA_WIDTH	= 32,     // Width of S_AXI data bus
  parameter integer AXI_ADDR_WIDTH	= 7,      // Width of S_AXI address bus
  
  parameter integer IMAGE_SIZE      = 256,
  parameter integer IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter integer PIXEL_MAX_VALUE = 255,
	parameter integer PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(
  input logic                   ACLK,         // Clock input
  input logic                   ARESETN,      // Reset input (active low)

  // WRITE ADDRESS (AW) channel
  input logic [31:0]            AWADDR,       // Write address
  input logic [2:0]             AWPROT,       // Write protection signals
  input logic                   AWVALID,      // Write address valid
  output logic                  AWREADY,      // Write address ready

  // WRITE DATA (W) channel
  input logic [31:0]            WDATA,        // Write data
  input logic [3:0]             WSTRB,        // Write byte strobes
  input logic                   WVALID,       // Write data valid
  output logic                  WREADY,       // Write data ready

  // WRITE RESPONSE (B) channel
  output logic [1:0]            BRESP,        // Write response
  output logic                  BVALID,       // Write response valid
  input logic                   BREADY,       // Write response ready

  // READ ADDRESS (AR) channel
  input logic [31:0]            ARADDR,       // Read address
  input logic [2:0]             ARPROT,       // Read protection signals
  input logic                   ARVALID,      // Read address valid
  output logic                  ARREADY,      // Read address ready

  // READ DATA (R) channel
  output logic [31:0]           RDATA,        // Read data
  output logic [1:0]            RRESP,        // Read response
  output logic                  RVALID,       // Read data valid
  input logic                   RREADY,       // Read data ready

  // From SNN
  input logic                   COPROCESSOR_RDY,
  input logic [7:0]             INFERED_DIGIT,

  // To SNN
  output logic [PIXEL_BITS-1:0] IMAGE [0:IMAGE_SIZE-1],
  output logic NEW_IMAGE
);

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------

  // Registers
  logic [7:0] image_data[0:255];  // 256 8-bit pixel values
  logic [31:0] image_fully_received;
  logic [31:0] infered_data;

  // Write
  logic [AXI_ADDR_WIDTH-1:0] write_address;
  logic [AXI_DATA_WIDTH-1:0] write_data;
  logic [AXI_DATA_WIDTH/8-1:0] strb;

  logic address_write_ready;
  logic write_response_valid;

  // Read
  logic [AXI_ADDR_WIDTH-1:0] read_data;
  logic [AXI_ADDR_WIDTH-1:0] read_address;
  logic read_valid;

  //----------------------------------------------------------------------------
  //	SEQUENTIAL LOGIC
  //----------------------------------------------------------------------------
  // Store Write data into registers
  always_ff @(posedge ACLK) begin
    if (!ARESETN) begin
      image_fully_received            <= 32'b0;
      foreach (image_data[i])
        image_data[i]                 <= 0;
    
    end else if (address_write_ready) begin
      if (write_address < 256)
        image_data[write_address]   <= apply_wstrb(image_data[write_address], write_data, strb);
      else
        image_fully_received        <= apply_wstrb(image_fully_received, write_data, strb);
    end
  end

  // BVALID set following any successful write to the SNN coprocessor
  always_ff @(posedge ACLK)
    if (!ARESETN)
      write_response_valid <= 0;
    else if (address_write_ready)
      write_response_valid <= 1;
    else if (BREADY)
      write_response_valid <= 0;

  always_ff @(posedge ACLK)
    if (!ARESETN)
      address_write_ready <= 1'b0;
    else  
      address_write_ready <= !address_write_ready && (AWVALID && WVALID) && (!BVALID || BREADY);

  // Read data from register
  always_ff @(posedge ACLK)
  if (!ARESETN)
    read_data <= 0;
  else if (!RVALID || RREADY)
    read_data <= infered_data;

  // Read handshake logic
  always_ff @(posedge ACLK)
    if (!ARESETN)
      read_valid <= 1'b0;
    else if (ARVALID && ARREADY)
      read_valid <= 1'b1;
    else if (RREADY)
      read_valid <= 1'b0;   
  //----------------------------------------------------------------------------
  //	COMBINATORIAL LOGIC
  //----------------------------------------------------------------------------
  assign write_address  = AWADDR[8:0];
  assign write_data     = WDATA;
  assign strb           = WSTRB;

  assign infered_data   = {COPROCESSOR_RDY, 23'b0, INFERED_DIGIT};
	assign read_address   = ARADDR[8:0];

  //----------------------------------------------------------------------------
  //	OUTPUT
  //----------------------------------------------------------------------------
  assign AWREADY    = address_write_ready;
  assign WREADY     = address_write_ready;
  assign BRESP      = 2'b00;                      // Assume no error
  assign BVALID     = write_response_valid;

  assign ARREADY    = !RVALID;
  assign RDATA      = read_data;
  assign RRESP      = 2'b00;       // Assume no error
  assign RVALID     = read_valid;

  assign IMAGE      = image_data;
  assign NEW_IMAGE  = (image_fully_received != 0) ? 1'b1: 1'b0;

  //----------------------------------------------------------------------------
  //	FUNCTIONS
  //----------------------------------------------------------------------------
  function [AXI_DATA_WIDTH-1:0]	apply_wstrb;
    input	[AXI_DATA_WIDTH-1:0]		prior_data;
    input	[AXI_DATA_WIDTH-1:0]		new_data;
    input	[AXI_DATA_WIDTH/8-1:0]	wstrb;

    integer	k;
    for(k = 0; k < AXI_DATA_WIDTH/8; k = k + 1)
    begin
      apply_wstrb[k*8 +: 8]
        = wstrb[k] ? new_data[k*8 +: 8] : prior_data[k*8 +: 8];
    end
  endfunction
  
  endmodule
  