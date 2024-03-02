/* Output Interface for AXI4-Lite 
    Address range:   1*32 = 32
    Address offset:  0x0002000
    Address:         0x0002000 - 0x000201F
*/


module AXI_out (
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

  // Read address decoding
  always_ff @(posedge ACLK or negedge ARESETN) begin
    if (!ARESETN) begin
      RVALID      <= 1'b0;
    end else if (ARVALID && ARREADY) begin
      // Read request acknowledged
      // RDATA <= image_data[ARADDR[7:0]];
      RRESP <= 'b00; // OKAY response
      RVALID <= 1'b1;
    end else if (COPROCESSOR_RDY) begin
      // Send data when COPROCESSOR_RDY is high
      RDATA <= {29'b0, 3'b111};
      RRESP <= 'b00; // OKAY response
      RVALID <= 1'b1;
    end else begin
      // Wait for read request or COPROCESSOR_RDY
      RVALID <= 1'b0;
    end
  end

  // AXI ready signal
  assign ARREADY = 1'b1; // Always ready to accept read requests

endmodule
