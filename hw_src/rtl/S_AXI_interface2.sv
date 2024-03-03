/* Slave Interface for AXI4-Lite.
  Write Registers:
    0-255:  image_data
    256:    image_fully_received
  Read Registers:
    0:      infered_data
*/

module S_AXI_interface2 #(
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

  // control signals
  wire write_en;
	reg w_addr_done;
	reg w_data_done;

  reg r_addr_done;
	reg r_data_done;

	//flip flops for latching data
	reg [31:0] w_data_latch;
	reg [8:0] w_addr_latch;
  reg [8:0] r_addr_latch;

  integer i;

	//----------------------------------------------------------------------------
  //	WRITE LOGIC
  //----------------------------------------------------------------------------
  
  //write address handshake
	always @(posedge ACLK) begin
		if(~ARESETN | (AWVALID & AWREADY) )
			AWREADY <= 0;
		else if(~AWREADY & AWVALID)
			AWREADY <= 1;
	end

	//write data handshake
	always @(posedge ACLK) begin
		if(~ARESETN | (WVALID & WREADY) )
			WREADY <= 0;
		else if(~WREADY & WVALID)
			WREADY <= 1;
	end

	//keep track of which handshakes completed
	always @(posedge ACLK) begin
		if(ARESETN==0 || (w_addr_done & w_data_done) ) begin
			w_addr_done <= 0;
			w_data_done <= 0;
		end else begin	
			if(AWVALID & AWREADY) //look for addr handshake
				w_addr_done <= 1;
			if(WVALID & WREADY) //look for data handshake
				w_data_done <= 1;	
		end
	end

	//latching logic
	always @(posedge ACLK) begin
		if(ARESETN==0) begin
			w_data_latch <= 32'd0;
			w_addr_latch <= 8'd0;
    end else begin
			if(WVALID & WREADY) //look for data handshake
				w_data_latch <= WDATA;
			if(AWVALID & AWREADY)
				w_addr_latch <= AWADDR;
		end
	end

	//write response logic
	always @(posedge ACLK) begin	
		if( ARESETN==0 | (BVALID & BREADY) )
			BVALID <= 0;
		else if(~BVALID & (w_data_done & w_addr_done) )
			BVALID <= 1;	
	end

	//write logic for register file
	always @(posedge ACLK) begin
		if(ARESETN == 0) begin
      image_fully_received          <= 32'b0;
      foreach (image_data[i])
        image_data[i]               <= 0;
    end else if(write_en) begin
      if (w_addr_latch < 256)
        image_data[w_addr_latch]   <= apply_wstrb(image_data[w_addr_latch], w_data_latch, WSTRB);
      else
        image_fully_received       <= apply_wstrb(image_fully_received, w_data_latch, WSTRB);
    end
	end

  //----------------------------------------------------------------------------
  //	READ LOGIC
  //----------------------------------------------------------------------------
  
  //Read address handshake
	always @(posedge ACLK) begin
		if(~ARESETN | (ARVALID & ARREADY) )
			ARREADY <= 0;
		else if(~ARREADY & ARVALID)
			ARREADY <= 1;
	end

	//Read data handshake
	always @(posedge ACLK) begin
		if(~ARESETN | (RVALID & RREADY) )
			RVALID <= 0;
		else if(RREADY & ~RVALID)
			RVALID <= 1;
	end

	//keep track of which handshakes completed
	always @(posedge ACLK) begin
		if(ARESETN==0 || (r_addr_done & r_data_done) ) begin
			r_addr_done <= 0;
			r_data_done <= 0;
		end else begin	
			if(ARVALID & ARREADY) //look for addr handshake
				r_addr_done <= 1;
			if(RVALID & RREADY) //look for data handshake
				r_data_done <= 1;	
		end
	end

	//latching logic
	always @(posedge ACLK) begin
		if(ARESETN==0) begin
			RDATA <= 32'd0;
			r_addr_latch <= 8'd0;
    end else begin
			if(RVALID & RREADY) //look for data handshake
				RDATA <= infered_data;
			if(ARVALID & ARREADY)
				r_addr_latch <= AWADDR;
		end
	end

  //----------------------------------------------------------------------------
  //	COMBINATORIAL
  //----------------------------------------------------------------------------
  assign write_en = w_data_done & w_addr_done;
  assign infered_data   = {COPROCESSOR_RDY, 23'b0, INFERED_DIGIT};

  //----------------------------------------------------------------------------
  //	OUTPUTS
  //----------------------------------------------------------------------------
  assign BRESP = 2'd0; //always indicate OKAY status for writes
  assign RRESP = 2'd0; //always indicate OKAY status for reads
  assign IMAGE = image_data;
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
  