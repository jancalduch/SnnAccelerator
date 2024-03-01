module AXI_tb();

  localparam IMAGE_SIZE      = 256;
  localparam IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE);
  localparam PIXEL_MAX_VALUE = 255;
	localparam PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE);

  // ------------------------------
  // -- Logic
  // ------------------------------
  // TB
  logic         AXI_tb_ready;

  //DUT
  logic CLK;
  logic RST;
  logic [31:0] awaddr;
  logic [2:0] awprot;
  logic awvalid;
  logic [31:0] wdata;
  logic [3:0] wstrb;
  logic wvalid;
  logic [31:0] araddr;
  logic [2:0] arprot;
  logic arvalid;
  logic coprocessor_rdy;
  logic [31:0] rdata;
  logic [1:0] rresp;
  logic rvalid;
  logic [PIXEL_BITS-1:0] IMAGE [0:IMAGE_SIZE-1];

  // ------------------------------
  // -- Init
  // ------------------------------

  initial begin
    AXI_tb_ready  = 1'b0;
    

    // Initialize image to 0
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      IMAGE[i] = 0;
    end

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


  // ------------------------------
  // -- DUT and assignments
  // ------------------------------

  AXI_in u_AXI_in (
    .aclk(clk),
    .aresetn(reset_n),
    .awaddr(awaddr),
    .awprot(awprot),
    .awvalid(awvalid),
    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .araddr(araddr),
    .arprot(arprot),
    .arvalid(arvalid),
    .coprocessor_rdy(coprocessor_rdy),
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid)
  );

  // ------------------------------
  // -- Test program
  // ------------------------------

  // Write test
  initial begin

    while (~AXI_tb_ready) wait_ns(1);

    // Initialize image data
    foreach (image_data[i]) begin
      image_data[i] = $random;
    end

    // Write image data to the module
    awvalid = 1'b0;
    wvalid = 1'b0;
    repeat (255) begin
      @(posedge clk);
      awaddr <= $random;
      awprot <= $random;
      awvalid <= 1'b1;
      wdata <= image_data[awaddr[7:0]];
      wstrb <= $random;
      wvalid <= 1'b1;
      @(posedge clk);
      awvalid <= 1'b0;
      wvalid <= 1'b0;
      @(posedge clk);
    end

    // Wait for a few cycles to allow writes to complete
    #100;

    // Read back image data and compare
    foreach (image_data[i]) begin
      @(posedge clk);
      araddr <= i;
      arprot <= $random;
      arvalid <= 1'b1;
      @(posedge clk);
      arvalid <= 1'b0;
      @(posedge clk);
      if (rvalid) begin
        if (rdata !== image_data[i]) begin
          $display("Error: Image data mismatch at address %d. Expected: %h, Got: %h", i, image_data[i], rdata);
        end
      end
    end
    $display("Write test complete");
  end

  // Read test
  initial begin
    while (~AXI_tb_ready) wait_ns(1);

    // Wait for a few cycles
    wait_ns(500);

    // Set COPROCESSOR_RDY to high
    coprocessor_rdy = 1'b1;

    // Read from module
    @(posedge clk);
    araddr <= 0;
    arprot <= $random;
    arvalid <= 1'b1;
    @(posedge clk);
    arvalid <= 1'b0;
    @(posedge clk);
    if (rvalid) begin
        $display("Read test: First pixel value received: %h", rdata);
    end

    // Wait for a few cycles
    #100;
    $stop; // End simulation
  end

  // SIMPLE TIME-HANDLING TASKS
  task wait_ns;
    input   tics_ns;
    integer tics_ns;
    #tics_ns;
  endtask

endmodule
