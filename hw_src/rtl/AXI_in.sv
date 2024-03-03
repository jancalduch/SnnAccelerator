/* Input Interface for AXI4-Lite 
    Address range:   256*32 = 8k
    Address offset:  0x0000000
    Address:         0x0000000 - 0x0001FFF
*/

module AXI_in #(  
  parameter integer AXI_DATA_WIDTH	= 32,     // Width of S_AXI data bus
  parameter integer AXI_ADDR_WIDTH	= 7       // Width of S_AXI address bus
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
  input logic                   BREADY        // Write response ready

);

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  
  localparam ADDRLSB = $clog2(AXI_DATA_WIDTH)-3;

  logic [7:0] image_data[0:255];  // 256 8-bit pixel values
  logic NEW_IMAGE;                // Indicate that an image is fully received

  logic [AXI_ADDR_WIDTH-ADDRLSB-1:0] write_address;
	logic [AXI_DATA_WIDTH-1:0] data;
	logic [AXI_DATA_WIDTH/8-1:0] strb;
  logic [7:0] write_data[0:255];

  logic write_ready;              // Indicate we want to write to a register
  logic address_write_ready;

  logic write_response_valid;

  //----------------------------------------------------------------------------
  //	SEQUENTIAL LOGIC
  //----------------------------------------------------------------------------
  // Store pixel value into image array
  always_ff @(posedge ACLK) begin
    if (!ARESETN) begin
      foreach (image_data[i])
        image_data[i] = 0;
    end else if (write_ready) begin
      // apply_wstrb(old_data, new_data, write_strobes)
      foreach (write_data[i])
        write_data[i] = apply_wstrb(image_data[i], data, strb);
      image_data[write_address] = write_data[write_address];
    end
  end
  
  // BVALID set following any successful write to the SNN coprocessor
  always_ff @(posedge ACLK)
    if (!ARESETN)
      write_response_valid <= 0;
    else if (write_ready)
      write_response_valid <= 1;
    else if (BREADY)
      write_response_valid <= 0;

  always_ff @(posedge ACLK)
    if (!ARESETN)
      address_write_ready <= 1'b0;
    else  
      address_write_ready <= !address_write_ready && (AWVALID && WVALID) && (!BVALID || BREADY);

  //----------------------------------------------------------------------------
  //	COMBINATORIAL LOGIC
  //----------------------------------------------------------------------------
  assign write_ready = address_write_ready;

  assign 	write_address = AWADDR[7:0]; //[AXI_ADDR_WIDTH-1:ADDRLSB];
	assign	data  = WDATA;
	assign	strb  = WSTRB;

  //----------------------------------------------------------------------------
  //	OUTPUT
  //----------------------------------------------------------------------------
  assign AWREADY  = address_write_ready;
  assign WREADY   = address_write_ready;
  assign BRESP    = 2'b00;                      // Assume no error
  assign BVALID   = write_response_valid;

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
