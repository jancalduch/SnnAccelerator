//====================================================================
//        Copyright (c) 2023 Nordic Semiconductor ASA, Norway
//====================================================================
// Created : hedi at 2023-09-28
//====================================================================

module decoder_tb ();

  localparam N = 256;
  localparam M = $clog2(N); 

  // ------------------------------
  // -- Logic
  // ------------------------------
  logic            decoder_ready;
  
  logic            CLK;
  logic            RST;
  logic            NEW_IMAGE;
	logic  [  M-1:0] AEROUT_ADDR; 
	logic  	         AEROUT_REQ;
	logic            AEROUT_ACK;
  logic            INFERENCE_DONE;
  logic  [  M-1:0] INFERED_DIGIT;

  // ------------------------------
  // -- Init
  // ------------------------------

  initial begin
    decoder_ready = 1'b0;

    AEROUT_REQ    = 1'b0;
    NEW_IMAGE     = 1'b0;
  end

  // ------------------------------
  // -- Clock and Reset
  // ------------------------------

  initial begin
    CLK = 1'b1;      // Start simualtion low to avoid false positives on $hold vhecks. 
    forever begin
      wait_ns(4);
        CLK = ~CLK;
      end
  end

  initial begin
    wait_ns(0.1);
    RST = 1'b0;
    wait_ns(10);
    RST = 1'b1;
    wait_ns(10);
    RST = 1'b0;
    wait_ns(10);
    decoder_ready = 1'b1;
  end
  
  // ------------------------------
  // -- DUT and assignments
  // ------------------------------
  decoder u_SnnDecoder (
    // Global input
    .CLK            ( CLK             ),
    .RST            ( RST             ),

    // Control signals 
    .NEW_IMAGE      ( NEW_IMAGE       ),
    // AER link
    .AEROUT_ADDR    ( AEROUT_ADDR     ),
    .AEROUT_REQ     ( AEROUT_REQ      ),
    .AEROUT_ACK     ( AEROUT_ACK      ),

    // Interrupt signal
    .INFERENCE_DONE ( INFERENCE_DONE  ),

    // Output value
    .INFERED_DIGIT  ( INFERED_DIGIT   )

  );

  // ------------------------------
  // -- Test program
  // ------------------------------

  initial begin
    while (~decoder_ready) wait_ns(1);

    wait_ns(2);

    // Send a first value
    send_aer(1, .AEROUT_ADDR(AEROUT_ADDR), .AEROUT_REQ(AEROUT_REQ));
    wait_ack(.AEROUT_ACK(AEROUT_ACK), .AEROUT_REQ(AEROUT_REQ));

    // Send a second value and check that it is not stored
    send_aer(3, .AEROUT_ADDR(AEROUT_ADDR), .AEROUT_REQ(AEROUT_REQ));
    wait_ack(.AEROUT_ACK(AEROUT_ACK), .AEROUT_REQ(AEROUT_REQ));

    // -------------------------------------------------------------------------------------------
    // New image
    send_new_image(.NEW_IMAGE(NEW_IMAGE));

    // Send a first value
    send_aer(2, .AEROUT_ADDR(AEROUT_ADDR), .AEROUT_REQ(AEROUT_REQ));
    wait_ack(.AEROUT_ACK(AEROUT_ACK), .AEROUT_REQ(AEROUT_REQ));

    // Send a second and immediately change to next image
    send_aer(7, .AEROUT_ADDR(AEROUT_ADDR), .AEROUT_REQ(AEROUT_REQ));
    wait_ack(.AEROUT_ACK(AEROUT_ACK), .AEROUT_REQ(AEROUT_REQ));
    
    // Send a second and immediately change to next image
    send_aer(9, .AEROUT_ADDR(AEROUT_ADDR), .AEROUT_REQ(AEROUT_REQ));
    wait_ack(.AEROUT_ACK(AEROUT_ACK), .AEROUT_REQ(AEROUT_REQ));
    
    // Send a second and immediately change to next image
    send_aer(8, .AEROUT_ADDR(AEROUT_ADDR), .AEROUT_REQ(AEROUT_REQ));
    wait_ack(.AEROUT_ACK(AEROUT_ACK), .AEROUT_REQ(AEROUT_REQ));
    
    // -------------------------------------------------------------------------------------------
    // New image
    send_new_image(.NEW_IMAGE(NEW_IMAGE));
    wait_ns(6);
    // Send a first value
    send_aer(4, .AEROUT_ADDR(AEROUT_ADDR), .AEROUT_REQ(AEROUT_REQ));
    wait_ack(.AEROUT_ACK(AEROUT_ACK), .AEROUT_REQ(AEROUT_REQ));

    // Send a second and immediately change to next image
    send_aer(5, .AEROUT_ADDR(AEROUT_ADDR), .AEROUT_REQ(AEROUT_REQ));
    NEW_IMAGE = 1'b0;

    wait_ns(20);
    $finish;

  end

  // SIMPLE TIME-HANDLING TASKS
  task wait_ns;
    input   tics_ns;
    integer tics_ns;
    #tics_ns;
  endtask

  // SEND VALUE THROUGH AER TASK
  task automatic send_aer(
    input logic [M-1:0] aer_address,
    ref   logic [M-1:0] AEROUT_ADDR,
    ref   logic         AEROUT_REQ
  );
    AEROUT_ADDR = aer_address;
    AEROUT_REQ = 1'b1;
  endtask

  // WAIT for ACK TASK
  task automatic wait_ack(
    ref logic AEROUT_REQ,
    ref logic AEROUT_ACK
  );
    while (~AEROUT_ACK) wait_ns(1);
    AEROUT_REQ = 1'b0;
    wait_ns(6);
  endtask

  // SEND NEW IMAGE signal TASK
  task automatic send_new_image(
    ref logic NEW_IMAGE
  );
    NEW_IMAGE     = 1'b1;
    wait_ns(4);
    NEW_IMAGE     = 1'b0;
  endtask

endmodule