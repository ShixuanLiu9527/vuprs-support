
`timescale 1 ns / 1 ps

	module vuprs_adc_controller_v2_0 #
	(
		// Users to add parameters here

		parameter integer USR_CLK_CYCLE_NS   = 20,   /* unit: ns, clock cycle of [usr_clk] (e.g. 20 ns for 50 MHz) */
              		      T_CYCLE_NS         = 5000, /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
          	  		      T_RESET_NS         = 50,   /* unit: ns, t_reset of AD7606 (refer to data sheet) */
          	  		      T_CONV_MIN_NS      = 3450, /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
          	  		      T_CONV_MAX_NS      = 4150, /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
          	  		      T1_NS              = 40,   /* unit: ns, t1 of AD7606 (refer to data sheet) */
          	  		      T2_NS              = 25,   /* unit: ns, t2 of AD7606 (refer to data sheet) */
          	  		      T10_NS             = 25,   /* unit: ns, t10 of AD7606 (refer to data sheet) */
          	  		      T11_NS             = 15,   /* unit: ns, t11 of AD7606 (refer to data sheet) */
          	  		      T14_NS             = 25,   /* unit: ns, t14 of AD7606 (refer to data sheet) */
          	  		      T15_NS             = 6,    /* unit: ns, t15 of AD7606 (refer to data sheet) */
          	  		      T26_NS             = 25,   /* unit: ns, t15 of AD7606 (refer to data sheet) */

		parameter integer C_M_AXIS_BUFFER_SIZE = 32,

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here

		input wire adc_card_present_detect,

		input wire          adc_rst_n,
		input wire          adc_clk,
	
		input wire          adc_a_hw_busy,                       /* BUSY pin of the AD7606 chip */
    	input wire          adc_a_hw_first_data,                 /* FIRSTDATA pin of the AD7606 chip */
    	input wire [15: 0]  adc_a_hw_data,                       /* D0 - D15 Pins of the AD7606 chip */

    	output wire         adc_a_hw_convst,                     /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    	output wire         adc_a_hw_rd,                         /* RD# pin of the AD7606 chip */
    	output wire         adc_a_hw_cs,                         /* CS# pin of the AD7606 chip */
    	output wire         adc_a_hw_range,                      /* RANGE pin of the AD7606 chip */
    	output wire [2: 0]  adc_a_hw_os,                         /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    	output wire         adc_a_hw_mode_select,                /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    	output wire         adc_a_hw_reset,                      /* RESET pin of the AD7606 chip */
    	output wire         adc_a_hw_stby_n,                     /* STBY# pin of the AD7606 */

		input wire          adc_b_hw_busy,                       /* BUSY pin of the AD7606 chip */
    	input wire          adc_b_hw_first_data,                 /* FIRSTDATA pin of the AD7606 chip */
    	input wire [15: 0]  adc_b_hw_data,                       /* D0 - D15 Pins of the AD7606 chip */

    	output wire         adc_b_hw_convst,                     /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    	output wire         adc_b_hw_rd,                         /* RD# pin of the AD7606 chip */
    	output wire         adc_b_hw_cs,                         /* CS# pin of the AD7606 chip */
    	output wire         adc_b_hw_range,                      /* RANGE pin of the AD7606 chip */
    	output wire [2: 0]  adc_b_hw_os,                         /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    	output wire         adc_b_hw_mode_select,                /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    	output wire         adc_b_hw_reset,                      /* RESET pin of the AD7606 chip */
    	output wire         adc_b_hw_stby_n,                     /* STBY# pin of the AD7606 */

		output wire fpga_sampling_led,
		output wire fpga_adc_card_present_led,

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tkeep,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready,
		
		// DEBUG_PORTS

		/* S_AXI */
		
		output wire [2: 0] DEBUG_frame_state,

		/* M_AXIS */

		output wire [1: 0] DEBUG_mst_exec_state,
		output wire [7: 0] DEBUG_buffer_pointer,
		output wire [32: 0] DEBUG_data_send_count,
		output wire DEBUG_fifo_rd_en,

		output wire [2: 0] DEBUG_fifo_write_state,
		output wire [7: 0] DEBUG_crc_calculated_channels,
		output wire [7: 0] DEBUG_fifo_pushed_number,
		output wire DEBUG_fifo_write_en,
		output wire [31: 0] DEBUG_current_fifo_write_data
	);

	wire ready;
	wire [C_S00_AXI_DATA_WIDTH - 1: 0] err_flags;
	wire [C_S00_AXI_DATA_WIDTH - 1: 0] sampling_clk_increment;
	wire [C_S00_AXI_DATA_WIDTH - 1: 0] sampling_points;
	wire one_frame_sampling_trigger;
	wire last_frame;
	wire software_rst;

// Instantiation of Axi Bus Interface S00_AXI
	vuprs_adc_controller_v2_0_S00_AXI # (
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
		
		.USR_CLK_CYCLE_NS(USR_CLK_CYCLE_NS)
	) vuprs_adc_controller_v2_0_S00_AXI_inst (

		/* Internal Connection */

		.adc_module_ready(ready),
		.adc_module_error_flag(err_flags),
		.sampling_clk_increment(sampling_clk_increment),
		.sampling_points(sampling_points),
		.one_frame_sampling_trigger(one_frame_sampling_trigger),
		.last_frame(last_frame),
		.software_rst(software_rst),

		.adc_card_present_detect(adc_card_present_detect),
		.fpga_sampling_led(fpga_sampling_led),
		.fpga_adc_card_present_led(fpga_adc_card_present_led),

		/* AXI-Lite Interface */

		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		
		/* DEBUG */
		
		.DEBUG_frame_state(DEBUG_frame_state)
	);

// Instantiation of Axi Bus Interface M00_AXIS
	vuprs_adc_controller_v2_0_M00_AXIS # ( 

		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
		.C_M_START_COUNT(C_M00_AXIS_START_COUNT),
		.C_M_AXIS_BUFFER_SIZE(C_M_AXIS_BUFFER_SIZE),

		.USR_CLK_CYCLE_NS(USR_CLK_CYCLE_NS),  /* unit: ns, clock cycle of [usr_clk] (e.g. 20 ns for 50 MHz) */
        .T_CYCLE_NS(T_CYCLE_NS),              /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
        .T_RESET_NS(T_RESET_NS),              /* unit: ns, t_reset of AD7606 (refer to data sheet) */
        .T_CONV_MIN_NS(T_CONV_MIN_NS),        /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
        .T_CONV_MAX_NS(T_CONV_MAX_NS),        /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
        .T1_NS(T1_NS),                        /* unit: ns, t1 of AD7606 (refer to data sheet) */
        .T2_NS(T2_NS),                        /* unit: ns, t2 of AD7606 (refer to data sheet) */
        .T10_NS(T10_NS),                      /* unit: ns, t10 of AD7606 (refer to data sheet) */
        .T11_NS(T11_NS),                      /* unit: ns, t11 of AD7606 (refer to data sheet) */
        .T14_NS(T14_NS),                      /* unit: ns, t14 of AD7606 (refer to data sheet) */
        .T15_NS(T15_NS),                      /* unit: ns, t15 of AD7606 (refer to data sheet) */
        .T26_NS(T26_NS),                      /* unit: ns, t15 of AD7606 (refer to data sheet) */

		.CONTROL_REGISTER_WIDTH(C_S00_AXI_DATA_WIDTH) // internal connection

	) vuprs_adc_controller_v2_0_M00_AXIS_inst (

		/* Internal Connection */

		.error_flags(err_flags),
		.sampling_clk_increment(sampling_clk_increment),
		.sampling_points(sampling_points),
		.one_frame_sampling_trigger(one_frame_sampling_trigger),
		.ready(ready),
		.last_frame(last_frame),
		.software_rst(software_rst),

		/* ADC Hardware Pins */

		.adc_clk(adc_clk),
		.adc_rst_n(adc_rst_n),

		.adc_a_hw_busy(adc_a_hw_busy),                 /* BUSY pin of the AD7606 chip */
    	.adc_a_hw_first_data(adc_a_hw_first_data),     /* FIRSTDATA pin of the AD7606 chip */
    	.adc_a_hw_data(adc_a_hw_data),                 /* D0 - D15 Pins of the AD7606 chip */
    	.adc_a_hw_convst(adc_a_hw_convst),             /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    	.adc_a_hw_rd(adc_a_hw_rd),                     /* RD# pin of the AD7606 chip */
    	.adc_a_hw_cs(adc_a_hw_cs),                     /* CS# pin of the AD7606 chip */
    	.adc_a_hw_range(adc_a_hw_range),               /* RANGE pin of the AD7606 chip */
    	.adc_a_hw_os(adc_a_hw_os),                     /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    	.adc_a_hw_mode_select(adc_a_hw_mode_select),   /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    	.adc_a_hw_reset(adc_a_hw_reset),               /* RESET pin of the AD7606 chip */
    	.adc_a_hw_stby_n(adc_a_hw_stby_n),             /* STBY# pin of the AD7606 */

		.adc_b_hw_busy(adc_b_hw_busy),                 /* BUSY pin of the AD7606 chip */
    	.adc_b_hw_first_data(adc_b_hw_first_data),     /* FIRSTDATA pin of the AD7606 chip */
    	.adc_b_hw_data(adc_b_hw_data),                 /* D0 - D15 Pins of the AD7606 chip */
    	.adc_b_hw_convst(adc_b_hw_convst),             /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    	.adc_b_hw_rd(adc_b_hw_rd),                     /* RD# pin of the AD7606 chip */
    	.adc_b_hw_cs(adc_b_hw_cs),                     /* CS# pin of the AD7606 chip */
    	.adc_b_hw_range(adc_b_hw_range),               /* RANGE pin of the AD7606 chip */
    	.adc_b_hw_os(adc_b_hw_os),                     /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    	.adc_b_hw_mode_select(adc_b_hw_mode_select),   /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    	.adc_b_hw_reset(adc_b_hw_reset),               /* RESET pin of the AD7606 chip */
    	.adc_b_hw_stby_n(adc_b_hw_stby_n),             /* STBY# pin of the AD7606 */

		/* AXI-Stream Interface */

		.M_AXIS_TKEEP(m00_axis_tkeep),
		.M_AXIS_ACLK(m00_axis_aclk),
		.M_AXIS_ARESETN(m00_axis_aresetn),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready),
		
		/* DEBUG */
		
		.DEBUG_mst_exec_state(DEBUG_mst_exec_state),
		.DEBUG_buffer_pointer(DEBUG_buffer_pointer),
		.DEBUG_data_send_count(DEBUG_data_send_count),
		.DEBUG_fifo_rd_en(DEBUG_fifo_rd_en),

		.DEBUG_fifo_write_state(DEBUG_fifo_write_state),
		.DEBUG_crc_calculated_channels(DEBUG_crc_calculated_channels),
		.DEBUG_fifo_pushed_number(DEBUG_fifo_pushed_number),
		.DEBUG_fifo_write_en(DEBUG_fifo_write_en),
		.DEBUG_current_fifo_write_data(DEBUG_current_fifo_write_data)
	);

	// Add user logic here

	// User logic ends

	endmodule
