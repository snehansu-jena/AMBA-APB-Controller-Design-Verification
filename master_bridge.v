module master_bridge(
       input       [8:0]       apb_write_paddr, apb_read_paddr,
	   input       [8:0]       apb_write_paddr, apb_read_paddr,
	   input                   PRESETn, PCLK, READ_WRITE, transfer, PREADY,
	   output reg              PSEL1, PSEL2,
	   output reg              PENABLE,
	   output reg  [8:0]       PADDR,
	   output reg              PWRITE,
	   output reg  [7:0]       PWDATA, apb_read_data_out,
	   output reg              PSLVRR
	   );
	   
	   //Simple synchronous FSM with registered outputs
	   
	   localparam IDLE   = 3'b001,
	              SETUP  = 3'b010,
	              ENABLE = 3'b100;
				  
	    reg [2:0] stste, next_state;
		
		//next-output signals (combinational)
		
		reg         next_enable;
		reg [8:0]   next_paddr;
		reg         next_pwrite;
		reg [7:0]   next_pwdata;
		reg         capture_read_data;
		
		// error flags (combinational)
		
		reg setup_error;
		reg invalid_read_paddr;
		reg invalid_write_paddr;
		reg invalid_write_data;
		reg invalid_setup_error_nxt;
		
		// synchronous state & registered outputs 
		
		always @(posedge PCLK or negedge PRESETn) begin
		    if (!PRESETn) begin
			    state             <= IDLE;
				PENABLE           <= 1'b0;
				PADDR             <= 9'd0;
				PWRITE            <= 1'b0;
				PWDATA            <= 8'd0;
				apb_read_data_out <= 8'd0;
				PSEL1             <= 1'b0;
				PSEL2             <= 1'b0;
				PSLVRR            <= 1'b0;
			end else begin
				state             <= next_state;
				PENABLE           <= next_enable;
				PADDR             <= next_paddr;
				PWRITE            <= next_pwrite;
				PWDATA            <= next_pwdata;
			if  (capture_read_data) apb_read_data_out <= PRDATA;
			
			// PSEL signals derived from registered PADDR and state
			
			if   (state != IDLE && (next_state == SETUP || next_state == ENABLE || PENABLE))
			    begin 
				  if (next_paddr[8]) begin PSEL1 <= 1'b0; PSEL2 <= 1'b1; end
				  else               begin PSEL1 <= 1'b1; PSEL2 <= 1'b0; end
				end
			else begin 
			     PSEL1 <= 1'b0; PSEL2 <= 1'b0;
				 end
				 PSLVRR <= invalid_setup_error_nxt;
			   end
			end
			
			// combinational next-state and next-output logic
			
			always @(*) begin
			
			  //defaults -> hold values
			  
			  next_state        = state;
			  next_enable       = 1'b0;
			  next_paddr        = PADDR;
			  next_pwrite       = PWRITE;
			  next_pwdata       = PWDATA;
			  capture_read_data = 1'b0;
			  
			  //default error flags

			  setup_error             = 1'b0;
			  invalid_read_paddr      = 1'b0;
		      invalid_write_paddr     = 1'b0;
		      invalid_write_data      = 1'b0;
			  invalid_setup_error_nxt = 1'b0;
			  
			  case(state)
			    IDLE: begin
				  // drive PWRITE/PWDATA/PADDR for the next setup if transfer asserted
				  if (transfer) begin
				      next_state        = SETUP;
					  next_enable       = ~READ_WRITE;
					  next_paddr        = READ_WRITE ? apb_read_paddr : apb_write_paddr;
					  next_pwdata       = apb_write_data;
				  end else begin
				    next_state = IDLE;
				  end
				end

                SETUP: begin
                  // stay in SETUP until we move to ENABLE or IDLE on PSLVRR
                  	next_enable             = 1'b0;
                    next_pwrite             = ~READ_WRITE;
                    next_paddr              = READ_WRITE ? apb_read_paddr : apb_write_paddr;
                    next_pwdata             = apb_write_data;
                    if (!PSLVRR) next_state = ENABLE;
                    else next_state         = IDLE;
                end

				ENABLE: begin
				   next_enable =1'b1;
				    // if PSLVRR go to IDLE
				    if (PSLVRR) begin
				       next_state = IDLE;
				    end else begin
					// wait for PREADY to complete transfer
					if (PREADY) begin
					// move to next SETUP if transfer still asserted, else IDLE
					next_state = trasfer ? SETUP : IDLE;
					// prepare PWRITE/paddr/PWDATA for the next trasfer if SETUP
					next_pwrite 
					next_paddr  = READ_WRITE ? apb_read_paddr : apb_write_paddr;
					next_pwdata = apb_write_data;
				end else begin
                    next_state = ENABLE; // remain in ENABLE
                end
               end
            end

            default: next_state = IDLE;
          endcase			
          
		  // error checks (deterministic)
		  // invalid data/address when bus expects values 
		  if ((apb_write_data  === 8'bx) && (!READ_WRITE) && (state==SETUP || state==ENABLE))
		    invalid_write_data  = 1'b1;
		  if ((apb_read_paddr  === 9'bx) && READ_WRITE && (state==SETUP || state==ENABLE))
		    invalid_write_data  = 1'b1;
		  if ((apb_write_paddr === 9'bx) && (!READ_WRITE) && (state==SETUP || state==ENABLE))
		    invalid_write_paddr = 1'b1;
			
		  // setup correctness only when in SETUP: check PADDR/PWDATA will match expected 
		  if (state == SETUP) begin
		    if (next_pwrite) begin
			 if ((next_paddr !== apb_write_paddr) || (next_pwdata !== apb_write_data))
			   setup_error = 1'b1;
			end else begin
			  if (next_paddr !== apb_read_paddr)
			    setup_error = 1'b1;
			end
		  end
		  
		  invalid_setup_error_nxt = setup_error || invalid_read_paddr || invalid_write_data || invalid_write_paddr;
		 end
endmodule
