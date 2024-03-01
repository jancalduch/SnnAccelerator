/* Input Interface for AXI4-Lite */


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
  input logic                   BREADY,       // Write response ready
);

  // Address range:   256*32 (image) + 1*32 (inference) = 8224
  // Address offset:  0x0000000
  // Address:         0x0000000 - 0x000201F


  // Address range:   256*32 = 8k
  // Address offset:  0x0000000
  // Address:         0x0000000 - 0x0001FFF


  // Image storage register
  logic [7:0] image_data[0:254]; // Assuming 255 pixel values, 8 bits each

  // Read address decoding
  always_ff @(posedge ACLK or negedge ARESETN) begin
    if (!ARESETN) begin
      // Reset state
      // Reset image_data array
      image_data <= '0;
    end else if (ARVALID && ARREADY) begin
      // Read request acknowledged
      // Read data from image_data array based on address
      RDATA <= image_data[araddr[7:0]];
      RRESP <= 'b00; // OKAY response
      RVALID <= 1'b1;
    end else begin
      // Wait for read request
      RVALID <= 1'b0;
    end
  end

  // AXI ready signal
  assign ARREADY = 1'b1; // Always ready to accept read requests

endmodule
