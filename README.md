This repo tracks a take home assignment for a non-senior FPGA role that was completed in an evenings worth of time. I'd say this exercise's difficulty matches a lab assignment in a junior/senior undergrad class without the weeklong deadline. 
The project source and sim files were added to a Vivado Project and simulated in place. I was required to use System Verilog. 

changelog (tags):
release/v1.0.0 - My submission. Opened issue #2 #3 and #4 for future improvements.

navigating this repo:
1. beam-mux-assignment.pdf - Original prompt.
2. beam-mux-report.pdf - My writeup. Note that the block diagram refers to "Beam Mux V3". The "V3" does not refer to any release tags on this branch. 
3. /source/ - Source files: the beam mux module and a Xilinx parameterized macro FIFO. 
4. /sim/ - sim files. Test bench, a wrapper, and a /bin/ folder with binary files for the stim
