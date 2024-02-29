module AXI_Interface (
    input logic                   aclk,         // Clock input
    input logic                   aresetn,      // Reset input (active low)

    // WRITE ADDRESS (AW)
    input logic [31:0]            awaddr,       // Write address
    input logic [2:0]             awprot,       // Write protection signals
    input logic                   awvalid,      // Write address valid
    output logic                  awready,      // Write address ready
    
    // WRITE DATA (W)
    input logic [31:0]            wdata,        // Write data
    input logic [3:0]             wstrb,        // Write byte strobes
    input logic                   wvalid,       // Write data valid
    output logic                  wready,       // Write data ready
    
    // WRITE RESPONSE (B)
    output logic [1:0]            bresp,        // Write response
    output logic                  bvalid,       // Write response valid
    input logic                   bready,       // Write response ready

    // READ ADDRESS (AR)
    input logic [31:0]            araddr,       // Read address
    input logic [2:0]             arprot,       // Read protection signals
    input logic                   arvalid,      // Read address valid
    output logic                  arready,      // Read address ready
    
    // READ DATA (R)
    output logic [31:0]           rdata,        // Read data
    output logic [1:0]            rresp,        // Read response
    output logic                  rvalid,       // Read data valid
    input logic                   rready        // Read data ready
);

    // Logic

endmodule
