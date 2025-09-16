`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Interview Coding Assignment
// Engineer: Michael R. Honar
// 
// Create Date: 09/05/2025 
// Design Name: "Beam" Mux with Simulation
// Module Name: tb_sim_beam_mux
// Project Name: Beam Mux Assignment
// Target Devices: n/a
// Tool Versions: Vivado 2025.1
// Description: Full assignment provided in supplemented documentation.
//              This is the test bench code, with stimulus.
// 
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: nothing so far. 
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_sim_beam_mux(
    //the essentials, note that reset is active-high 
    output logic o_clk,
    output logic o_rst,
    //axis_source
    output logic [31:0] axis_source_tdata,
    output logic axis_source_tvalid,
    input logic axis_source_tready,
    output logic axis_source_tlast,
    //flow control
    output logic [1:0] o_dac_sel,  
    //axis_dac0
    input logic [31:0] axis_dac0_tdata,
    input logic axis_dac0_tvalid,
    output logic axis_dac0_tready,
    //axis_dac1
    input logic [31:0] axis_dac1_tdata,
    input logic axis_dac1_tvalid,
    output logic axis_dac1_tready,
    //axis_dac2
    input logic [31:0] axis_dac2_tdata,
    input logic axis_dac2_tvalid,
    output logic axis_dac2_tready
    );
    
    //test bench parameters
    string path = "C:/Users/rezah/BeamMux/BeamMux.srcs/sim_1/new/bin/"; //set absolulte path to where bin files are.
    parameter iterations = 16; //number of bin files. 
    parameter dac_sel = 0; //which dac to output to (0 = rotating)
    
    
//    //reg[31:0] tdata[0:10];
//    logic [31:0] tdata;
//    assign axis_source_tdata = tdata;
    
    //array to hold the dac sel. note that consecutive 0s are to test round robin.
    //if a number preceeds 0, then round robin will chose the next iterative dac.
    //TODO: IMPLEMENT THIS ARRAY. THIS ARRAY IS NOT CURRENTLY USED.
    logic [1:0] dac_sel_arr [iterations] = '{ 
        2'd0, //dac1, begin RR
        2'd0, //dac2
        2'd0, //dac3
        2'd0, //dac1, end RR
        2'd3, //dac3,
        2'd2, //dac2
        2'd0, //dac3, begin RR
        2'd0, //dac1
        2'd0, //dac2
        2'd0, //dac3
        2'd0, //dac1
        2'd0, //dac2, end RR
        2'd1, //dac1
        2'd1, //dac1
        2'd3, //dac3
        2'd3  //dac3
        };
        
    //array to hold the size of each burst. 
    integer burst_size_arr [iterations] = '{ 
        1024,
        1024,
        2048,
        2048,
        1024,
        1024,
        65536,
        65536,
        16384,
        4096,
        1024,
        1024,
        1024,
        1024,
        1024,
        1024
        };
        
    //reset gen
    //take care of some initial values, and control reset.
    initial begin : reset_gen
        o_rst = 1'b1;
        axis_source_tvalid = 1'b0;
        axis_source_tdata = 0;
        axis_source_tlast = 1'b0;
        o_dac_sel = 2'b0;
        #30 o_rst = 1'b0;
    end
   
    //clock gen 300mhz. 
    //not an ideal period, in the fpga a proper clock divider would be used. 
    parameter PERIOD = 3.3334;
    
    initial begin : clock_gen
        o_clk = 1'b0;
        #(PERIOD/2) 
        forever
            #(PERIOD/2) o_clk = ~o_clk;
    end 
    
    //STIM
    //fileIO the modulator. 16 bursts will be sent, using fileio.
    //iterates a loop "iterations" times to open a file.
    //when a file is opened, the axi-s stim send an acknowledge flag that it is processing the file
    //when a file hits eof, the axi-s stim sends a de-asserted flag that the file is closed, 
    //and to iterate to the next file. 
    //this sim module ends once all files have been processed. 
    integer i = 0; //iterator for number of bursts. 
    integer input_file = 0; //fopen value 
    string relative_path; //relative path to where bin files are. note: need to set path at the top of this file (line 50).
    logic ack_fopen = 1'b0;
    integer eof = 1;
    integer data_counter = 0;
        
    always begin : modulator_sim
        wait (o_rst == 1'b0);
        #100;
        for (i = 0; i < iterations; i = i+1) begin
            //open file
            $sformat(relative_path, "%s%02d%s", path, i, ".bin");
            input_file = $fopen(relative_path, "rb");
            if (input_file == 0) begin
                $display("Error: Failed to open file, %s\nExiting Simulation.", path);
                $finish;
            end else begin
                $display("Success: Opened %02d.bin", i);
            end;
            //wait for modulator_sim to acknowledge fopen
            wait (ack_fopen == 1'b1);
            //wait for modulator_sim to complete file processing
            wait (ack_fopen == 1'b0);
            //set input_file to 0 to reset modulator_sim outputs.
            input_file = 0;
            wait (data_counter == 0);
            $display("Success: Finished streaming %02d.bin", i);
        end
        $display("Success: Finished streaming all files.");  
        #1000000;
        $finish;
    end
    
    //STIM
    //model the modulator's axi-stream
    //this reads the open file with correct valid assertion.
    //this stim can handle back-pressure via beam-mux's tready.
    //TODO: randomize tvalid being de-asserted.     
    always_ff @(posedge o_clk) begin
        if (input_file == 0) begin
            data_counter = 0;
            axis_source_tdata = 0;
            axis_source_tvalid = 1'b0;
            axis_source_tlast = 1'b0;
        end else if (data_counter == 0) begin
            //tvalid should not wait on tready. read the file, have tdata and tvalid "ready" for beam mux
            eof = $fread(axis_source_tdata, input_file);
            ack_fopen = 1'b1;
            axis_source_tvalid = 1'b1;
            data_counter += 1;
        end else if (data_counter <= burst_size_arr[i]) begin
            if (axis_source_tready == 1'b1) begin
                eof = $fread(axis_source_tdata, input_file);
                data_counter += 1; //increment data counter because we are valid
                if (data_counter == burst_size_arr[i]) begin
                    axis_source_tlast = 1'b1;
                    ack_fopen = 1'b0;
                end //data last
            end //tready
        end else if (data_counter > burst_size_arr[i]) begin // might not need this if statement..
            axis_source_tdata = 0;
            axis_source_tvalid = 1'b0;
            axis_source_tlast = 1'b0;
        end //tvalid    
    end
    
    //STIM
    //set dac sel signal
    //currently dac_sel is hard coded to 0. this rotates the dac sel. 
    //I have tested random dac sels to sucess. 
    //I wanted to create an FSM for DAC select because the process is a bit
    //  more intricate than i thought.
    //Wanted to implement a data counter and tvalid checker (dac tvalid should never be de-asserted).
    //That would of also made this a monitor. 
    //Unfortunately I did not have enough time to architect a cohesive dac_sel stim and axis_dac monitor. 
    //I did manually assign dac_sel during sim and verified via inspection of correct dac_sel behavior.
    assign o_dac_sel = dac_sel;
    //o_dac_sel = dac_sel_arr[j];

    
    //MONITOR
    //a monitor module for axis_dac.
    //Unfortunately I did not have enough time to architect a cohesive dac_sel stim and axis_dac monitor.
    //The intention here was to check the tdata counts from the beam_mux module with the stim, for each stream.
    //Additionally, while a stream is active, check that tvalid never gets de-asserted to meet the uninterrupted sample req.
    //The final check was to ensure the correct dac is being output. 
    //A tready de-assert randomizer was also to be put in this monitor, since the assignment assumes the dacs can provide backpressure.
    //I performed these three checks via inspection using the waveform. I put details in the report. 
    //i left tready asserted high to allow the data stream from the beam mux. 
    initial begin : axis_dac_mon
        axis_dac0_tready <= 1'b1;
        axis_dac1_tready <= 1'b1;
        axis_dac2_tready <= 1'b1;
    end  
    
endmodule
