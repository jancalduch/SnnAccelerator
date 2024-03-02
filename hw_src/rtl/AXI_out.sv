/* Output Interface for AXI4-Lite 
    Address range:   1*32 = 32
    Address offset:  0x0002000
    Address:         0x0002000 - 0x000201F
*/


module AXI_out #(
  // Width of S_AXI data bus
  parameter integer AXI_DATA_WIDTH	= 32,
  // Width of S_AXI address bus
  parameter integer AXI_ADDR_WIDTH	= 7
)(
  input logic                   ACLK,         // Clock input
  input logic                   ARESETN,      // Reset input (active low)

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
  input logic [7:0]             INFERED_DIGIT
);

  //----------------------------------------------------------------------------
  //	LOGIC
  //----------------------------------------------------------------------------
  localparam ADDRLSB = $clog2(AXI_DATA_WIDTH)-3;
  
  logic [31:0] read_data;
  logic read_valid;
  logic read_ready;
  logic address_read_ready;

  //----------------------------------------------------------------------------
  //	DESGIN
  //----------------------------------------------------------------------------
  always_ff @(posedge ACLK)
    if (!RVALID || RREADY)
      read_data <= {COPROCESSOR_RDY, 23'b0, INFERED_DIGIT};

  always_ff @(posedge ACLK)
    if (!ARESETN)
      read_valid <= 1'b0;
    else if (read_ready)
      read_valid <= 1'b1;
    else if (RREADY)
      read_valid <= 1'b0;
	
  //----------------------------------------------------------------------------
  //	COMBINATORIAL LOGIC
  //----------------------------------------------------------------------------
  assign read_ready = (ARVALID && ARREADY);

	assign read_address = ARADDR[AXI_ADDR_WIDTH-1:ADDRLSB];

  always_comb
    address_read_ready = !RVALID;

  //----------------------------------------------------------------------------
  //	OUTPUT
  //----------------------------------------------------------------------------
  assign ARREADY = address_read_ready;
  assign RDATA = read_data;
  assign RRESP = 2'b00;       // Assume no error
  assign RVALID = read_valid;

endmodule
