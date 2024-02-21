module encoder_tb ();

  localparam IMAGE_SIZE      = 5;
  localparam IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE);
  localparam PIXEL_MAX_VALUE = 10;
	localparam PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE);

  // ------------------------------
  // -- Logic
  // ------------------------------
  // TB
  logic         sorter_ready;
  logic         auto_ack_verbose;
  
  logic         [IMAGE_SIZE_BITS:0] pixel_id_spike;

  // DUT
  logic         CLK;
  logic         RST;

  logic [PIXEL_BITS:0] IMAGE [0:IMAGE_SIZE-1];
  logic NEW_IMAGE; 
  logic IMAGE_ENCODED;

  logic [IMAGE_SIZE_BITS:0] AEROUT_ADDR;
  logic AEROUT_REQ;
  logic AEROUT_ACK;

  // ------------------------------
  // -- Init
  // ------------------------------

  initial begin
    sorter_ready      = 1'b0;
    NEW_IMAGE         = 1'b0;
    AEROUT_ACK  =  1'b0;

    auto_ack_verbose = 1'b0;

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
    sorter_ready = 1'b1;
  end
  
  // ------------------------------
  // -- DUT and assignments
  // ------------------------------
  encoder #(
    IMAGE_SIZE,
    IMAGE_SIZE_BITS,
    PIXEL_MAX_VALUE,
    PIXEL_BITS
  )u_encoder (
    // Global input
    .CLK              ( CLK               ),
    .RST              ( RST               ),

    // Input image 
    .IMAGE            ( IMAGE             ),
    .NEW_IMAGE        ( NEW_IMAGE         ),

    // Image sorted
    .IMAGE_ENCODED    ( IMAGE_ENCODED     ),

    // Output 8-bit AER link --------------------------
    .AEROUT_ADDR      ( AEROUT_ADDR       ),
    .AEROUT_REQ       ( AEROUT_REQ        ),
    .AEROUT_ACK       ( AEROUT_ACK        )

  );

  // ------------------------------
  // -- Test program
  // ------------------------------

  initial begin
    while (~sorter_ready) wait_ns(1);

    wait_ns(2);

    // Generate an image
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      IMAGE[i] = $urandom_range(0, PIXEL_MAX_VALUE);
    end
    $display("Image sent:");
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      $write("%d: ", i);
      $display("%d", IMAGE[i]);
    end

    fork
      auto_ack(.req(AEROUT_REQ), .ack(AEROUT_ACK), .addr(AEROUT_ADDR), .pixel_id(pixel_id_spike), .verbose(auto_ack_verbose));
    join_none

    //Start monitoring output spikes in the console
    auto_ack_verbose = 1'b1;

    // Signal that there is a new image
    NEW_IMAGE = 1'b1;
    wait_ns(4);
    NEW_IMAGE = 1'b0;

    // Output each value until the whole image has been sorted
    while (!IMAGE_ENCODED) wait_ns(1);

    wait_ns(500);
    $finish;

  end

  // SIMPLE TIME-HANDLING TASKS
  task wait_ns;
    input   tics_ns;
    integer tics_ns;
    #tics_ns;
  endtask

  /***************************
	 AER automatic acknowledge
	***************************/
  task automatic auto_ack (
    ref    logic       req,
    ref    logic       ack,
    ref    logic [7:0] addr,
    ref    logic [7:0] pixel_id,
    ref    logic       verbose
  );

  forever begin
    while (~req) wait_ns(1);
    wait_ns(100);
    pixel_id = addr;
    if (verbose)
      $display("----- IL SPIKE (FROM encder): Event from pixel ID %d", pixel_id);
    ack = 1'b1;
    while (req) wait_ns(1);
    wait_ns(100);
    ack = 1'b0;
  end

endtask

endmodule