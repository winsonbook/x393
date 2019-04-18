/*!
 * <b>Module:</b>sens_lepton3
 * @file sens_lepton3.v
 * @date 2015-05-10  
 * @author Andrey Filippov     
 *
 * @brief Sensor interface with 12-bit for parallel bus
 *
 * @copyright Copyright (c) 2015 Elphel, Inc.
 *
 * <b>License:</b>
 *
 * sens_lepton3.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  sens_lepton3.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *
 * Additional permission under GNU GPL version 3 section 7:
 * If you modify this Program, or any covered work, by linking or combining it
 * with independent modules provided by the FPGA vendor only (this permission
 * does not extend to any 3-rd party modules, "soft cores" or macros) under
 * different license terms solely for the purpose of generating binary "bitstream"
 * files and/or simulating the code, the copyright holders of this Program give
 * you the right to distribute the covered work without those independent modules
 * as long as the source code for them is available from the FPGA vendor free of
 * charge, and there is no dependence on any encrypted modules for simulating of
 * the combined code. This permission applies to you if the distributed code
 * contains all the components and scripts required to completely simulate it
 * with at least one of the Free Software programs.
 */
`timescale 1ns/1ps
`include "system_defines.vh" // just for debugging histograms 
module  sens_lepton3 #(
    parameter SENSIO_ADDR =        'h330,
    parameter SENSIO_ADDR_MASK =   'h7f8,
    parameter SENSIO_CTRL =        'h0,
    parameter SENSIO_STATUS =      'h1,
    parameter SENSIO_JTAG =        'h2,
    parameter SENSIO_WIDTH =       'h3, // set line width (1.. 2^16) if 0 - use HACT
    parameter SENSIO_DELAYS =      'h4, // 'h4..'h7 - each address sets 4 delays through 4 bytes of 32-bit data
    parameter SENSIO_STATUS_REG =  'h21,

    parameter SENS_JTAG_PGMEN =    8,
    parameter SENS_JTAG_PROG =     6,
    parameter SENS_JTAG_TCK =      4,
    parameter SENS_JTAG_TMS =      2,
    parameter SENS_JTAG_TDI =      0,
    
    parameter SENS_CTRL_MRST=      0,  //  1: 0
    parameter SENS_CTRL_ARST=      2,  //  3: 2
    parameter SENS_CTRL_ARO=       4,  //  5: 4
    parameter SENS_CTRL_RST_MMCM=  6,  //  7: 6
    parameter SENS_CTRL_EXT_CLK=   8,  //  9: 8
    parameter SENS_CTRL_LD_DLY=   10,  // 10
    parameter SENS_CTRL_QUADRANTS =      12,  // 17:12, enable - 20
    parameter SENS_CTRL_QUADRANTS_WIDTH = 7, // 6,
    parameter SENS_CTRL_ODD =             6, //
    parameter SENS_CTRL_QUADRANTS_EN =   20,  // 18:12, enable - 20 (1 bits reserved)
     
    
    parameter LINE_WIDTH_BITS =   16,
    
    parameter IODELAY_GRP ="IODELAY_SENSOR", // may need different for different channels?
    parameter integer IDELAY_VALUE = 0,
    parameter integer PXD_DRIVE = 12,
    parameter PXD_IBUF_LOW_PWR = "TRUE",
    parameter PXD_IOSTANDARD = "DEFAULT",
    parameter PXD_SLEW = "SLOW",
    parameter real SENS_REFCLK_FREQUENCY =    300.0,
    parameter SENS_HIGH_PERFORMANCE_MODE =    "FALSE",
    
    parameter SENS_PHASE_WIDTH=               8,      // number of bits for te phase counter (depends on divisors)
    parameter SENS_BANDWIDTH =                "OPTIMIZED",  //"OPTIMIZED", "HIGH","LOW"

    parameter CLKIN_PERIOD_SENSOR =   10.000, // input period in ns, 0..100.000 - MANDATORY, resolution down to 1 ps
    parameter CLKFBOUT_MULT_SENSOR =   8,  // 100 MHz --> 800 MHz
    parameter CLKFBOUT_PHASE_SENSOR =  0.000,  // CLOCK FEEDBACK phase in degrees (3 significant digits, -360.000...+360.000)
    parameter IPCLK_PHASE =            0.000,
    parameter IPCLK2X_PHASE =          0.000,
    parameter BUF_IPCLK =             "BUFR",
    parameter BUF_IPCLK2X =           "BUFR",  
    

    parameter SENS_DIVCLK_DIVIDE =     1,            // Integer 1..106. Divides all outputs with respect to CLKIN
    parameter SENS_REF_JITTER1   =     0.010,        // Expected jitter on CLKIN1 (0.000..0.999)
    parameter SENS_REF_JITTER2   =     0.010,
    parameter SENS_SS_EN         =     "FALSE",      // Enables Spread Spectrum mode
    parameter SENS_SS_MODE       =     "CENTER_HIGH",//"CENTER_HIGH","CENTER_LOW","DOWN_HIGH","DOWN_LOW"
    parameter SENS_SS_MOD_PERIOD =     10000,        // integer 4000-40000 - SS modulation period in ns
    parameter STATUS_ALIVE_WIDTH =     4,
    
    // mode bits
    parameter VOSPI_MRST =            0,
    parameter VOSPI_MRST_BITS =       2,
    parameter VOSPI_PWDN =            2,
    parameter VOSPI_PWDN_BITS =       2,
    parameter VOSPI_MCLK =            4,
    parameter VOSPI_MCLK_BITS =       2,
    parameter VOSPI_EN =              6,
    parameter VOSPI_EN_BITS =         2,
    parameter VOSPI_SEGM0_OK =        8,
    parameter VOSPI_SEGM0_OK_BITS =   2,
    parameter VOSPI_OUT_EN =         10,
    parameter VOSPI_OUT_EN_BITS =     2,
    parameter VOSPI_OUT_EN_SINGL =   12,
    parameter VOSPI_RESET_CRC =      13,
    parameter VOSPI_SPI_CLK =        14,
    parameter VOSPI_SPI_CLK_BITS =    2,
    parameter VOSPI_GPIO =           16,
    parameter VOSPI_GPIO_BITS =       8,
    
    
    parameter VOSPI_FAKE_OUT =       24, // to keep hardware
    parameter VOSPI_MOSI =           25, // pot used
    parameter VOSPI_PACKET_WORDS =    80,
    parameter VOSPI_NO_INVALID =       1, // do not output invalid packets data
    parameter VOSPI_PACKETS_PER_LINE = 2,
    parameter VOSPI_SEGMENT_FIRST =    1,
    parameter VOSPI_SEGMENT_LAST =     4,
    parameter VOSPI_PACKET_FIRST =     0,
    parameter VOSPI_PACKET_LAST =     60,
    parameter VOSPI_PACKET_TTT =      20,  // line number where segment number is provided
    parameter VOSPI_SOF_TO_HACT =      2,  // clock cycles from SOF to HACT
    parameter VOSPI_HACT_TO_HACT_EOF = 2,  // minimal clock cycles from HACT to HACT or to EOF
    parameter VOSPI_MCLK_HALFDIV =     4   // divide mclk (200Hhz) to get 50 MHz, then divide by 2 and use for sensor 25MHz clock
)(
    // programming interface
    input         mrst,         // @posedge mclk, sync reset
    input         mclk,         // global clock, half DDR3 clock, synchronizes all I/O through the command port
    input   [7:0] cmd_ad,       // byte-serial command address/data (up to 6 bytes: AL-AH-D0-D1-D2-D3 
    input         cmd_stb,      // strobe (with first byte) for the command a/d
    output  [7:0] status_ad,    // status address/data - up to 5 bytes: A - {seq,status[1:0]} - status[2:9] - status[10:17] - status[18:25]
    output        status_rq,    // input request to send status downstream
    input         status_start, // Acknowledge of the first status packet byte (address)

    input         prst,
    output        prsts,        // @pclk - includes sensor reset and sensor PLL reset

    input         pclk,         // global clock input, SPI rate (10-20 MHz) - defines internal pixel rate
//    input         sns_mclk,     // 25Mz for the sensor 

// sensor pads excluding i2c    
    inout         spi_miso,     // input
    inout         spi_mosi,     // not used
    output        spi_cs,       // output, externally connected to inout port
    output        spi_clk,      // output, externally connected to inout port
    inout  [3:0]  gpio,         // only [3] may be used as input from sensor

    output        lwir_mclk,    // output, externally connected to inout port
      
    output        lwir_mrst,    // output, externally connected to inout port   
    output        lwir_pwdn,    // output, externally connected to inout port    

    inout         mipi_dp,      // input diff, not implemented in lepton3 sensor
    inout         mipi_dn,      // input diff, not implemented in lepton3 sensor
    inout         mipi_clkp,    // input diff, not implemented in lepton3 sensor
    inout         mipi_clkn,    // input diff, not implemented in lepton3 sensor
     
    inout         senspgm,    // SENSPGM I/O pin
    inout         sns_ctl,    // npot used at all
    // output
    output [15:0] pxd,  // @pclk
    output        hact, // @pclktwice per actual line
    output        sof,  // @pclk
    output        eof   // @pclk
);
    localparam VOSPI_STATUS_BITS = 14;
// Status data (6 bits + 4)
    wire [VOSPI_STATUS_BITS-1:0] status;
    wire                  [ 3:0] segment_id;
    wire                         crc_err_w;  // single-cycle CRC error
    reg                          crc_err_r;  // at least one CRC error happened since reset
    wire                         in_busy;
    wire                         out_busy;
    wire                  [ 3:0] gpio_in;    // none currently used
    wire                         fake_in;

    assign status = {
       fake_in,
       crc_err_r,
       out_busy,
       in_busy,
       gpio_in     [3:0],
       segment_id  [3:0],      
       out_busy | in_busy, senspgm_int
    };

// then re-sync to pclk (and to sns_mclk)
    reg         spi_nrst_mclk;
    reg         spi_en_mclk;
    reg         segm0_ok_mclk; // from mode register?
    reg         out_en_mclk;   // single paulse - single frame, level - continuous
    wire        out_en_single_mclk;
    wire        crc_reset_mclk;
    reg         lwir_mrst_mclk;
    reg         lwir_pwdn_mclk;
    reg         sns_mclk_en_mclk;
    reg         spi_clk_en_mclk;
    wire [ 3:0] gpio_out;     // only [3] may be used 
    wire [ 3:0] gpio_en;      // none currently used

// resynced  to pclk
    reg  [ 1:0] spi_nrst_pclk;     // reset spi and frame immediately (will need to reset sensor too)
    reg  [ 1:0] spi_en_pclk;       // enable spi communications
    reg  [ 1:0] segm0_ok_pclk;     // allow illegal segments
    reg  [ 1:0] out_en_pclk;
    reg  [ 1:0] lwir_mrst_pclk;
    reg  [ 1:0] lwir_pwdn_pclk;
//    reg  [ 1:0] sns_mclk_en_pclk;
    reg  [ 1:0] spi_clk_en_pclk;
    wire        out_en_single_pclk;
    wire        crc_reset_pclk;


    wire        fake_out;
    wire        spi_mosi_int; // not used

    reg         out_en_r;   // single paulse - single frame, level - continuous

    
    wire        cmd_we;
    wire  [2:0] cmd_a;
    wire [31:0] cmd_data;
    reg  [31:0] data_r;
    reg         set_ctrl_r;
    reg         set_status_r;
    
//    reg  [ 1:0] sns_mclk_en_lwir_mclk;
    reg         sns_mclk_r;
    reg  [3:0]  sns_mclk_cntr;
    
    wire        spi_clken; // from lower module, clock will be combined
    
    
    wire        spi_miso_int;
    wire        spi_cs_int;
    wire        senspgm_int;
    wire        sns_ctl_int;
    // not implemented in the sensor, put dummy input buffer5s
    wire        mipi_dp_int;
    wire        mipi_dn_int;
    wire        mipi_clkp_int;
    wire        mipi_clkn_int;
    
    
// temporary?
    assign fake_in = sns_ctl_int ^ mipi_dp_int ^ mipi_dn_int ^ mipi_clkp_int ^ mipi_clkn_int;

    assign out_en_single_mclk = set_ctrl_r && data_r[VOSPI_OUT_EN_SINGL] && !mrst;
    assign crc_reset_mclk   =   set_ctrl_r && data_r[VOSPI_RESET_CRC] && !mrst;
    assign fake_out =           set_ctrl_r && data_r[VOSPI_FAKE_OUT];
    assign spi_mosi_int =       set_ctrl_r && data_r[VOSPI_MOSI]; // not used

    assign prsts = prst | !lwir_mrst_pclk[1];
    
    always @(posedge mclk) begin
        if      (mrst)     data_r <= 0;
        else if (cmd_we)   data_r <= cmd_data;
        
        if (mrst)          set_status_r <=0;
        else               set_status_r <= cmd_we && (cmd_a== SENSIO_STATUS);                             
        
        if (mrst) set_ctrl_r <=0;
        else               set_ctrl_r <=   cmd_we && (cmd_a== SENSIO_CTRL);
        
        if      (mrst)                                             spi_nrst_mclk <= 0;
        else if (set_ctrl_r && |data_r[VOSPI_EN +: VOSPI_EN_BITS]) spi_nrst_mclk <= data_r[VOSPI_EN + 1]; 
        
        if      (mrst)                                             spi_en_mclk <= 0;
        else if (set_ctrl_r && |data_r[VOSPI_EN +: VOSPI_EN_BITS]) spi_en_mclk <= &data_r[VOSPI_EN +: 2]; 
                                     
        if      (mrst)                                                           segm0_ok_mclk <= 0;
        else if (set_ctrl_r && data_r[VOSPI_SEGM0_OK + VOSPI_SEGM0_OK_BITS - 1]) segm0_ok_mclk <= data_r[VOSPI_SEGM0_OK]; 
        
        if      (mrst)                                                           out_en_mclk <= 0;
        else if (set_ctrl_r && data_r[VOSPI_OUT_EN + VOSPI_OUT_EN_BITS - 1])     out_en_mclk <= data_r[VOSPI_OUT_EN]; 
        
        if      (mrst)                                                           lwir_mrst_mclk <= 0;
        else if (set_ctrl_r && data_r[VOSPI_MRST +  VOSPI_MRST_BITS - 1])        lwir_mrst_mclk <= data_r[VOSPI_MRST]; 
        
        if      (mrst)                                                           lwir_pwdn_mclk <= 0;
        else if (set_ctrl_r && data_r[VOSPI_PWDN + VOSPI_PWDN_BITS - 1])         lwir_pwdn_mclk <= data_r[VOSPI_PWDN]; 
        
        if      (mrst)                                                           sns_mclk_en_mclk <= 0;
        else if (set_ctrl_r && data_r[VOSPI_MCLK + VOSPI_MCLK_BITS - 1])         sns_mclk_en_mclk <= data_r[VOSPI_MCLK]; 
        
        if      (mrst)                                                           spi_clk_en_mclk <= 0;
        else if (set_ctrl_r && data_r[VOSPI_SPI_CLK + VOSPI_SPI_CLK_BITS - 1])   spi_clk_en_mclk <= data_r[VOSPI_SPI_CLK]; 
    end 
    // resync to pclk    
    always @ (posedge pclk) begin
        spi_nrst_pclk[1:0] <=    {spi_nrst_pclk[0],    spi_nrst_mclk};
        spi_en_pclk[1:0] <=      {spi_en_pclk[0],      spi_en_mclk};
        segm0_ok_pclk[1:0] <=    {segm0_ok_pclk[0],    segm0_ok_mclk};
        out_en_pclk[1:0] <=      {out_en_pclk[0],      out_en_mclk};
        lwir_mrst_pclk[1:0] <=   {lwir_mrst_pclk[0],   lwir_mrst_mclk};
        lwir_pwdn_pclk[1:0] <=   {lwir_pwdn_pclk[0],   lwir_pwdn_mclk};
        spi_clk_en_pclk[1:0] <=  {spi_clk_en_pclk[0],  spi_clk_en_mclk}; 
        
        out_en_r <=               out_en_single_pclk | out_en_pclk[1];
        
        if (prst || crc_reset_pclk) crc_err_r <= 0;
        else if (crc_err_w)         crc_err_r <= 1;
        
    end
    
    always @(posedge mclk) begin
        if      (mrst)                           sns_mclk_r <= 0;
        else if (sns_mclk_cntr == 0)             sns_mclk_r <= sns_mclk_en_mclk && !sns_mclk_r;
        
        if      (mrst || (sns_mclk_cntr == 0))   sns_mclk_cntr <= VOSPI_MCLK_HALFDIV - 1;
        else if (sns_mclk_en_mclk || sns_mclk_r) sns_mclk_cntr <= sns_mclk_cntr  - 1;
    end
    

//    always @(posedge sns_mclk) begin
//        sns_mclk_en_lwir_mclk[1:0] <= {sns_mclk_en_lwir_mclk[0],sns_mclk_en_mclk}; 
//    end

     pulse_cross_clock pulse_cross_clock_out_en_single_i (
        .rst         (mrst),                     // input
        .src_clk     (mclk),                     // input
        .dst_clk     (pclk),                     // input
        .in_pulse    (out_en_single_mclk),  // input
        .out_pulse   (out_en_single_pclk),              // output
        .busy() // output
    );

     pulse_cross_clock pulse_cross_clock_crc_reset_i (
        .rst         (mrst),                     // input
        .src_clk     (mclk),                     // input
        .dst_clk     (pclk),                     // input
        .in_pulse    (crc_reset_mclk),           // input
        .out_pulse   (crc_reset_pclk),           // output
        .busy() // output
    );

// implement I/O ports, including fake ones, to be able to assign them I/O pads    
    // generate clocka to sesnor output, controlled by control word bits
    // SPI clock (10..20MHz)
    reg prst_r;
    always @ (posedge pclk) begin
        prst_r <= prst;
    end
    oddr_ss #( // spi_clk
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW),
        .DDR_CLK_EDGE ("OPPOSITE_EDGE"),
        .INIT         (1'b0),
        .SRTYPE       ("SYNC")
    ) spi_clk_i (
        .clk   (pclk),                                    // input
        .ce    (spi_clk_en_pclk[1] | spi_clken | prst_r), // input
        .rst   (prst),                                    // input
        .set   (1'b0),                                    // input
        .din   (2'b01),                                   // input[1:0] 
        .tin   (1'b0),                                    // input
        .dq    (spi_clk)                                  // output
    );
    // sensor master clock (25MHz)
    iobuf #( // lwir_mclk
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) lwir_mclk_i (
        .O  (),                      // output
        .IO (lwir_mclk),             // inout I/O pad
        .I  (sns_mclk_r),           // input
        .T  (1'b0)                  // input - always on
    );

/*    
    oddr_ss #(
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW),
        .DDR_CLK_EDGE ("OPPOSITE_EDGE"),
        .INIT         (1'b0),
        .SRTYPE       ("SYNC")
    ) lwir_mclk_i (
        .clk   (sns_mclk),                 // input
        .ce    (sns_mclk_en_lwir_mclk[1]), // input
        .rst   (prst),                     // input
        .set   (1'b0),                     // input
        .din   (2'b01),                    // input[1:0] 
        .tin   (1'b0),                     // input
        .dq    (lwir_mclk)                 // output
    );
*/
    iobuf #( // spi_miso
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) spi_miso_i (
        .O  (spi_miso_int),         // output
        .IO (spi_miso),             // inout I/O pad
        .I  (1'b0),                 // input
        .T  (1'b1)                  // input - always off
    );

    iobuf #( // spi_mosi, not implemented in the sensor
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) spi_mosi_i (
        .O  (),                     // output - currently not used
        .IO (spi_mosi),             // inout I/O pad
        .I  (spi_mosi_int),         // input
        .T  (!fake_out)             // input - always off
    );
    
     iobuf #( // spi_cs
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) spi_cs_i (
        .O  (),                     // output - currently not used
        .IO (spi_cs),               // inout I/O pad
        .I  (spi_cs_int),           // input
        .T  (1'b0)                  // input - always on
    );

    generate // gpio[3:0]
        genvar i;
        for (i=0; i < (VOSPI_GPIO_BITS / 2); i=i+1) begin: gpio_block
            gpio393_bit gpio_bit_i (
                .clk     (mclk),                          // input
                .srst    (mrst),                          // input
                .we      (set_ctrl_r),                    // input
                .d_in    (data_r[VOSPI_GPIO + 2*i +: 2]), // input[1:0] 
                .d_out   (gpio_out[i]),                   // output
                .en_out  (gpio_en[i])                     // output
            );
        
            iobuf #(
                .DRIVE        (PXD_DRIVE),
                .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
                .IOSTANDARD   (PXD_IOSTANDARD),
                .SLEW         (PXD_SLEW)
            ) gpio_i (
                .O  (gpio_in[i]),  // output - currently not used
                .IO (gpio[i]),     // inout I/O pad
                .I  (gpio_out[i]), // input
                .T  (!gpio_en[i])  // input - always on
            );
        
        end
    endgenerate

// for debug/test alive   
    iobuf #( // lwir_mrst
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) lwir_mrst_i (
        .O  (),                  // output - currently not used
        .IO (lwir_mrst),         // inout I/O pad
        .I  (lwir_mrst_pclk[0]), // input
        .T  (1'b0)               // input - always on
    );

    iobuf #( // lwir_pwdn
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) lwir_pwdn_i (
        .O  (),                  // output - currently not used
        .IO (lwir_pwdn),         // inout I/O pad
        .I  (lwir_pwdn_pclk[0]), // input
        .T  (1'b0)               // input - always on
    );
    
// MIPI - anyway it is not implemented, IOSTANDARD not known, put just single-ended input buffers    
    iobuf #( // mipi_dp
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) mipi_dp_i (
        .O  (mipi_dp_int),         // output - currently not used
        .IO (mipi_dp),             // inout I/O pad
        .I  (1'b0),                // input
        .T  (1'b1)                 // input - always off
    );

    iobuf #( // mipi_dn
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) mipi_dn_i (
        .O  (mipi_dn_int),         // output - currently not used
        .IO (mipi_dn),             // inout I/O pad
        .I  (1'b0),                // input
        .T  (1'b1)                 // input - always off
    );

    iobuf #( // mipi_clkp
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) mipi_clkp_i (
        .O  (mipi_clkp_int),         // output - currently not used
        .IO (mipi_clkp),             // inout I/O pad
        .I  (1'b0),                // input
        .T  (1'b1)                 // input - always off
    );

    iobuf #( // mipi_clkn
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) mipi_clkn_i (
        .O  (mipi_clkn_int),         // output - currently not used
        .IO (mipi_clkn),             // inout I/O pad
        .I  (1'b0),                  // input
        .T  (1'b1)                   // input - always off
    );

    iobuf #( // senspgm
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) senspgm_i (
        .O  (senspgm_int),         // output (detection of the SFE
        .IO (senspgm),             // inout I/O pad
        .I  (1'b0),                // input
        .T  (1'b1)                 // input - always off
    );

    iobuf #( // sns_ctl
        .DRIVE        (PXD_DRIVE),
        .IBUF_LOW_PWR (PXD_IBUF_LOW_PWR),
        .IOSTANDARD   (PXD_IOSTANDARD),
        .SLEW         (PXD_SLEW)
    ) sns_ctl_i (
        .O  (sns_ctl_int),         // output - currently not used
        .IO (sns_ctl),             // inout I/O pad
        .I  (1'b0),                // input
        .T  (1'b1)                 // input - always off
    );

    
    wire        segment_done; 
    wire        discard_segment;
    reg         start_segment;
    reg  [ 3:0] exp_segment;
    reg         spi_en_d;
    // first frame has to be good (only segments only 1..4), next can continue with 0-s     
    reg         segm0_ok_r;
    
    always @(posedge pclk) begin
//        spi_en_d <= spi_nrst_pclk[1];
        spi_en_d <= spi_en_pclk[1];
        
        
        if      (!spi_en_d)                        exp_segment <= VOSPI_SEGMENT_FIRST;
        else if (segment_done && !discard_segment) exp_segment <= (exp_segment == VOSPI_SEGMENT_LAST) ?
                                                                   VOSPI_SEGMENT_FIRST :
                                                                   (exp_segment + 1);
        if      (!spi_en_d)                                                               segm0_ok_r <= 0;
        else if (segment_done && !discard_segment && (exp_segment == VOSPI_SEGMENT_LAST)) segm0_ok_r <= segm0_ok_pclk[1];
        
        start_segment <= spi_en_d && !in_busy && !start_segment;
        
        
    end
            
    
    
    vospi_segment_61 #(
        .VOSPI_PACKET_WORDS     (VOSPI_PACKET_WORDS),     // 80
        .VOSPI_NO_INVALID       (VOSPI_NO_INVALID),       //  1
        .VOSPI_PACKETS_PER_LINE (VOSPI_PACKETS_PER_LINE), //  2
        .VOSPI_SEGMENT_FIRST    (VOSPI_SEGMENT_FIRST),    //  1
        .VOSPI_SEGMENT_LAST     (VOSPI_SEGMENT_LAST),     //  4
        .VOSPI_PACKET_FIRST     (VOSPI_PACKET_FIRST),     //  0
        .VOSPI_PACKET_LAST      (VOSPI_PACKET_LAST),      // 60
        .VOSPI_PACKET_TTT       (VOSPI_PACKET_TTT),       // 20
        .VOSPI_SOF_TO_HACT      (VOSPI_SOF_TO_HACT),      //  2
        .VOSPI_HACT_TO_HACT_EOF (VOSPI_HACT_TO_HACT_EOF)  //  2
    ) vospi_segment_61_i (
        .rst             (!spi_nrst_pclk[1]),   // input
        .clk             (pclk),             // input
        .start           (start_segment),    // input
        .exp_segment     (exp_segment),      // input[3:0] 
        .segm0_ok        (segm0_ok_r),       // input
        .out_en          (out_en_r),         // input
        .spi_clken       (spi_clken),        // output
        .spi_cs          (spi_cs_int),       // output
        .miso            (spi_miso_int),     // input
        .in_busy         (in_busy),          // output
        .out_busy        (out_busy),         // output
        .segment_done    (segment_done),     // output reg 
        .discard_segment (discard_segment),  // output
        .dout            (pxd),              // output[15:0] 
        .hact            (hact),             // output
        .sof             (sof),              // output
        .eof             (eof),              // output
        .crc_err         (crc_err_w),        // output
        .id              (segment_id)        // output[3:0] 
    );


    cmd_deser #(
        .ADDR        (SENSIO_ADDR),
        .ADDR_MASK   (SENSIO_ADDR_MASK),
        .NUM_CYCLES  (6),
        .ADDR_WIDTH  (3),
        .DATA_WIDTH  (32)
    ) cmd_deser_sens_io_i (
        .rst         (1'b0),     // rst), // input
        .clk         (mclk),     // input
        .srst        (mrst),     // input
        .ad          (cmd_ad),   // input[7:0] 
        .stb         (cmd_stb),  // input
        .addr        (cmd_a),    // output[15:0] 
        .data        (cmd_data), // output[31:0] 
        .we          (cmd_we)    // output
    );

    status_generate #(
        .STATUS_REG_ADDR(SENSIO_STATUS_REG),
        .PAYLOAD_BITS(VOSPI_STATUS_BITS) // STATUS_PAYLOAD_BITS)
    ) status_generate_sens_io_i (
        .rst        (1'b0),         // rst), // input
        .clk        (mclk),         // input
        .srst       (mrst),     // input
        .we         (set_status_r), // input
        .wd         (data_r[7:0]),  // input[7:0] 
        .status     ({status}),       // input[25:0] 
        .ad         (status_ad),    // output[7:0] 
        .rq         (status_rq),    // output
        .start      (status_start)  // input
    );
    
 
// for debug/test alive kept for debug if it will be needed
/*   
    pulse_cross_clock pulse_cross_clock_vact_a_mclk_i (
        .rst         (irst),                     // input
        .src_clk     (ipclk),                    // input
        .dst_clk     (mclk),                     // input
        .in_pulse    (vact_out_pre && !vact_r),  // input
        .out_pulse   (vact_a_mclk),              // output
        .busy() // output
    );

    pulse_cross_clock pulse_cross_clock_hact_ext_a_mclk_i (
        .rst         (irst),                     // input
        .src_clk     (ipclk),                    // input
        .dst_clk     (mclk),                     // input
        .in_pulse    (hact_ext && !hact_ext_r),  // input
        .out_pulse   (hact_ext_a_mclk),          // output
        .busy() // output
    );

    pulse_cross_clock pulse_cross_clock_hact_a_mclk_i (
        .rst         (irst),                     // input
        .src_clk     (ipclk),                    // input
        .dst_clk     (mclk),                     // input
        .in_pulse    (hact_r && !hact_r2),       // input
        .out_pulse   (hact_a_mclk),              // output
        .busy() // output
    );
*/

endmodule

