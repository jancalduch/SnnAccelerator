//------------------------------------------------------------------------------
//
// "decoder.sv" - Module to decode the output spike event and generate an interrupt 
//                  when the infered class is stored.
//
//------------------------------------------------------------------------------


module decoder #(
	parameter N = 256,
	parameter M = 8
)(
  // Global inputs ----------------------------------
  input  logic            CLK,
  input  logic            RST,

  // Control signals --------------------------------
  input logic             NEW_IMAGE,

  // AER link ---------------------------------------
  input logic  [  M-1:0]  AEROUT_ADDR, 
  input logic  	          AEROUT_REQ,
  output logic            AEROUT_ACK,
  
  // Interrupt signal -------------------------------
  // To the encoder
  output logic            INFERENCE_RDY,
  // To the outside
  output logic            DECODER_RDY,

  // Output value
  output logic  [  M-1:0] INFERED_DIGIT
);

  //----------------------------------------------------------------------------------
	//	PARAMETERS 
	//----------------------------------------------------------------------------------

	// FSM states 
	localparam INIT         = 2'd0; 
  localparam STORE        = 2'd1;
  localparam WAIT         = 2'd2;

	//----------------------------------------------------------------------------------
	//	REGS & WIRES
	//----------------------------------------------------------------------------------
    
  reg AEROUT_REQ_sync_int, AEROUT_REQ_sync;

  logic first_value_infered, storeValue;

  logic [6:0] cnt_up;
  logic waiting_finished;

  logic [M-1:0] inferedValue;
  logic decoder_ready;
  
  reg  [  1:0] state, nextstate;
    
	//----------------------------------------------------------------------------------
	//	SYNC BARRIERS FROM AER
	//----------------------------------------------------------------------------------
    
  always @(posedge CLK, posedge RST) begin
		if(RST) begin
			AEROUT_REQ_sync_int     <= 1'b0;
			AEROUT_REQ_sync	        <= 1'b0;
		end
		else begin
			AEROUT_REQ_sync_int     <= AEROUT_REQ;
			AEROUT_REQ_sync	        <= AEROUT_REQ_sync_int;
		end
	end
    
	//----------------------------------------------------------------------------------
	//	CONTROL FSM
	//----------------------------------------------------------------------------------
    
  // State register
	always_ff @(posedge CLK, posedge RST) begin
		if   (RST) state <= INIT;
		else       state <= nextstate;
	end
    
	// Next state logic
	always_comb begin
    case(state)
			INIT:	
        if (AEROUT_REQ_sync)   
          if (!first_value_infered) nextstate = STORE;
          else                      nextstate = WAIT;
        else                        nextstate = INIT;
      STORE: 
        if      (!AEROUT_REQ_sync)  nextstate = INIT;
        else                        nextstate = STORE;                              
			WAIT: 
        if      (!AEROUT_REQ_sync)  nextstate = INIT;
				else					              nextstate = WAIT;
			default: 					            nextstate = INIT;
	  endcase 
  end

  // Output logic      
  always_comb begin  
      
    if (state == INIT) begin
      storeValue            = 1'b0;
      AEROUT_ACK            = 1'b0;
        
    end else if (state == STORE) begin
      storeValue            = 1'b1;
      AEROUT_ACK            = 1'b1;

    end else if (state == WAIT) begin
      storeValue            = 1'b0;
      AEROUT_ACK            = 1'b1;

    end else begin
      storeValue            = 1'b0;
      AEROUT_ACK            = 1'b0;
    end
  end

  // Comparator to know when we have processed all tinyODIN events
  // 23 clk for current aer_in
  // 9 for pushing next value
  // 23 for next aer_in
  always_comb begin
    waiting_finished = (cnt_up == 55);
  end

  // Counter up of clocks passed
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                       cnt_up <= 0;
    else if (NEW_IMAGE)            cnt_up <= 0;
    else if (first_value_infered && (state == INIT) && !AEROUT_REQ)  cnt_up <= (waiting_finished) ? cnt_up: cnt_up + 1;
    else                           cnt_up <= cnt_up;
  end

  // Store infered digit once the request is cleared
  always_ff @(posedge CLK) begin
    if (RST)              inferedValue <= 0;
    else if (storeValue)  inferedValue <= AEROUT_ADDR;
  end

  // Signal that value is infered
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                                  first_value_infered <= 1'b0;
    else if (NEW_IMAGE)                       first_value_infered <= 1'b0;
    else if (storeValue && !AEROUT_REQ_sync)  first_value_infered <= 1'b1;
    else                                      first_value_infered <= first_value_infered;
  end

  // Make sure that we have processed all events in tinyODIN scheduler.
  always_ff @(posedge CLK or posedge RST) begin
    if (RST)                    decoder_ready <= 1'b0;
    else if (NEW_IMAGE)         decoder_ready <= 1'b0;
    else if (waiting_finished)  decoder_ready <= 1'b1;
    else                        decoder_ready <= decoder_ready;
  end

  // Output
  assign INFERED_DIGIT          = inferedValue;
  assign INFERENCE_RDY          = first_value_infered;
  assign DECODER_RDY            = decoder_ready;          

endmodule 


