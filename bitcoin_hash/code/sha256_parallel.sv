// Simplified SHA-256 module for bitcoin phase one, only one block.
module sha256_parallel #(parameter integer NUM_OF_WORDS = 20)(
 input logic  clk, reset_n, start,
 input logic [31:0] w[16],
 input logic [31:0] hin[7:0],
 output logic done,
 output logic [31:0] hout[7:0]);

// FSM state variables 
enum logic [2:0] {IDLE, COMPUTE, DONE} state;


// Local variables
logic [31:0] wt[16];
logic [31:0] h_b[8];
logic [31:0] a, b, c, d, e, f, g, h;
logic [7:0] i, t;
// SHA256 K constants
parameter int k[0:63] = '{
   32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
   32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
   32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
   32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
   32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
   32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
   32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
   32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
};

function logic [31:0] wtnew;
	logic [31:0] s0, s1;
  
	s0 = rightrotate(wt[1], 7) ^ rightrotate(wt[1], 18) ^ (wt[1] >> 3);
	s1 = rightrotate(wt[14], 17) ^ rightrotate(wt[14], 19) ^ (wt[14] >> 10);
	wtnew = wt[0] + s0 + wt[9] + s1;

endfunction


// SHA256 hash round
function logic [255:0] sha256_op(input logic [31:0] a, b, c, d, e, f, g, h, w,
                                 input logic [7:0] t);
    logic [31:0] S1, S0, ch, maj, t1, t2; // internal signals
    begin
        S1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25);
        ch = (e & f) ^ ((~e) & g);
        t1 = h + S1 + ch + k[t] + w;
        S0 = rightrotate(a, 2) ^ rightrotate(a, 13) ^ rightrotate(a, 22);
        maj = (a & b) ^ (a & c) ^ (b & c);
        t2 = S0 + maj;

        sha256_op = {t1 + t2, a, b, c, d + t1, e, f, g};
    end
endfunction


// Right Rotation Example : right rotate input x by r
// Lets say input x = 1111 ffff 2222 3333 4444 6666 7777 8888
// lets say r = 4
// x >> r  will result in : 0000 1111 ffff 2222 3333 4444 6666 7777 
// x << (32-r) will result in : 8888 0000 0000 0000 0000 0000 0000 0000
// final right rotate expression is = (x >> r) | (x << (32-r));
// (0000 1111 ffff 2222 3333 4444 6666 7777) | (8888 0000 0000 0000 0000 0000 0000 0000)
// final value after right rotate = 8888 1111 ffff 2222 3333 4444 6666 7777
// Right rotation function
function logic [31:0] rightrotate(input logic [31:0] x,
                                  input logic [ 7:0] r);
   rightrotate = (x >> r) | (x << (32 - r));
endfunction


// SHA-256 FSM 
// Get a BLOCK from the memory, COMPUTE Hash output using SHA256 function
// and write back hash value back to memory
always_ff @(posedge clk, negedge reset_n)
begin
  if (!reset_n) begin
    state <= IDLE;
    i <= 0;
    t <= 0;
    done <= 0;
  end 
  else case (state)
    // Initialize hash values h0 to h7 and a to h, other variables and memory we, address offset, etc
    IDLE: begin
      done <= 0; 
		if(start) begin
      // get the messages ready
      for(int h = 0; h < 16; h++) begin
        wt[h] <= w[h];
      end
      // initialize hash values
			h_b[0] <= hin[0];
			h_b[1] <= hin[1];
			h_b[2] <= hin[2];
			h_b[3] <= hin[3];
			h_b[4] <= hin[4];
			h_b[5] <= hin[5];
			h_b[6] <= hin[6];
			h_b[7] <= hin[7];
			
      // initialize abcdefgh
			a <= hin[0];
			b <= hin[1];
			c <= hin[2];
			d <= hin[3];
			e <= hin[4];
			f <= hin[5];
			g <= hin[6];
			h <= hin[7];
        
      state <= COMPUTE;
		  
      i <= 0;
      t <= 0;
      end
    end

    COMPUTE: begin
      // word expansion
		
		  if (t < 64) begin
			  // SHA Operation for w = 0 to 14, from the original W[16] array
			
			  {a, b, c, d, e, f, g, h} <= sha256_op(a, b, c, d, e, f, g, h, wt[0], t);	
			
			  for (int n = 0; n < 15; n++) wt[n] <= wt[n + 1];
			  wt[15] <= wtnew();
			
			  t <= t + 1;
			
			  state <= COMPUTE;

      end else begin
		
	      state <= DONE;
        // Setting up the required hash for the block
        hout[0] <= h_b[0] + a;
        hout[1] <= h_b[1] + b;
        hout[2] <= h_b[2] + c;
        hout[3] <= h_b[3] + d;
        hout[4] <= h_b[4] + e;
        hout[5] <= h_b[5] + f;
        hout[6] <= h_b[6] + g;
        hout[7] <= h_b[7] + h;			 

      end
    end

    DONE: begin
      state <= IDLE;
      done <= 1;
    end
   endcase
  end

endmodule
