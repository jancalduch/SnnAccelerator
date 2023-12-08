//====================================================================
//        Copyright (c) 2023 Nordic Semiconductor ASA, Norway
//====================================================================
// Created : jais at 2023-10-20
//====================================================================

program automatic testPrInferenceAll_SnnAccelerator (
  inTest_SnnAccelerator uin_SnnAccelerator
);
  
  initial begin 
    while (~uin_SnnAccelerator.SPI_config_rdy) wait_ns(1);

    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbStart("completeInference");  

    /*****************************************************************************************************************************************************************************************************************/
    /* Program Control Registers for Loading Weights */
    /*****************************************************************************************************************************************************************************************************************/
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("program registers");
    uin_SnnAccelerator.start_time = $time;
    
    //Disable network operation
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0 }), .data(20'b1                                             ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY 
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd3 }), .data(paTest_SnnAccelerator::SPI_MAX_NEUR               ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_MAX_NEUR
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd1 }), .data(paTest_SnnAccelerator::SPI_OPEN_LOOP              ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_OPEN_LOOP
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd2 }), .data(paTest_SnnAccelerator::SPI_AER_SRC_CTRL_nNEUR     ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_AER_SRC_CTRL_nNEUR

    /*****************************************************************************************************************************************************************************************************************/  
    /* Verify the Control Registers */
    /*****************************************************************************************************************************************************************************************************************/
    
    $display("----- Starting verification of programmed SNN control registers");

    assert(u_SnnAccelerator.la_Include.u_Core.spi_slave_0.SPI_GATE_ACTIVITY          ==  1'b1                                             ) else $fatal(0, "SPI_GATE_ACTIVITY parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_Core.spi_slave_0.SPI_MAX_NEUR               == paTest_SnnAccelerator::SPI_MAX_NEUR               ) else $fatal(0, "SPI_MAX_NEUR parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_Core.spi_slave_0.SPI_OPEN_LOOP              == paTest_SnnAccelerator::SPI_OPEN_LOOP              ) else $fatal(0, "SPI_OPEN_LOOP parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_Core.spi_slave_0.SPI_AER_SRC_CTRL_nNEUR     == paTest_SnnAccelerator::SPI_AER_SRC_CTRL_nNEUR     ) else $fatal(0, "SPI_AER_SRC_CTRL_nNEUR parameter not correct.");
        
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
    uin_SnnAccelerator.param_leak_str  = 7'd127;            // Set a leakage higher than the threshold, so a leakage event resets the potential of all neurons
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
            
        
    // Verify neurons
    if (paTest_SnnAccelerator::VERIFY_NEURON_MEMORY) begin
      $display("----- Starting verification of neuron memory in the SNN through SPI.");
      nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("verify neurons");

      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::SPI_MAX_NEUR; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
        for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<4; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
          uin_SnnAccelerator.neur_data       = uin_SnnAccelerator.neuron_pattern >> (uin_SnnAccelerator.j<<3);
          uin_SnnAccelerator.addr_temp[15:8] = uin_SnnAccelerator.j;    // Select a byte
          uin_SnnAccelerator.addr_temp[7:0]  = uin_SnnAccelerator.i;    // Select a word

          uin_SnnAccelerator.spi_read (.addr({1'b1,1'b0,2'b01,uin_SnnAccelerator.addr_temp[15:0]}), .data(uin_SnnAccelerator.spi_read_data), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); 
          assert(uin_SnnAccelerator.spi_read_data == {12'b0,uin_SnnAccelerator.neur_data[7:0]}) else $fatal(0, "Byte %d of neuron %d not written/read correctly.", uin_SnnAccelerator.j, uin_SnnAccelerator.i);
        end
      end
      $display("----- Ending verification of neuron memory in the SNN through SPI, no error found!");
    end else
      $display("----- Skipping verification of neuron memory in the SNN through SPI.");
        
        
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
    $display("----- Starting programmation of 256x10 synapses in the SNN through SPI.");
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("program synapses");
    for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::SPI_MAX_NEUR-1; uin_SnnAccelerator.i=uin_SnnAccelerator.i+2) begin
      for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<paTest_SnnAccelerator::N; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin

        uin_SnnAccelerator.addr_temp[ 12:5] = uin_SnnAccelerator.input_neurons[uin_SnnAccelerator.j][7:0];    // Choose word
        uin_SnnAccelerator.addr_temp[  4:0] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][7:3];   // Choose word
        uin_SnnAccelerator.addr_temp[14:13] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][2:1];   // Choose byte

        uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b10,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h00,{uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i+1][3:0], uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i][3:0]}}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));    // Synapse value = pre-synaptic neuron index 4 LSBs
      end
    end
    $display("----- Ending programmation of 256x10 synapses in the SNN through SPI.");
    uin_SnnAccelerator.end_time = $time;

    uin_SnnAccelerator.execution_time = uin_SnnAccelerator.end_time - uin_SnnAccelerator.start_time;
    $display("----- Programming execution time is %.4f ms", uin_SnnAccelerator.execution_time/1000000.0);

    // Verify synapse memory
    if (paTest_SnnAccelerator::VERIFY_ALL_SYNAPSES) begin
      $display("----- Starting verification of 256x10 synapses in the SNN through SPI.");
      nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("verify synapses");
      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::SPI_MAX_NEUR-1; uin_SnnAccelerator.i=uin_SnnAccelerator.i+2) begin
        for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<paTest_SnnAccelerator::N; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
          uin_SnnAccelerator.addr_temp[ 12:5] = uin_SnnAccelerator.input_neurons[uin_SnnAccelerator.j][7:0];    // Choose word
          uin_SnnAccelerator.addr_temp[  4:0] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][7:3];   // Choose word
          uin_SnnAccelerator.addr_temp[14:13] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][2:1];   // Choose byte
          uin_SnnAccelerator.spi_read (.addr({1'b1,1'b0,2'b10,uin_SnnAccelerator.addr_temp[15:0]}), .data(uin_SnnAccelerator.spi_read_data), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); 
          assert(uin_SnnAccelerator.spi_read_data == {12'b0,{uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i+1][3:0], uin_SnnAccelerator.weights[uin_SnnAccelerator.j][uin_SnnAccelerator.i][3:0]}}) else $fatal(0, "Byte %d of address %d not written/read correctly.", uin_SnnAccelerator.j, uin_SnnAccelerator.i);
        end
      end
      $display("----- Ending verification of 256x10 synapses in the SNN through SPI, no error found!");
    end else
      $display("----- Skipping verification of 256x10 synapses in the SNN through SPI.");

    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("Finished programming");
      
    /*****************************************************************************************************************************************************************************************************************/
    /* Inference */
    /*****************************************************************************************************************************************************************************************************************/
    
    //Start getting output AER evenst and don't monitor output spikes in the console
    uin_SnnAccelerator.auto_ack_verbose = 1'b0;
    fork
      uin_SnnAccelerator.auto_ack(.req(uin_SnnAccelerator.AEROUT_REQ), .ack(uin_SnnAccelerator.AEROUT_ACK), .addr(uin_SnnAccelerator.AEROUT_ADDR), .neur(uin_SnnAccelerator.aer_neur_spk), .verbose(uin_SnnAccelerator.auto_ack_verbose), .spike(uin_SnnAccelerator.spiked));
    join_none

    uin_SnnAccelerator.images_to_test = 10000;
    // Get test_lables and convert from ASCII char to int
    uin_SnnAccelerator.file_name = "/pro/sig_research/AI/work/jais/sproject/SnnAccelerator_top/projects/student/SnnAccelerator/sim/tb/test_labels.txt";
    uin_SnnAccelerator.parese_digits(.file_name (uin_SnnAccelerator.file_name), .digit_number(uin_SnnAccelerator.images_to_test));

    // Get Rank Order encoded data 
    
    uin_SnnAccelerator.file_name = "/pro/sig_research/AI/work/jais/sproject/SnnAccelerator_top/projects/student/SnnAccelerator/sim/tb/roc_test_images.txt";
    uin_SnnAccelerator.parese_roc_images(.file_name(uin_SnnAccelerator.file_name), .array_number(uin_SnnAccelerator.images_to_test), .array_depth(256));
    
    // --------------------------------------------------------------------------------- Do inference for all images in MNIST dataset ------------------------------------------

    uin_SnnAccelerator.best_time = 64'd1000000000000;
    uin_SnnAccelerator.worst_time = 0;
    uin_SnnAccelerator.total_time = 0;

    //Re-enable network operation 
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0}), .data(20'd0), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY (0)
    
    $display("----- Starting inference of all images");
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("start inference");

    uin_SnnAccelerator.total_correct_guesses = 0;
    for (uin_SnnAccelerator.img = 0; uin_SnnAccelerator.img < uin_SnnAccelerator.images_to_test; uin_SnnAccelerator.img = uin_SnnAccelerator.img + 1) begin
      
      uin_SnnAccelerator.start_time = $time;

      // Send two leakage event to all neurons to reset their potential (each event decreases 127 as leakage is 7 bits)
      uin_SnnAccelerator.aer_send (.addr_in({1'b0,1'b1,8'hFF}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ));
      uin_SnnAccelerator.aer_send (.addr_in({1'b0,1'b1,8'hFF}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ));

      // Perform inference of one image until the first OL neuron spikes
      fork
        uin_SnnAccelerator.detect_spike_update_metrics(.spiked(uin_SnnAccelerator.spiked), .first_spike(uin_SnnAccelerator.first_spike), .img(uin_SnnAccelerator.img));
      join_none

      uin_SnnAccelerator.rank_order = uin_SnnAccelerator.roc_test_images[uin_SnnAccelerator.img];
      for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<paTest_SnnAccelerator::N; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
        uin_SnnAccelerator.aer_send (.addr_in({1'b0,1'b0,uin_SnnAccelerator.rank_order[uin_SnnAccelerator.j][7:0]}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ));
        if (uin_SnnAccelerator.first_spike) begin
          uin_SnnAccelerator.end_time = $time;
          uin_SnnAccelerator.execution_time = uin_SnnAccelerator.end_time - uin_SnnAccelerator.start_time;
          uin_SnnAccelerator.time_array[uin_SnnAccelerator.img] = uin_SnnAccelerator.execution_time;

          if (uin_SnnAccelerator.execution_time > uin_SnnAccelerator.worst_time) begin 
            uin_SnnAccelerator.worst_time = uin_SnnAccelerator.execution_time;
            uin_SnnAccelerator.worst_time_image = uin_SnnAccelerator.img; 
          end
          if (uin_SnnAccelerator.execution_time < uin_SnnAccelerator.best_time) begin 
            uin_SnnAccelerator.best_time = uin_SnnAccelerator.execution_time;
            uin_SnnAccelerator.best_time_image = uin_SnnAccelerator.img;
          end
          uin_SnnAccelerator.total_time = uin_SnnAccelerator.total_time + uin_SnnAccelerator.execution_time;

          break;
        end
      end

      // Perform inference of one image
      // uin_SnnAccelerator.rank_order = uin_SnnAccelerator.roc_test_images[uin_SnnAccelerator.img];
      // for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<paTest_SnnAccelerator::N; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
      //   uin_SnnAccelerator.spiked = 1'b0;
      //   uin_SnnAccelerator.aer_send (.addr_in({1'b0,1'b0,uin_SnnAccelerator.rank_order[uin_SnnAccelerator.j][7:0]}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ));
      //   wait_ns(100);
      //   if (uin_SnnAccelerator.spiked) begin
      //     // $display("----- Digit should be %d and received %d", uin_SnnAccelerator.test_labels[uin_SnnAccelerator.img], uin_SnnAccelerator.aer_neur_spk); 
      //     if (uin_SnnAccelerator.aer_neur_spk==uin_SnnAccelerator.test_labels[uin_SnnAccelerator.img]) begin
      //       uin_SnnAccelerator.total_correct_guesses += 1;
      //     end else
      //       // $display("----- Indexed that failed is: %d", uin_SnnAccelerator.img);
          
      //     break;
      //   end
      // end

      if (uin_SnnAccelerator.img % 1000 == 0) $display("."); 

    end
    
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("finish inference");
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbStop();

    uin_SnnAccelerator.accuracy = real'(uin_SnnAccelerator.total_correct_guesses)*(100.0/real'(uin_SnnAccelerator.images_to_test)); 
    $display("----- Inference finished with a %.2f %% Accuracy!", uin_SnnAccelerator.accuracy); 
 
    uin_SnnAccelerator.average_time = uin_SnnAccelerator.total_time/(1000.0*real'(uin_SnnAccelerator.images_to_test));
    $display("----- Average execution time is %.4f us", uin_SnnAccelerator.average_time);
    $display("----- Best execution time is image %d with %.4f us", uin_SnnAccelerator.best_time_image, (uin_SnnAccelerator.best_time/1000.0));
    $display("----- Worst execution time is image %d with %.4f us", uin_SnnAccelerator.worst_time_image, (uin_SnnAccelerator.worst_time/1000.0));
     
    uin_SnnAccelerator.time_array.sort();
    $display("----- Median execution time is %.4f us", (uin_SnnAccelerator.time_array[5000]/1000.0));
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

