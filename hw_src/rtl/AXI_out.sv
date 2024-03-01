/* Output Interface for AXI4-Lite */


module AXI_in (
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
  input logic                   RREADY        // Read data ready
);

  // Address range:   1*32 = 32
  // Address offset:  0x4002000
  // Address:         0x4002000 - 0x400201F



  // Image storage register
  logic [7:0] image_data[0:254]; // Assuming 255 pixel values, 8 bits each

  // COPROCESSOR_RDY signal detection
  logic [7:0] coprocessor_data; // Data to be sent when COPROCESSOR_RDY is high
  always_ff @(posedge ACLK or negedge ARESETN) begin
    if (!ARESETN) begin
      coprocessor_data <= '0;
    end else if (COPROCESSOR_RDY) begin
      // Data to be sent when COPROCESSOR_RDY is high
      coprocessor_data <= image_data[0]; // For example, sending the first pixel value
    end
  end

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
    end else if (COPROCESSOR_RDY) begin
      // Send data when COPROCESSOR_RDY is high
      RDATA <= coprocessor_data;
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
