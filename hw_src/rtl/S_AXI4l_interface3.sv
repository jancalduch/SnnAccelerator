module S_AXI4l_interface3 #(
  parameter integer N               = 256,    // Maximum number of neurons
  parameter integer M               = 8,      // log2(N)

  parameter integer AXI_DATA_WIDTH  = 32,     // Width of S_AXI data bus
  parameter integer AXI_ADDR_WIDTH  = 32,      // Width of S_AXI address bus
  
  parameter integer IMAGE_SIZE      = 256,
  parameter integer IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE),
  parameter integer PIXEL_MAX_VALUE = 255,
  parameter integer PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE)
)(
  input logic                   ACLK,         // Clock input
  input logic                   ARESETN,      // Reset input (active low)

  // WRITE ADDRESS (AW) channel
  input logic [AXI_ADDR_WIDTH-1:0]  AWADDR,       // Write address
  input logic [2:0]                 AWPROT,       // Write protection signals
  input logic                       AWVALID,      // Write address valid
  output logic                      AWREADY,      // Write address ready

  // WRITE DATA (W) channel
  input logic [AXI_DATA_WIDTH-1:0]  WDATA,        // Write data
  input logic [3:0]                 WSTRB,        // Write byte strobes
  input logic                       WVALID,       // Write data valid
  output logic                      WREADY,       // Write data ready

  // WRITE RESPONSE (B) channel
  output logic [1:0]                BRESP,        // Write response
  output logic                      BVALID,       // Write response valid
  input logic                       BREADY,       // Write response ready

  // READ ADDRESS (AR) channel
  input logic [AXI_ADDR_WIDTH-1:0]  ARADDR,       // Read address
  input logic [2:0]                 ARPROT,       // Read protection signals
  input logic                       ARVALID,      // Read address valid
  output logic                      ARREADY,      // Read address ready

  // READ DATA (R) channel
  output logic [AXI_DATA_WIDTH-1:0] RDATA,        // Read data
  output logic [1:0]                RRESP,        // Read response
  output logic                      RVALID,       // Read data valid
  input logic                       RREADY,       // Read data ready

  // From SNN
  input logic [M-1:0]               INFERED_DIGIT,

  // To SNN
  output logic [PIXEL_BITS-1:0] IMAGE [0:IMAGE_SIZE-1],
  output logic NEW_IMAGE
);

  //----------------------------------------------------------------------------
  //  LOGIC Declarations
  //----------------------------------------------------------------------------

  // Registers
  logic [PIXEL_BITS-1:0]      image_data [0:IMAGE_SIZE-1];   // 256 8-bit pixel values
  logic [AXI_DATA_WIDTH-1:0]  image_fully_received;      // Flag to indicate all pixels have been received
  logic [AXI_DATA_WIDTH-1:0]  infered_data;              // Infered digit from SNN and COP_RDY flag
  
  // AXI4-Lite signals
  logic                       axi_awready;
  logic                       axi_wready;
  logic                       axi_bvalid;

  logic                       axi_arready;
  logic [AXI_DATA_WIDTH-1:0]  axi_rdata;
  logic                       axi_rvalid;

  // Helper logic
  logic valid_write_address, valid_write_data, write_response_stall;
  logic [AXI_ADDR_WIDTH-1:0]      pre_waddr, waddr;
  logic [AXI_DATA_WIDTH-1:0]      pre_wdata, wdata;
  logic [(AXI_DATA_WIDTH/8)-1:0]  pre_wstrb, wstrb;

  logic valid_read_request, read_response_stall;
  logic [AXI_ADDR_WIDTH-1:0]      pre_raddr, rd_addr;

  //----------------------------------------------------------------------------
  //  WRITE LOGIC
  //----------------------------------------------------------------------------
  assign valid_write_address  = AWVALID || !axi_awready;
  assign valid_write_data     = WVALID  || !axi_wready;
  assign write_response_stall = BVALID  && !BREADY;

  /* Write address ready handshake:
    If the output channel is stalled, we remain stalled if the buffer is full
    or if the buffer is empty and there is a request.
    Assert ready if the output channel is clear and write data are available.
    If we were ready before, remain ready unless an address unaccompanied by data shows up.
  */
  always_ff @(posedge ACLK)
  if (!ARESETN)                   axi_awready <= 1'b1;
  else if (write_response_stall)  axi_awready <= !valid_write_address;
  else if (valid_write_data)      axi_awready <= 1'b1;
  else                            axi_awready <= (axi_awready && !AWVALID); // axi_awready <= !valid_write_address

  /* Write data ready handshake:
    If the output channel is stalled, we remain stalled until valid write data shows up.
    Assert ready if the output channel is clear, and a write address is available.
    If we were ready before, remain ready unless there's new data avaialble to cause us to stall
  */
  always_ff @(posedge ACLK)
  if (!ARESETN)                   axi_wready <= 1'b1;
  else if (write_response_stall)  axi_wready <= !valid_write_data;
  else if (valid_write_address)   axi_wready <= 1'b1;
  else                            axi_wready <= (axi_wready && !WVALID);  // axi_wready <= !valid_write_data

  /* Buffer address, data and strobe, and then write:
    Write the data if the output channel isn't stalled, we have a valid 
    address, and we have valid data.
  */
  
  // Buffer the address, data and strobe
  always_ff @(posedge ACLK)
  if (AWREADY)
    pre_waddr <= AWADDR;

  always_ff @(posedge ACLK)
  if (WREADY) begin
    pre_wdata <= WDATA;
    pre_wstrb <= WSTRB;
  end

  // Read the write address, data and strobe from our "buffers"
  always_comb waddr = (!axi_awready)  ? pre_waddr : AWADDR;
  always_comb wdata = (!axi_wready)   ? pre_wdata : WDATA;
  always_comb wstrb = (!axi_wready)   ? pre_wstrb : WSTRB;

  // Write the data into registers
  always_ff @(posedge ACLK) begin
    if (!ARESETN) begin
      image_fully_received        <= 32'b0;
      foreach (image_data[i])
        image_data[i]             <= 0;
    end else if (!write_response_stall && valid_write_address && valid_write_data) begin
      if (waddr < 256)
        image_data[waddr] <= apply_wstrb(image_data[waddr], wdata, wstrb);
      else
        image_fully_received      <= apply_wstrb(image_fully_received, wdata, wstrb);
    end
  end

  /* Write response valid handshake:
    Indicate a valid write if we have a valid address and we had valid data.
    No matter if we are stalled, keeo setting hte ready signal as often as we want.
    If BREADY was true, then it was just accepted and can return to idle.
  */
  always_ff @(posedge ACLK )
  if (!ARESETN)                                       axi_bvalid <= 1'b0;
  else if (valid_write_address && valid_write_data)   axi_bvalid <= 1'b1;
  else if (BREADY)                                    axi_bvalid <= 1'b0;

  //----------------------------------------------------------------------------
  //  READ LOGIC
  //----------------------------------------------------------------------------
  assign valid_read_request   = ARVALID || !ARREADY;
  assign read_response_stall  = RVALID  && !RREADY;

  assign infered_data = {24'b0, INFERED_DIGIT};

  /* Read data valid handshake:
    Need to stay valid as long as the return path is stalled
    When the stall has cleared we can always clear the valid signal
  */
  always_ff @(posedge ACLK )
  if (!ARESETN)
    axi_rvalid <= 0;
  else if (read_response_stall)
    axi_rvalid <= 1'b1;
  else if (valid_read_request)
    axi_rvalid <= 1'b1;
  else
    axi_rvalid <= 1'b0;

  /* Buffer address and read data:
    Buffer the addres and read data if the outgoing channel is not stalled
  */
  // Buffer the address
  always_ff @(posedge ACLK)
  if (ARREADY)
    pre_raddr <= ARADDR;

  // Read the read address from our "buffer"
  always_comb rd_addr = (!axi_arready) ? pre_raddr : ARADDR;

  // Put the data on the read channel if the channel isn't stalled and we have valid address
  always_ff @(posedge ACLK)
  if (!read_response_stall && valid_read_request)       // (!OPT_READ_SIDEEFFECTS || valid_read_request)
    axi_rdata <= infered_data;


  /* Read address ready handshake:
    If the outgoing channel is stalled and there is something in the buffer, 
    axi_arready needs to stay low
  */
  always_ff @(posedge ACLK)
  if (!ARESETN)                   axi_arready <= 1'b1;
  else if (read_response_stall)   axi_arready <= !valid_read_request;
  else                            axi_arready <= 1'b1;

  //----------------------------------------------------------------------------
  //  OUTPUT CONNECTIONS
  //----------------------------------------------------------------------------
  assign AWREADY    = axi_awready;
  assign WREADY     = axi_wready;
  assign BRESP      = 2'b00;        // The OKAY response
  assign BVALID     = axi_bvalid;

  assign ARREADY    = axi_arready;
  assign RDATA      = axi_rdata;
  assign RRESP      = 2'b00;        // The OKAY response
  assign RVALID     = axi_rvalid;

  assign IMAGE      = image_data;
  assign NEW_IMAGE  = (image_fully_received != 0) ? 1'b1: 1'b0;

  //----------------------------------------------------------------------------
  //  FUNCTIONS
  //----------------------------------------------------------------------------
  function [AXI_DATA_WIDTH-1:0] apply_wstrb;
    input [AXI_DATA_WIDTH-1:0]    prior_data;
    input [AXI_DATA_WIDTH-1:0]    new_data;
    input [AXI_DATA_WIDTH/8-1:0]  wstrb;

    integer k;
    for(k = 0; k < AXI_DATA_WIDTH/8; k = k + 1)
    begin
      apply_wstrb[k*8 +: 8]
        = wstrb[k] ? new_data[k*8 +: 8] : prior_data[k*8 +: 8];
    end
  endfunction
endmodule