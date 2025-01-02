module bitcoin_hash (
	input logic clk, reset_n, start,
    input logic [15:0] message_addr, output_addr,
    output logic done, mem_clk, mem_we,
    output logic [15:0] mem_addr,
    output logic [31:0] mem_write_data,
    input logic [31:0] mem_read_data
);

parameter NUM_NONCES = 16;
parameter NUM_WORDS = 20;

logic istart[16];
logic idone[16];
logic ireset; // why different reset?
logic [7:0] i;
logic [15:0] offset; // in word address
logic        cur_we;
logic [15:0] cur_addr;
logic [31:0] cur_write_data;
logic [31:0] cur_nonce;

assign mem_clk = clk;
assign mem_addr = cur_addr + offset;
assign mem_we = cur_we;
assign mem_write_data = cur_write_data;

enum logic[3:0] {IDLE, WAIT, READ, PREPHASE1, PHASE1, BLOCK2, PREPHASE2, PHASE2, BLOCK3, PREPHASE3, PHASE3, WRITE, INCREMENT} state;
logic [31:0] hin[7:0];

logic [31:0] w[NUM_NONCES][16]; // First, 16 words are the same for all nonce values so we only need on, this is for the differing '2nd block'

logic [31:0] message[20];

logic [31:0] hout[NUM_NONCES][7:0];

genvar k;
generate
	// create 16 SHA256 Modules
	for (k = 0; k < NUM_NONCES; k++) begin : gen_for_sha256
		sha256_parallel #(.NUM_OF_WORDS(NUM_WORDS)) sha256_parallel_inst(
 			.clk(clk), 
			.w(w[k]),
 			.reset_n(ireset), 
 			.start(istart[k]),
 			.done(idone[k]), 
			.hin(hin),
			.hout(hout[k])
 		);
	end
endgenerate

always_ff @(posedge clk, negedge reset_n) begin
  if (!reset_n) begin
		state <= IDLE;
		for (int n = 0; n < 16; n++) begin
			istart[n] <= 1'b0;
		end
		ireset <= 0;
		offset <= 0;
    	i <= 0;
  end else begin
		case (state)
			IDLE: begin
				if (start) begin
					state <= WAIT;
					ireset <= 1; // Necessary to keep at high?
					cur_addr <= message_addr;
       				offset <= 0; 
        			cur_we <= 1'b0;
				end else begin
					state <= IDLE;
				end
			end
			
			WAIT: begin // one extra state to wait for memory read
      			state <= READ;
      			offset <= offset + 1;
    		end

			// generates message block1
	  		READ: begin
		 		// Read 640 bits message from testbench memory in chunks of 32bits words (i.e. read 20 locations from memory by incrementing address offset) Move to Block creation FSM state
				if (i < NUM_WORDS) begin
					message[i] <= mem_read_data;
					offset <= offset + 1;
					i <= i + 1;
		 		end else begin
					// get first 16 bits of messages to w i.e. phase 1
					for (int n = 0; n < 16; n++) begin
						w[0][n] <= message[n];
					end
					state <= PREPHASE1; // Transition to next state
					offset <= 0; // reset offset
		 		end
			end

			PREPHASE1: begin
				// Load original Hashes into Hin
				hin[0] <= 32'h6a09e667;
			  	hin[1] <= 32'hbb67ae85;
			  	hin[2] <= 32'h3c6ef372;
			  	hin[3] <= 32'ha54ff53a;
			  	hin[4] <= 32'h510e527f;
			  	hin[5] <= 32'h9b05688c;
        		hin[6] <= 32'h1f83d9ab;
				hin[7] <= 32'h5be0cd19;

				// start the 1st sha256 module out of the 8
				istart[0] <= 1'b1;
				state <= PHASE1;
			end

			
			PHASE1: begin
				if (idone[0] == 1) begin
					state <= BLOCK2;
					ireset <= 0; // reset all modules
					// Prepare hash values
					hin[0] <= hout[0][0];
					hin[1] <= hout[0][1];
					hin[2] <= hout[0][2];
					hin[3] <= hout[0][3];
					hin[4] <= hout[0][4];
					hin[5] <= hout[0][5];
					hin[6] <= hout[0][6];
					hin[7] <= hout[0][7];
				end else begin
					state <= PHASE1;
				end
			end

			// generates message block2 
			BLOCK2: begin
				ireset <= 1;
				for (int j = 0; j < 16; j++) begin
					for (int e = 0; e < 3; e++) begin
				 		w[j][e] <= message[16 + e];
			  		end 
				
					w[j][3] <= j;
					w[j][4] <= 32'h80000000;

	
					for (int e = 0; e < 10; e++) begin
						w[j][e + 5] <= 32'h00000000;
					end

					w[j][15] <= 32'd640;
				end
				state <= PREPHASE2;
			end

			PREPHASE2: begin
				// start all 16 modules
				for (int n = 0; n < 16; n++) begin
					istart[n] <= 1'b1;
				end
				state <= PHASE2;
			end


			PHASE2: begin

				if (idone[0] == 1'b1) begin
					$display("Phase 2 done!");
					state <= BLOCK3;
					for (int n = 0; n < 16; n++) begin
						istart[n] <= 1'b0;
					end
					ireset <= 0; // reset all modules
					for (int j = 0; j < 16; j++) begin
					//Hash value from Phase 2
						w[j][0] <= hout[j][0];
						w[j][1] <= hout[j][1];
						w[j][2] <= hout[j][2];
						w[j][3] <= hout[j][3];
						w[j][4] <= hout[j][4];
						w[j][5] <= hout[j][5];
						w[j][6] <= hout[j][6];
						w[j][7] <= hout[j][7];
						//Padding 1
						w[j][8] <= 32'h80000000;
						// Padding 0s
						for (int s = 9; s < 15; s++) begin
							w[j][s] <= 32'h00000000; 
						end 
						//message padding size
						w[j][15] <= 32'd256; 
					end
				end else begin
					// wait for the operations to be done
					state <= PHASE2;
				end
			end


			BLOCK3: begin
				ireset <= 1'b1;
				
				state <= PREPHASE3;
			end


			PREPHASE3: begin
				//Original Hash values
				hin[0] <= 32'h6a09e667;
			  	hin[1] <= 32'hbb67ae85;
			  	hin[2] <= 32'h3c6ef372;
			  	hin[3] <= 32'ha54ff53a;
			  	hin[4] <= 32'h510e527f;
			  	hin[5] <= 32'h9b05688c;
        		hin[6] <= 32'h1f83d9ab;
				hin[7] <= 32'h5be0cd19;

				// start all 16 modules
				for (int n = 0; n < 16; n++) begin
					istart[n] <= 1'b1;
				end
				state <= PHASE3;

			end
			


			PHASE3: begin
				if (idone[0] == 1'b1) begin
					state <= WRITE;
					for (int n = 0; n < 16; n++) begin
						istart[n] <= 1'b0;
					end
					ireset <= 0; // reset all modules
				end else begin
					// wait for the operations to be done
					state <= PHASE3;
				end
			end


			WRITE: begin

				// Only need to write H0 out
				cur_we <= 1'b1;
      			cur_addr <= output_addr;
				cur_write_data <= hout[offset][0];
				if (offset < 16) begin
        			state <= INCREMENT;
      			end else begin
        			cur_we <= 1'b0;
        			state <= IDLE;
      			end
    		end


    		INCREMENT: begin
      			offset <= offset + 1;
      			state <= WRITE;
   		 	end
		endcase
    end
end

assign done = (state == IDLE);

endmodule
