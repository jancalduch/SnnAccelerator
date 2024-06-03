program automatic testPrInference_SnnAccelerator (
  inTest_SnnAccelerator uin_SnnAccelerator
);

  initial begin 
    while (~uin_SnnAccelerator.SPI_config_rdy) wait_ns(1);

    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbStart("singleInference");  
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("configure registers");

    /*****************************************************************************************************************************************************************************************************************/
    /* Program Control Registers for Loading Weights */
    /*****************************************************************************************************************************************************************************************************************/
    //Disable network operation
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0 }), .data(20'b1                                             ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY 
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd3 }), .data(paTest_SnnAccelerator::SPI_MAX_NEUR               ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_MAX_NEUR
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd1 }), .data(paTest_SnnAccelerator::SPI_OPEN_LOOP              ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_OPEN_LOOP
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd2 }), .data(paTest_SnnAccelerator::SPI_AER_SRC_CTRL_nNEUR     ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_AER_SRC_CTRL_nNEUR

    /*****************************************************************************************************************************************************************************************************************/  
    /* Verify the Control Registers */
    /*****************************************************************************************************************************************************************************************************************/
    
    $display("----- Starting verification of programmed SNN control registers");

    assert(u_SnnAccelerator.la_Include.u_cop.u_Core.spi_slave_0.SPI_GATE_ACTIVITY          ==  1'b1                                             ) else $fatal(0, "SPI_GATE_ACTIVITY parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_cop.u_Core.spi_slave_0.SPI_MAX_NEUR               == paTest_SnnAccelerator::SPI_MAX_NEUR               ) else $fatal(0, "SPI_MAX_NEUR parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_cop.u_Core.spi_slave_0.SPI_OPEN_LOOP              == paTest_SnnAccelerator::SPI_OPEN_LOOP              ) else $fatal(0, "SPI_OPEN_LOOP parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_cop.u_Core.spi_slave_0.SPI_AER_SRC_CTRL_nNEUR     == paTest_SnnAccelerator::SPI_AER_SRC_CTRL_nNEUR     ) else $fatal(0, "SPI_AER_SRC_CTRL_nNEUR parameter not correct.");
        
    $display("----- Ending verification of programmed SNN control registers, no error found!");
        
    uin_SnnAccelerator.SPI_param_checked = 1'b1;
    
    while (~uin_SnnAccelerator.SNN_initialized_rdy) wait_ns(1);
        
    /*****************************************************************************************************************************************************************************************************************/
    /* Program Neuron Memory: disable - leak - thr - state */
    /*****************************************************************************************************************************************************************************************************************/
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("program neurons");

    // Initializing all neurons to zero
    $display("----- Disabling neurons 0 to 255.");   
    for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::N; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
      uin_SnnAccelerator.addr_temp[15:8] = 3;   // Programming only last byte for disabling a neuron
      uin_SnnAccelerator.addr_temp[7:0]  = uin_SnnAccelerator.i;   // Doing so for all neurons
      uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b01,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h7F,8'h80}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
    end
    $display("----- Disabling neurons done...");

    $display("----- Starting programming of 10 first neurons in neuron memory in the SNN through SPI.");
    uin_SnnAccelerator.param_leak_str  = 7'd0;
    uin_SnnAccelerator.param_thr       = $signed( 12'd222);
    uin_SnnAccelerator.mem_init        = $signed( 12'd0);
    
    uin_SnnAccelerator.neuron_pattern = {1'b0, uin_SnnAccelerator.param_leak_str, uin_SnnAccelerator.param_thr, uin_SnnAccelerator.mem_init};

    for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::SPI_MAX_NEUR; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
      for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<4; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
        uin_SnnAccelerator.neur_data       = uin_SnnAccelerator.neuron_pattern >> (uin_SnnAccelerator.j<<3);
        uin_SnnAccelerator.addr_temp[15:8] = uin_SnnAccelerator.j;    // Select a byte
        uin_SnnAccelerator.addr_temp[7:0]  = uin_SnnAccelerator.i;    // Select a word
        uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b01,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h00,uin_SnnAccelerator.neur_data[7:0]}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
      end
    end
    $display("----- Ending programming of 10 first neurons in neuron memory in the SNN through SPI.");
            
    /* Verify Neuron memory*/
    if (paTest_SnnAccelerator::VERIFY_NEURON_MEMORY) begin
      nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("verify neurons");
      $display("----- Starting verification of neuron memory in the SNN through SPI.");

      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::SPI_MAX_NEUR; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
        for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<4; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
          uin_SnnAccelerator.neur_data       = uin_SnnAccelerator.neuron_pattern >> (uin_SnnAccelerator.j<<3);
          uin_SnnAccelerator.addr_temp[15:8] = uin_SnnAccelerator.j;    // Select a byte
          uin_SnnAccelerator.addr_temp[7:0]  = uin_SnnAccelerator.i;    // Select a word
          uin_SnnAccelerator.spi_read (.addr({1'b1,1'b0,2'b01,uin_SnnAccelerator.addr_temp[15:0]}), .data(uin_SnnAccelerator.spi_read_data), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
          // $display("----- Should have read %d and got %d", uin_SnnAccelerator.neur_data[7:0], uin_SnnAccelerator.spi_read_data); 
          assert(uin_SnnAccelerator.spi_read_data == {12'b0,uin_SnnAccelerator.neur_data[7:0]}) else $fatal(0, "Byte %d of neuron %d not written/read correctly.", uin_SnnAccelerator.j, uin_SnnAccelerator.i);
        end
      end
      $display("----- Ending verification of neuron memory in the SNN through SPI, no error found!");
    end else
      $display("----- Skipping verification of neuron memory in the SNN through SPI.");

    // $stop;  

    /*****************************************************************************************************************************************************************************************************************/
    /* Program Synapse Memory */
    /*****************************************************************************************************************************************************************************************************************/

    uin_SnnAccelerator.file_name = "/pro/sig_research/AI/work/jais/sproject/SnnAccelerator_top/projects/student/SnnAccelerator/sim/tb/weights.txt";
    uin_SnnAccelerator.parese_weights(uin_SnnAccelerator.file_name, 256, 10);

    uin_SnnAccelerator.target_neurons = '{9,8,7,6,5,4,3,2,1,0};
    uin_SnnAccelerator.input_neurons  = '{255,254,253,252,251,250,249,248,247,246,245,244,243,242,241,240,239,238,237,236,235,234,233,232,231,230,
                                          229,228,227,226,225,224,223,222,221,220,219,218,217,216,215,214,213,212,211,210,209,208,207,206,205,
                                          204,203,202,201,200,199,198,197,196,195,194,193,192,191,190,189,188,187,186,185,184,183,182,181,180,
                                          179,178,177,176,175,174,173,172,171,170,169,168,167,166,165,164,163,162,161,160,159,158,157,156,155,
                                          154,153,152,151,150,149,148,147,146,145,144,143,142,141,140,139,138,137,136,135,134,133,132,131,130,
                                          129,128,127,126,125,124,123,122,121,120,119,118,117,116,115,114,113,112,111,110,109,108,107,106,105,
                                          104,103,102,101,100,99,98,97,96,95,94,93,92,91,90,89,88,87,86,85,84,83,82,81,80,
                                          79,78,77,76,75,74,73,72,71,70,69,68,67,66,65,64,63,62,61,60,59,58,57,56,55,
                                          54,53,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,
                                          29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,
                                          4,3,2,1,0};
    // Programming synapses
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("program synapses");
    $display("----- Starting programmation of 256x10 synapses in the SNN through SPI.");
    for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::SPI_MAX_NEUR-1; uin_SnnAccelerator.i=uin_SnnAccelerator.i+2) begin
      for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<paTest_SnnAccelerator::N; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin

        uin_SnnAccelerator.addr_temp[ 12:5] = uin_SnnAccelerator.input_neurons[uin_SnnAccelerator.j][7:0];    // Choose word
        uin_SnnAccelerator.addr_temp[  4:0] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][7:3];   // Choose word
        uin_SnnAccelerator.addr_temp[14:13] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][2:1];   // Choose byte

        uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b10,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h00,{uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i+1][3:0], uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i][3:0]}}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));    // Synapse value = pre-synaptic neuron index 4 LSBs
      end
    end
    $display("----- Ending programmation of 256x10 synapses in the SNN through SPI.");

            
    /* Verify Synapse Memory */
    if (paTest_SnnAccelerator::VERIFY_ALL_SYNAPSES) begin
      nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("verify synapses");
      $display("----- Starting verification of 256x10 synapses in the SNN through SPI.");
      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::SPI_MAX_NEUR-1; uin_SnnAccelerator.i=uin_SnnAccelerator.i+2) begin
        for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<paTest_SnnAccelerator::N; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
          uin_SnnAccelerator.addr_temp[ 12:5] = uin_SnnAccelerator.input_neurons[uin_SnnAccelerator.j][7:0];    // Choose word
          uin_SnnAccelerator.addr_temp[  4:0] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][7:3];   // Choose word
          uin_SnnAccelerator.addr_temp[14:13] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][2:1];   // Choose byte
          uin_SnnAccelerator.spi_read (.addr({1'b1,1'b0,2'b10,uin_SnnAccelerator.addr_temp[15:0]}), .data(uin_SnnAccelerator.spi_read_data), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); 
          // $display("----- Should have read %d and got %d", {uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i+1][3:0], uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i][3:0]}, uin_SnnAccelerator.spi_read_data); 
          assert(uin_SnnAccelerator.spi_read_data == {12'b0,{uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i+1][3:0], uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i][3:0]}}) else $fatal(0, "Byte %d of address %d not written/read correctly.", uin_SnnAccelerator.j, uin_SnnAccelerator.i);
        end
      end
      $display("----- Ending verification of 256x10 synapses in the SNN through SPI, no error found!");
    end else
      $display("----- Skipping verification of 256x10 synapses in the SNN through SPI.");

      
    /*****************************************************************************************************************************************************************************************************************/
    /* Inference */
    /*****************************************************************************************************************************************************************************************************************/

    //Re-enable network operation 
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0}), .data(20'd0), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY (0)

    if (paTest_SnnAccelerator::DO_CLOSED_LOOP) begin
      uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd1}), .data(20'b0), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_OPEN_LOOP (0)
    end

    $display("----- Starting inference of a single image");

    // IMAGE to send
    uin_SnnAccelerator.IMAGE = '{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 32, 81, 1, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 38, 174, 244, 101, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 53, 187, 
    243, 239, 190, 75, 2, 0, 0, 0, 0, 0, 0, 0, 0, 25, 185, 111, 98, 219, 222, 
    71, 6, 0, 0, 0, 0, 0, 0, 0, 26, 120, 127, 20, 100, 228, 149, 27, 0, 0, 0, 0, 
    0, 0, 0, 0, 24, 214, 163, 183, 192, 227, 120, 0, 0, 0, 0, 0, 0, 0, 0, 1, 55, 
    164, 188, 83, 82, 170, 104, 12, 0, 0, 0, 0, 0, 0, 0, 1, 10, 35, 17, 4, 51, 
    185, 93, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 180, 77, 4, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 3, 50, 159, 98, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    24, 174, 64, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 45, 97, 38, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("start inference");

    // -----------------------------
    // -- SEND DATA
    // -----------------------------

    // Send image through AXI byte by byte
    for (int address = 0; address < paTest_SnnAccelerator::IMAGE_SIZE; address++) begin
      uin_SnnAccelerator.axi4l_write(address, uin_SnnAccelerator.IMAGE[address]);
    end
    // Notify that image is fully sent
    uin_SnnAccelerator.axi4l_write(256, 1);
    uin_SnnAccelerator.axi4l_write(256, 0);
    
    // -----------------------------
    // -- READ DATA
    // -----------------------------
    // Wait for interrupt and then read data
    wait(uin_SnnAccelerator.COPROCESSOR_RDY);
    uin_SnnAccelerator.axi4l_read(5, uin_SnnAccelerator.read_data);
    
    $display("INFERED DIGIT IS %d and should be 9.", uin_SnnAccelerator.read_data[7:0]);

    uin_SnnAccelerator.read_data = 32'h0;

    $display("----- Test Finished"); 
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbStop();
    wait_ns(500);
    $finish;
        
  end


  // -----------------------------
  // -- Tasks
  // -----------------------------

  // SIMPLE TIME-HANDLING TASKS
  task wait_ns;
    input   tics_ns;
    integer tics_ns;
    #tics_ns;
  endtask
endprogram
