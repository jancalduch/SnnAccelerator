//====================================================================
//        Copyright (c) 2023 Nordic Semiconductor ASA, Norway
//====================================================================
// Created : hedi at 2023-09-28
//====================================================================

program automatic testPr_SnnAccelerator (
  inTest_SnnAccelerator uin_SnnAccelerator
);

  // -----------------------------
  // -- Localparams
  // -----------------------------


  // -----------------------------
  // -- Initial
  // -----------------------------


  // -----------------------------
  // -- Main Stimulus
  // -----------------------------


  initial begin
    while (~uin_SnnAccelerator.SPI_config_rdy) wait_ns(1);

    /*****************************************************************************************************************************************************************************************************************
                                                                          PROGRAMMING THE CONTROL REGISTERS AND NEURON PARAMETERS THROUGH 19-bit SPI
    *****************************************************************************************************************************************************************************************************************/

    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0 }), .data(20'b1                                             ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd1 }), .data(paTest_SnnAccelerator::SPI_OPEN_LOOP              ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_OPEN_LOOP
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd2 }), .data(paTest_SnnAccelerator::SPI_AER_SRC_CTRL_nNEUR     ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_AER_SRC_CTRL_nNEUR
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd3 }), .data(paTest_SnnAccelerator::SPI_MAX_NEUR               ), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_MAX_NEUR


    /*****************************************************************************************************************************************************************************************************************
                                                                                                VERIFY THE NEURON PARAMETERS
    *****************************************************************************************************************************************************************************************************************/

    $display("----- Starting verification of programmed SNN parameters");

    assert(u_SnnAccelerator.la_Include.u_Core.spi_slave_0.SPI_GATE_ACTIVITY          ==  1'b1                                             ) else $fatal(0, "SPI_GATE_ACTIVITY parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_Core.spi_slave_0.SPI_OPEN_LOOP              == paTest_SnnAccelerator::SPI_OPEN_LOOP              ) else $fatal(0, "SPI_OPEN_LOOP parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_Core.spi_slave_0.SPI_AER_SRC_CTRL_nNEUR     == paTest_SnnAccelerator::SPI_AER_SRC_CTRL_nNEUR     ) else $fatal(0, "SPI_AER_SRC_CTRL_nNEUR parameter not correct.");
    assert(u_SnnAccelerator.la_Include.u_Core.spi_slave_0.SPI_MAX_NEUR               == paTest_SnnAccelerator::SPI_MAX_NEUR               ) else $fatal(0, "SPI_MAX_NEUR parameter not correct.");

    $display("----- Ending verification of programmed SNN parameters, no error found!");

    uin_SnnAccelerator.SPI_param_checked = 1'b1;

    while (~uin_SnnAccelerator.SNN_initialized_rdy) wait_ns(1);



    /*****************************************************************************************************************************************************************************************************************
                                                                                                PROGRAM NEURON MEMORY WITH TEST VALUES
    *****************************************************************************************************************************************************************************************************************/

    if (paTest_SnnAccelerator::PROGRAM_NEURON_MEMORY) begin
      $display("----- Starting programmation of neuron memory in the SNN through SPI.");
      uin_SnnAccelerator.neuron_pattern = {2{8'b01010101,8'b10101010}};
      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::N; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
        for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<4; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
          uin_SnnAccelerator.neur_data       = uin_SnnAccelerator.neuron_pattern >> (uin_SnnAccelerator.j<<3);
          uin_SnnAccelerator.addr_temp[15:8] = uin_SnnAccelerator.j;
          uin_SnnAccelerator.addr_temp[7:0]  = uin_SnnAccelerator.i;    // Each single neuron
          uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b01,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h00,uin_SnnAccelerator.neur_data[7:0]}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
        end
        if(!(uin_SnnAccelerator.i%10))
          $display("programming neurons... (i=%0d/256)", uin_SnnAccelerator.i);
      end
      $display("----- Ending programmation of neuron memory in the SNN through SPI.");
    end else
      $display("----- Skipping programmation of neuron memory in the SNN through SPI.");


    /*****************************************************************************************************************************************************************************************************************
                                                                                                    READ BACK AND TEST NEURON MEMORY
    *****************************************************************************************************************************************************************************************************************/

    if (paTest_SnnAccelerator::VERIFY_NEURON_MEMORY) begin
      $display("----- Starting verification of neuron memory in the SNN through SPI.");
      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::N; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
        for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<4; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
          uin_SnnAccelerator.neur_data       = uin_SnnAccelerator.neuron_pattern >> (uin_SnnAccelerator.j<<3);
          uin_SnnAccelerator.addr_temp[15:8] = uin_SnnAccelerator.j;
          uin_SnnAccelerator.addr_temp[7:0]  = uin_SnnAccelerator.i;    // Each single neuron
          uin_SnnAccelerator.spi_read (.addr({1'b1,1'b0,2'b01,uin_SnnAccelerator.addr_temp[15:0]}), .data(uin_SnnAccelerator.spi_read_data), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
          assert(uin_SnnAccelerator.spi_read_data == {12'b0,uin_SnnAccelerator.neur_data[7:0]}) else $fatal(0, "Byte %d of neuron %d not written/read correctly.", uin_SnnAccelerator.j, uin_SnnAccelerator.i);
        end
        if(!(uin_SnnAccelerator.i%10))
          $display("verifying neurons... (i=%0d/256)", uin_SnnAccelerator.i);
      end
      $display("----- Ending verification of neuron memory in the SNN through SPI, no error found!");
    end else
      $display("----- Skipping verification of neuron memory in the SNN through SPI.");


    /*****************************************************************************************************************************************************************************************************************
                                                                                                PROGRAM SYNAPSE MEMORY WITH TEST VALUES
    *****************************************************************************************************************************************************************************************************************/

    if (paTest_SnnAccelerator::PROGRAM_ALL_SYNAPSES) begin
      uin_SnnAccelerator.synapse_pattern = {4'd15,4'd7,4'd12,4'd13,4'd10,4'd5,4'd1,4'd2};
      $display("----- Starting programmation of all synapses in the SNN through SPI.");
      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<8192; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
        for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<4; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
          uin_SnnAccelerator.syn_data        = uin_SnnAccelerator.synapse_pattern >> (uin_SnnAccelerator.j<<3);
          uin_SnnAccelerator.addr_temp[15:13] = uin_SnnAccelerator.j;    // Each single byte in a 32-bit word
          uin_SnnAccelerator.addr_temp[12:0 ] = uin_SnnAccelerator.i;    // Programmed address by address
          uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b10,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h00,uin_SnnAccelerator.syn_data[7:0]}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
        end
        if(!(uin_SnnAccelerator.i%500))
          $display("programming synapses... (i=%0d/8192)", uin_SnnAccelerator.i);
      end
      $display("----- Ending programmation of all synapses in the SNN through SPI.");
    end else
      $display("----- Skipping programmation of all synapses in the SNN through SPI.");


    /*****************************************************************************************************************************************************************************************************************
                                                                                                    READ BACK AND TEST SYNAPSE MEMORY
    *****************************************************************************************************************************************************************************************************************/

    if (paTest_SnnAccelerator::VERIFY_ALL_SYNAPSES) begin
      $display("----- Starting verification of all synapses in the SNN through SPI.");
      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<8192; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
        for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<4; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
          uin_SnnAccelerator.syn_data        = uin_SnnAccelerator.synapse_pattern >> (uin_SnnAccelerator.j<<3);
          uin_SnnAccelerator.addr_temp[15:13] = uin_SnnAccelerator.j;    // Each single byte in a 32-bit word
          uin_SnnAccelerator.addr_temp[12:0 ] = uin_SnnAccelerator.i;    // Programmed address by address
          uin_SnnAccelerator.spi_read (.addr({1'b1,1'b0,2'b10,uin_SnnAccelerator.addr_temp[15:0]}), .data(uin_SnnAccelerator.spi_read_data), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
          assert(uin_SnnAccelerator.spi_read_data == {12'b0,uin_SnnAccelerator.syn_data[7:0]}) else $fatal(0, "Byte %d of address %d not written/read correctly.", uin_SnnAccelerator.j, uin_SnnAccelerator.i);
        end
        if(!(uin_SnnAccelerator.i%500))
          $display("verifying synapses... (i=%0d/8192)", uin_SnnAccelerator.i);
      end
      $display("----- Ending verification of all synapses in the SNN through SPI, no error found!");
    end else
      $display("----- Skipping verification of all synapses in the SNN through SPI.");


    /*****************************************************************************************************************************************************************************************************************
                                                                                                 SYSTEM-LEVEL CHECKING
    *****************************************************************************************************************************************************************************************************************/

    if (paTest_SnnAccelerator::DO_FULL_CHECK) begin

      fork
        uin_SnnAccelerator.auto_ack(.req(uin_SnnAccelerator.AEROUT_REQ), .ack(uin_SnnAccelerator.AEROUT_ACK), .addr(uin_SnnAccelerator.AEROUT_ADDR), .neur(uin_SnnAccelerator.aer_neur_spk), .verbose(uin_SnnAccelerator.auto_ack_verbose));
      join_none

      // Initializing all neurons to zero
      $display("----- Disabling neurons 0 to 255.");
      for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<paTest_SnnAccelerator::N; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
        uin_SnnAccelerator.addr_temp[15:8] = 3;   // Programming only last byte for disabling a neuron
        uin_SnnAccelerator.addr_temp[7:0]  = uin_SnnAccelerator.i;   // Doing so for all neurons
        uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b01,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h7F,8'h80}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
      end
      $display("----- Programming neurons done...");


      for (uin_SnnAccelerator.phase=0; uin_SnnAccelerator.phase<2; uin_SnnAccelerator.phase=uin_SnnAccelerator.phase+1) begin

        $display("--- Starting phase %d.", uin_SnnAccelerator.phase);

        //Disable network operation
        uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0}), .data(20'd1), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY (1)
        uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd1}), .data(20'd1), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_OPEN_LOOP (1)

        $display("----- Starting programming of neurons 0,1,3,13,27,38,53,62,100,119,140,169,194,248,250,255.");

        uin_SnnAccelerator.target_neurons = '{255,250,248,194,169,140,119,100,62,53,38,27,13,3,1,0};
        uin_SnnAccelerator.input_neurons  = '{255,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0};

        // Programming neurons
        for (uin_SnnAccelerator.i=0; uin_SnnAccelerator.i<16; uin_SnnAccelerator.i=uin_SnnAccelerator.i+1) begin
          uin_SnnAccelerator.shift_amt      = 32'b0;

          case (uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i])
            0 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd0     :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd1);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            1 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd1     :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd3);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            3 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd10    :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd10);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            13 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd30    :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd100);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            27 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd40    :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd200);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            38 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd50    :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd300);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            53 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd60    :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd400);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            62 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd70    :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd500);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            100 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd80    :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd600);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            119 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd90    :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd700);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            140 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd100   :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd800);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            169 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd110   :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd900);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            194 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd127   :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd2022);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            248 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd120   :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd1000);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            250 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd130   :           7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd1500);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            255 : begin
              uin_SnnAccelerator.param_leak_str  = (!uin_SnnAccelerator.phase) ?           7'd140  :            7'd10;
              uin_SnnAccelerator.param_thr       = (!uin_SnnAccelerator.phase) ? $signed( 12'd2047) : $signed( 12'd2000);
              uin_SnnAccelerator.mem_init        = (!uin_SnnAccelerator.phase) ? $signed( 12'd2046) : $signed( 12'd0);
            end
            default : $fatal("Error in neuron configuration");
          endcase

          uin_SnnAccelerator.neuron_pattern = {1'b0, uin_SnnAccelerator.param_leak_str, uin_SnnAccelerator.param_thr, uin_SnnAccelerator.mem_init};

          for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<4; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
            uin_SnnAccelerator.neur_data       = uin_SnnAccelerator.neuron_pattern >> uin_SnnAccelerator.shift_amt;
            uin_SnnAccelerator.addr_temp[15:8] = uin_SnnAccelerator.j;
            uin_SnnAccelerator.addr_temp[7:0]  = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i];
            uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b01,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h00,uin_SnnAccelerator.neur_data[7:0]}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));
            uin_SnnAccelerator.shift_amt       = uin_SnnAccelerator.shift_amt + 32'd8;
          end

          for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<16; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
            uin_SnnAccelerator.addr_temp[ 12:5] = uin_SnnAccelerator.input_neurons[uin_SnnAccelerator.j][7:0];
            uin_SnnAccelerator.addr_temp[  4:0] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][7:3];
            uin_SnnAccelerator.addr_temp[14:13] = uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.i][2:1];
            uin_SnnAccelerator.spi_send (.addr({1'b0,1'b1,2'b10,uin_SnnAccelerator.addr_temp[15:0]}), .data({4'b0,8'h00,{uin_SnnAccelerator.input_neurons[uin_SnnAccelerator.j][3:0],uin_SnnAccelerator.input_neurons[uin_SnnAccelerator.j][3:0]}}), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK));    // Synapse value = pre-synaptic neuron index 4 LSBs
          end

        end


        if (paTest_SnnAccelerator::DO_OPEN_LOOP) begin

          //Re-enable network operation (SPI_OPEN_LOOP stays at 1)
          uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0}), .data(20'd0), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY (0)

          $display("----- Starting stimulation pattern.");

          for (uin_SnnAccelerator.n=0; uin_SnnAccelerator.n<256; uin_SnnAccelerator.n++)
            uin_SnnAccelerator.vcore[uin_SnnAccelerator.n] = $signed(u_SnnAccelerator.la_Include.u_Core.neuron_core_0.neurarray_0.SRAM[uin_SnnAccelerator.n][11:0]);

          if (!uin_SnnAccelerator.phase) begin
            // Every 2 ms send a leakage event for 2050 times and read the potential state of all neurons
            for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<2050; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
              uin_SnnAccelerator.aer_send (.addr_in({1'b0,1'b1,8'hFF}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ)); //Time reference event (global)
              wait_ns(2000);

              for (uin_SnnAccelerator.n=0; uin_SnnAccelerator.n<256; uin_SnnAccelerator.n++)
                uin_SnnAccelerator.vcore[uin_SnnAccelerator.n] = $signed(u_SnnAccelerator.la_Include.u_Core.neuron_core_0.neurarray_0.SRAM[uin_SnnAccelerator.n][11:0]);
            end

            wait_ns(10000);

            /*
             * Here, all neurons but number 0 should be at a membrane potential of 0
             */
            for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<16; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1)
              assert ($signed(uin_SnnAccelerator.vcore[uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j]]) == (((uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j] > 0) && (uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j] < paTest_SnnAccelerator::SPI_MAX_NEUR)) ? $signed(12'd0) : $signed(12'd2046))) else $fatal(0, "Issue in open-loop experiments: membrane potential of neuron %d not correct after leakage",uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j]);


          end else begin

          for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<16; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1)
            for (uin_SnnAccelerator.k=0; uin_SnnAccelerator.k<10; uin_SnnAccelerator.k=uin_SnnAccelerator.k+1) begin
              uin_SnnAccelerator.aer_send (.addr_in({1'b0,1'b0,uin_SnnAccelerator.input_neurons[uin_SnnAccelerator.j][7:0]}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ)); //Neuron events
              wait_ns(2000);

              for (uin_SnnAccelerator.n=0; uin_SnnAccelerator.n<256; uin_SnnAccelerator.n++)
                uin_SnnAccelerator.vcore[uin_SnnAccelerator.n] = $signed(u_SnnAccelerator.la_Include.u_Core.neuron_core_0.neurarray_0.SRAM[uin_SnnAccelerator.n][11:0]);
            end

            wait_ns(10000);

            /*
             * Here, neurons that did not fire (all except 0,1,3,13,27) should be at mem pot -80
             */
            for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<16; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1)
              if ((uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j] > 27) && (uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j] < paTest_SnnAccelerator::SPI_MAX_NEUR))
                assert ($signed(uin_SnnAccelerator.vcore[uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j]]) == $signed(-12'd80)) else $fatal(0, "Issue in open-loop experiments: membrane potential of neuron %d not correct after stimulation",uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j]);


            for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<100; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1) begin
              uin_SnnAccelerator.aer_send (.addr_in({1'b0,1'b1,8'hFF}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ)); //Time reference event (global)
              wait_ns(2000);

              for (uin_SnnAccelerator.n=0; uin_SnnAccelerator.n<256; uin_SnnAccelerator.n++)
                uin_SnnAccelerator.vcore[uin_SnnAccelerator.n] = $signed(u_SnnAccelerator.la_Include.u_Core.neuron_core_0.neurarray_0.SRAM[uin_SnnAccelerator.n][11:0]);
            end

            wait_ns(10000);

            /*
             * Here, all mem pots should be back to 0
             */
            for (uin_SnnAccelerator.j=0; uin_SnnAccelerator.j<16; uin_SnnAccelerator.j=uin_SnnAccelerator.j+1)
              assert ($signed(uin_SnnAccelerator.vcore[uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j]]) == $signed(12'd0)) else $fatal(0, "Issue in open-loop experiments: membrane potential of neuron %d not correct after leakage",uin_SnnAccelerator.target_neurons[uin_SnnAccelerator.j]);

            fork
              // Thread 1
              for (uin_SnnAccelerator.k=0; uin_SnnAccelerator.k<300; uin_SnnAccelerator.k=uin_SnnAccelerator.k+1) begin
                uin_SnnAccelerator.aer_send (.addr_in({1'b0,1'b0,uin_SnnAccelerator.input_neurons[7][7:0]}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ)); //Neuron events
                wait_ns(2000);

                for (uin_SnnAccelerator.n=0; uin_SnnAccelerator.n<256; uin_SnnAccelerator.n++)
                  uin_SnnAccelerator.vcore[uin_SnnAccelerator.n] = $signed(u_SnnAccelerator.la_Include.u_Core.neuron_core_0.neurarray_0.SRAM[uin_SnnAccelerator.n][11:0]);
              end

              //Thread 2
              /*
              * Here, neuron 194 (with the highest membrane potential among enabled neurons) should fire. Neuron 248, 250 or 255 should be disabled.
              */
              while (uin_SnnAccelerator.aer_neur_spk != 8'd194) begin
                assert ((uin_SnnAccelerator.aer_neur_spk != 8'd248) && (uin_SnnAccelerator.aer_neur_spk != 8'd250) && (uin_SnnAccelerator.aer_neur_spk != 8'd255)) else $fatal(0, "Issue in open-loop experiments: neurons 248, 250 or 255 should be disabled.");
                wait_ns(1);
              end
            join

            wait_ns(100000);

          end

        end


        if (paTest_SnnAccelerator::DO_CLOSED_LOOP) begin

          //Re-enable network operation
          uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0}), .data(20'd0), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY (0)
          uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd1}), .data(20'b0), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_OPEN_LOOP (0)

          $display("----- Starting stimulation pattern.");


          if (uin_SnnAccelerator.phase) begin

            //Start monitoring output spikes in the console
            uin_SnnAccelerator.auto_ack_verbose = 1'b1;

            uin_SnnAccelerator.aer_send (.addr_in({1'b1,1'b0,{4'h5,4'd3}}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ)); //Virtual value-5 event to neuron 3
            uin_SnnAccelerator.aer_send (.addr_in({1'b1,1'b0,{4'h5,4'd3}}), .addr_out(uin_SnnAccelerator.AERIN_ADDR), .ack(uin_SnnAccelerator.AERIN_ACK), .req(uin_SnnAccelerator.AERIN_REQ)); //Virtual value-5 event to neuron 3
            /*
             * Here, the correct output firing sequence is 3,0,1,0.
             */
            while (!uin_SnnAccelerator.AEROUT_REQ) wait_ns(1);
            assert (uin_SnnAccelerator.AEROUT_ADDR == 8'd3) else $fatal(0, "Issue in closed-loop experiments: first spike of the output sequence is not correct, received %d", uin_SnnAccelerator.AEROUT_ADDR);
            while ( uin_SnnAccelerator.AEROUT_REQ) wait_ns(1);
            while (!uin_SnnAccelerator.AEROUT_REQ) wait_ns(1);
            assert (uin_SnnAccelerator.AEROUT_ADDR == 8'd0) else $fatal(0, "Issue in closed-loop experiments: second spike of the output sequence is not correct, received %d", uin_SnnAccelerator.AEROUT_ADDR);
            while ( uin_SnnAccelerator.AEROUT_REQ) wait_ns(1);
            while (!uin_SnnAccelerator.AEROUT_REQ) wait_ns(1);
            assert (uin_SnnAccelerator.AEROUT_ADDR == 8'd1) else $fatal(0, "Issue in closed-loop experiments: third spike of the output sequence is not correct, received %d", uin_SnnAccelerator.AEROUT_ADDR);
            while ( uin_SnnAccelerator.AEROUT_REQ) wait_ns(1);
            while (!uin_SnnAccelerator.AEROUT_REQ) wait_ns(1);
            assert (uin_SnnAccelerator.AEROUT_ADDR == 8'd0) else $fatal(0, "Issue in closed-loop experiments: fourth spike of the output sequence is not correct, received %d", uin_SnnAccelerator.AEROUT_ADDR);
            while ( uin_SnnAccelerator.AEROUT_REQ) wait_ns(1);
            uin_SnnAccelerator.time_window_check = 0;
            while (uin_SnnAccelerator.time_window_check < 10000) begin
              assert (!uin_SnnAccelerator.AEROUT_REQ) else $fatal(0, "There should not be more than 4 output spikes in the closed-loop experiments, received %d", uin_SnnAccelerator.AEROUT_ADDR);
              wait_ns(1);
              uin_SnnAccelerator.time_window_check += 1;
            end
          end

        end

      end

      $display("----- No error found -- All tests passed! :-)");

    end else
      $display("----- Skipping scheduler checking.");

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