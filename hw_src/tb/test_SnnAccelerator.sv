//====================================================================
//        Copyright (c) 2023 Nordic Semiconductor ASA, Norway
//====================================================================
// Created : hedi at 2023-09-28
//====================================================================

module test_SnnAccelerator ();

  // ------------------------------
  // -- Local parameters
  // ------------------------------

  //localparam real T_CK16M = 62.5ns;


  // ------------------------------
  // -- Interfaces
  // ------------------------------

  inTest_SnnAccelerator uin_SnnAccelerator();

  // ------------------------------
  // -- Logic
  // ------------------------------

  // ------------------------------
  // -- Init
  // ------------------------------

  initial begin
    uin_SnnAccelerator.SCK         =  1'b0;
    uin_SnnAccelerator.MOSI        =  1'b0;
    uin_SnnAccelerator.AERIN_ADDR  = 10'b0;
    uin_SnnAccelerator.AERIN_REQ   =  1'b0;
    uin_SnnAccelerator.AEROUT_ACK  =  1'b0;

    uin_SnnAccelerator.SPI_config_rdy      = 1'b0;
    uin_SnnAccelerator.SPI_param_checked   = 1'b0;
    uin_SnnAccelerator.SNN_initialized_rdy = 1'b0;
    uin_SnnAccelerator.auto_ack_verbose    = 1'b0;
  end

  // ------------------------------
  // -- Clock and Reset
  // ------------------------------

  initial begin
    uin_SnnAccelerator.CLK = 1'b1;      // Start simualtion low to avoid false positives on $hold vhecks. 
    forever begin
      wait_ns(paTest_SnnAccelerator::CLK_HALF_PERIOD);
        uin_SnnAccelerator.CLK = ~uin_SnnAccelerator.CLK;
      end
  end

  initial begin
    wait_ns(0.1);
    uin_SnnAccelerator.RST = 1'b0;
    wait_ns(100);
    uin_SnnAccelerator.RST = 1'b1;
    wait_ns(100);
    uin_SnnAccelerator.RST = 1'b0;
    wait_ns(100);
    uin_SnnAccelerator.SPI_config_rdy = 1'b1;
    while (~uin_SnnAccelerator.SPI_param_checked) wait_ns(1);
    wait_ns(100);
    uin_SnnAccelerator.RST = 1'b1;
    wait_ns(100);
    uin_SnnAccelerator.RST = 1'b0;
    wait_ns(100);
    uin_SnnAccelerator.SNN_initialized_rdy = 1'b1;
  end
  

  // ------------------------------
  // -- DUT and assignments
  // ------------------------------
  SnnAccelerator u_SnnAccelerator (
    // Global input
    .CLK            ( uin_SnnAccelerator.CLK          ),
    .RST            ( uin_SnnAccelerator.RST          ),

    // SPI slave
    .SCK            ( uin_SnnAccelerator.SCK          ),
    .MOSI           ( uin_SnnAccelerator.MOSI         ),
    .MISO           ( uin_SnnAccelerator.MISO         ),

    // Input 10-bit AER
    .AERIN_ADDR     ( uin_SnnAccelerator.AERIN_ADDR   ),
    .AERIN_REQ      ( uin_SnnAccelerator.AERIN_REQ    ),
    .AERIN_ACK      ( uin_SnnAccelerator.AERIN_ACK    ),

    // Output 8-bit AER
    .AEROUT_ADDR    ( uin_SnnAccelerator.AEROUT_ADDR  ),
    .AEROUT_REQ     ( uin_SnnAccelerator.AEROUT_REQ   ),
    .AEROUT_ACK     ( uin_SnnAccelerator.AEROUT_ACK   ),

    // Debug
    .SCHED_FULL     ( uin_SnnAccelerator.SCHED_FULL   )

  );

  // ------------------------------
  // -- Concurrent assertions
  // ------------------------------

  // assertions_SnnAccelerator u_assertions(
  //   .uin_SnnAccelerator (uin_SnnAccelerator)
  // );

  // // OR

  // bind u_SnnAccelerator assertions_SnnAccelerator bind_assertions_SnnAccelerator (
  //   .* // Connect the signals in the design of the same name
  // );


  // ------------------------------
  // -- Test program
  // ------------------------------

  testPrInferenceAll_SnnAccelerator u_testPr(
    .uin_SnnAccelerator (uin_SnnAccelerator)
  );

  // testPrInference_SnnAccelerator u_testPr(
  //   .uin_SnnAccelerator (uin_SnnAccelerator)
  // );

  // SIMPLE TIME-HANDLING TASKS
  task wait_ns;
    input   tics_ns;
    integer tics_ns;
    #tics_ns;
  endtask


endmodule