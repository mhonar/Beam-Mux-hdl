`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Interview Coding Assignment
// Engineer: Michael R. Honar
// 
// Create Date: 09/05/2025 
// Design Name: "Beam" Mux with Simulation
// Module Name: wrapper_tb_sim_beam_mux
// Project Name: Beam Mux Assignment
// Target Devices: n/a
// Tool Versions: Vivado 2025.1
// Description: Full assignment provided in supplemented documentation.
//              This is the tb/sim wrapper code.
// 
// Dependencies: none.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: none so far. 
// 
//////////////////////////////////////////////////////////////////////////////////


module wrapper_tb_sim_beam_mux();

    //wire instantiations...
    //the essentials, note that reset is active-high 
    logic clk;
    logic rst;
    //axis_source 
    logic [31:0] axis_source_tdata;
    logic axis_source_tvalid;
    logic axis_source_tready;
    logic axis_source_tlast;
    //flow control
    logic [1:0] dac_sel;
    //axis_dac0
    logic [31:0] axis_dac0_tdata;
    logic axis_dac0_tvalid;
    logic axis_dac0_tready;
    //axis_dac1
    logic [31:0] axis_dac1_tdata;
    logic axis_dac1_tvalid;
    logic axis_dac1_tready;
    //axis_dac2
    logic [31:0] axis_dac2_tdata;
    logic axis_dac2_tvalid;
    logic axis_dac2_tready;
    
    //Instantiation of the Beam Mux Module
    beam_mux beam_mux_inst (
        //the essentials, note that reset is active-high 
        .i_clk(clk),
        .i_rst(rst),
        //axis_source
        .axis_source_tdata(axis_source_tdata),
        .axis_source_tvalid(axis_source_tvalid),
        .axis_source_tready(axis_source_tready),
        .axis_source_tlast(axis_source_tlast),
        //flow control
        .i_dac_sel(dac_sel),  
        //axis_dac0
        .axis_dac0_tdata(axis_dac0_tdata),
        .axis_dac0_tvalid(axis_dac0_tvalid),
        .axis_dac0_tready(axis_dac0_tready),
        //axis_dac1
        .axis_dac1_tdata(axis_dac1_tdata),
        .axis_dac1_tvalid(axis_dac1_tvalid),
        .axis_dac1_tready(axis_dac1_tready),
        //axis_dac2
        .axis_dac2_tdata(axis_dac2_tdata),
        .axis_dac2_tvalid(axis_dac2_tvalid),
        .axis_dac2_tready(axis_dac2_tready),
        //errors
        .burst_size_error()
    );
    
    //Instantiation of the Test Bench
    tb_sim_beam_mux tb_inst (
        //the essentials, note that reset is active-high 
        .o_clk(clk),
        .o_rst(rst),
        //axis_source
        .axis_source_tdata(axis_source_tdata),
        .axis_source_tvalid(axis_source_tvalid),
        .axis_source_tready(axis_source_tready),
        .axis_source_tlast(axis_source_tlast),
        //flow control
        .o_dac_sel(dac_sel),  
        //axis_dac0
        .axis_dac0_tdata(axis_dac0_tdata),
        .axis_dac0_tvalid(axis_dac0_tvalid),
        .axis_dac0_tready(axis_dac0_tready),
        //axis_dac1
        .axis_dac1_tdata(axis_dac1_tdata),
        .axis_dac1_tvalid(axis_dac1_tvalid),
        .axis_dac1_tready(axis_dac1_tready),
        //axis_dac2
        .axis_dac2_tdata(axis_dac2_tdata),
        .axis_dac2_tvalid(axis_dac2_tvalid),
        .axis_dac2_tready(axis_dac2_tready)
    );
    
    
endmodule
