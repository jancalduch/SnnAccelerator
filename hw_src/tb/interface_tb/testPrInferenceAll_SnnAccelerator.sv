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
    uin_SnnAccelerator.images_to_test = 10000;
    
    // Get test_lables and convert from ASCII char to int
    uin_SnnAccelerator.file_name = "/pro/sig_research/AI/work/jais/sproject/SnnAccelerator_top/projects/student/SnnAccelerator/sim/tb/test_labels.txt";
    uin_SnnAccelerator.parese_digits(.file_name (uin_SnnAccelerator.file_name), .digit_number(uin_SnnAccelerator.images_to_test));

    // Get Images 
    uin_SnnAccelerator.file_name = "/pro/sig_research/AI/work/jais/sproject/SnnAccelerator_top/projects/student/SnnAccelerator/sim/tb/test_images.txt";
    uin_SnnAccelerator.parese_images(.file_name(uin_SnnAccelerator.file_name), .array_number(uin_SnnAccelerator.images_to_test), .array_depth(256));
    
    // Get ROC images
    uin_SnnAccelerator.file_name = "/pro/sig_research/AI/work/jais/sproject/SnnAccelerator_top/projects/student/SnnAccelerator/sim/tb/roc_test_images_rounded.txt";
    uin_SnnAccelerator.parese_roc_images(.file_name(uin_SnnAccelerator.file_name), .array_number(uin_SnnAccelerator.images_to_test), .array_depth(256));
    
    // Failed guessed images
    uin_SnnAccelerator.failed_images = '{8, 11, 15, 22, 27, 33, 34, 43, 44, 54, 59, 61, 63, 66, 73, 75, 80, 84, 87, 97, 107, 111, 114, 115, 116, 133, 137, 149, 151, 152, 158, 160, 165, 167, 175, 182, 185, 187, 190, 193, 195, 196, 198, 201, 209, 211, 215, 218, 230, 232, 233, 234, 241, 242, 245, 247, 251, 255, 257, 259, 268, 273, 279, 282, 290, 300, 301, 304, 307, 317, 320, 321, 336, 338, 340, 341, 344, 352, 358, 366, 376, 381, 388, 399, 403, 406, 426, 428, 433, 434, 443, 445, 448, 450, 464, 468, 478, 479, 483, 487, 488, 495, 497, 498, 501, 505, 507, 510, 511, 514, 527, 530, 531, 548, 551, 552, 553, 565, 571, 572, 578, 582, 591, 593, 602, 605, 606, 610, 613, 615, 617, 628, 630, 638, 645, 646, 654, 655, 658, 659, 661, 664, 667, 671, 679, 684, 685, 686, 691, 699, 702, 707, 708, 712, 714, 716, 717, 720, 730, 734, 739, 740, 751, 756, 759, 760, 761, 774, 795, 800, 813, 817, 818, 824, 839, 842, 844, 857, 874, 876, 877, 896, 898, 906, 915, 924, 930, 931, 934, 935, 936, 944, 947, 950, 952, 956, 959, 960, 965, 966, 968, 977, 982, 989, 992, 998, 1000, 1003, 1010, 1012, 1014, 1015, 1024, 1032, 1039, 1045, 1048, 1052, 1062, 1068, 1070, 1072, 1077, 1078, 1091, 1092, 1093, 1096, 1097, 1101, 1103, 1107, 1112, 1114, 1116, 1117, 1119, 1121, 1122, 1128, 1142, 1143, 1166, 1173, 1191, 1192, 1194, 1197, 1198, 1200, 1202, 1204, 1206, 1208, 1219, 1224, 1226, 1228, 1233, 1234, 1243, 1247, 1248, 1252, 1260, 1266, 1270, 1273, 1281, 1283, 1288, 1289, 1308, 1319, 1320, 1325, 1326, 1328, 1330, 1337, 1345, 1347, 1363, 1364, 1378, 1393, 1403, 1404, 1415, 1425, 1437, 1438, 1444, 1450, 1453, 1465, 1466, 1469, 1476, 1494, 1495, 1499, 1500, 1522, 1523, 1525, 1527, 1528, 1529, 1530, 1534, 1549, 1553, 1559, 1562, 1569, 1571, 1581, 1595, 1609, 1611, 1627, 1630, 1635, 1637, 1638, 1640, 1641, 1655, 1660, 1661, 1681, 1686, 1687, 1694, 1701, 1702, 1709, 1716, 1717, 1718, 1721, 1722, 1729, 1732, 1733, 1735, 1740, 1741, 1750, 1751, 1754, 1755, 1757, 1759, 1767, 1769, 1773, 1774, 1776, 1785, 1790, 1800, 1801, 1806, 1808, 1809, 1810, 1813, 1816, 1838, 1843, 1868, 1878, 1880, 1881, 1885, 1900, 1901, 1903, 1911, 1913, 1918, 1920, 1926, 1930, 1931, 1933, 1938, 1940, 1941, 1948, 1952, 1953, 1955, 1963, 1968, 1970, 1973, 1981, 1984, 2004, 2009, 2016, 2018, 2024, 2029, 2037, 2043, 2044, 2051, 2052, 2053, 2054, 2057, 2064, 2068, 2070, 2073, 2080, 2093, 2095, 2107, 2109, 2115, 2118, 2121, 2125, 2129, 2130, 2131, 2134, 2140, 2143, 2144, 2166, 2177, 2180, 2182, 2183, 2185, 2189, 2192, 2200, 2208, 2209, 2214, 2215, 2218, 2221, 2224, 2229, 2246, 2258, 2264, 2266, 2272, 2279, 2286, 2293, 2299, 2305, 2325, 2326, 2329, 2333, 2341, 2351, 2355, 2358, 2369, 2371, 2380, 2381, 2382, 2386, 2393, 2395, 2398, 2400, 2402, 2404, 2405, 2406, 2409, 2413, 2419, 2422, 2431, 2434, 2438, 2441, 2447, 2449, 2450, 2457, 2460, 2461, 2473, 2488, 2507, 2513, 2516, 2528, 2534, 2535, 2540, 2546, 2547, 2548, 2556, 2559, 2560, 2564, 2571, 2578, 2582, 2586, 2589, 2598, 2604, 2607, 2610, 2616, 2628, 2631, 2635, 2636, 2637, 2642, 2647, 2648, 2659, 2665, 2668, 2670, 2678, 2684, 2695, 2702, 2705, 2713, 2719, 2724, 2728, 2730, 2731, 2736, 2740, 2745, 2753, 2754, 2756, 2758, 2770, 2771, 2778, 2780, 2789, 2805, 2807, 2808, 2810, 2812, 2813, 2814, 2820, 2823, 2827, 2834, 2847, 2850, 2851, 2852, 2853, 2862, 2863, 2879, 2888, 2890, 2896, 2898, 2906, 2914, 2915, 2917, 2919, 2921, 2925, 2926, 2927, 2929, 2930, 2939, 2940, 2943, 2945, 2946, 2953, 2957, 2961, 2969, 2970, 2974, 2986, 2995, 2998, 3005, 3008, 3023, 3026, 3027, 3029, 3033, 3038, 3047, 3049, 3055, 3060, 3061, 3062, 3065, 3068, 3069, 3073, 3093, 3095, 3099, 3100, 3108, 3110, 3114, 3115, 3117, 3120, 3122, 3130, 3132, 3133, 3136, 3146, 3157, 3160, 3166, 3167, 3181, 3189, 3193, 3202, 3205, 3206, 3210, 3219, 3222, 3225, 3227, 3233, 3236, 3240, 3250, 3253, 3261, 3262, 3263, 3268, 3269, 3275, 3285, 3287, 3289, 3292, 3295, 3296, 3307, 3323, 3329, 3330, 3333, 3336, 3338, 3345, 3349, 3351, 3358, 3363, 3364, 3373, 3376, 3377, 3381, 3384, 3394, 3404, 3405, 3406, 3414, 3416, 3425, 3426, 3429, 3432, 3437, 3447, 3448, 3450, 3452, 3453, 3457, 3459, 3460, 3467, 3468, 3475, 3483, 3490, 3494, 3502, 3503, 3506, 3509, 3520, 3521, 3543, 3549, 3552, 3556, 3558, 3559, 3563, 3565, 3571, 3573, 3580, 3593, 3597, 3601, 3604, 3610, 3614, 3618, 3627, 3634, 3635, 3646, 3652, 3654, 3657, 3664, 3665, 3669, 3685, 3687, 3702, 3713, 3716, 3718, 3727, 3728, 3730, 3732, 3736, 3738, 3742, 3749, 3751, 3756, 3767, 3769, 3776, 3780, 3782, 3787, 3796, 3801, 3806, 3808, 3820, 3821, 3827, 3834, 3836, 3838, 3846, 3848, 3851, 3853, 3859, 3869, 3873, 3876, 3879, 3884, 3885, 3891, 3893, 3902, 3906, 3918, 3926, 3941, 3946, 3949, 3950, 3966, 3968, 3976, 3989, 3998, 4000, 4002, 4007, 4015, 4017, 4027, 4029, 4044, 4051, 4054, 4059, 4065, 4068, 4075, 4076, 4078, 4084, 4093, 4111, 4116, 4140, 4141, 4145, 4146, 4154, 4156, 4165, 4168, 4171, 4176, 4177, 4178, 4180, 4185, 4187, 4197, 4201, 4203, 4212, 4215, 4221, 4222, 4223, 4224, 4225, 4228, 4238, 4239, 4248, 4255, 4256, 4259, 4261, 4263, 4265, 4271, 4289, 4293, 4297, 4298, 4300, 4302, 4306, 4308, 4325, 4338, 4353, 4356, 4358, 4363, 4374, 4379, 4380, 4382, 4391, 4393, 4395, 4408, 4410, 4423, 4425, 4429, 4433, 4435, 4437, 4438, 4439, 4441, 4443, 4444, 4447, 4449, 4451, 4454, 4464, 4469, 4477, 4480, 4481, 4494, 4497, 4498, 4500, 4505, 4507, 4511, 4513, 4514, 4515, 4523, 4540, 4544, 4548, 4551, 4560, 4566, 4567, 4572, 4574, 4575, 4576, 4577, 4578, 4583, 4589, 4613, 4615, 4633, 4639, 4640, 4656, 4657, 4658, 4660, 4671, 4679, 4690, 4698, 4702, 4720, 4722, 4724, 4726, 4731, 4733, 4736, 4737, 4742, 4743, 4744, 4745, 4748, 4751, 4763, 4764, 4777, 4785, 4791, 4795, 4796, 4804, 4807, 4814, 4816, 4823, 4828, 4829, 4833, 4836, 4837, 4838, 4839, 4844, 4847, 4860, 4861, 4863, 4868, 4874, 4876, 4879, 4886, 4888, 4890, 4893, 4896, 4910, 4915, 4933, 4941, 4945, 4956, 4968, 4978, 4987, 4990, 5001, 5013, 5017, 5038, 5046, 5047, 5049, 5053, 5056, 5065, 5067, 5068, 5078, 5081, 5086, 5090, 5091, 5101, 5118, 5132, 5134, 5138, 5140, 5143, 5148, 5157, 5159, 5173, 5175, 5176, 5177, 5200, 5201, 5209, 5231, 5232, 5239, 5242, 5246, 5260, 5261, 5268, 5269, 5271, 5281, 5299, 5311, 5331, 5339, 5360, 5379, 5380, 5440, 5446, 5457, 5464, 5468, 5503, 5518, 5522, 5530, 5532, 5543, 5560, 5564, 5569, 5571, 5573, 5583, 5588, 5593, 5600, 5608, 5611, 5620, 5623, 5628, 5639, 5642, 5645, 5649, 5653, 5654, 5655, 5661, 5663, 5670, 5674, 5677, 5678, 5709, 5714, 5719, 5722, 5730, 5734, 5735, 5736, 5744, 5745, 5746, 5749, 5752, 5757, 5759, 5760, 5771, 5779, 5780, 5803, 5812, 5814, 5821, 5831, 5833, 5835, 5842, 5843, 5851, 5855, 5857, 5862, 5866, 5867, 5871, 5874, 5887, 5888, 5891, 5892, 5899, 5903, 5906, 5910, 5912, 5913, 5922, 5935, 5936, 5938, 5955, 5962, 5967, 5972, 5973, 5974, 5975, 5985, 6004, 6006, 6011, 6019, 6021, 6023, 6042, 6043, 6046, 6056, 6059, 6070, 6071, 6072, 6080, 6081, 6083, 6087, 6091, 6101, 6110, 6112, 6124, 6126, 6135, 6153, 6157, 6161, 6166, 6168, 6172, 6173, 6178, 6202, 6210, 6223, 6228, 6233, 6238, 6251, 6269, 6312, 6324, 6329, 6331, 6347, 6359, 6370, 6374, 6381, 6385, 6399, 6400, 6410, 6418, 6421, 6425, 6426, 6428, 6432, 6434, 6441, 6445, 6449, 6452, 6458, 6465, 6471, 6473, 6480, 6490, 6494, 6495, 6503, 6505, 6507, 6517, 6530, 6542, 6544, 6545, 6555, 6558, 6560, 6565, 6568, 6569, 6571, 6573, 6576, 6577, 6578, 6597, 6598, 6611, 6619, 6624, 6628, 6632, 6641, 6642, 6643, 6651, 6652, 6661, 6662, 6688, 6694, 6712, 6716, 6720, 6721, 6722, 6725, 6732, 6733, 6740, 6743, 6744, 6746, 6755, 6763, 6765, 6775, 6776, 6783, 6784, 6785, 6788, 6796, 6801, 6803, 6817, 6840, 6864, 6872, 6878, 6883, 6885, 6886, 6894, 6895, 6905, 6906, 6919, 6923, 6944, 6945, 6954, 6958, 6962, 6970, 6973, 6978, 6981, 6998, 7002, 7003, 7030, 7035, 7049, 7077, 7084, 7121, 7130, 7161, 7162, 7167, 7170, 7171, 7177, 7182, 7195, 7204, 7212, 7216, 7232, 7241, 7247, 7248, 7249, 7256, 7257, 7262, 7265, 7268, 7284, 7293, 7294, 7311, 7320, 7325, 7326, 7333, 7337, 7341, 7350, 7352, 7354, 7357, 7363, 7381, 7394, 7395, 7419, 7424, 7426, 7430, 7432, 7434, 7437, 7439, 7448, 7451, 7453, 7454, 7459, 7462, 7468, 7471, 7476, 7477, 7478, 7480, 7481, 7487, 7489, 7490, 7491, 7494, 7498, 7499, 7504, 7505, 7514, 7520, 7531, 7541, 7558, 7565, 7574, 7584, 7597, 7603, 7620, 7622, 7648, 7673, 7709, 7720, 7735, 7736, 7756, 7777, 7783, 7790, 7797, 7800, 7803, 7804, 7806, 7809, 7812, 7813, 7819, 7820, 7821, 7822, 7823, 7826, 7829, 7831, 7837, 7839, 7842, 7847, 7849, 7850, 7854, 7856, 7857, 7858, 7859, 7865, 7868, 7869, 7870, 7875, 7876, 7886, 7888, 7890, 7894, 7896, 7899, 7905, 7911, 7916, 7917, 7918, 7920, 7921, 7928, 7930, 7944, 7945, 7990, 7991, 8003, 8004, 8010, 8014, 8020, 8022, 8029, 8043, 8044, 8047, 8050, 8059, 8062, 8091, 8094, 8097, 8106, 8119, 8128, 8144, 8151, 8156, 8165, 8170, 8181, 8184, 8196, 8198, 8210, 8218, 8229, 8231, 8243, 8253, 8254, 8258, 8262, 8265, 8266, 8270, 8272, 8273, 8277, 8279, 8282, 8288, 8294, 8296, 8299, 8308, 8309, 8310, 8316, 8319, 8325, 8330, 8332, 8339, 8353, 8361, 8381, 8405, 8408, 8410, 8413, 8416, 8431, 8444, 8456, 8457, 8476, 8477, 8486, 8489, 8495, 8497, 8505, 8507, 8508, 8509, 8510, 8520, 8522, 8524, 8530, 8533, 8539, 8553, 8571, 8578, 8616, 8632, 8637, 8653, 8656, 8665, 8670, 8672, 8674, 8679, 8710, 8722, 8738, 8752, 8757, 8766, 8785, 8847, 8849, 8873, 8875, 8885, 8906, 8928, 8933, 8952, 8981, 9002, 9003, 9005, 9009, 9013, 9015, 9016, 9017, 9019, 9024, 9025, 9026, 9031, 9035, 9036, 9039, 9044, 9045, 9054, 9057, 9063, 9073, 9079, 9085, 9110, 9136, 9141, 9156, 9158, 9161, 9170, 9175, 9180, 9190, 9198, 9200, 9206, 9211, 9216, 9234, 9245, 9248, 9275, 9280, 9290, 9305, 9308, 9316, 9332, 9342, 9375, 9385, 9388, 9410, 9427, 9446, 9450, 9479, 9503, 9505, 9508, 9513, 9522, 9524, 9530, 9533, 9538, 9540, 9552, 9554, 9560, 9564, 9580, 9587, 9594, 9595, 9599, 9600, 9606, 9610, 9612, 9614, 9622, 9624, 9634, 9636, 9640, 9645, 9649, 9653, 9655, 9656, 9657, 9661, 9662, 9666, 9674, 9677, 9682, 9692, 9699, 9700, 9712, 9719, 9729, 9735, 9744, 9745, 9747, 9749, 9752, 9755, 9764, 9768, 9769, 9770, 9771, 9772, 9779, 9783, 9786, 9795, 9811, 9817, 9819, 9826, 9831, 9832, 9834, 9835, 9839, 9840, 9850, 9857, 9863, 9873, 9876, 9879, 9881, 9883, 9890, 9891, 9892, 9893, 9901, 9904, 9905, 9907, 9912, 9915, 9922, 9925, 9941, 9943, 9944, 9947, 9955, 9958, 9959, 9970, 9975, 9982, 9986, 9991
    };
    uin_SnnAccelerator.fail_cnt = 0;

    // --------------------------------------------------------------------------------- Do inference for all images in MNIST dataset ------------------------------------------
    uin_SnnAccelerator.best_time = 64'd1000000000000;
    uin_SnnAccelerator.worst_time = 0;
    uin_SnnAccelerator.total_time = 0;
    uin_SnnAccelerator.total_correct_guesses = 0;

    //Re-enable network operation 
    uin_SnnAccelerator.spi_send (.addr({1'b0,1'b0,2'b00,16'd0}), .data(20'd0), .MISO(uin_SnnAccelerator.MISO), .MOSI(uin_SnnAccelerator.MOSI), .SCK(uin_SnnAccelerator.SCK)); //SPI_GATE_ACTIVITY (0)
    
    $display("----- Starting inference of all images");
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("start inference");

    for (uin_SnnAccelerator.img = 0; uin_SnnAccelerator.img < uin_SnnAccelerator.images_to_test; uin_SnnAccelerator.img = uin_SnnAccelerator.img + 1) begin
      // -----------------------------
      // -- SEND DATA
      // -----------------------------
      // Get image and send through AXI byte by byte
      // uin_SnnAccelerator.test_image = uin_SnnAccelerator.roc_test_images[uin_SnnAccelerator.img];
      uin_SnnAccelerator.test_image = uin_SnnAccelerator.test_images[uin_SnnAccelerator.img];
      
      uin_SnnAccelerator.start_time = $time;
      for (int address = 0; address < paTest_SnnAccelerator::IMAGE_SIZE; address++) begin
        uin_SnnAccelerator.axi4l_write(address, uin_SnnAccelerator.test_image[address]);
        // $display("----- Image %d is %d", uin_SnnAccelerator.img, uin_SnnAccelerator.test_image[i]);
      end
      
      // Notify that image is fully sent
      uin_SnnAccelerator.axi4l_write(256, 1);
      uin_SnnAccelerator.axi4l_write(256, 0);

      uin_SnnAccelerator.axi_write_time = uin_SnnAccelerator.axi_write_time + ($time - uin_SnnAccelerator.start_time);

      // -----------------------------
      // -- READ DATA
      // -----------------------------
      // Wait for interrupt and then read data
      wait(uin_SnnAccelerator.COPROCESSOR_RDY);
      uin_SnnAccelerator.axi4l_read(5, uin_SnnAccelerator.read_data);
      uin_SnnAccelerator.end_time = $time;

      // Update metrics
      if (uin_SnnAccelerator.read_data[7:0] == uin_SnnAccelerator.test_labels[uin_SnnAccelerator.img]) begin
        uin_SnnAccelerator.total_correct_guesses += 1;
      //end else begin
        //if ( uin_SnnAccelerator.img != uin_SnnAccelerator.failed_images[uin_SnnAccelerator.fail_cnt])
          //$display("----- Digit should be %d and received %d for image %d", uin_SnnAccelerator.test_labels[uin_SnnAccelerator.img], uin_SnnAccelerator.INFERED_DIGIT, uin_SnnAccelerator.img);
        //else 
          //uin_SnnAccelerator.fail_cnt++;
      end;

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

      uin_SnnAccelerator.read_data = 32'h0;

      if (uin_SnnAccelerator.img % 1000 == 0) $display("1000 more: %d", uin_SnnAccelerator.img); 

    end
    
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbTimestamp("finish inference");
    nVipPa_FSDBDumper::cl_FSDBDumper::get().ta_fsdbStop();

    uin_SnnAccelerator.accuracy = uin_SnnAccelerator.total_correct_guesses*100.0/uin_SnnAccelerator.images_to_test; 
    $display("----- Inference finished with a %.2f %% Accuracy!", uin_SnnAccelerator.accuracy); 
 
    uin_SnnAccelerator.average_time = uin_SnnAccelerator.total_time/(1000.0*uin_SnnAccelerator.images_to_test);
    $display("----- Average AXI write time is %.4f us", uin_SnnAccelerator.axi_write_time/(1000.0*uin_SnnAccelerator.images_to_test));
    $display("----- Average execution time is %.4f us\n", uin_SnnAccelerator.average_time);
    
    $display("----- Best execution time is image %d with %.4f us", uin_SnnAccelerator.best_time_image, (uin_SnnAccelerator.best_time/1000.0));
    $display("----- Worst execution time is image %d with %.4f us", uin_SnnAccelerator.worst_time_image, (uin_SnnAccelerator.worst_time/1000.0));
     
    // uin_SnnAccelerator.time_array.sort();
    // $display("----- Median execution time is %.4f us", (uin_SnnAccelerator.time_array[5000]/1000.0));
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