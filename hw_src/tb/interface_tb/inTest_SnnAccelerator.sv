//====================================================================
//        Copyright (c) 2023 Nordic Semiconductor ASA, Norway
//====================================================================
// Created : hedi at 2023-09-28
//====================================================================

interface inTest_SnnAccelerator;

  // -----------------------------
  // -- Testbench
  // -----------------------------
  logic SPI_config_rdy;
  logic SPI_param_checked;
  logic SNN_initialized_rdy;

  logic [    31:0] synapse_pattern , syn_data;
  logic [    31:0] neuron_pattern  , neur_data;
  logic [    31:0] shift_amt;
  logic [    15:0] addr_temp;

  logic [    19:0] spi_read_data;

  logic        [ 6:0] param_leak_str;
  logic signed [11:0] param_thr;
  logic signed [11:0] mem_init;


  // integer target_neurons[15:0];
  // integer input_neurons[15:0];

  integer target_neurons[9:0];
  integer input_neurons[255:0];
  
  integer weights[0:255][0:9];
  integer roc_test_images[0:10000][0:255];
  integer rank_order[0:255];
  integer test_labels[0:10000];
  integer test_images[0:10000][0:255];
  integer test_image[0:255];

  integer failed_images[0:1740];
  integer fail_cnt;

  integer images_to_test;
  integer total_correct_guesses;
  real accuracy;

  logic [7:0] aer_neur_spk;

  logic signed [11:0] vcore[255:0];
  integer time_window_check;
  logic auto_ack_verbose;
  logic spiked, first_spike;

  integer i,j,k,n, img;
  integer phase;

  string file_name;
  integer file;
  integer num_items;
  integer value;
  integer values;

  real start_time, end_time, execution_time, total_time, worst_time, best_time, median_time, average_time;
  real axi_write_time;
  integer best_time_image, worst_time_image;
  real time_array[10000];

  logic [31:0] read_data;
  logic COPROCESSOR_RDY;

  logic [paTest_SnnAccelerator::PIXEL_BITS-1:0] IMAGE [0:paTest_SnnAccelerator::IMAGE_SIZE-1];

  // -----------------------------
  // -- DUT IO
  // -----------------------------

  logic                                CLK;
  logic                                RST;
  logic                                SCK;
  logic                                MOSI;
  logic                                MISO;
  wire                                 SCHED_FULL;

  logic [pa_SnnAccelerator::AXI_ADDR_WIDTH-1:0] AWADDR;       // Write address
  logic [2:0]                                   AWPROT;       // Write protection signals
  logic                                         AWVALID;      // Write address valid
  logic                                         AWREADY;      // Write address ready

  logic [pa_SnnAccelerator::AXI_DATA_WIDTH-1:0] WDATA;        // Write data
  logic [3:0]                                   WSTRB;        // Write byte strobes
  logic                                         WVALID;       // Write data valid
  logic                                         WREADY;       // Write data ready

  logic [1:0]                                   BRESP;        // Write response
  logic                                         BVALID;       // Write response valid
  logic                                         BREADY;       // Write response ready

  logic [pa_SnnAccelerator::AXI_ADDR_WIDTH-1:0] ARADDR;       // Read address
  logic [2:0]                                   ARPROT;       // Read protection signals
  logic                                         ARVALID;      // Read address valid
  logic                                         ARREADY;      // Read address ready

  logic [pa_SnnAccelerator::AXI_DATA_WIDTH-1:0] RDATA;        // Read data
  logic [1:0]                                   RRESP;        // Read response
  logic                                         RVALID;       // Read data valid
  logic                                         RREADY;       // Read data ready

  // -----------------------------
  // -- TASKS
  // -----------------------------

  //AER send event
  task automatic aer_send (
    input  logic [paTest_SnnAccelerator::M+1:0] addr_in,
    ref    logic [paTest_SnnAccelerator::M+1:0] addr_out,
    ref    logic          ack,
    ref    logic          req);
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
    ref    logic       spike);
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

  // Detect when a neurons spikes and update the metrics accordingly
  task automatic detect_spike_update_metrics (
    ref logic spiked,
    ref logic first_spike,
    ref integer img);
    first_spike = 1'b0;
    while((spiked) != 1'b1) wait_ns(1);
    // $display("----- Digit should be %d and received %d for image %d", uin_SnnAccelerator.test_labels[img], uin_SnnAccelerator.aer_neur_spk, img);
    first_spike = 1'b1; 
    if (uin_SnnAccelerator.aer_neur_spk==uin_SnnAccelerator.test_labels[img]) begin
      uin_SnnAccelerator.total_correct_guesses += 1;
    end 
  endtask

  //SPI send data
  task automatic spi_send (
    input  logic [19:0] addr,
    input  logic [19:0] data,
    input  logic        MISO, // not used
    ref    logic        MOSI,
    ref    logic        SCK);
    integer i;
    for (i=0; i<20; i=i+1) begin
      MOSI = addr[19-i];
      wait_ns(paTest_SnnAccelerator::SCK_HALF_PERIOD);
      SCK  = 1'b1;
      wait_ns(paTest_SnnAccelerator::SCK_HALF_PERIOD);
      SCK  = 1'b0;
    end
    for (i=0; i<20; i=i+1) begin
      MOSI = data[19-i];
      wait_ns(paTest_SnnAccelerator::SCK_HALF_PERIOD);
      SCK  = 1'b1;
      wait_ns(paTest_SnnAccelerator::SCK_HALF_PERIOD);
      SCK  = 1'b0;
    end
  endtask

  //SPI read data
  task automatic spi_read (
    input  logic [19:0] addr,
    output logic [19:0] data,
    ref    logic        MISO,
    ref    logic        MOSI,
    ref    logic        SCK);
    integer i;
    for (i=0; i<20; i=i+1) begin
      MOSI = addr[19-i];
      wait_ns(paTest_SnnAccelerator::SCK_HALF_PERIOD);
      SCK  = 1'b1;
      wait_ns(paTest_SnnAccelerator::SCK_HALF_PERIOD);
      SCK  = 1'b0;
    end
    for (i=0; i<20; i=i+1) begin
      wait_ns(paTest_SnnAccelerator::SCK_HALF_PERIOD);
      data = {data[18:0],MISO};
      SCK  = 1'b1;
      wait_ns(paTest_SnnAccelerator::SCK_HALF_PERIOD);
      SCK  = 1'b0;
    end
  endtask

  // Write to AXI Slave
  task axi4l_write;
    input [31:0] addr;
    input [31:0] data;
    begin
      AWADDR  <= addr;  //Put write address on bus
      AWVALID <= 1'b1;  //indicate address is valid

      WDATA   <= data;  //put write data on bus
      WVALID  <= 1'b1;  //indicate data is valid
      WSTRB   <= 4'h1;  //writing 1st byte
  
      BREADY  <= 1'b1;  //indicate ready for a response
      
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

  // Read from AXI Slave
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
  endtask;
  
  // Parse digits one after the other
  task parese_digits (
    input string file_name,
    input integer digit_number);
    
    uin_SnnAccelerator.file = $fopen(file_name, "r");
    if (uin_SnnAccelerator.file != 0) begin
      for (int i = 0; i < digit_number; i = i + 1) begin
        uin_SnnAccelerator.num_items = $fscanf(uin_SnnAccelerator.file, "%c", uin_SnnAccelerator.test_labels[i]);
        uin_SnnAccelerator.test_labels[i] = uin_SnnAccelerator.test_labels[i] - "0";
        // $display("Read label in iteration %d is %d", i, uin_SnnAccelerator.test_labels[i]);
        if (uin_SnnAccelerator.num_items == 0)
          break;
      end
    end else begin
      $display("Error opening the file");
    end
  endtask

  // Parse roc images separated by new line
  task automatic parese_roc_images (
    input string file_name,
    input integer array_number,
    input integer array_depth);

    uin_SnnAccelerator.file = $fopen(file_name, "r");
    if (uin_SnnAccelerator.file != 0) begin
      // Read and parse the text file
      for (int i = 0; i < array_number; i++) begin
        for (int j = 0; j < array_depth; j++) begin
          if (j < 1)
            $fscanf(uin_SnnAccelerator.file, "[%d, ", uin_SnnAccelerator.roc_test_images[i][j]);
          else if (j < array_depth-1)
            $fscanf(uin_SnnAccelerator.file, "%d, ", uin_SnnAccelerator.roc_test_images[i][j]);
          else
            $fscanf(uin_SnnAccelerator.file, "%d]", uin_SnnAccelerator.roc_test_images[i][j]);
          // $display("Read: roc_test_images[%0d][%0d] = %0d", i, j, uin_SnnAccelerator.roc_test_images[i][j]);
        end
        // Read and Consume the newline character
        $fgetc(uin_SnnAccelerator.file);
      end

      $fclose(uin_SnnAccelerator.file);

    end else begin
      $display("Error opening the file");
    end
  endtask

  // Parse images separated by new line
  task automatic parese_images (
    input string file_name,
    input integer array_number,
    input integer array_depth);

    uin_SnnAccelerator.file = $fopen(file_name, "r");
    if (uin_SnnAccelerator.file != 0) begin
      // Read and parse the text file
      for (int i = 0; i < array_number; i++) begin
        for (int j = 0; j < array_depth; j++) begin
          if (j < 1)
            $fscanf(uin_SnnAccelerator.file, "[%d, ", uin_SnnAccelerator.test_images[i][j]);
          else if (j < array_depth-1)
            $fscanf(uin_SnnAccelerator.file, "%d, ", uin_SnnAccelerator.test_images[i][j]);
          else
            $fscanf(uin_SnnAccelerator.file, "%d]", uin_SnnAccelerator.test_images[i][j]);
          // $display("Read: test_images[%0d][%0d] = %0d", i, j, uin_SnnAccelerator.test_images[i][j]);
        end
        // Read and Consume the newline character
        $fgetc(uin_SnnAccelerator.file);
      end

      $fclose(uin_SnnAccelerator.file);

    end else begin
      $display("Error opening the file");
    end
  endtask

  // Parse weight matrix
  task parese_weights (
    input string file_name,
    input integer array_number,
    input integer array_depth);

    uin_SnnAccelerator.file = $fopen(file_name, "r");
    if (uin_SnnAccelerator.file != 0) begin
      // Read and parse the text file
      for (int i = 0; i < array_number; i++) begin
        for (int j = 0; j < array_depth; j++) begin
          if (j < 1)
            $fscanf(uin_SnnAccelerator.file, "[%d, ", uin_SnnAccelerator.weights[i][j]);
          else if (j < array_depth-1)
            $fscanf(uin_SnnAccelerator.file, "%d, ", uin_SnnAccelerator.weights[i][j]);
          else
            $fscanf(uin_SnnAccelerator.file, "%d]", uin_SnnAccelerator.weights[i][j]);
          // $display("Read: weights[%0d][%0d] = %0d", i, j, uin_SnnAccelerator.weights[i][j]);
        end
        // Read and Consume the newline character
        $fgetc(uin_SnnAccelerator.file);
      end

      $fclose(uin_SnnAccelerator.file);

    end else begin
      $display("Error opening the file");
    end
  endtask

endinterface
