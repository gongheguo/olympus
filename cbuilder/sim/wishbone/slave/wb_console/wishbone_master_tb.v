//wishbone master interconnect testbench
/*
Distributed under the MIT licesnse.
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


`define TIMEOUT_COUNT 40
`define INPUT_FILE "master_input_test_data.txt"  
`define OUTPUT_FILE "master_output_test_data.txt"

module wishbone_master_tb (
);

//Virtual Host Interface Signals
reg               clk           = 0;
reg               rst           = 0;
wire              master_ready;
reg               in_ready      = 0;
reg   [31:0]      in_command    = 32'h00000000;
reg   [31:0]      in_address    = 32'h00000000;
reg   [31:0]      in_data       = 32'h00000000;
reg   [27:0]      in_data_count = 0;
reg               out_ready     = 0;
wire              out_en;
wire  [31:0]      out_status;
wire  [31:0]      out_address;
wire  [31:0]      out_data;
wire  [27:0]      out_data_count;
reg               ih_reset      = 0;

//wishbone signals
wire              wbm_we_o;
wire              wbm_cyc_o;
wire              wbm_stb_o;
wire [3:0]        wbm_sel_o;
wire [31:0]       wbm_adr_o;
wire [31:0]       wbm_dat_i;
wire [31:0]       wbm_dat_o;
wire              wbm_ack_o;
wire              wbm_int_i;

//wishbone signals
wire              mem_we_o;
wire              mem_cyc_o;
wire              mem_stb_o;
wire [3:0]        mem_sel_o;
wire [31:0]       mem_adr_o;
wire [31:0]       mem_dat_i;
wire [31:0]       mem_dat_o;
wire              mem_ack_o;
wire              mem_int_i;




wishbone_master wm (
  .clk(clk),
  .rst(rst),
  .ih_reset(ih_reset),
  .in_ready(in_ready),
  .in_command(in_command),
  .in_address(in_address),
  .in_data(in_data),
  .in_data_count(in_data_count),
  .out_ready(out_ready),
  .out_en(out_en),
  .out_status(out_status),
  .out_address(out_address),
  .out_data(out_data),
  .out_data_count(out_data_count),
  .master_ready(master_ready),

  .wb_adr_o(wbm_adr_o),
  .wb_dat_o(wbm_dat_o),
  .wb_dat_i(wbm_dat_i),
  .wb_stb_o(wbm_stb_o),
  .wb_cyc_o(wbm_cyc_o),
  .wb_we_o(wbm_we_o),
  .wb_msk_o(wbm_msk_o),
  .wb_sel_o(wbm_sel_o),
  .wb_ack_i(wbm_ack_i),
  .wb_int_i(wbm_int_i),

  //memory bus
  .mem_adr_o(mem_adr_o),
  .mem_dat_o(mem_dat_o),
  .mem_dat_i(mem_dat_i),
  .mem_stb_o(mem_stb_o),
  .mem_cyc_o(mem_cyc_o),
  .mem_we_o(mem_we_o),
  .mem_msk_o(mem_msk_o),
  .mem_sel_o(mem_sel_o),
  .mem_ack_i(mem_ack_i),
  .mem_int_i(mem_int_i)

);

//wishbone slave 0 signals
wire		wbs0_we_o;
wire		wbs0_cyc_o;
wire[31:0]	wbs0_dat_o;
wire		wbs0_stb_o;
wire [3:0]	wbs0_sel_o;
wire		wbs0_ack_i;
wire [31:0]	wbs0_dat_i;
wire [31:0]	wbs0_adr_o;
wire		wbs0_int_i;


//wishbone slave 1 signals
wire		wbs1_we_o;
wire		wbs1_cyc_o;
wire[31:0]	wbs1_dat_o;
wire		wbs1_stb_o;
wire [3:0]	wbs1_sel_o;
wire		wbs1_ack_i;
wire [31:0]	wbs1_dat_i;
wire [31:0]	wbs1_adr_o;
wire		wbs1_int_i;

//arbitrator signals
wire		arb_we_o;
wire		arb_cyc_o;
wire[31:0]	arb_dat_o;
wire		arb_stb_o;
wire [3:0]	arb_sel_o;
wire		arb_ack_i;
wire [31:0]	arb_dat_i;
wire [31:0]	arb_adr_o;
wire		arb_int_i;


//frame buffer master bus
wire		fb_we_o;
wire		fb_cyc_o;
wire[31:0]	fb_dat_o;
wire		fb_stb_o;
wire [3:0]	fb_sel_o;
wire		fb_ack_i;
wire [31:0]	fb_dat_i;
wire [31:0]	fb_adr_o;
wire		fb_int_i;

//wishbone slave 0 signals
wire		mem0_we_o;
wire		mem0_cyc_o;
wire[31:0]	mem0_dat_o;
wire		mem0_stb_o;
wire [3:0]	mem0_sel_o;
wire		mem0_ack_i;
wire [31:0]	mem0_dat_i;
wire [31:0]	mem0_adr_o;
wire		mem0_int_i;



//mem 0
wb_bram m0 (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(arb_we_o),
	.wbs_cyc_i(arb_cyc_o),
	.wbs_dat_i(arb_dat_o),
	.wbs_stb_i(arb_stb_o),
	.wbs_ack_o(arb_ack_i),
	.wbs_dat_o(arb_dat_i),
	.wbs_adr_i(arb_adr_o),
	.wbs_int_o(arb_int_i)
);



//slave 1
wb_console s1 (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(wbs1_we_o),
	.wbs_cyc_i(wbs1_cyc_o),
	.wbs_dat_i(wbs1_dat_o),
	.wbs_stb_i(wbs1_stb_o),
	.wbs_ack_o(wbs1_ack_i),
	.wbs_dat_o(wbs1_dat_i),
	.wbs_adr_i(wbs1_adr_o),
	.wbs_int_o(wbs1_int_i),

	.fb_we_o(fb_we_o),
	.fb_cyc_o(fb_cyc_o),
	.fb_dat_o(fb_dat_o),
	.fb_stb_o(fb_stb_o),
	.fb_ack_i(fb_ack_i),
	.fb_dat_i(fb_dat_i),
	.fb_adr_o(fb_adr_o),
	.fb_int_i(fb_int_i)


);

//arbitrator
arbitrator_2_masters arb (
	.clk(clk),
	.rst(rst),

	.m0_we_i(mem0_we_o),
	.m0_cyc_i(mem0_cyc_o),
	.m0_stb_i(mem0_stb_o),
	.m0_sel_i(mem0_sel_o),
	.m0_ack_o(mem0_ack_i),
	.m0_dat_i(mem0_dat_o),
	.m0_dat_o(mem0_dat_i),
	.m0_adr_i(mem0_adr_o),
	.m0_int_o(mem0_int_i),

	.m1_we_i(fb_we_o),
	.m1_cyc_i(fb_cyc_o),
	.m1_stb_i(fb_stb_o),
	.m1_sel_i(fb_sel_o),
	.m1_ack_o(fb_ack_i),
	.m1_dat_i(fb_dat_o),
	.m1_dat_o(fb_dat_i),
	.m1_adr_i(fb_adr_o),
	.m1_int_o(fb_int_1),

	.s_we_o(arb_we_o),
	.s_cyc_o(arb_cyc_o),
	.s_stb_o(arb_stb_o),
	.s_sel_o(arb_sel_o),
	.s_ack_i(arb_ack_i),
	.s_dat_o(arb_dat_o),
	.s_dat_i(arb_dat_i),
	.s_adr_o(arb_adr_o),
	.s_int_i(arb_int_i)
);



wishbone_interconnect wi (
    .clk(clk),
    .rst(rst),

    .m_we_i(wbm_we_o),
    .m_cyc_i(wbm_cyc_o),
    .m_stb_i(wbm_stb_o),
    .m_ack_o(wbm_ack_i),
    .m_dat_i(wbm_dat_o),
    .m_dat_o(wbm_dat_i),
    .m_adr_i(wbm_adr_o),
    .m_int_o(wbm_int_i),

    .s0_we_o(wbs0_we_o),
    .s0_cyc_o(wbs0_cyc_o),
    .s0_stb_o(wbs0_stb_o),
    .s0_ack_i(wbs0_ack_i),
    .s0_dat_o(wbs0_dat_o),
    .s0_dat_i(wbs0_dat_i),
    .s0_adr_o(wbs0_adr_o),
    .s0_int_i(wbs0_int_i),

    .s1_we_o(wbs1_we_o),
    .s1_cyc_o(wbs1_cyc_o),
    .s1_stb_o(wbs1_stb_o),
    .s1_ack_i(wbs1_ack_i),
    .s1_dat_o(wbs1_dat_o),
    .s1_dat_i(wbs1_dat_i),
    .s1_adr_o(wbs1_adr_o),
    .s1_int_i(wbs1_int_i)


);

wishbone_mem_interconnect wmi (
    .clk(clk),
    .rst(rst),

    .m_we_i(mem_we_o),
    .m_cyc_i(mem_cyc_o),
    .m_stb_i(mem_stb_o),
    .m_ack_o(mem_ack_i),
    .m_dat_i(mem_dat_o),
    .m_dat_o(mem_dat_i),
    .m_adr_i(mem_adr_o),
    .m_int_o(mem_int_i),

    .s0_we_o(mem0_we_o),
    .s0_cyc_o(mem0_cyc_o),
    .s0_stb_o(mem0_stb_o),
    .s0_ack_i(mem0_ack_i),
    .s0_dat_o(mem0_dat_o),
    .s0_dat_i(mem0_dat_i),
    .s0_adr_o(mem0_adr_o),
    .s0_int_i(mem0_int_i)

);

integer           fd_in;
integer           fd_out;
integer           read_count;
integer           timeout_count;
integer           ch;

integer           data_count;

reg               execute_command;
reg               command_finished;
reg               request_more_data;
reg               request_more_data_ack;
reg     [27:0]    data_write_count;


//Clock rate is 50MHz
always #1 clk = ~clk;

initial begin
  fd_out                      = 0;
  read_count                  = 0;
  data_count                  = 0;
  timeout_count               = 0;
  request_more_data_ack       <=  0;
  execute_command             <=  0;

  $dumpfile ("design.vcd");
  $dumpvars (0, wishbone_master_tb);
  fd_in                       = $fopen(`INPUT_FILE, "r");
  fd_out                      = $fopen(`OUTPUT_FILE, "w");

  rst                         <= 0;
  #4
  rst                         <= 1;

  //clear the handler signals
  in_ready                    <= 0;
  in_command                  <= 0;
  in_address                  <= 32'h0;
  in_data                     <= 32'h0;
  in_data_count               <= 0;
  out_ready                   <= 0;
  //clear wishbone signals
  #20
  rst                         <= 0;
  out_ready                   <= 1;

  if (fd_in == 0) begin
    $display ("TB: input stimulus file was not found");
  end
  else begin
    //while there is still data to be read from the file
    while (!$feof(fd_in)) begin
      //read in a command
      read_count              = $fscanf (fd_in, "%h:%h:%h:%h\n", in_data_count, in_command, in_address, in_data);

      if (read_count != 4) begin
        ch = $fgetc(fd_in);
        $display ("Error: read_count = %h != 4", read_count);
        $display ("Character: %h", ch);
      end
      else begin
        case (in_command)
          0: $display ("TB: Executing PING commad");
          1: $display ("TB: Executing WRITE command");
          2: $display ("TB: Executing READ command");
          3: $display ("TB: Executing RESET command");
        endcase
        execute_command                 <= 1;
        #2
        while (~command_finished) begin
          request_more_data_ack         <= 0;

          if ((in_command & 32'h0000FFFF) == 1) begin
            if (request_more_data && ~request_more_data_ack) begin
              read_count      = $fscanf(fd_in, "%h\n", in_data);  
              $display ("TB: reading a new double word: %h", in_data);
              request_more_data_ack     <= 1;
            end
          end

          //so time porgresses wait a tick
          #2
          //this doesn't need to be here, but there is a weird behavior in iverilog
          //that wont allow me to put a delay in right before an 'end' statement
          execute_command <= 1;
        end //while command is not finished
        while (command_finished) begin
          #2;
          execute_command <= 0;
        end
        #100
        $display ("TB: finished command");
      end //end read_count == 4
    end //end while ! eof
  end //end not reset
  #100;
  $fclose (fd_in);
  $fclose (fd_out);
  $finish();
end

parameter         IDLE            = 4'h0;
parameter         EXECUTE         = 4'h1;
parameter         RESET           = 4'h2;
parameter         PING_RESPONSE   = 4'h3;
parameter         WRITE_DATA      = 4'h4;
parameter         WRITE_RESPONSE  = 4'h5;
parameter         GET_WRITE_DATA  = 4'h6;
parameter         READ_RESPONSE   = 4'h7;
parameter         READ_MORE_DATA  = 4'h8;

reg [3:0]         state           =   IDLE;

reg               prev_int        = 0;

//initial begin
//    $monitor("%t, state: %h", $time, state);
//end

always @ (posedge clk) begin
  if (rst) begin
    state                     <= IDLE;
    request_more_data         <= 0;
    timeout_count             <= 0;
    prev_int                  <= 0;
    ih_reset                  <= 0;
    data_write_count          <=  0;
  end
  else begin
    ih_reset                  <= 0;
    in_ready                  <= 0;
    out_ready                 <= 1;
    command_finished          <= 0;


    //Countdown the NACK timeout
    if (execute_command && timeout_count > 0) begin
      timeout_count           <= timeout_count - 1;
    end

    if (execute_command && timeout_count == 0) begin
      case (in_command)
        0: $display ("TB: Master timed out while executing PING commad");
        1: $display ("TB: Master timed out while executing WRITE command");
        2: $display ("TB: Master timed out while executing READ command");
        3: $display ("TB: Master timed out while executing RESET command");
      endcase

      state                   <= IDLE;
      command_finished        <= 1;
      timeout_count           <= `TIMEOUT_COUNT;
      data_write_count        <= 1;
    end //end reached the end of a timeout

    case (state)
      IDLE: begin
        if (execute_command & ~command_finished) begin
          $display ("TB: #:C:A:D = %h:%h:%h:%h", in_data_count, in_command, in_address, in_data);
          timeout_count       <= `TIMEOUT_COUNT;
          state               <= EXECUTE;
        end
      end
      EXECUTE: begin
        if (master_ready) begin
          //send the command over 
          in_ready            <= 1;
          case (in_command & 32'h0000FFFF)
            0: begin
              //ping
              state           <=  PING_RESPONSE;
            end
            1: begin
              //write
              if (in_data_count > 1) begin
                $display ("TB: \tWrote double word %d: %h", data_write_count, in_data);
                state                   <=  WRITE_DATA;
                timeout_count           <= `TIMEOUT_COUNT;
                data_write_count        <=  data_write_count + 1;
              end
              else begin
                if (data_write_count > 1) begin
                  $display ("TB: \tWrote double word %d: %h", data_write_count, in_data);
                end
                state                   <=  WRITE_RESPONSE;
              end
            end
            2: begin
              //read
              state           <=  READ_RESPONSE;
            end
            3: begin
              //reset
              state           <=  RESET;
            end
          endcase
        end
      end
      RESET: begin
        //reset the system
        ih_reset                    <=  1;
        command_finished            <=  1;
        state                       <=  IDLE;
      end
      PING_RESPONSE: begin
        if (out_en) begin
          if (out_status == (~(32'h00000000))) begin
            $display ("TB: Read a successful ping reponse");
          end
          else begin
            $display ("TB: Ping response is incorrect!");
          end
          $display ("TB: \tS:A:D = %h:%h:%h\n", out_status, out_address, out_data);
          command_finished  <= 1;
          state                     <=  IDLE;
        end
      end
      WRITE_DATA: begin
        if (!in_ready && master_ready) begin
          state                     <=  GET_WRITE_DATA;
          request_more_data         <=  1;
        end
      end
      WRITE_RESPONSE: begin
        if (out_en) begin
         if (out_status == (~(32'h00000001))) begin
            $display ("TB: Read a successful write reponse");
          end
          else begin
            $display ("TB: Write response is incorrect!");
          end
          $display ("TB: \tS:A:D = %h:%h:%h\n", out_status, out_address, out_data);
          state                   <=  IDLE;
          command_finished  <= 1;
        end
      end
      GET_WRITE_DATA: begin
        if (request_more_data_ack) begin
//XXX: should request more data be a strobe?
          request_more_data   <=  0;
          in_ready            <=  1;
          in_data_count       <=  in_data_count -1;
          state               <=  EXECUTE;
        end
      end
      READ_RESPONSE: begin
        if (out_en) begin
          if (out_status == (~(32'h00000002))) begin
            $display ("TB: Read a successful read response");
            if (out_data_count > 0) begin
              state             <=  READ_MORE_DATA;
              //reset the NACK timeout
              timeout_count     <=  `TIMEOUT_COUNT;
            end
            else begin
              state             <=  IDLE;
              command_finished  <= 1;
            end
          end
          else begin
            $display ("TB: Read response is incorrect");
            command_finished  <= 1;
          end
          $display ("TB: \tS:A:D = %h:%h:%h\n", out_status, out_address, out_data);
        end
      end
      READ_MORE_DATA: begin
        if (out_en) begin
          out_ready             <=  0;
          if (out_status == (~(32'h00000002))) begin
            $display ("TB: Read a 32bit data packet");
            $display ("Tb: \tRead Data: %h", out_data);
          end
          else begin
            $display ("TB: Read reponse is incorrect");
          end

          //read the output data count to determine if there is more data
          if (out_data_count == 0) begin
            state             <=  IDLE;
            command_finished  <=  1;
          end
        end
      end
      default: begin
        $display ("TB: state is wrong");
        state <= IDLE;
      end //somethine wrong here
    endcase //state machine
    if (out_en && out_status == `PERIPH_INTERRUPT) begin
      $display("TB: Output Handler Recieved interrupt");
      $display("TB:\tcommand: %h", out_status);
      $display("TB:\taddress: %h", out_address);
      $display("TB:\tdata: %h", out_data);
    end
  end//not reset
end


endmodule
