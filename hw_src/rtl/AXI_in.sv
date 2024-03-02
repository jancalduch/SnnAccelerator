/* Input Interface for AXI4-Lite 
    Address range:   256*32 = 8k
    Address offset:  0x0000000
    Address:         0x0000000 - 0x0001FFF
*/


module AXI_in (
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

  // Image storage register
  logic [7:0] image_data[0:255]; // Assuming 256 pixel values, 8 bits each
  logic NEW_IMAGE;

  // Write address decoding
  always_ff @(posedge ACLK or negedge ARESETN) begin
    if (!ARESETN) begin
      BVALID              <= 1'b0;
    end else if (AWVALID && AWREADY && WREADY && WVALID) begin
      image_data[AWADDR[7:0]]  <= WDATA[7:0];
      BRESP               <= 'b00; // OKAY response
      BVALID              <= 1'b1;
    end else begin
      BVALID              <= 1'b0;
    end
  end

  // AXI ready signal
  assign AWREADY = 1'b1; // Always ready to accept read requests
  assign WREADY  = 1'b1;

endmodule
