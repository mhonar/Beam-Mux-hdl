`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Interview Coding Assignment
// Engineer: Michael R. Honar
// 
// Create Date: 09/05/2025 
// Design Name: "Beam" Mux with Simulation
// Module Name: beam_mux
// Project Name: Beam Mux Assignment
// Target Devices: n/a
// Tool Versions: Vivado 2025.1
// Description: Full assignment provided in supplemented documentation.
//              This is the module source code.
// 
// Dependencies: none.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: i prefer vhdl.
// 
//////////////////////////////////////////////////////////////////////////////////


module beam_mux(
    //the essentials, note that reset is active-high 
    input logic i_clk,
    input logic i_rst,
    //axis_source
    input logic [31:0] axis_source_tdata,
    input logic axis_source_tvalid,
    output logic axis_source_tready, //gated tready for flow control when output to the dacs are busy
    input logic axis_source_tlast,
    //flow control
    input logic [1:0] i_dac_sel,  
    //axis_dac0
    output logic [31:0] axis_dac0_tdata,
    output logic axis_dac0_tvalid,
    input logic axis_dac0_tready,
    //axis_dac1
    output logic [31:0] axis_dac1_tdata,
    output logic axis_dac1_tvalid,
    input logic axis_dac1_tready,
    //axis_dac2
    output logic [31:0] axis_dac2_tdata,
    output logic axis_dac2_tvalid,
    input logic axis_dac2_tready,
    //errors
    output logic burst_size_error
    );

    //signal (wire/reg) declarations 
    logic first; //used for dac_sel, to handle 0 vs 1 mapping to dac 1.
    //primary fifo signals
    logic [31:0] fifo_m_axis_tdata;
    logic fifo_m_axis_tvalid;
    logic fifo_m_axis_tready;
    logic fifo_m_axis_tlast;
    //counter logic signals
    logic [16:0] current_burst_size;
    logic [7:0] burst_count;
    logic increment, decrement;
    logic size_error;
    //downstream flow control
    logic gated_m_axis_tready;
    logic gated_m_axis_tvalid;
    logic enable_flow;
    logic [1:0] dac_sel; //need to control dac_sel depending on input, and tlast.
    
    //xpm fifos use rstn
    assign rstn = ~i_rst;
    
    //primary fifo instantiation
    //see xpm_fifo_axis for instantiation parameters. 
    //Note: sim msgs are enabled. module may report errors for ecc and other dc ports.
    xpm_fifo_axis_primary primary_fifo_inst (
        //upstream
        .s_aclk(i_clk),
        .s_aresetn(rstn),
        //axi-s from modulator
        .s_axis_tdata(axis_source_tdata),
        .s_axis_tvalid(axis_source_tvalid),
        .s_axis_tready(axis_source_tready),
        .s_axis_tlast(axis_source_tlast),
        //axi-s to dacs
        .m_aclk(i_clk),
        .m_axis_tdata(fifo_m_axis_tdata),
        .m_axis_tvalid(fifo_m_axis_tvalid),
        .m_axis_tready(gated_m_axis_tready),
        .m_axis_tlast(fifo_m_axis_tlast)
        );
        
    //counter logic
    //counts the incoming axi-stream burst. once tlast (always qualified with tready, tvalid) is asserted, assert the increment flag
    //else do not increment
    //checks for the size error of the stream (input validation)
    always_ff @(posedge i_clk) begin : counter_logic
        if (i_rst) begin
            current_burst_size <= 17'b0;
            increment <= 1'b0;
            size_error <= 1'b0;
            first <= 1'b1;
        end else begin
            if (axis_source_tlast == 1'b1 && axis_source_tvalid == 1'b1 && axis_source_tready == 1'b1) begin
                first <= 1'b0;
                current_burst_size <= 17'b0;
                increment <= 1'b1;
                if (current_burst_size < 1023 || current_burst_size >= 65536) begin
                    size_error <= 1'b1;
                end
            end else if (axis_source_tvalid == 1'b1 && axis_source_tready == 1'b1) begin
                current_burst_size <= current_burst_size + 1;
                increment <= 1'b0;
            end else begin
                increment <= 1'b0;///counter logic
            end
        end //rst vs clk
    end //always block 

    //enable flow control logic
    //if burst_count (number of bursts in the primary fifo) > 0, then enable flow.
    //for each assertion of tlast (with tvalid/ready), assert decrement flag
    //else deassert the decrement flag
    always_ff @(posedge i_clk) begin : enable_flow_control
        if (i_rst) begin
            enable_flow <= 1'b0;
            decrement <= 1'b0;
        end else begin
            if (enable_flow == 1'b1) begin
                if (fifo_m_axis_tlast == 1'b1 && fifo_m_axis_tvalid == 1'b1 && gated_m_axis_tready == 1'b1) begin
                    enable_flow <= 1'b0;
                    decrement <= 1'b1;
                end
            end else begin
                decrement <= 1'b0;
                if(burst_count > 0) begin
                    enable_flow <= 1'b1;
                end
            end //flow_en 
        end //rst vs clk
    end //always block
    
    //simple combinational circuit
    //set burst count equal to itself + increment flag - decrement flag. 
    always_comb begin : set_burst_count
        if (i_rst) begin
            burst_count <= 8'b0;
        end else begin
            burst_count <= burst_count + increment - decrement;
        end
    end            
    
    //sequential always block to set downstream flow control of the mux circuit.
    //either gated_tready/valid gets set to passthrough or
    //  gated_tready/valid gets set to 0 when no complete burst in buffer. 
    //initialize to passthrough from the xpm fifo. this is safe because 
    //  the xpm fifo has its own de-asserted reset handling for tready
    always_comb begin : flow_control
        if (i_rst) begin 
            gated_m_axis_tready <= fifo_m_axis_tready; 
            gated_m_axis_tvalid <= fifo_m_axis_tvalid;
        end else begin
            if (enable_flow == 1'b0) begin
                gated_m_axis_tready <= 0;
                gated_m_axis_tvalid <= 0;
            end else begin
                gated_m_axis_tready <= fifo_m_axis_tready;
                gated_m_axis_tvalid <= fifo_m_axis_tvalid;
            end //stop flow vs pass through
        end //rst vs clk
    end //always block
    
    
    //set dac_sel here
    //base case if first stream and dac_sel == 0
    //special consideration needed for when initial dac gets selected: once reset is de-asserted
    //assign new dac_sel upon tlast out of the mux
    //always qualify tlast with and tvalid and tready.
    always_ff @(posedge i_clk) begin : set_dac_sel
        if (i_rst) begin
            dac_sel <= 2'b00;
        end else begin
            if (first == 1'b1) begin
                if (i_dac_sel == 2'b0) begin
                    dac_sel = i_dac_sel;
                end else begin
                    dac_sel <= i_dac_sel - 1;
                end
            end else if (fifo_m_axis_tlast == 1'b1 && gated_m_axis_tvalid == 1'b1 && gated_m_axis_tready == 1'b1) begin
                if (i_dac_sel == 2'b00) begin
                    dac_sel <= (dac_sel + 1) % 3;
                end else begin
                    dac_sel = i_dac_sel - 1;        
                end //round robin vs set to input
            end //first vs not first
        end //rst vs clk
    end //always block

    //dac switch: the final boss... combinational circuit (a demuxer)
    //note: dac_sel is set above
    always_comb begin : dac_switch
        case (dac_sel)
            2'b00 : begin
                axis_dac0_tdata = fifo_m_axis_tdata;
                axis_dac0_tvalid = gated_m_axis_tvalid;
                fifo_m_axis_tready = axis_dac0_tready;
                axis_dac1_tdata = 0;
                axis_dac1_tvalid = 0;
                axis_dac2_tdata = 0;
                axis_dac2_tvalid = 0;
            end
            2'b01: begin
                axis_dac0_tdata = 0;
                axis_dac0_tvalid = 0;
                axis_dac1_tdata = fifo_m_axis_tdata;
                axis_dac1_tvalid = gated_m_axis_tvalid;
                fifo_m_axis_tready = axis_dac1_tready;
                axis_dac2_tdata = 0;
                axis_dac2_tvalid = 0;
            end
            2'b10: begin
                axis_dac0_tdata = 0;
                axis_dac0_tvalid = 0;
                axis_dac1_tdata = 0;
                axis_dac1_tvalid = 0;
                axis_dac2_tdata = fifo_m_axis_tdata;
                axis_dac2_tvalid = gated_m_axis_tvalid;
                fifo_m_axis_tready = axis_dac2_tready;
            end
        endcase
    end
endmodule