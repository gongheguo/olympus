//wb_sdram.v
/*
Distributed under the MIT license.
Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
*/

/*
	Use this to tell sycamore how to populate the Device ROM table
	so that users can interact with your slave

	META DATA

	identification of your device 0 - 65536
	DRT_ID:  5

	flags (read drt.txt in the slave/device_rom_table directory 1 means
	a standard device
	DRT_FLAGS:  1

	number of registers this should be equal to the nubmer of ADDR_???
	parameters
	DRT_SIZE:  4194304

*/


module wb_sdram (
	clk,
	rst,

	//Add signals to control your device here

	wbs_we_i,
	wbs_cyc_i,
	wbs_sel_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,


	sdram_clk,
	sdram_cke,
	sdram_cs_n,
	sdram_ras,
	sdram_cas,
	sdram_we,

	sdram_addr,
	sdram_bank,
	sdram_data,
	sdram_data_mask,
	sdram_ready

);

input 				clk;
input 				rst;

//wishbone slave signals
input 				    wbs_we_i;
input 				    wbs_stb_i;
input 				    wbs_cyc_i;
input		  [3:0]	  wbs_sel_i;
input		  [31:0]	wbs_adr_i;
input  		[31:0]	wbs_dat_i;
output		[31:0]	wbs_dat_o;
output reg			  wbs_ack_o;
output reg			  wbs_int_o;


//SDRAM signals
output				sdram_clk;
output				sdram_cke;
output				sdram_cs_n;
output				sdram_ras;
output				sdram_cas;
output				sdram_we;

output		[11:0]	sdram_addr;
output		[1:0]	  sdram_bank;
inout		  [15:0]	sdram_data;
output		[1:0]	  sdram_data_mask;
output				    sdram_ready;


reg					fifo_wr;
reg					fifo_rd;

wire				wr_fifo_full;
wire				rd_fifo_empty;

reg       [3:0] delay;
reg         wb_reading;

reg         writing;
reg         reading;


sdram ram (
	.clk(clk),
	.rst(rst),

	.app_write_pulse(fifo_wr),
	.app_write_data(wbs_dat_i),
	.app_write_mask(~wbs_sel_i),
	.write_fifo_full(wr_fifo_full),

	.app_read_pulse(fifo_rd),
	.app_read_data(wbs_dat_o),
	.read_fifo_empty(rd_fifo_empty),

	.app_write_enable(writing),
	.app_read_enable(reading),
	.sdram_ready(sdram_ready),
	.app_address(wbs_adr_i[23:2]),
	
	.sd_clk(sdram_clk),
	.cke(sdram_cke),
	.cs_n(sdram_cs_n),
	.ras(sdram_ras),
	.cas(sdram_cas),
	.we(sdram_we),

	.address(sdram_addr),
	.bank(sdram_bank),
	.data(sdram_data),
	.data_mask(sdram_data_mask)

);

//blocks
always @ (posedge clk) begin
	if (rst) begin
		wbs_ack_o		<= 0;
		wbs_int_o		<= 0;
		fifo_wr			<= 0;
		fifo_rd			<= 0;
    delay       <= 0;
    wb_reading  <= 0;
    writing     <= 0;
    reading     <= 0;
	end
	else begin
		fifo_wr		<=	0;
		fifo_rd		<=	0;
		
		//when the master acks our ack, then put our ack down
    if (~wbs_cyc_i) begin
      writing <=  0;
      reading <=  0;
    end
		if (wbs_ack_o & ~wbs_stb_i)begin
			wbs_ack_o <= 0;
		end

		if (wbs_stb_i & wbs_cyc_i) begin
    	//master is requesting somethign
			if (wbs_we_i) begin
        writing <=  1;
				//write request
				if (~wr_fifo_full & ~wbs_ack_o) begin
				  $display("user wrote %h to address %h", wbs_dat_i, wbs_adr_i);
					wbs_ack_o <= 1;
					fifo_wr		<=	1;
				end
			end

      //Reading
			else if (~writing) begin 
        reading <=  1;
        if (delay > 0) begin
          delay <= delay - 1;
        end
        else begin
          if (wb_reading) begin
            wbs_ack_o <=  1;
            wb_reading <=  0;
          end
          else begin
    				//read request
	    			if (~rd_fifo_empty & ~wbs_ack_o) begin
		    		//	$display("user wb_reading %h", wbs_dat_o);
			    		fifo_rd	<=	1;
              wb_reading <=  1;
              delay   <=  1;
				    end
          end
        end
			end
		end
	end
end


endmodule
