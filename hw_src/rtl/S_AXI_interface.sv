/* Slave Interface for AXI4-Lite. Wrapper for
    the input and output interfaces. 
    
    Address range:   256*32 (image) + 1*32 (inference) = 8224
    Address offset:  0x0000000
    Address:         0x0000000 - 0x000201F
  */


module S_AXI_interface (
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
    input logic [7:0]             INFERED_DIGIT

    // To SNN

  );
  
  AXI_in u_AXI_in (
    .ACLK             (ACLK),
    .ARESETN          (ARESETN),

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
    .BREADY           (BREADY)
  );

  AXI_out u_AXI_out (
    .ACLK             (ACLK),
    .ARESETN          (ARESETN),

    .ARADDR           (ARADDR),
    .ARPROT           (ARPROT),
    .ARVALID          (ARVALID),
    .ARREADY          (ARREADY),

    .RDATA            (RDATA),
    .RRESP            (RRESP),
    .RVALID           (RVALID),
    .RREADY           (RREADY),

    .COPROCESSOR_RDY  (COPROCESSOR_RDY),
    .INFERED_DIGIT    (INFERED_DIGIT)
  );
  
  endmodule
  