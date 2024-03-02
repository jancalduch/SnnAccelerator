module AXI_tb();

  localparam IMAGE_SIZE      = 256;
  localparam IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE);
  localparam PIXEL_MAX_VALUE = 255;
	localparam PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE);

  // ------------------------------
  // -- Logic
  // ------------------------------
  // TB
  logic AXI_tb_ready;
  logic [PIXEL_BITS-1:0] IMAGE_IN [0:IMAGE_SIZE-1];
  logic [PIXEL_BITS-1:0] init_values [0:IMAGE_SIZE-1];


  //DUT
  logic CLK;
  logic RST, ARESETN;

  logic [31:0] AWADDR;
  logic AWVALID;
  logic AWREADY;

  logic [31:0] WDATA;
  logic [3:0] WSTRB;
  logic WVALID;
  logic WREADY;

  logic [1:0] BRESP;
  logic BVALID;
  logic BREADY;

  logic [31:0] ARADDR;
  logic [2:0] ARPROT;
  logic ARVALID;
  logic ARREADY;

  logic [31:0] RDATA;
  logic [1:0] RRESP;
  logic RVALID;
  logic RREADY;

  logic COPROCESSOR_RDY;
  logic [7:0] INFERED_DIGIT;    // M-1:0


  // ------------------------------
  // -- Init
  // ------------------------------

  initial begin
    AXI_tb_ready  = 1'b0;

    AWVALID       = 1'b0;
    WVALID        = 1'b0;
    ARVALID       = 1'b0;    

    // Initialize image to 0
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      IMAGE_IN[i] = 0;
    end

    // Image to send
    init_values = '{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 32, 81, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, 174, 244, 101, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 53, 187, 243, 239, 190, 75, 2, 0, 0, 0, 0, 0, 0, 0, 0, 25, 185, 111, 98, 219, 222, 71, 6, 0, 0, 0, 0, 0, 0, 0, 26, 120, 127, 20, 100, 228, 149, 27, 0, 0, 0, 0, 0, 0, 0, 0, 24, 214, 163, 183, 192, 227, 120, 0, 0, 0, 0, 0, 0, 0, 0, 1, 55, 164, 188, 83, 82, 170, 104, 12, 0, 0, 0, 0, 0, 0, 0, 1, 10, 35, 17, 4, 51, 185, 93, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 180, 77, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 50, 159, 98, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 174, 64, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 45, 97, 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

  end
    
  // ------------------------------
  // -- Clock and Reset
  // ------------------------------

  initial begin
    CLK = 1'b1; 
    forever begin
      wait_ns(2);
      CLK = ~CLK;
    end
  end

  initial begin
    wait_ns(0.1);
    RST = 1'b0;
    wait_ns(100);
    RST = 1'b1;
    wait_ns(100);
    RST = 1'b0;
    wait_ns(100);
    AXI_tb_ready = 1'b1;
  end

  assign ARESETN = ~RST; 

  // ------------------------------
  // -- DUT and assignments
  // ------------------------------

  S_AXI_interface u_S_AXI_interface (
    .ACLK             (CLK),
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
    .BREADY           (BREADY),

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

  // ------------------------------
  // -- Test program
  // ------------------------------

  // Write test
  initial begin

    while (~AXI_tb_ready) wait_ns(1);

    // Generate and print input image
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      IMAGE_IN[i] = init_values[i];
    end

    $display("Image sent:");
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      $write("%d: ", i);
      $display("%d", IMAGE_IN[i]);
    end

    // Send data byte by byte
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      @(posedge CLK)
      AWADDR <= i;
      AWVALID <= 1'b1;
      
      @(posedge CLK)
      WDATA <= IMAGE_IN[AWADDR[7:0]];
      WSTRB <= 4'b001;                  // Only LSB has valid information
      WVALID <= 1'b1;
      
      @(posedge CLK);
      
      AWVALID <= 1'b0;
      WVALID <= 1'b0;
      
      @(posedge CLK);
    end

    wait_ns(500);
    $finish;

  end

  // Read test
  // initial begin
  //   while (~AXI_tb_ready) wait_ns(1);

  //   // Wait for a few cycles
  //   wait_ns(500);

  //   // Set COPROCESSOR_RDY to high
  //   COPROCESSOR_RDY = 1'b1;

  //   // Read from module
  //   @(posedge clk);
  //   araddr <= 0;
  //   arprot <= $random;
  //   arvalid <= 1'b1;
  //   @(posedge clk);
  //   arvalid <= 1'b0;
  //   @(posedge clk);
  //   if (rvalid) begin
  //       $display("Read test: First pixel value received: %h", rdata);
  //   end

  //   // Wait for a few cycles
  //   #100;
  //   $stop; // End simulation
  // end

  // SIMPLE TIME-HANDLING TASKS
  task wait_ns;
    input   tics_ns;
    integer tics_ns;
    #tics_ns;
  endtask

endmodule
