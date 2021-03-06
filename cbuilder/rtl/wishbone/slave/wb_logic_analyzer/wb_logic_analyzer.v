//wb_logic_analyzer.v
/*
Distributed under the GNU GPL
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
  DRT_ID:  12

  flags (read drt.txt in the slave/device_rom_table directory 1 means
  a standard device
  DRT_FLAGS:  1

  number of registers this should be equal to the nubmer of ADDR_???
  parameters
  DRT_SIZE:  16

*/

//this code was inspired byt Laurentiu DUCA and the openverifla project

`include "logic_analyzer_defines.v"

`define CONTROL_RESET             0
`define CONTROL_ENABLE_INTERRUPT  1
`define CONTROL_ENABLE_LA         2
`define CONTROL_RESTART_LA        3

`define STATUS_FINISHED           0

module wb_logic_analyzer(
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

  //logic analyzer
  la_clk,
  la_data,
  la_ext_trig,
  
  //uart interface
  la_uart_tx,
  la_uart_rx

);

input               clk;
input               rst;

//wishbone slave signals
input               wbs_we_i;
input               wbs_stb_i;
input               wbs_cyc_i;
input       [3:0]   wbs_sel_i;
input       [31:0]  wbs_adr_i;
input       [31:0]  wbs_dat_i;
output reg  [31:0]  wbs_dat_o;
output reg          wbs_ack_o;
output reg          wbs_int_o;

//logic anayzer signals
input               la_clk;
input       [`CAP_DAT_WIDTH - 1: 0]  la_data;
input               la_ext_trig;
//these are used to interface with te LA through a UART in case users is
//debugging a host communication
input               la_uart_rx;
output              la_uart_tx;
reg   [3:0]         read_history;
reg                 reset;


//parameters

parameter     CONTROL       = 32'h00000000;
parameter     STATUS        = 32'h00000001;
parameter     TRIGGER       = 32'h00000002;
parameter     TRIGGER_MASK  = 32'h00000003;
parameter     TRIGGER_AFTER = 32'h00000004;
parameter     TRIGGER_EDGE  = 32'h00000005;
parameter     BOTH_EDGES    = 32'h00000006;
parameter     REPEAT_COUNT  = 32'h00000007;
parameter     DATA_COUNT    = 32'h00000008;
parameter     CLOCK_DIVIDER = 32'h00000009;
parameter     READ_DATA     = 32'h00000010;



//register/wires
reg   [31:0]                control;
wire  [31:0]                status;
reg   [31:0]                trigger;
reg   [31:0]                trigger_mask;
reg   [31:0]                trigger_after;
reg   [31:0]                trigger_edge;
reg   [31:0]                both_edges;
reg   [31:0]                repeat_count;
reg   [31:0]                clock_divider;
reg                         set_strobe;

reg                         data_read_en;
reg   [31:0]                data_read_count;

wire                        control_reset;
wire                        interrupt_enable;
wire                        control_enable_la;
wire                        control_restart_la;


reg                         wb_data_read_strobe;
reg   [3:0]                 sleep;

//logic analyzer finished capture
wire                        finished;

reg                         disable_uart;
wire  [31:0]                uart_trigger;
wire  [31:0]                uart_trigger_mask;
wire  [31:0]                uart_trigger_after;
wire  [31:0]                uart_trigger_edge;
wire  [31:0]                uart_both_edges;
wire  [31:0]                uart_repeat_count;
wire                        uart_set_strobe;
wire                        uart_enable;

wire                        udata_read_strobe;


wire                        la_data_read_strobe;
wire  [31:0]                la_data_read_size;
wire  [31:0]                la_data_out;

//submodule
uart_la_interface ulac (
  .rst(reset),
  .clk(clk),

  .trigger(uart_trigger),
  .trigger_mask(uart_trigger_mask),
  .trigger_after(uart_trigger_after),
  .trigger_edge(uart_trigger_edge),
  .both_edges(uart_both_edges),
  .repeat_count(uart_repeat_count),
  .set_strobe(uart_set_strobe),
  .disable_uart(disable_uart),
  .enable(uart_enable),
  .finished(finished),

  .data_read_strobe(udata_read_strobe),
  .data_read_size(la_data_read_size),
  .data(la_data_out),

  .phy_rx(la_uart_rx),
  .phy_tx(la_uart_tx)
);

logic_analyzer #(
  .CAPTURE_WIDTH(`CAP_DAT_WIDTH),
  .CAPTURE_DEPTH(`CAP_MEM_SIZE)
)la (
  .clk(clk),
  .rst(reset),
  
  .cap_clk(la_clk),
  .cap_external_trigger(la_ext_trig),
  .cap_data(la_data),
  .clk_div(clock_divider),

  .trigger(trigger),
  .trigger_mask(trigger_mask),
  .trigger_after(trigger_after),
  .trigger_edge(trigger_edge),
  .both_edges(both_edges),
  .repeat_count(repeat_count),
  .set_strobe(set_strobe),
  .enable(enable),
  .restart(control_restart_la),
  .finished(finished),

  .data_out_read_strobe(la_data_read_strobe),
  .data_out_read_size(la_data_read_size),
  .data_out(la_data_out)

);

//asynchronous logic

assign  control_reset       = control[`CONTROL_RESET];
assign  interrupt_enable    = control[`CONTROL_ENABLE_INTERRUPT];
assign  control_enable_la   = control[`CONTROL_ENABLE_LA];
assign  control_restart_la  = control[`CONTROL_RESTART_LA];


assign  status[`STATUS_FINISHED]  = finished;
assign  status[31:1]              = 31'h0000000;

assign  la_data_read_strobe = (udata_read_strobe || wb_data_read_strobe);
assign  enable              = (uart_enable | control_enable_la);


//synchronous logic

//initialize variables within startup (this will work for synthesis too)
initial begin
  control           <=  1;
end

//extended reset logic
always @ (posedge clk) begin
  if (control_reset) begin
    reset                   <=  1;
    read_history            <=  0;
  end
  else begin
    reset                   <=  1;
    if (read_history == 4'b1111) begin
      reset                 <=  0;
    end
    read_history            <=  {read_history[2:0], 1'h1};
  end
end


//WB Interface Contrller
always @ (posedge clk) begin
  if (rst) begin
    wbs_dat_o               <=  32'h0;
    wbs_ack_o               <=  0;
    data_read_count         <=  0;
    wb_data_read_strobe     <=  0;
    sleep                   <=  0;
    disable_uart            <=  0;
  end

  else if (control_reset) begin
    //reset the rest flag
    control[`CONTROL_RESET] <=  0;

    clock_divider           <=  0;
    trigger                 <=  0;
    trigger_mask            <=  0;
    trigger_after           <=  0;
    trigger_edge            <=  0;
    both_edges              <=  0;
    repeat_count            <=  0;
    data_read_en            <=  0;
    wb_data_read_strobe     <=  0;
    sleep                   <=  0;
    disable_uart            <=  0;
  end

  else begin
    control[`CONTROL_RESTART_LA]  <=  0;
    disable_uart            <=  0;

    if (~wbs_cyc_i) begin
      set_strobe                  <=  0;
    end

    //check to see if the UART device sent a set_strobe
    if (uart_set_strobe) begin
      trigger               <=  uart_trigger;
      trigger_mask          <=  uart_trigger_mask;
      trigger_after         <=  uart_trigger_after;
      trigger_edge          <=  uart_trigger_edge;
      both_edges            <=  uart_both_edges;
      repeat_count          <=  uart_repeat_count;
      set_strobe            <=  1;
    end

    wb_data_read_strobe     <=  0;
    //when the master acks our ack, then put our ack down
    if (wbs_ack_o & ~wbs_stb_i)begin
      wbs_ack_o <= 0;
      if (data_read_count == 0) begin
        data_read_en        <=  0;
      end
    end

    if (wbs_stb_i & wbs_cyc_i & ~wbs_ack_o) begin
      //master is requesting somethign
      if (wbs_we_i) begin
        //write request
        case (wbs_adr_i) 
          CONTROL: begin
            control         <=  wbs_dat_i;
            disable_uart    <=  1;
          end
          TRIGGER: begin
            trigger         <=  wbs_dat_i;
            set_strobe      <=  1;
          end
          TRIGGER_MASK: begin
            trigger_mask    <=  wbs_dat_i;
            set_strobe      <=  1;
          end
          TRIGGER_AFTER: begin
            trigger_after   <=  wbs_dat_i;
            set_strobe      <=  1;
          end
          TRIGGER_EDGE: begin
            trigger_edge    <=  wbs_dat_i;
            set_strobe      <=  1;
          end
          BOTH_EDGES: begin
            both_edges      <=  wbs_dat_i;
            set_strobe      <=  1;
          end
          REPEAT_COUNT: begin
            repeat_count    <=  wbs_dat_i;
            set_strobe      <=  1;
          end
          CLOCK_DIVIDER: begin
            clock_divider   <=  wbs_dat_i;
          end
          default: begin
          end
        endcase
      end

      else begin 
        if (data_read_en) begin
          if (sleep > 0) begin
            sleep <=  sleep - 1;
          end
          else begin
            if (data_read_count > 0) begin
              data_read_count <= data_read_count - 1;
            end
            else begin
              data_read_en    <=  0;
            end
            wb_data_read_strobe <=  1;
            wbs_dat_o         <=  la_data_out;
            wbs_ack_o         <=  1;
          end
        end
        //not continuously reading data
        else begin
          //read request
          case (wbs_adr_i)
            CONTROL: begin
              wbs_dat_o <= control;
            end
            STATUS: begin
              wbs_dat_o <= status;
            end
            TRIGGER: begin
              wbs_dat_o <= trigger;
            end
            TRIGGER_MASK: begin
              wbs_dat_o <=  trigger_mask;
            end
            TRIGGER_AFTER: begin
              wbs_dat_o <=  trigger_after;
            end
            TRIGGER_EDGE: begin
              wbs_dat_o <=  trigger_edge;
            end
            BOTH_EDGES: begin
              wbs_dat_o <=  both_edges;
            end
            REPEAT_COUNT: begin
              wbs_dat_o <=  repeat_count;
            end
            DATA_COUNT: begin
              wbs_dat_o <=  la_data_read_size - 1;
            end
            CLOCK_DIVIDER: begin
              wbs_dat_o <=  clock_divider;
            end

            READ_DATA: begin
              //wb_data_read_strobe   <=  1;
              data_read_en          <=  1;
              data_read_count       <=  la_data_read_size - 1;
              sleep                 <=  4;
              //start a read cycle
              //the user can only read the data continuously from start to finish
              //the user can cancel if they deassert the cycle
            end
            default: begin
            end
          endcase
        end
      end
      if (wbs_adr_i != READ_DATA) begin
        if (!data_read_en) begin
          wbs_ack_o <= 1;
       end
      end
    end
  end
end

always @ (posedge clk) begin
  if (rst) begin
    wbs_int_o     <=  0;
  end
  else begin
    wbs_int_o     <=  0;
    if (interrupt_enable && finished) begin
      wbs_int_o   <=  1;
    end
  end
end


endmodule
