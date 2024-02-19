module aer_out_tb ();

  localparam IMAGE_SIZE      = 5;
  localparam IMAGE_SIZE_BITS = $clog2(IMAGE_SIZE);
  localparam PIXEL_MAX_VALUE = 10;
	localparam PIXEL_BITS      = $clog2(PIXEL_MAX_VALUE);

  // ------------------------------
  // -- Logic
  // ------------------------------
  logic         sorter_ready;
  
  logic         CLK;
  logic         RST;

  logic [PIXEL_BITS-1:0] image [0:IMAGE_SIZE-1];
  logic [PIXEL_BITS-1:0] sorted_indexes [0:IMAGE_SIZE-1];

  logic         done;
  logic         new_image;

  // ------------------------------
  // -- Init
  // ------------------------------

  initial begin
    sorter_ready = 1'b0;
    new_image = 1'b0;

    // Initialize image to 0
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      image[i] = 0;
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
  sorter u_sorter (
    // Global input
    .CLK            ( CLK             ),
    .RST            ( RST             ),

    // Input image 
    .image          ( image           ),
    .new_image      ( new_image       ),
    
    // Sorted image
    .sorted_indexes ( sorted_indexes  ),
    .done           ( done            )
  );

  // ------------------------------
  // -- Test program
  // ------------------------------

  initial begin
    while (~sorter_ready) wait_ns(1);

    wait_ns(2);

    // Generate an image
    // $time;
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      image[i] = $urandom_range(0, PIXEL_MAX_VALUE-1);
    end
    $display("Image sent:");
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      $write("%d: ", i);
      $display("%h", image[i]);
    end

    new_image = 1'b1;
    wait_ns(4);
    new_image = 1'b0;

    while (~done) wait_ns(1);

    // Print the encoded image
    $display("Image recieved:");
    for (int i = 0; i < IMAGE_SIZE; i++) begin
      $write("%d: ", i);
      $display("%h", sorted_indexes[i]);
    end

    wait_ns(500);
    $finish;

  end

  // SIMPLE TIME-HANDLING TASKS
  task wait_ns;
    input   tics_ns;
    integer tics_ns;
    #tics_ns;
  endtask

  //AER send event
  task automatic aer_send (
    input  logic [paTest_SnnAccelerator::M+1:0] addr_in,
    ref    logic [paTest_SnnAccelerator::M+1:0] addr_out,
    ref    logic          ack,
    ref    logic          req
  );
    while (ack) wait_ns(1);
    addr_out = addr_in;
    wait_ns(5);
    req = 1'b1;
    while (!ack) wait_ns(1);
    wait_ns(5);
    req = 1'b0;
  endtask


  //AER automatic acknowledge
  task automatic auto_ack (
    ref    logic       req,
    ref    logic       ack,
    ref    logic [7:0] addr,
    ref    logic [7:0] neur,
    ref    logic       verbose,
    ref    logic       spike
  );
    forever begin
      spike = 1'b0;
      while (~req) wait_ns(1);
      wait_ns(100);
      neur = addr;
      spike = 1'b1;
      if (verbose)
        $display("----- NEURON OUTPUT SPIKE (FROM AER): Event from neuron %d", neur);
      ack = 1'b1;
      while (req) wait_ns(1);
      wait_ns(100);
      ack = 1'b0;
    end
  endtask

endmodule