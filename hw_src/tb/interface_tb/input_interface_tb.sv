module input_interface_tb ();

  localparam IMAGE_SIZE      = 256;
  localparam IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE);
  localparam PIXEL_MAX_VALUE = 255;
	localparam PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE);

  // ------------------------------
  // -- Logic
  // ------------------------------
  // TB
  logic         sorter_ready;
  logic         auto_ack_verbose;
  
  logic         [9:0] pixel_id_spike;

  logic         [PIXEL_BITS-1:0] init_values [0:IMAGE_SIZE-1];

  // DUT
  logic         CLK;
  logic         RST;

  logic [PIXEL_BITS-1:0] IMAGE [0:IMAGE_SIZE-1];
  logic NEW_IMAGE; 
  logic ENCODER_RDY;
  logic FIRST_INFERENCE_DONE;

  logic [9:0] AERIN_ADDR;
  logic AERIN_REQ;
  logic AERIN_ACK;

  

  // ------------------------------
  // -- Init
  // ------------------------------

  initial begin
    sorter_ready  = 1'b0;
    NEW_IMAGE     = 1'b0;
    AERIN_ACK     = 1'b0;
    FIRST_INFERENCE_DONE = 1'b0;

    auto_ack_verbose = 1'b0;

    // Initialize image to 0
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      IMAGE[i] = 0;
    end

    // Image to encode
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
    sorter_ready = 1'b1;
  end
  
  // ------------------------------
  // -- DUT and assignments
  // ------------------------------
  input_interface #(
    IMAGE_SIZE,
    IMAGE_SIZE_BITS,
    PIXEL_MAX_VALUE,
    PIXEL_BITS
  )u_input_interface (
    // Global input
    .CLK              ( CLK               ),
    .RST              ( RST               ),

    // Input image 
    .IMAGE            ( IMAGE             ),
    .NEW_IMAGE        ( NEW_IMAGE         ),

    .FIRST_INFERENCE_DONE   ( FIRST_INFERENCE_DONE    ),

    // Image sorted
    .ENCODER_RDY    ( ENCODER_RDY     ),

    // Output 8-bit AER link --------------------------
    .AERIN_ADDR      ( AERIN_ADDR       ),
    .AERIN_REQ       ( AERIN_REQ        ),
    .AERIN_ACK       ( AERIN_ACK        )

  );

  // ------------------------------
  // -- Test program
  // ------------------------------

  initial begin
    while (~sorter_ready) wait_ns(1);

    wait_ns(2);

    // Generate an image
    // for (int i = 0; i < IMAGE_SIZE; i++) begin
    //   IMAGE[i] = $urandom_range(0, PIXEL_MAX_VALUE);
    // end

    for (int i = 0; i < IMAGE_SIZE; i++) begin
      IMAGE[i] = init_values[i];
    end

    $display("Image sent:");
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      $write("%d: ", i);
      $display("%d", IMAGE[i]);
    end

    fork
      auto_ack(.req(AERIN_REQ), .ack(AERIN_ACK), .addr(AERIN_ADDR), .pixel_id(pixel_id_spike), .verbose(auto_ack_verbose));
    join_none

    //Start monitoring output spikes in the console
    auto_ack_verbose = 1'b1;

    // Signal that there is a new image
    NEW_IMAGE = 1'b1;
    wait_ns(4);
    NEW_IMAGE = 1'b0;

    // Output each value until we dont need to send values anymore
    wait_ns(200000);
    FIRST_INFERENCE_DONE = 1'b1;
    while(!ENCODER_RDY) wait_ns(1);
    FIRST_INFERENCE_DONE = 1'b0;
    // while(!ENCODER_RDY) wait_ns(1);

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
    ref    logic [9:0] addr,
    ref    logic [9:0] pixel_id,
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