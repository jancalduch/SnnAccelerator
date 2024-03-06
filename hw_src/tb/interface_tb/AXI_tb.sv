module AXI_tb();
  localparam N                = 256;
  localparam M                = $clog2(N);

  localparam IMAGE_SIZE       = 256;
  localparam IMAGE_SIZE_BITS  = $clog2(IMAGE_SIZE);
  localparam PIXEL_MAX_VALUE  = 255;
	localparam PIXEL_BITS       = $clog2(PIXEL_MAX_VALUE);

  localparam AXI_DATA_WIDTH   = 32;
  localparam AXI_ADDR_WIDTH   = 32;

  // ------------------------------
  // -- Logic
  // ------------------------------
  // TB
  logic AXI_tb_ready;
  logic [31:0] IMAGE_IN [0:IMAGE_SIZE-1];
  logic [31:0] init_values [0:IMAGE_SIZE-1];

  logic [31:0] read_data;

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
  
  logic [PIXEL_BITS-1:0] IMAGE [0:IMAGE_SIZE-1];
  logic NEW_IMAGE;


  // ------------------------------
  // -- Init
  // ------------------------------

  initial begin
    AXI_tb_ready  = 1'b0;
    read_data     = 32'b0;

    AWVALID       = 1'b0;
    WVALID        = 1'b0;
    BREADY        = 1'b0;

    ARVALID       = 1'b0;
    RREADY        = 1'b0;
    
    COPROCESSOR_RDY = 1'b0;
    INFERED_DIGIT = 0;

    // Initialize image to 0
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      IMAGE_IN[i] = 0;
    end

    // Image to send
    init_values = '{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 32, 81, 
                    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, 174, 244, 101, 13, 
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 53, 187, 243, 239, 190, 75, 2, 
                    0, 0, 0, 0, 0, 0, 0, 0, 25, 185, 111, 98, 219, 222, 71, 6, 
                    0, 0, 0, 0, 0, 0, 0, 26, 120, 127, 20, 100, 228, 149, 27, 0, 
                    0, 0, 0, 0, 0, 0, 0, 24, 214, 163, 183, 192, 227, 120, 0, 0, 
                    0, 0, 0, 0, 0, 0, 1, 55, 164, 188, 83, 82, 170, 104, 12, 0, 
                    0, 0, 0, 0, 0, 0, 1, 10, 35, 17, 4, 51, 185, 93, 0, 0, 0, 0, 
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 180, 77, 4, 0, 0, 0, 0, 0, 0, 
                    0, 0, 0, 0, 0, 3, 50, 159, 98, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
                    0, 0, 0, 24, 174, 64, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
                    45, 97, 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
                    0, 0, 0, 0, 0};

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

  S_AXI4l_interface3 #(
    N,
    M,
    AXI_DATA_WIDTH,
    AXI_ADDR_WIDTH,
    IMAGE_SIZE,     
    IMAGE_SIZE_BITS,
    PIXEL_MAX_VALUE,
    PIXEL_BITS     
  ) u_S_AXI4l_interface (
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
    .ARPROT           (),
    .ARVALID          (ARVALID),
    .ARREADY          (ARREADY),

    .RDATA            (RDATA),
    .RRESP            (RRESP),
    .RVALID           (RVALID),
    .RREADY           (RREADY),

    .INFERED_DIGIT    (INFERED_DIGIT),

    .IMAGE            (IMAGE),
    .NEW_IMAGE        (NEW_IMAGE)
  );

  // ------------------------------
  // -- Test program
  // ------------------------------

  // Write test
  initial begin

    while (~AXI_tb_ready) wait_ns(1);

    //--------------------------------------------------------------------------
    //	SEND IMAGE
    //--------------------------------------------------------------------------

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
    for (int address = 0; address < IMAGE_SIZE; address++) begin
      axi4l_write(address, IMAGE_IN[address]);
    end
    // Notify that image is fully sent
    axi4l_write(256, 1);
    axi4l_write(256, 0);

    // Check that image is correct
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      assert (IMAGE_IN[i] == u_S_AXI4l_interface.image_data[i]) else $error("It's gone wrong");
    end

    wait_ns(100);

    //--------------------------------------------------------------------------
    //	READ RESULT
    //--------------------------------------------------------------------------
    // After some time, simulate SNN sending a result
    fork
      SNN_send_result(5, 3000);
    join_none
    
    // Wait until a result is valid and then read
    wait(COPROCESSOR_RDY);
    wait_ns(4);
    axi4l_read(0, read_data);

    COPROCESSOR_RDY <= 1'b0;
    
    assert (read_data[7:0] == INFERED_DIGIT) else $fatal("Wrong value read");

    wait_ns(500);

    $finish;

  end


  // SIMPLE TIME-HANDLING TASKS
  task wait_ns;
    input   tics_ns;
    integer tics_ns;
    #tics_ns;
  endtask

  task axi4l_write;
    input [31:0] addr;
    input [31:0] data;
    begin
      AWADDR  <= addr;	//Put write address on bus
      AWVALID <= 1'b1;	//indicate address is valid

      WDATA   <= data;	//put write data on bus
      WVALID  <= 1'b1;	//indicate data is valid
      WSTRB   <= 4'h1;  //writing 1st byte
  
      BREADY  <= 1'b1;	//indicate ready for a response
      
      //wait for one slave ready signal or the other and a positive edge
      wait(WREADY || AWREADY);
      @(posedge CLK);

      if(WREADY && AWREADY) begin   //received both ready signals
        AWVALID <= 0;
        WVALID  <= 0;
      end else begin                //wait for the other signal and a positive edge
        if(WREADY) begin            //case data handshake completed
          WVALID <= 0;
          wait(AWREADY);            //wait for address address ready
        end else if(AWREADY) begin  //case address handshake completed
          AWVALID <= 0;
          wait(WREADY);             //wait for data ready
        end 
        @(posedge CLK);             // complete the second handshake
        AWVALID <= 0;               //make sure both valid signals are deasserted
        WVALID  <= 0;
      end
              
      WSTRB <= 0;      //both handshakes have occured, deassert strobe

      wait(BVALID);   //wait for valid response
      @(posedge CLK); //both handshake signals and rising edge
      BREADY <= 0;     //deassert ready for response
  
    end
  endtask;

  task axi4l_read;
    input [31:0] addr;
    output logic [31:0] data;
    begin
      @(posedge CLK);
      ARADDR <= addr;     // Put read address on bus
      ARVALID <= 1'b1;    // Indicate address is valid
      RREADY <= 1'b1;     // Indicate ready for a response

      // Wait for address handshake to complete
      wait(ARREADY);
      @(posedge CLK);
      ARVALID <= 0;       // Deassert address valid after handshake

      // Wait for data response
      wait(RVALID);
      @(posedge CLK);
      data = RDATA;      // Assign received data
      RREADY <= 0;        // Deassert ready for response
    end
  endtask

  task automatic SNN_send_result;
    input [7:0] digit;
    input integer signal_time;
    begin
      wait_ns(signal_time);
      INFERED_DIGIT = digit;
      COPROCESSOR_RDY = 1'b1;
    end
  endtask

endmodule
