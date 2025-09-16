`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// A simple wrapper to keep the XPM_FIFO_AXIS template out of the beam_mux module. 
// 
// This module is unique to the beam_mux because the parameters are hard coded. 
//
// It is ill-advised to reuse this module elsewhere in the design,
// unless the parameters have been checked to be valid. 
//
// The following parameters have been modified from defaults:
//  .EN_SIM_ASSERT_ERR("error")
//  .FIFO_DEPTH(131072)
//  .SIM_ASSERT_CHK(1)
//  .USE_ADV_FEATURES("0")
//
// The following "DoNotCare" ports have been commented out:
// .almost_empty_axis(almost_empty_axis)
// .almost_full_axis(almost_full_axis)
// .dbiterr_axis(dbiterr_axis)
// .prog_empty_axis(prog_empty_axis)
// .prog_full_axis(prog_full_axis)
// .rd_data_count_axis(rd_data_count_axis)
// .sbiterr_axis(sbiterr_axis)
// .wr_data_count_axis(wr_data_count_axis)
//
// The following output ports have been left open, with justification:
// .m_axis_tdest() - not using tdest in beam_mux module
// .m_axis_tid() - not using tid in beam_mux module
// .m_axis_tkeep() - not using tkeep in beam_mux module
// .m_axis_tstrb() - not using tstrb in beam_mux module
// .m_axis_tuser() - not using tuser in beam_mux module
//
// The following ports have been hardcoded, with justification:
// .injectdbiterr_axis(1'b0) - tied to 0, do not want dbe's
// .injectsbiterr_axis(1'b0) - tied to 0, do not want sbe's
// .s_axis_tdest(1'b0) - not using tdest in beam_mux module
// .s_axis_tid(1'b0) - not using tid in beam_mux module
// .s_axis_tkeep(4'b1111) - keeping all 4 bytes of a tdata packet
// .s_axis_tstrb(4'b1111) - a;; 4 bytes of a tdata packet is valid data
// .s_axis_tuser(1'b0) - not using tuser in beam_mux module
//
// 
//////////////////////////////////////////////////////////////////////////////////


module xpm_fifo_axis_primary (
    //upstream
    input s_aclk,
    input s_aresetn,
    //axi-s from modulator
    input [31:0] s_axis_tdata,
    input s_axis_tvalid,
    output s_axis_tready,
    input s_axis_tlast,
    //axi-s to dacs
    input m_aclk,
    output [31:0] m_axis_tdata,
    output m_axis_tvalid,
    input m_axis_tready,
    output m_axis_tlast
    );

// XPM_FIFO instantiation template for AXI Stream FIFO configurations
// Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
// =======================================================================================================================

// Parameter usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Parameter name       | Data type          | Restrictions, if applicable                                             |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | CASCADE_HEIGHT       | Integer            | Range: 0 - 64. Default value = 0.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- No Cascade Height, Allow Vivado Synthesis to choose.                                                             |
// | 1 or more - Vivado Synthesis sets the specified value as Cascade Height.                                            |
// +---------------------------------------------------------------------------------------------------------------------+
// | CDC_SYNC_STAGES      | Integer            | Range: 2 - 8. Default value = 2.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the number of synchronization stages on the CDC path.                                                     |
// | Applicable only if CLOCKING_MODE = "independent_clock"                                                              |
// +---------------------------------------------------------------------------------------------------------------------+
// | CLOCKING_MODE        | String             | Allowed values: common_clock, independent_clock. Default value = common_clock.|
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate whether AXI Stream FIFO is clocked with a common clock or with independent clocks-                        |
// |                                                                                                                     |
// |   "common_clock"- Common clocking; clock both write and read domain s_aclk                                          |
// |   "independent_clock"- Independent clocking; clock write domain with s_aclk and read domain with m_aclk             |
// +---------------------------------------------------------------------------------------------------------------------+
// | ECC_MODE             | String             | Allowed values: no_ecc, en_ecc. Default value = no_ecc.                 |
// |---------------------------------------------------------------------------------------------------------------------|
// |                                                                                                                     |
// |   "no_ecc" - Disables ECC                                                                                           |
// |   "en_ecc" - Enables both ECC Encoder and Decoder                                                                   |
// |                                                                                                                     |
// | NOTE: ECC_MODE should be "no_ecc" if FIFO_MEMORY_TYPE is set to "auto". Violating this may result incorrect behavior.|
// +---------------------------------------------------------------------------------------------------------------------+
// | EN_SIM_ASSERT_ERR    | String             | Default value = warning.                                                |
// |---------------------------------------------------------------------------------------------------------------------|
// |                                                                                                                     |
// |   "warning" - Report warning message for FIFO overflow and underflow in simulation.                                 |
// |   "error" - Report error message for FIFO overflow and underflow in simulation.                                     |
// |   "fatal" - Report fatal message for FIFO overflow and underflow in simulation.                                     |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_DEPTH           | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the AXI Stream FIFO Write Depth, must be power of two                                                       |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_MEMORY_TYPE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate the fifo memory primitive (resource type) to use-                                                         |
// |                                                                                                                     |
// |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// |   "block"- Block RAM FIFO                                                                                           |
// |   "distributed"- Distributed RAM FIFO                                                                               |
// |   "ultra"- URAM FIFO                                                                                                |
// |                                                                                                                     |
// | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with FIFO_MEMORY_TYPE set to "auto".|
// +---------------------------------------------------------------------------------------------------------------------+
// | PACKET_FIFO          | String             | Allowed values: false, true. Default value = false.                     |
// |---------------------------------------------------------------------------------------------------------------------|
// |                                                                                                                     |
// |   "true"- Enables Packet FIFO mode                                                                                  |
// |   "false"- Disables Packet FIFO mode                                                                                |
// +---------------------------------------------------------------------------------------------------------------------+
// | PROG_EMPTY_THRESH    | Integer            | Range: 5 - 4194301. Default value = 10.                                 |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.                    |
// |                                                                                                                     |
// |   Min_Value = 5                                                                                                     |
// |   Max_Value = FIFO_WRITE_DEPTH - 5                                                                                  |
// |                                                                                                                     |
// | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
// | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
// +---------------------------------------------------------------------------------------------------------------------+
// | PROG_FULL_THRESH     | Integer            | Range: 5 - 4194301. Default value = 10.                                 |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
// |                                                                                                                     |
// |   Min_Value = 5 + CDC_SYNC_STAGES                                                                                   |
// |   Max_Value = FIFO_WRITE_DEPTH - 5                                                                                  |
// |                                                                                                                     |
// | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
// | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
// +---------------------------------------------------------------------------------------------------------------------+
// | RD_DATA_COUNT_WIDTH  | Integer            | Range: 1 - 23. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the width of rd_data_count_axis. To reflect the correct value, the width should be log2(FIFO_DEPTH)+1.    |
// +---------------------------------------------------------------------------------------------------------------------+
// | RELATED_CLOCKS       | Integer            | Range: 0 - 1. Default value = 0.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios.                   |
// | Applicable only if CLOCKING_MODE = "independent_clock"                                                              |
// +---------------------------------------------------------------------------------------------------------------------+
// | SIM_ASSERT_CHK       | Integer            | Range: 0 - 1. Default value = 0.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable simulation message reporting. Messages related to potential misuse will not be reported.                 |
// | 1- Enable simulation message reporting. Messages related to potential misuse will be reported.                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | TDATA_WIDTH          | Integer            | Range: 8 - 2048. Default value = 32.                                    |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the TDATA port, s_axis_tdata and m_axis_tdata                                                  |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | TDEST_WIDTH          | Integer            | Range: 1 - 32. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the TDEST port, s_axis_tdest and m_axis_tdest                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | TID_WIDTH            | Integer            | Range: 1 - 32. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the ID port, s_axis_tid and m_axis_tid                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// | TUSER_WIDTH          | Integer            | Range: 1 - 4086. Default value = 1.                                     |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the TUSER port, s_axis_tuser and m_axis_tuser                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | USE_ADV_FEATURES     | String             | Default value = 1000.                                                   |
// |---------------------------------------------------------------------------------------------------------------------|
// | Enables almost_empty_axis, rd_data_count_axis, prog_empty_axis, almost_full_axis, wr_data_count_axis,               |
// | prog_full_axis sideband signals.                                                                                    |
// |                                                                                                                     |
// |   Setting USE_ADV_FEATURES[1] to 1 enables prog_full flag; Default value of this bit is 0                           |
// |   Setting USE_ADV_FEATURES[2] to 1 enables wr_data_count; Default value of this bit is 0                            |
// |   Setting USE_ADV_FEATURES[3] to 1 enables almost_full flag; Default value of this bit is 0                         |
// |   Setting USE_ADV_FEATURES[9] to 1 enables prog_empty flag; Default value of this bit is 0                          |
// |   Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count; Default value of this bit is 0                           |
// |   Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | WR_DATA_COUNT_WIDTH  | Integer            | Range: 1 - 23. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the width of wr_data_count_axis. To reflect the correct value, the width should be log2(FIFO_DEPTH)+1.    |
// +---------------------------------------------------------------------------------------------------------------------+

// Port usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | almost_empty_axis| Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to|
// | empty.                                                                                                              |
// +---------------------------------------------------------------------------------------------------------------------+
// | almost_full_axis| Output    | 1                                     | s_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.|
// +---------------------------------------------------------------------------------------------------------------------+
// | dbiterr_axis   | Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Double Bit Error- Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
// +---------------------------------------------------------------------------------------------------------------------+
// | injectdbiterr_axis| Input     | 1                                     | s_aclk  | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Double Bit Error Injection- Injects a double bit error if the ECC feature is used.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | injectsbiterr_axis| Input     | 1                                     | s_aclk  | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Single Bit Error Injection- Injects a single bit error if the ECC feature is used.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_aclk         | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Master Interface Clock: All signals on master interface are sampled on the rising edge of this clock.               |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tdata   | Output    | TDATA_WIDTH                           | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TDATA: The primary payload that is used to provide the data that is passing across the interface. The width         |
// | of the data payload is an integer number of bytes.                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tdest   | Output    | TDEST_WIDTH                           | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TDEST: Provides routing information for the data stream.                                                            |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tid     | Output    | TID_WIDTH                             | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TID: The data stream identifier that indicates different streams of data.                                           |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tkeep   | Output    | TDATA_WIDTH/8                         | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TKEEP: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as part of the data stream. Associated bytes that have the TKEEP byte qualifier deasserted are null bytes           |
// | and can be removed from the data stream. For a 64-bit DATA, bit 0 corresponds to the least significant byte         |
// | on DATA, and bit 7 corresponds to the most significant byte. For example:                                           |
// |                                                                                                                     |
// |   KEEP[0] = 1b, DATA[7:0] is not a NULL byte                                                                        |
// |   KEEP[7] = 0b, DATA[63:56] is a NULL byte                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tlast   | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TLAST: Indicates the boundary of a packet.                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tready  | Input     | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TREADY: Indicates that the slave can accept a transfer in the current cycle.                                        |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tstrb   | Output    | TDATA_WIDTH/8                         | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TSTRB: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as a data byte or a position byte. For a 64-bit DATA, bit 0 corresponds to the least significant byte on            |
// | DATA, and bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the most significant    |
// | byte. For example:                                                                                                  |
// |                                                                                                                     |
// |   STROBE[0] = 1b, DATA[7:0] is valid                                                                                |
// |   STROBE[7] = 0b, DATA[63:56] is not valid                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tuser   | Output    | TUSER_WIDTH                           | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TUSER: The user-defined sideband information that can be transmitted alongside the data stream.                     |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tvalid  | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both TVALID and TREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | prog_empty_axis| Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Programmable Empty- This signal is asserted when the number of words in the FIFO is less than or equal              |
// | to the programmable empty threshold value.                                                                          |
// | It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.              |
// +---------------------------------------------------------------------------------------------------------------------+
// | prog_full_axis | Output    | 1                                     | s_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal            |
// | to the programmable full threshold value.                                                                           |
// | It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.          |
// +---------------------------------------------------------------------------------------------------------------------+
// | rd_data_count_axis| Output    | RD_DATA_COUNT_WIDTH                   | m_aclk  | NA          | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Read Data Count- This bus indicates the number of words available for reading in the FIFO.                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_aclk         | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Slave Interface Clock: All signals on slave interface are sampled on the rising edge of this clock.                 |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_aresetn      | Input     | 1                                     | NA      | Active-low  | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Active low asynchronous reset.                                                                                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tdata   | Input     | TDATA_WIDTH                           | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TDATA: The primary payload that is used to provide the data that is passing across the interface. The width         |
// | of the data payload is an integer number of bytes.                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tdest   | Input     | TDEST_WIDTH                           | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TDEST: Provides routing information for the data stream.                                                            |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tid     | Input     | TID_WIDTH                             | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TID: The data stream identifier that indicates different streams of data.                                           |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tkeep   | Input     | TDATA_WIDTH/8                         | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TKEEP: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as part of the data stream. Associated bytes that have the TKEEP byte qualifier deasserted are null bytes           |
// | and can be removed from the data stream. For a 64-bit DATA, bit 0 corresponds to the least significant byte         |
// | on DATA, and bit 7 corresponds to the most significant byte. For example:                                           |
// |                                                                                                                     |
// |   KEEP[0] = 1b, DATA[7:0] is not a NULL byte                                                                        |
// |   KEEP[7] = 0b, DATA[63:56] is a NULL byte                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tlast   | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TLAST: Indicates the boundary of a packet.                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tready  | Output    | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TREADY: Indicates that the slave can accept a transfer in the current cycle.                                        |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tstrb   | Input     | TDATA_WIDTH/8                         | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TSTRB: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as a data byte or a position byte. For a 64-bit DATA, bit 0 corresponds to the least significant byte on            |
// | DATA, and bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the most significant    |
// | byte. For example:                                                                                                  |
// |                                                                                                                     |
// |   STROBE[0] = 1b, DATA[7:0] is valid                                                                                |
// |   STROBE[7] = 0b, DATA[63:56] is not valid                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tuser   | Input     | TUSER_WIDTH                           | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TUSER: The user-defined sideband information that can be transmitted alongside the data stream.                     |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tvalid  | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both TVALID and TREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | sbiterr_axis   | Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Single Bit Error- Indicates that the ECC decoder detected and fixed a single-bit error.                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | wr_data_count_axis| Output    | WR_DATA_COUNT_WIDTH                   | s_aclk  | NA          | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Write Data Count: This bus indicates the number of words written into the FIFO.                                     |
// +---------------------------------------------------------------------------------------------------------------------+


// xpm_fifo_axis : In order to incorporate this function into the design,
//    Verilog    : the following instance declaration needs to be placed
//   instance    : in the body of the design code.  The instance name
//  declaration  : (xpm_fifo_axis_inst) and/or the port declarations within the
//     code      : parenthesis may be changed to properly reference and
//               : connect this function to the design.  All inputs
//               : and outputs must be connected.

//  Please reference the appropriate libraries guide for additional information on the XPM modules.

//  <-----Cut code below this line---->

   // xpm_fifo_axis: AXI Stream FIFO
   // Xilinx Parameterized Macro, version 2025.1

   xpm_fifo_axis #(
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CDC_SYNC_STAGES(2),            // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .EN_SIM_ASSERT_ERR("error"),    // String
      .FIFO_DEPTH(131072),             // DECIMAL
      .FIFO_MEMORY_TYPE("auto"),      // String
      .PACKET_FIFO("false"),          // String
      .PROG_EMPTY_THRESH(10),         // DECIMAL
      .PROG_FULL_THRESH(10),          // DECIMAL
      .RD_DATA_COUNT_WIDTH(17),       // DECIMAL
      .RELATED_CLOCKS(0),             // DECIMAL
      .SIM_ASSERT_CHK(1),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .TDATA_WIDTH(32),               // DECIMAL
      .TDEST_WIDTH(1),                // DECIMAL
      .TID_WIDTH(1),                  // DECIMAL
      .TUSER_WIDTH(1),                // DECIMAL
      .USE_ADV_FEATURES("0"),         // String
      .WR_DATA_COUNT_WIDTH(1)         // DECIMAL
   )
   xpm_fifo_axis_inst (
//      .almost_empty_axis(almost_empty_axis),   // 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be
                                               // performed before the FIFO goes to empty.

//      .almost_full_axis(almost_full_axis),     // 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be
                                               // performed before the FIFO is full.

//      .dbiterr_axis(dbiterr_axis),             // 1-bit output: Double Bit Error- Indicates that the ECC decoder detected a double-bit error and data
                                               // in the FIFO core is corrupted.

      .m_axis_tdata(m_axis_tdata),             // TDATA_WIDTH-bit output: TDATA: The primary payload that is used to provide the data that is passing
                                               // across the interface. The width of the data payload is an integer number of bytes.

      .m_axis_tdest(),             // TDEST_WIDTH-bit output: TDEST: Provides routing information for the data stream.
      .m_axis_tid(),                 // TID_WIDTH-bit output: TID: The data stream identifier that indicates different streams of data.
      .m_axis_tkeep(),             // TDATA_WIDTH/8-bit output: TKEEP: The byte qualifier that indicates whether the content of the
                                               // associated byte of TDATA is processed as part of the data stream. Associated bytes that have the
                                               // TKEEP byte qualifier deasserted are null bytes and can be removed from the data stream. For a
                                               // 64-bit DATA, bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the
                                               // most significant byte. For example: KEEP[0] = 1b, DATA[7:0] is not a NULL byte KEEP[7] = 0b,
                                               // DATA[63:56] is a NULL byte

      .m_axis_tlast(m_axis_tlast),             // 1-bit output: TLAST: Indicates the boundary of a packet.
      .m_axis_tstrb(),             // TDATA_WIDTH/8-bit output: TSTRB: The byte qualifier that indicates whether the content of the
                                               // associated byte of TDATA is processed as a data byte or a position byte. For a 64-bit DATA, bit 0
                                               // corresponds to the least significant byte on DATA, and bit 0 corresponds to the least significant
                                               // byte on DATA, and bit 7 corresponds to the most significant byte. For example: STROBE[0] = 1b,
                                               // DATA[7:0] is valid STROBE[7] = 0b, DATA[63:56] is not valid

      .m_axis_tuser(),             // TUSER_WIDTH-bit output: TUSER: The user-defined sideband information that can be transmitted
                                               // alongside the data stream.

      .m_axis_tvalid(m_axis_tvalid),           // 1-bit output: TVALID: Indicates that the master is driving a valid transfer. A transfer takes place
                                               // when both TVALID and TREADY are asserted

//      .prog_empty_axis(prog_empty_axis),       // 1-bit output: Programmable Empty- This signal is asserted when the number of words in the FIFO is
                                               // less than or equal to the programmable empty threshold value. It is de-asserted when the number of
                                               // words in the FIFO exceeds the programmable empty threshold value.

//      .prog_full_axis(prog_full_axis),         // 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is
                                               // greater than or equal to the programmable full threshold value. It is de-asserted when the number
                                               // of words in the FIFO is less than the programmable full threshold value.

//      .rd_data_count_axis(rd_data_count_axis), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count- This bus indicates the number of words available
                                               // for reading in the FIFO.

      .s_axis_tready(s_axis_tready),           // 1-bit output: TREADY: Indicates that the slave can accept a transfer in the current cycle.
//      .sbiterr_axis(sbiterr_axis),             // 1-bit output: Single Bit Error- Indicates that the ECC decoder detected and fixed a single-bit
                                               // error.

//      .wr_data_count_axis(wr_data_count_axis), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written
                                               // into the FIFO.

      .injectdbiterr_axis(1'b0), // 1-bit input: Double Bit Error Injection- Injects a double bit error if the ECC feature is used.
      .injectsbiterr_axis(1'b0), // 1-bit input: Single Bit Error Injection- Injects a single bit error if the ECC feature is used.
      .m_aclk(m_aclk),                         // 1-bit input: Master Interface Clock: All signals on master interface are sampled on the rising edge
                                               // of this clock.

      .m_axis_tready(m_axis_tready),           // 1-bit input: TREADY: Indicates that the slave can accept a transfer in the current cycle.
      .s_aclk(s_aclk),                         // 1-bit input: Slave Interface Clock: All signals on slave interface are sampled on the rising edge
                                               // of this clock.

      .s_aresetn(s_aresetn),                   // 1-bit input: Active low asynchronous reset.
      .s_axis_tdata(s_axis_tdata),             // TDATA_WIDTH-bit input: TDATA: The primary payload that is used to provide the data that is passing
                                               // across the interface. The width of the data payload is an integer number of bytes.

      .s_axis_tdest(1'b0),             // TDEST_WIDTH-bit input: TDEST: Provides routing information for the data stream.
      .s_axis_tid(1'b0),                 // TID_WIDTH-bit input: TID: The data stream identifier that indicates different streams of data.
      .s_axis_tkeep(4'b1111),             // TDATA_WIDTH/8-bit input: TKEEP: The byte qualifier that indicates whether the content of the
                                               // associated byte of TDATA is processed as part of the data stream. Associated bytes that have the
                                               // TKEEP byte qualifier deasserted are null bytes and can be removed from the data stream. For a
                                               // 64-bit DATA, bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the
                                               // most significant byte. For example: KEEP[0] = 1b, DATA[7:0] is not a NULL byte KEEP[7] = 0b,
                                               // DATA[63:56] is a NULL byte

      .s_axis_tlast(s_axis_tlast),             // 1-bit input: TLAST: Indicates the boundary of a packet.
      .s_axis_tstrb(4'b1111),             // TDATA_WIDTH/8-bit input: TSTRB: The byte qualifier that indicates whether the content of the
                                               // associated byte of TDATA is processed as a data byte or a position byte. For a 64-bit DATA, bit 0
                                               // corresponds to the least significant byte on DATA, and bit 0 corresponds to the least significant
                                               // byte on DATA, and bit 7 corresponds to the most significant byte. For example: STROBE[0] = 1b,
                                               // DATA[7:0] is valid STROBE[7] = 0b, DATA[63:56] is not valid

      .s_axis_tuser(1'b0),             // TUSER_WIDTH-bit input: TUSER: The user-defined sideband information that can be transmitted
                                               // alongside the data stream.

      .s_axis_tvalid(s_axis_tvalid)            // 1-bit input: TVALID: Indicates that the master is driving a valid transfer. A transfer takes place
                                               // when both TVALID and TREADY are asserted

   );

   // End of xpm_fifo_axis_inst instantiation
   
endmodule