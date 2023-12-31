//====================================================================
//        Copyright (c) 2023 Nordic Semiconductor ASA, Norway
//====================================================================
// Created : hedi at 2023-09-28
//====================================================================

package paTest_SnnAccelerator;

  localparam integer CLK_HALF_PERIOD      = 2;
  localparam integer SCK_HALF_PERIOD      = 25;

  localparam integer N                    = 256;
  localparam integer M                    = 8;

  localparam bit PROGRAM_ALL_SYNAPSES     = 1'b1;
  localparam bit VERIFY_ALL_SYNAPSES      = 1'b1;
  localparam bit PROGRAM_NEURON_MEMORY    = 1'b1;
  localparam bit VERIFY_NEURON_MEMORY     = 1'b1;
  localparam bit DO_FULL_CHECK            = 1'b1;
  //localparam bit DO_OPEN_LOOP             = 1'b1;
  localparam bit DO_CLOSED_LOOP           = 1'b0;

  localparam bit SPI_OPEN_LOOP            = 1'b1;
  localparam bit SPI_AER_SRC_CTRL_nNEUR   = 1'b0;
  localparam integer SPI_MAX_NEUR         = 8'd10; // default test = 200; inference = 10


endpackage