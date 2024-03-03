//------------------------------------------------------//
//- Digital IC Design 2021                              //
//-                                                     //
//- Final Project: FP_MUL                               //
//------------------------------------------------------//
`timescale 1ns/10ps

//cadence translate_off
//cadence translate_on

module FP_MUL(CLK, RESET, ENABLE, DATA_IN, DATA_OUT, READY);

//Parameter
parameter n_stage=22;
parameter fp_latency=46;//fp_latency= 2*n_stage -1 + 3(operate Z_frac_final times)
// I/O Ports
input         CLK; //clock signal
input         RESET; //sync. RESET=1
input         ENABLE; //input data sequence when ENABLE =1
input   [7:0] DATA_IN; //input data sequence
output  [7:0] DATA_OUT; //ouput data sequence
output        READY; //output data is READY when READY=1

reg           READY;
reg     [4:0] counter_in;
reg           in_data_rdy;
reg     [7:0] output_Z [0:7];
reg     [7:0] DATA_OUT;
reg     [3:0] counter_out;
reg		[6:0] counter_self;
reg 	 	  A_sign,B_sign,Z_sign;
reg		[10:0]A_expo,B_expo;
reg		[11:0]AB_expo,Z_expo;
reg		[51:0]A_frac,B_frac;
reg		[54:0]A_frac_temp,B_frac_temp;
wire	[103:0]mult_AB_frac;
reg  	[103:0]AB_frac_temp; //
reg  	[54:0]AB_frac;//
reg		[54:0]one_temp;
reg		[54:0]Z_frac;
reg		[54:0]Z_frac_norm1;
reg 	[54:0]Z_frac_norm1_temp;
reg		[51:0]Z_frac_final;
reg    	[1:0]carry;

integer       fp_count;
integer       i;

//CW_mult_n_stage #(52, 52, n_stage) u1 ( .A(A_frac), .B(B_frac), .TC(1'd0), .CLK (CLK), .Z(mult_AB_frac));

//Latch input data sequence
always@(posedge CLK)
begin
	if(RESET) begin
    	counter_in <= 0;
 	end 
	else if (ENABLE && (counter_in < 5'd8) ) begin
    	counter_in <= counter_in + 1'b1;  
 	end 
	else if (ENABLE && (counter_in < 5'd15) ) begin
    	counter_in <= counter_in + 1'b1;
 	end 
	else if (counter_out == 4'd8) begin //When output is completed, in_data_rdy=0;
     	counter_in <= 0;     
	end
end

always@(posedge CLK)
begin
	if(RESET)
		counter_self <= 7'd0;
	else if(counter_self == (26 + fp_latency))
		counter_self <= 7'd0;
	else
		counter_self <= counter_self + 7'd1;
end

always@(posedge CLK)
begin
	if(RESET)begin
		A_sign <= 1'd0;
		B_sign <= 1'd0;
		Z_sign <= 1'd0;
	end else if(counter_self == 8) begin
		A_sign <= DATA_IN[7];
	end else if(counter_self == 16) begin
		B_sign <= DATA_IN[7];
	end else if(counter_self == 17) begin
		Z_sign <= A_sign ^ B_sign;
	end else if(counter_self == (26 + fp_latency))begin
		A_sign <= 1'd0;
		B_sign <= 1'd0;
		Z_sign <= 1'd0;
	end else begin
		A_sign <= A_sign;
		B_sign <= B_sign;
		Z_sign <= Z_sign;
	end
end

always@(posedge CLK)
begin
	if(RESET)begin
		A_expo <= 11'd0;
		B_expo <= 11'd0;
	end else if(counter_self == 7) begin
		A_expo[3:0] <= DATA_IN[7:4];
	end else if(counter_self == 8) begin
		A_expo[10:4] <= DATA_IN[6:0];
	end else if(counter_self == 15) begin
		B_expo[3:0] <= DATA_IN[7:4];
	end else if(counter_self == 16) begin
		B_expo[10:4] <= DATA_IN[6:0];
	end else if(counter_self == (17 + fp_latency))begin
		A_expo <= 11'd0;
		B_expo <= 11'd0;
	end else begin
		A_expo <= A_expo;
		B_expo <= B_expo;
	end
end	

always@(posedge CLK)
begin
	if(RESET)begin
		AB_expo <= 12'd0;
		Z_expo  <= 12'd0;
	end else if(counter_self < 16 ) begin
		AB_expo <= 12'd0;
		Z_expo  <= 12'd0;
	end else if(counter_self == (15 + n_stage + n_stage)) begin
		AB_expo <= A_expo + B_expo;
	end else if(counter_self == (15 + n_stage + n_stage + 1)) begin
			Z_expo <= AB_expo - 1023;
	end else if(counter_self == (16 + fp_latency))begin
			Z_expo <= Z_expo + carry ;
	end else if(counter_self == (26 + fp_latency))begin
		AB_expo <= 12'd0;
		Z_expo  <= 12'd0;
	end else begin
		AB_expo <= AB_expo;
		Z_expo  <= Z_expo;
	end
end
		
always@(posedge CLK)
begin
	if(RESET)begin
		A_frac <= 52'd0;
	end else if(counter_self == 1) begin
		A_frac[7:0] <= DATA_IN;
	end else if(counter_self == 2) begin
		A_frac[15:8] <= DATA_IN;
	end else if(counter_self == 3) begin
		A_frac[23:16] <= DATA_IN;
	end else if(counter_self == 4) begin
		A_frac[31:24] <= DATA_IN;
	end else if(counter_self == 5) begin
		A_frac[39:32] <= DATA_IN;
	end else if(counter_self == 6) begin
		A_frac[47:40] <= DATA_IN;
	end else if(counter_self == 7) begin
		A_frac[51:48] <= DATA_IN[3:0];
	end else if(counter_self == (15 + n_stage))begin
		A_frac <= 52'd0;
	end else begin
		A_frac <= A_frac;
	end
end	

always@(posedge CLK)
begin
	if(RESET)begin
		B_frac <= 52'd0;
	end else if(counter_self == 9) begin
		B_frac[7:0] <= DATA_IN;
	end else if(counter_self == 10) begin
		B_frac[15:8] <= DATA_IN;
	end else if(counter_self == 11) begin
		B_frac[23:16] <= DATA_IN;
	end else if(counter_self == 12) begin
		B_frac[31:24] <= DATA_IN;
	end else if(counter_self == 13) begin
		B_frac[39:32] <= DATA_IN;
	end else if(counter_self == 14) begin
		B_frac[47:40] <= DATA_IN;
	end else if(counter_self == 15) begin
		B_frac[51:48] <= DATA_IN[3:0];
	end else if(counter_self == (15 + n_stage))begin
		B_frac <= 52'd0;
	end else begin
		B_frac <= B_frac;
	end
end	

always@(posedge CLK)
begin
	if(RESET)begin
		A_frac_temp <= 55'd0;
		B_frac_temp <= 55'd0;
		AB_frac_temp <= 104'd0;
		AB_frac 	<= 55'd0;
		one_temp	<= 55'd0;
		Z_frac  	<= 55'd0;
		Z_frac_norm1 <= 55'd0;
		Z_frac_norm1_temp <= 55'd0;
		Z_frac_final <= 52'd0;
		carry <= 2'd0;
	end else if(counter_self <= (14 + n_stage)) begin
		A_frac_temp <= 55'd0;
		B_frac_temp <= 55'd0;
		AB_frac_temp <= 104'd0;
		AB_frac 	<= 55'd0;
		one_temp	<= 55'd0;
		Z_frac  	<= 55'd0;
		Z_frac_norm1 <= 55'd0;
		Z_frac_norm1_temp <= 55'd0;
		Z_frac_final <= 52'd0;
		carry <= 2'd0;
	end else if(counter_self == (15 + n_stage)) begin
			A_frac_temp[52:1] <= A_frac;
			B_frac_temp[52:1] <= B_frac;
	end else if(counter_self == (13 + n_stage + n_stage)) begin
			AB_frac_temp <= A_frac_temp[52:1] * B_frac_temp[52:1];
			one_temp[53] <= 1'd1;
	end else if(counter_self == (14 + n_stage + n_stage))begin
			Z_frac <= A_frac_temp + B_frac_temp + AB_frac_temp[103:51] + one_temp;
	end else if(counter_self == (14 + n_stage + n_stage + 1))begin
		if(Z_frac[54] == 1'd1)begin
			Z_frac_norm1 <= Z_frac >> 1;
			carry <= 2'd1;
		end else begin
			Z_frac_norm1 <= Z_frac;
		end
	end else if(counter_self == (14 + n_stage + n_stage + 2))begin
		if(Z_frac_norm1[0] == 1'd1)
			Z_frac_norm1_temp <= Z_frac_norm1 + 1'd1;
		else
			Z_frac_norm1_temp <= Z_frac_norm1;
	end else if(counter_self == (14 + n_stage + n_stage + 3))begin
			Z_frac_final <= Z_frac_norm1_temp[52:1];
	end else if(counter_self == (26 + fp_latency))begin
		A_frac_temp <= 55'd0;
		B_frac_temp <= 55'd0;
		AB_frac 	<= 55'd0;
		one_temp	<= 55'd0;
		Z_frac  	<= 55'd0;
		Z_frac_norm1 <= 55'd0;
		Z_frac_norm1_temp <= 55'd0;
		Z_frac_final <= 52'd0;
		carry <= 2'd0;
	end else begin
		A_frac_temp <= A_frac_temp;
		B_frac_temp <= B_frac_temp;
		AB_frac 	<= AB_frac;
		one_temp	<= one_temp;
		Z_frac  	<= Z_frac;
		Z_frac_norm1 <= Z_frac_norm1;
		Z_frac_norm1_temp <= Z_frac_norm1_temp;
		Z_frac_final <= Z_frac_final;
		carry <= carry;
	end
end

always@(posedge CLK)
begin
	if(RESET)
		for(i=0; i <= 7; i=i+1) output_Z[i] <= 0;
	else if(in_data_rdy)begin
		output_Z[7] <= {Z_sign,Z_expo[10:4]};
		output_Z[6] <= {Z_expo[3:0],Z_frac_final[51:48]};
		output_Z[5] <= Z_frac_final[47:40];
		output_Z[4] <= Z_frac_final[39:32];
		output_Z[3] <= Z_frac_final[31:24];
		output_Z[2] <= Z_frac_final[23:16];
		output_Z[1] <= Z_frac_final[15:8];
		output_Z[0] <= Z_frac_final[7:0];
	end else begin
		for(i=0; i <= 7; i=i+1) output_Z[i] <= output_Z[i];
	end
end

always@(posedge CLK)
begin
	if(RESET)
     in_data_rdy <= 1'b0;
  	else if (ENABLE && (counter_in < 5'd8) )
     in_data_rdy <= 1'b0;
  	else if (ENABLE && (counter_in < 5'd15))
     in_data_rdy <= 1'b0;
  	else if (ENABLE && !in_data_rdy) //Last input received, in_data_rdy=1
     in_data_rdy <= 1'b1;
  	else if (counter_out == 4'd8)//When output is completed, in_data_rdy=0;
     in_data_rdy <= 1'b0;   
end

//Output Control
always@(posedge CLK)
begin
  if(RESET) begin
     fp_count <= 0;
     READY <= 0;
     DATA_OUT <= 0;
     counter_out <= 0;
  end else if (in_data_rdy && (fp_count != fp_latency)) begin
     fp_count <= fp_count + 1'b1;
  end else if (in_data_rdy) begin //input is ready
        
     if(counter_out < 4'd8) begin
        DATA_OUT <= output_Z[counter_out];
        counter_out <= counter_out + 1'b1;
        READY <= 1'b1;
     end else begin
        READY <= 1'b0;
     end

  end else begin
     counter_out <= 0;
     fp_count <= 0;
  end
end

endmodule
