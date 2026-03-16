
`timescale 1 ns / 1 ps

	/* AXI-Stream Master, without CRC calculation */

	module vadc_v1_0_M00_AXIS #
	(
		parameter integer USR_CLK_CYCLE_NS  = 20,   /* unit: ns, clock cycle of [adc_clk] (e.g. 20 ns for 50 MHz) */
              		  T_CYCLE_NS            = 5000, /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
          	  		  T_RESET_NS            = 50,   /* unit: ns, t_reset of AD7606 (refer to data sheet) */
          	  		  T_CONV_MIN_NS         = 3450, /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
          	  		  T_CONV_MAX_NS         = 4150, /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
          	  		  T1_NS                 = 40,   /* unit: ns, t1 of AD7606 (refer to data sheet) */
          	  		  T2_NS                 = 25,   /* unit: ns, t2 of AD7606 (refer to data sheet) */
          	  		  T10_NS                = 25,   /* unit: ns, t10 of AD7606 (refer to data sheet) */
          	  		  T11_NS                = 15,   /* unit: ns, t11 of AD7606 (refer to data sheet) */
          	  		  T14_NS                = 25,   /* unit: ns, t14 of AD7606 (refer to data sheet) */
          	  		  T15_NS                = 6,    /* unit: ns, t15 of AD7606 (refer to data sheet) */
          	  		  T26_NS                = 25,   /* unit: ns, t15 of AD7606 (refer to data sheet) */

		parameter integer CONTROL_REGISTER_WIDTH = 32,        /* control register width */

		/* Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH. */

		parameter integer C_M_AXIS_TDATA_WIDTH	 = 32,

		/* Start init_count is the number of clock cycles the master will wait before initiating/issuing any transaction. */

		parameter integer C_M_START_COUNT	     = 32,

		/* AXI-Stream Buffer size */

		parameter integer C_M_AXIS_BUFFER_SIZE   = 32,  /* Smaller than 255 */

		/* Data Header & Data Tailer */

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F

	)
	(
		output wire [CONTROL_REGISTER_WIDTH - 1: 0]  error_flags,
		output wire                                  ready,

		input wire [CONTROL_REGISTER_WIDTH - 1: 0]   sampling_clk_increment,
		input wire [CONTROL_REGISTER_WIDTH - 1: 0]   sampling_points,
		input wire                                   last_frame,
		input wire                                   software_rst,
		input wire                                   continuous_sampling,

		input wire                                   one_frame_sampling_trigger, /* rising edge to trigger */
		input wire                                   adc_clk,                    /* clock for ADC, 100 MHz or 50 MHz */
		input wire                                   adc_rst_n,                  /* reset signal for ADC */

		/* ---------------------------------- ADC-A hardware signals -------------------------------------------- */

		input wire          adc_a_hw_busy,        /* BUSY pin of the AD7606 chip */
    	input wire          adc_a_hw_first_data,  /* FIRSTDATA pin of the AD7606 chip */
    	input wire [15: 0]  adc_a_hw_data,        /* D0 - D15 Pins of the AD7606 chip */

    	output wire         adc_a_hw_convst,      /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    	output wire         adc_a_hw_rd,          /* RD# pin of the AD7606 chip */
    	output wire         adc_a_hw_cs,          /* CS# pin of the AD7606 chip */
    	output wire         adc_a_hw_range,       /* RANGE pin of the AD7606 chip */
    	output wire [2: 0]  adc_a_hw_os,          /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    	output wire         adc_a_hw_mode_select, /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    	output wire         adc_a_hw_reset,       /* RESET pin of the AD7606 chip */
    	output wire         adc_a_hw_stby_n,      /* STBY# pin of the AD7606 */

		/* ---------------------------------- ADC-B hardware signals -------------------------------------------- */

		input wire          adc_b_hw_busy,        /* BUSY pin of the AD7606 chip */
    	input wire          adc_b_hw_first_data,  /* FIRSTDATA pin of the AD7606 chip */
    	input wire [15: 0]  adc_b_hw_data,        /* D0 - D15 Pins of the AD7606 chip */

    	output wire         adc_b_hw_convst,      /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    	output wire         adc_b_hw_rd,          /* RD# pin of the AD7606 chip */
    	output wire         adc_b_hw_cs,          /* CS# pin of the AD7606 chip */
    	output wire         adc_b_hw_range,       /* RANGE pin of the AD7606 chip */
    	output wire [2: 0]  adc_b_hw_os,          /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    	output wire         adc_b_hw_mode_select, /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    	output wire         adc_b_hw_reset,       /* RESET pin of the AD7606 chip */
    	output wire         adc_b_hw_stby_n,      /* STBY# pin of the AD7606 */

		/* ---------------------------------- AXI-Stream Interface -------------------------------------------- */

		output wire [(C_M_AXIS_TDATA_WIDTH / 8) - 1: 0] M_AXIS_TKEEP,
		input wire                                      M_AXIS_ACLK,
		input wire                                      M_AXIS_ARESETN,

		/* 
		   Master Stream Ports. 
		   TVALID indicates that the master is driving a valid transfer, 
		   A transfer takes place when both TVALID and TREADY are asserted. 
		*/

		output wire                                     M_AXIS_TVALID,

		/* 
		   TDATA is the primary payload that is used to provide the 
		   data that is passing across the interface from the master. 
		*/

		output wire [C_M_AXIS_TDATA_WIDTH - 1: 0]       M_AXIS_TDATA,

		/* 
		   TSTRB is the byte qualifier that indicates 
		   whether the content of the associated byte of TDATA is 
		   processed as a data byte or a position byte. 
		*/

		output wire [(C_M_AXIS_TDATA_WIDTH / 8) - 1: 0] M_AXIS_TSTRB,

		/* TLAST indicates the boundary of a packet. */

		output wire                                     M_AXIS_TLAST,

		/* TREADY indicates that the slave can accept a transfer in the current cycle. */

		input wire                                      M_AXIS_TREADY,

		/* ------------------------------------- DEBUG ----------------------------------- */

		output wire [7:0] DEBUG_fifo_pushed_number,
		output wire [3:0] DEBUG_mst_exec_state,
		output wire [2:0] DEBUG_fifo_write_state,

		output wire DEBUG_fifo_full,
		output wire DEBUG_fifo_almost_full,
		output wire DEBUG_fifo_reset
	);
	
	function integer clogb2 (input integer bit_depth);
		begin
	    	for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	      		bit_depth = bit_depth >> 1;
	  	end
	endfunction

	// WAIT_COUNT_BITS is the width of the wait counter.                                 
	localparam integer BUFFER_POINTER_BITS = clogb2(C_M_AXIS_BUFFER_SIZE) + 3;

	// BIT_NUM gives the minimum number of bits needed to address 'depth' size of FIFO.  
	localparam BIT_NUM  = CONTROL_REGISTER_WIDTH + 1;

	localparam FIFO_RESET_CLOCK_COUNT = 10;
	localparam FIFO_RESET_CLOCK_COUNT_2 = 65;
	localparam FIFO_RESET_WAIT_MAX_COUNT = 150;

	localparam ADC_DEFAULT_CLOCK_INCREMENT = 12500;

	localparam BUFFER_RESET_CLOCK_COUNT = 3;

	localparam integer WAIT_COUNT_BITS = clogb2(FIFO_RESET_WAIT_MAX_COUNT) + 3;
	                                                                                  
	/*  
		Define the states of state machine
		The control state machine oversees the writing of input streaming data to the FIFO,
		and outputs the streaming data from the FIFO
	*/

	localparam [3: 0] EXEC_STATE__IDLE = 4'd0,
	                  EXEC_STATE__MAKE_RESET_SIGNAL  = 4'd1,
					  EXEC_STATE__WAIT_FOR_RESET_START = 4'd2,
					  EXEC_STATE__WAIT_FOR_RESET_END = 4'd3,
	                  EXEC_STATE__SEND_STREAM   = 4'd4;

	localparam FIFO_WRITE_STATE__IDLE             = 1'd0,
	           FIFO_WRITE_STATE__WRITE_FIFO       = 1'd1;

	localparam INVALID_DATA                       = {(C_M_AXIS_TDATA_WIDTH){1'b1}};

	localparam INVALID_SAMPLING_PARAM             = {(CONTROL_REGISTER_WIDTH){1'b1}};

	localparam BUFFER_RESET_VALUE                 = {(C_M_AXIS_TDATA_WIDTH){1'b1}};

	localparam HIGH                               = 1'b1,
			   LOW                                = 1'b0;

	localparam TRUE                               = 1'b1,
			   FALSE                              = 1'b0;

	localparam [7: 0] INVALID_BUFFER_POINTER      = C_M_AXIS_BUFFER_SIZE;  // 32

	localparam [31: 0] INVALID_BUFFER_DATA        = 32'hF0F0_F0F0;

	localparam FRAME_WORD_NUMBER                  = 10;

	localparam MINIUM_SAMPLING_CLK_INCREMENT      = (1000_000_000 / 150_000) / USR_CLK_CYCLE_NS + 1;  // 150 kHz max

	reg [3: 0] mst_exec_state;  // State variable
	
	reg [3: 0] mst_exec_state_sync00;  // ADC clock domain
	reg [3: 0] mst_exec_state_sync01;  // ADC clock domain
	reg [3: 0] mst_exec_state_sync;  // ADC clock domain
	
	reg [BIT_NUM - 1: 0] data_send_count;  // indicate the quantity of sended data, BIT_NUM
	
	// AXI Stream internal signals

	reg [WAIT_COUNT_BITS - 1: 0] fifo_reset_count;

	reg [WAIT_COUNT_BITS - 1: 0] fifo_reset_count_sync_00;  // AXI clock domain
	reg [WAIT_COUNT_BITS - 1: 0] fifo_reset_count_sync_01;  // AXI clock domain
	reg [WAIT_COUNT_BITS - 1: 0] fifo_reset_count_sync;  // AXI clock domain
	
	// reg  							    axis_tvalid;  // streaming data valid
	reg  	                            axis_tlast;   // t_last
	reg [C_M_AXIS_TDATA_WIDTH - 1 : 0] 	axis_tdata;    // FIFO implementation signals

	assign M_AXIS_TDATA = axis_tdata;

	reg                                 last_frame_sync;

	reg module_ready;

	reg fifo_rd_en = FALSE;

	wire [C_M_AXIS_TDATA_WIDTH - 1: 0] current_fifo_read_data;

	reg [63: 0] current_sampling_data_points;

	reg one_frame_sampling_trigger_sync1;
	reg one_frame_sampling_trigger_sync2;
	
	wire fifo_almost_full;
	wire fifo_full;
	wire fifo_empty;
	wire fifo_almost_empty;

	wire fifo_wr_rst_busy;
	wire fifo_rd_rst_busy;

	reg fifo_reset = LOW;
	
	reg software_rst_sync_adc_00 = FALSE;
	reg software_rst_sync_adc_01 = FALSE;
	reg software_rst_sync_adc = FALSE;

	reg software_rst_sync_axi = FALSE;

	reg [C_M_AXIS_TDATA_WIDTH - 1: 0] send_buffer[0: C_M_AXIS_BUFFER_SIZE];  // 32, send_buffer[32] is invalid
	reg [BUFFER_POINTER_BITS -1: 0] buffer_pointer;
	reg reset_buffer = FALSE;

	reg buffer_over_flow = FALSE;
	reg buffer_pointer_error = FALSE;
	reg fifo_reset_error = FALSE;
	
	wire [15: 0] adc_a_ch1;
	wire [15: 0] adc_a_ch2;
	wire [15: 0] adc_a_ch3;
	wire [15: 0] adc_a_ch4;
	wire [15: 0] adc_a_ch5;
	wire [15: 0] adc_a_ch6;
	wire [15: 0] adc_a_ch7;
	wire [15: 0] adc_a_ch8;

	wire [15: 0] adc_b_ch1;
	wire [15: 0] adc_b_ch2;
	wire [15: 0] adc_b_ch3;
	wire [15: 0] adc_b_ch4;
	wire [15: 0] adc_b_ch5;
	wire [15: 0] adc_b_ch6;
	wire [15: 0] adc_b_ch7;
	wire [15: 0] adc_b_ch8;
	
	wire adc_a_sampling;
	wire adc_a_ready;
	wire [3: 0] adc_a_err;

	wire adc_b_sampling;
	wire adc_b_ready;
	wire [3: 0] adc_b_err;

	reg adc_have_sampled = FALSE;  /* to ensure the output data of ADC modules is valid */

	/* User Registers end */

	// I/O Connections assignments

	assign M_AXIS_TVALID = (buffer_pointer != INVALID_BUFFER_POINTER) && (mst_exec_state == EXEC_STATE__SEND_STREAM);  // tvalid signal
	assign M_AXIS_TLAST	 = axis_tlast;

	assign ready = module_ready;
	assign error_flags = {{(CONTROL_REGISTER_WIDTH - 11){1'b0}}, fifo_reset_error, buffer_pointer_error, buffer_over_flow, adc_b_err[3: 0], adc_a_err[3: 0]};

	wire axis_hand_shake = M_AXIS_TVALID && M_AXIS_TREADY;

	`define ONE_VALID_DATA_SEND_AT_THAT_TIME (axis_hand_shake)

	`define ONE_VALID_DATA_PUSHED_IN_FIFO (fifo_write_en && !fifo_full)
	`define ADC_SAMPLING_COMPLETE (!adc_a_sampling && !adc_b_sampling)

	/* --------------------------------------------------------------------------------------------------------- */
	/* ---------------------------------------- AXI-Stream CLOCK DOMAIN ---------------------------------------- */
	/* --------------------------------------------------------------------------------------------------------- */

	/* ---------------------------------------------- T_DATA --------------------------------------------------- */

	always @(*) begin
		axis_tdata = send_buffer[buffer_pointer];
	end

	/* ---------------------------------------------- AXI-Stream Buffer ----------------------------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (!adc_rst_n) software_rst_sync_axi <= FALSE;
		else software_rst_sync_axi <= software_rst;
	end

	integer i;

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || reset_buffer || buffer_pointer_error || software_rst_sync_axi) begin

			for (i = 0; i <= C_M_AXIS_BUFFER_SIZE - 1; i = i + 1) begin
				send_buffer[i] <= 0;
			end
			send_buffer[INVALID_BUFFER_POINTER] <= INVALID_BUFFER_DATA;
			buffer_pointer <= INVALID_BUFFER_POINTER;

			buffer_over_flow <= FALSE;
			buffer_pointer_error <= FALSE;

			fifo_rd_en <= FALSE;

		end else begin

			/* push buffer at first */

			if (mst_exec_state == EXEC_STATE__SEND_STREAM) begin

				if (buffer_pointer == INVALID_BUFFER_POINTER) begin  // t_valid = LOW at that moment

					/* if FIFO read enable at that time, push FIFO data to buffer */

					if (fifo_rd_en) begin
						send_buffer[0] <= current_fifo_read_data;
						buffer_pointer <= 0;
					end else begin
						buffer_pointer <= buffer_pointer;
					end

					/* Enable FIFO reading */

					if(!fifo_almost_empty) fifo_rd_en <= TRUE;
					else fifo_rd_en <= FALSE;

				end else if (buffer_pointer <= C_M_AXIS_BUFFER_SIZE - 1) begin

					if (fifo_rd_en) begin  // the data must be push into buffer

						/* FIFO read control */

						if (buffer_pointer >= C_M_AXIS_BUFFER_SIZE - 2) begin
							fifo_rd_en <= FALSE;  // this is the last data (pointer is C_M_AXIS_BUFFER_SIZE - 1), stop read
						end else begin
							if (!fifo_almost_empty) fifo_rd_en <= TRUE;  // continue read
							else fifo_rd_en <= FALSE;
						end

						/* -------------------------------------------------------------------------------------- */
						/* ------------------------------------- Update data ------------------------------------ */
						/* -------------------------------------------------------------------------------------- */

						/* Update buffer */

						for (i = 0; i <= C_M_AXIS_BUFFER_SIZE - 2; i = i + 1) begin
							send_buffer[i + 1] <= send_buffer[i];
						end
						send_buffer[0] <= current_fifo_read_data;

						/* Update pointer */

						if (!`ONE_VALID_DATA_SEND_AT_THAT_TIME) begin

							if (buffer_pointer <= C_M_AXIS_BUFFER_SIZE - 2) buffer_pointer <= buffer_pointer + 1;  /*  */
							else begin
								/* buffer_pointer == C_M_AXIS_BUFFER_SIZE - 1, data must be send */
								/* Buffer overflow */
								buffer_over_flow <= TRUE;
							end

						end else begin

							buffer_pointer <= buffer_pointer;  // do nothing for pointer

						end

					end else begin

						/* Enable FIFO read signal */

						if(!fifo_almost_empty) begin

							/* continue read */

							if (buffer_pointer == C_M_AXIS_BUFFER_SIZE - 1) fifo_rd_en <= FALSE;  // cannot read any more
							else fifo_rd_en <= TRUE;

						end
						else fifo_rd_en <= FALSE;

						/* Update buffer pointer */

						if (!`ONE_VALID_DATA_SEND_AT_THAT_TIME) begin
							buffer_pointer <= buffer_pointer;  // do nothing for pointer
						end else begin
							if (buffer_pointer == 0) buffer_pointer <= INVALID_BUFFER_POINTER;
							else buffer_pointer <= buffer_pointer - 1;
						end

					end

				end

				else begin

					buffer_pointer_error <= TRUE;  // CRITICAL: BUFFER POINTER ERROR !!!!!

				end

			end else begin
				
				fifo_rd_en <= FALSE;  // reset fifo

			end
		end
	end

	/* ------------------------------------------- Data Input -------------------------------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync_axi) begin
			current_sampling_data_points <= 0;
			last_frame_sync <= FALSE;
		end else begin
			if (mst_exec_state == EXEC_STATE__IDLE) begin
				current_sampling_data_points <= sampling_points * FRAME_WORD_NUMBER;  /* FRAME_WORD_NUMBER * 32 bit */
			end
			last_frame_sync <= last_frame;
		end
	end

	/* ----------------------------------------- Detect rising edge --------------------------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync_axi) begin
			one_frame_sampling_trigger_sync1 <= LOW;
			one_frame_sampling_trigger_sync2 <= LOW;
		end else begin
			one_frame_sampling_trigger_sync1 <= one_frame_sampling_trigger;
			one_frame_sampling_trigger_sync2 <= one_frame_sampling_trigger_sync1;
		end
	end

	wire one_frame_sampling_trigger_rising_edge = one_frame_sampling_trigger_sync1 && (~one_frame_sampling_trigger_sync2);

	/* ---------------------------------------- System state --------------------------------------------------- */

	/* --------------------------------------------------------------------------------------------------------- */
	/* ---------------------------------------- ADC CLOCK DOMAIN START ----------------------------------------- */
	/* --------------------------------------------------------------------------------------------------------- */

	/* sync to mst_exec_state */

	always @(posedge adc_clk) begin
		if (!adc_rst_n || software_rst_sync_adc) begin
			mst_exec_state_sync <= EXEC_STATE__IDLE;
			mst_exec_state_sync00 <= EXEC_STATE__IDLE;
			mst_exec_state_sync01 <= EXEC_STATE__IDLE;
		end else begin
			mst_exec_state_sync00 <= mst_exec_state;
			mst_exec_state_sync01 <= mst_exec_state_sync00;
			mst_exec_state_sync <= mst_exec_state_sync01;
		end
	end

	/* Reset FIFO when mst_exec_state_sync == EXEC_STATE__INIT_COUNTER */

	always @(posedge adc_clk) begin
		if (!adc_rst_n || software_rst_sync_adc) begin
			fifo_reset_count <= 0;
			fifo_reset <= LOW;  // start reset fifo
		end else begin
		  	case (mst_exec_state_sync)

				EXEC_STATE__IDLE: begin
					fifo_reset <= LOW;
					fifo_reset_count <= 0;
				end

				EXEC_STATE__MAKE_RESET_SIGNAL: begin
					fifo_reset <= HIGH;
					fifo_reset_count <= fifo_reset_count + 1;
				end

				EXEC_STATE__WAIT_FOR_RESET_START: begin
					fifo_reset <= LOW;
					fifo_reset_count <= 0;
				end

				EXEC_STATE__WAIT_FOR_RESET_END: begin
					fifo_reset <= LOW;
					fifo_reset_count <= fifo_reset_count + 1;
				end

				default: begin
					fifo_reset <= LOW;
					fifo_reset_count <= 0;
				end

			endcase
		end
	end

	/* --------------------------------------------------------------------------------------------------------- */
	/* ---------------------------------------- ADC CLOCK DOMAIN END ------------------------------------------- */
	/* --------------------------------------------------------------------------------------------------------- */

	/* --------------------------------------------------------------------------------------------------------- */
	/* ------------------------------------ AXI-Stream CLOCK DOMAIN START -------------------------------------- */
	/* --------------------------------------------------------------------------------------------------------- */

	/* sync to fifo_reset_count (ADC Clock Domain --> AXI-Stream Clock Domain) */

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync_axi) begin
			fifo_reset_count_sync_00 <= 0;
			fifo_reset_count_sync_01 <= 0;
			fifo_reset_count_sync <= 0;
		end else begin
			fifo_reset_count_sync_00 <= fifo_reset_count;
			fifo_reset_count_sync_01 <= fifo_reset_count_sync_00;
			fifo_reset_count_sync <= fifo_reset_count_sync_01;
		end
	end

	/* Flags */
	
	always @(posedge M_AXIS_ACLK) begin
	
		if (!M_AXIS_ARESETN || software_rst_sync_axi) begin
			mst_exec_state <= EXEC_STATE__IDLE;
			module_ready <= TRUE;
			reset_buffer <= TRUE;  // start reset buffer
			fifo_reset_error <= FALSE;
		end else begin
			case (mst_exec_state)

				EXEC_STATE__IDLE: begin
					fifo_reset_error <= FALSE;
					reset_buffer <= TRUE;  // start reset buffer
					if (one_frame_sampling_trigger_rising_edge) begin
						mst_exec_state <= EXEC_STATE__MAKE_RESET_SIGNAL;
						module_ready <= FALSE;  // sampling flag to TRUE
					end else begin
						mst_exec_state <= EXEC_STATE__IDLE;
						module_ready <= TRUE;
					end
				end

				EXEC_STATE__MAKE_RESET_SIGNAL: begin
					fifo_reset_error <= FALSE;
					reset_buffer <= TRUE;
					if (fifo_reset_count_sync >= FIFO_RESET_CLOCK_COUNT) mst_exec_state <= EXEC_STATE__WAIT_FOR_RESET_START;
					else mst_exec_state <= EXEC_STATE__MAKE_RESET_SIGNAL;
				end

				EXEC_STATE__WAIT_FOR_RESET_START: begin
					fifo_reset_error <= FALSE;
					reset_buffer <= TRUE;
					if (fifo_full) mst_exec_state <= EXEC_STATE__WAIT_FOR_RESET_END;
					else mst_exec_state <= EXEC_STATE__WAIT_FOR_RESET_START;
				end

				EXEC_STATE__WAIT_FOR_RESET_END: begin
					reset_buffer <= TRUE;
					if (fifo_full == LOW) begin
						fifo_reset_error <= FALSE;
						mst_exec_state <= EXEC_STATE__SEND_STREAM;
					end else if (fifo_reset_count_sync > FIFO_RESET_WAIT_MAX_COUNT) begin
						fifo_reset_error <= TRUE;
						mst_exec_state <= EXEC_STATE__SEND_STREAM;
					end else mst_exec_state <= EXEC_STATE__WAIT_FOR_RESET_END;
				end

				EXEC_STATE__SEND_STREAM: begin
					reset_buffer <= FALSE;
					if (continuous_sampling) begin
						mst_exec_state <= EXEC_STATE__SEND_STREAM;
						reset_buffer <= FALSE;  // send not complete
					end else begin

						if (data_send_count >= current_sampling_data_points - 1 && `ONE_VALID_DATA_SEND_AT_THAT_TIME) begin
							mst_exec_state <= EXEC_STATE__IDLE;
							reset_buffer <= TRUE;  // send complete, reset buffer
						end else begin
							mst_exec_state <= EXEC_STATE__SEND_STREAM;
							reset_buffer <= FALSE;  // send not complete
						end

					end
				end

				default: begin
					mst_exec_state <= EXEC_STATE__IDLE;
					reset_buffer <= TRUE;
					module_ready <= TRUE;
					fifo_reset_error <= FALSE;
				end

			endcase
		end

	end

	/* Registers */

	assign M_AXIS_TSTRB	 = {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};  /* Always be TRUE */
	assign M_AXIS_TKEEP  = {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};  /* Always be TRUE */

	always @(posedge M_AXIS_ACLK) begin
	
		if (!M_AXIS_ARESETN || software_rst_sync_axi) begin

			data_send_count <= 0;
			axis_tlast <= LOW;
			
		end else begin

			case (mst_exec_state)

				EXEC_STATE__SEND_STREAM: begin

					if (`ONE_VALID_DATA_SEND_AT_THAT_TIME && !continuous_sampling) begin  // one valid data has been sent at that time

						data_send_count <= data_send_count + 1;

						/*
							current_sampling_data_points - 1 number of data have been send, (current data is the last one)
							T_LAST should be HIGH to indicate the last data.
						*/

						if (data_send_count == current_sampling_data_points - 2) begin  

							if (last_frame_sync) axis_tlast <= HIGH;

						/* 
						   the last data was successfully sent, 
						   T_LAST should be LOW at that time in order to comply with the AXI-Stream protocol.
						*/

						end else if (data_send_count == current_sampling_data_points - 1) begin  // all data have been sent at that time

							if (last_frame_sync) axis_tlast <= LOW;

						end else begin
							
							axis_tlast <= LOW;

						end
					end

				end

				default: begin
					data_send_count <= 0;
					axis_tlast <= LOW;
				end

			endcase

		end

	end

	/* --------------------------------------------------------------------------------------------------------- */
	/* -------------------------------------- AXI-Stream CLOCK DOMAIN END -------------------------------------- */
	/* --------------------------------------------------------------------------------------------------------- */

	/* --------------------------------------------------------------------------------------------------------- */
	/* -------------------------------------------- ADC CLOCK DOMAIN ------------------------------------------- */
	/* --------------------------------------------------------------------------------------------------------- */

	reg [BIT_NUM - 1: 0] sampling_clk_counter;
	reg sampling_clk = LOW;

	reg [CONTROL_REGISTER_WIDTH - 1: 0] sampling_clk_increment_sync_00;
	reg [CONTROL_REGISTER_WIDTH - 1: 0] sampling_clk_increment_sync_01;
	reg [CONTROL_REGISTER_WIDTH - 1: 0] sampling_clk_increment_sync;

	/* FIFO write logic registers  */
	
	reg [2: 0] fifo_write_state = FIFO_WRITE_STATE__IDLE;
	
	reg [7: 0] fifo_pushed_number = 8'd0;
	
	reg [C_M_AXIS_TDATA_WIDTH - 1: 0] current_fifo_write_data = INVALID_DATA;
	
	reg fifo_write_en = 1'b0;
	
	reg adc_data_have_pushed = 1'b0;
	
	/* DEBUG */

	assign DEBUG_fifo_pushed_number = fifo_pushed_number;
	assign DEBUG_mst_exec_state = mst_exec_state;
	assign DEBUG_fifo_write_state = fifo_write_state;

	assign DEBUG_fifo_full = fifo_full;
	assign DEBUG_fifo_almost_full = fifo_almost_full;
	assign DEBUG_fifo_reset = fifo_reset;

	/* --------------------------------------------------------------------------------------------------------- */
	/* ----------------------------------------------- SYNC ---------------------------------------------------- */
	/* --------------------------------------------------------------------------------------------------------- */

	/* ----------------------- sync 0: software rst (AXI-Stream Domain --> ADC Domain) ------------------------- */

	always @(posedge adc_clk) begin
		if (!adc_rst_n) begin
			software_rst_sync_adc_00 <= FALSE;
			software_rst_sync_adc_01 <= FALSE;
			software_rst_sync_adc <= FALSE;
		end else begin
			software_rst_sync_adc_00 <= software_rst;
			software_rst_sync_adc_01 <= software_rst_sync_adc_00;
			software_rst_sync_adc <= software_rst_sync_adc_01;
		end
	end

	/* ----------------------- sync 1: sampling_clk_increment -------------------------------------------------- */

	always @(posedge adc_clk) begin
		if (!adc_rst_n || software_rst_sync_adc) begin
			
			sampling_clk_increment_sync_00 <= ADC_DEFAULT_CLOCK_INCREMENT;
			sampling_clk_increment_sync_01 <= ADC_DEFAULT_CLOCK_INCREMENT;
			sampling_clk_increment_sync <= ADC_DEFAULT_CLOCK_INCREMENT;

		end else if (mst_exec_state_sync == EXEC_STATE__IDLE) begin

			if (sampling_clk_increment >= MINIUM_SAMPLING_CLK_INCREMENT) sampling_clk_increment_sync_00 <= sampling_clk_increment;
			else sampling_clk_increment_sync_00 <= sampling_clk_increment_sync_00;

			sampling_clk_increment_sync_01 <= sampling_clk_increment_sync_00;
			sampling_clk_increment_sync <= sampling_clk_increment_sync_01;
		end
	end

	/* ---------------------------------------- AD sampling clock ---------------------------------------------- */

	always @(posedge adc_clk) begin
		if (!adc_rst_n || software_rst_sync_adc) begin

			sampling_clk_counter <= 0;
			sampling_clk <= LOW;

			adc_have_sampled <= FALSE;
			
		end else begin

			/* Generate sample clock at SEND STREAM state */

			if (mst_exec_state_sync != EXEC_STATE__IDLE) begin  /* Start generate clock in advance */

				if (sampling_clk_counter >= sampling_clk_increment_sync - 1) begin

					sampling_clk_counter <= 0;
					sampling_clk <= ~sampling_clk;

				end else begin

					sampling_clk_counter <= sampling_clk_counter + 1;

				end

				if (!`ADC_SAMPLING_COMPLETE) begin
					adc_have_sampled <= TRUE;  /* lock to TRUE, to ensure the output data of ADC modules is valid */
				end

			end else begin

				/* reset */

				sampling_clk_counter <= 0;
				sampling_clk <= LOW;
				adc_have_sampled <= FALSE;

			end
		end
	end

	/* -------------------------------------------------------------------------------------------------------------------- */
	/* ---------------------------------------- ADC sampling (FIFO write logic) ------------------------------------------- */
	/* -------------------------------------------------------------------------------------------------------------------- */

	/* --------------------------------------------------- FLAGS ---------------------------------------------------------- */

	always @(posedge adc_clk) begin

	   	if (!adc_rst_n || software_rst_sync_adc) begin

	        fifo_write_state <= FIFO_WRITE_STATE__IDLE;
			adc_data_have_pushed <= FALSE;
			
	    end else begin

			if (mst_exec_state_sync == EXEC_STATE__SEND_STREAM) begin

				case (fifo_write_state)

				FIFO_WRITE_STATE__IDLE: begin

					/* sampling complete at that time */

					if (`ADC_SAMPLING_COMPLETE && adc_have_sampled) begin

						if (!adc_data_have_pushed) fifo_write_state <= FIFO_WRITE_STATE__WRITE_FIFO;  /* no data pushed */
						else fifo_write_state <= FIFO_WRITE_STATE__IDLE;

					/* sampling not complete, reset related flag */

					end else begin

						fifo_write_state <= FIFO_WRITE_STATE__IDLE;
						adc_data_have_pushed <= FALSE;
						
					end

				end

				FIFO_WRITE_STATE__WRITE_FIFO: begin

					/* ----------------------------------------------------------------------------------- */
					/* ----------------------- FIFO control (currently pushed) --------------------------- */
					/* ---------- NOTE: current pushed data count == (fifo_pushed_number + 1) ------------ */
					/* ----------------------------------------------------------------------------------- */

					if (`ONE_VALID_DATA_PUSHED_IN_FIFO) begin
					
						if (fifo_pushed_number >= (FRAME_WORD_NUMBER - 1)) begin
						
							fifo_write_state <= FIFO_WRITE_STATE__IDLE;
							adc_data_have_pushed <= TRUE;

						end else begin
						
							fifo_write_state <= FIFO_WRITE_STATE__WRITE_FIFO;
							adc_data_have_pushed <= FALSE;

						end

					/* ----------------------------------------------------------------------------------- */
					/* ----------------------- FIFO control (NOT currently pushed) ----------------------- */
					/* -------------- NOTE: current pushed data count == fifo_pushed_number -------------- */
					/* ----------------------------------------------------------------------------------- */

					end else begin
					
						if (fifo_pushed_number >= FRAME_WORD_NUMBER) begin

							fifo_write_state <= FIFO_WRITE_STATE__IDLE;
							adc_data_have_pushed <= TRUE;

						end else begin
						  
							fifo_write_state <= FIFO_WRITE_STATE__WRITE_FIFO;
							adc_data_have_pushed <= FALSE;

						end

					end
			
				end
			
				default: fifo_write_state <= FIFO_WRITE_STATE__IDLE;

				endcase

			end
		end
	end

	/* -------------------------------------------------- REGISTERS ------------------------------------------------------- */

	always @(posedge adc_clk) begin
	   	if (!adc_rst_n || software_rst_sync_adc) begin

	        fifo_write_en <= FALSE;
			current_fifo_write_data <= {(C_M_AXIS_TDATA_WIDTH){1'b1}};

			fifo_pushed_number <= 0;
			
	    end else begin

			if (mst_exec_state_sync == EXEC_STATE__SEND_STREAM) begin

	       		case(fifo_write_state)

	        	   	FIFO_WRITE_STATE__IDLE: begin

						if (`ADC_SAMPLING_COMPLETE && !adc_data_have_pushed) begin  // state jump situation

							fifo_pushed_number <= 0;  /* set to 0, no data have been pushed into FIFO */

							/* ---------------------------------- DATA Control ---------------------------------- */

							current_fifo_write_data <= FRAME_HEADER;

							/* ---------------------------------- FIFO Control ---------------------------------- */

							if (fifo_almost_full) fifo_write_en <= FALSE;
							else fifo_write_en <= TRUE;

						end else begin

							fifo_pushed_number <= 0;
							current_fifo_write_data <= {(C_M_AXIS_TDATA_WIDTH){1'b1}};
							fifo_write_en <= FALSE;
						  
						end

	        	    end

	        	   	FIFO_WRITE_STATE__WRITE_FIFO: begin

						if (`ONE_VALID_DATA_PUSHED_IN_FIFO) begin

							fifo_pushed_number <= fifo_pushed_number + 1;  // push one data at that time

							/* ---------------------------------- DATA Control ---------------------------------- */

							case (fifo_pushed_number)
								8'd0: current_fifo_write_data <= {adc_a_ch2, adc_a_ch1};          /* pushed 1, continue */
								8'd1: current_fifo_write_data <= {adc_a_ch4, adc_a_ch3};          /* pushed 2, continue */
								8'd2: current_fifo_write_data <= {adc_a_ch6, adc_a_ch5};          /* pushed 3, continue */
								8'd3: current_fifo_write_data <= {adc_a_ch8, adc_a_ch7};          /* pushed 4, continue */
        
								8'd4: current_fifo_write_data <= {adc_b_ch2, adc_b_ch1};          /* pushed 5, continue */
								8'd5: current_fifo_write_data <= {adc_b_ch4, adc_b_ch3};          /* pushed 6, continue */
								8'd6: current_fifo_write_data <= {adc_b_ch6, adc_b_ch5};          /* pushed 7, continue */
								8'd7: current_fifo_write_data <= {adc_b_ch8, adc_b_ch7};          /* pushed 8, continue */
        
								8'd8: current_fifo_write_data <= FRAME_TAILER;                    /* pushed 9, continue */

								8'd9: current_fifo_write_data <= {(C_M_AXIS_TDATA_WIDTH){1'b1}};  /* pushed 10, jump */

								default: current_fifo_write_data <= {(C_M_AXIS_TDATA_WIDTH){1'b1}};  /* invalid */
							endcase

							/* ----------------------------------------------------------------------------------- */
							/* ----------------------- FIFO control (currently pushed) --------------------------- */
							/* ---------- NOTE: current pushed data count == (fifo_pushed_number + 1) ------------ */
							/* ----------------------------------------------------------------------------------- */

							/* pushed number <= FRAME_WORD_NUMBER - 1, contiune */

							if (fifo_pushed_number <= (FRAME_WORD_NUMBER - 2)) begin

								if (fifo_almost_full) fifo_write_en <= FALSE;
								else fifo_write_en <= TRUE;

							/* pushed number <= FRAME_WORD_NUMBER, jump */

							end else begin
								
								fifo_write_en <= FALSE;

							end

						end else begin

							/* ----------------------------------------------------------------------------------- */
							/* ----------------------- FIFO control (NOT currently pushed) ----------------------- */
							/* ---------- NOTE: current pushed data count == fifo_pushed_number ------------------ */
							/* ----------------------------------------------------------------------------------- */
							
							/* pushed number <= FRAME_WORD_NUMBER - 1, contiune */

							if (fifo_pushed_number <= (FRAME_WORD_NUMBER - 1)) begin

								if (fifo_almost_full) fifo_write_en <= FALSE;
								else fifo_write_en <= TRUE;

							end else begin
								
								fifo_write_en <= FALSE;

							end

						end

	        	    end

	       		endcase

			end else begin

				/* mst_exec_state_sync != EXEC_STATE__SEND_STREAM, Reset */
				
				fifo_write_en <= FALSE;
				fifo_pushed_number <= 0;
				current_fifo_write_data <= {(C_M_AXIS_TDATA_WIDTH){1'b1}};
				
			end
	    end
	end

	/* --------------------------------------------------------------------------------------------------------- */
	/* ------------------------------------------------ MODULES ------------------------------------------------ */
	/* --------------------------------------------------------------------------------------------------------- */

	adc_fifo vuprs_adc_fifo (
  		.rst(fifo_reset),                  // input wire rst
  		.wr_clk(adc_clk),                  // input wire wr_clk
  		.rd_clk(M_AXIS_ACLK),              // input wire rd_clk
  		.din(current_fifo_write_data),     // input wire [31 : 0] din
  		.wr_en(fifo_write_en),             // input wire wr_en
  		.rd_en(fifo_rd_en),                // input wire rd_en
  		.dout(current_fifo_read_data),     // output wire [31 : 0] dout
  		.full(fifo_full),                  // output wire full
  		.almost_full(fifo_almost_full),    // output wire almost_full
  		.empty(fifo_empty),                // output wire empty
  		.almost_empty(fifo_almost_empty),  // output wire almost_empty
  		.wr_rst_busy(fifo_wr_rst_busy),    // output wire wr_rst_busy
  		.rd_rst_busy(fifo_rd_rst_busy)     // output wire rd_rst_busy
	);
    
    ad7606 #(

        .USR_CLK_CYCLE_NS(USR_CLK_CYCLE_NS),                      /* unit: ns, clock cycle of [usr_clk] (e.g. 20 ns for 50 MHz) */
        .T_CYCLE_NS(T_CYCLE_NS),                    /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
        .T_RESET_NS(T_RESET_NS),                      /* unit: ns, t_reset of AD7606 (refer to data sheet) */
        .T_CONV_MIN_NS(T_CONV_MIN_NS),                    /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
        .T_CONV_MAX_NS(T_CONV_MAX_NS),                    /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
        .T1_NS(T1_NS),                      /* unit: ns, t1 of AD7606 (refer to data sheet) */
        .T2_NS(T2_NS),                      /* unit: ns, t2 of AD7606 (refer to data sheet) */
        .T10_NS(T10_NS),                      /* unit: ns, t10 of AD7606 (refer to data sheet) */
        .T11_NS(T11_NS),                      /* unit: ns, t11 of AD7606 (refer to data sheet) */
        .T14_NS(T14_NS),                      /* unit: ns, t14 of AD7606 (refer to data sheet) */
        .T15_NS(T15_NS),                       /* unit: ns, t15 of AD7606 (refer to data sheet) */
        .T26_NS(T26_NS)                       /* unit: ns, t15 of AD7606 (refer to data sheet) */

    )
    vuprs_adc_a(

        /* -------------------------------------------- User interface ------------------------------------------ */

        .usr_trigger(sampling_clk),                   /* Sample Enable, rising edge trigger, must be smaller than 100 kHz */
        .usr_clk(adc_clk),                       /* System Clock, corresponding to USR_CLK_CYCLE_NS  */
        .usr_rst(adc_rst_n),                       /* Reset this module, falling edge trigger */

        .usr_channel1(adc_a_ch1),                  /* Data of channel-V1, 16 bit */
        .usr_channel2(adc_a_ch2),                  /* Data of channel-V2, 16 bit */
        .usr_channel3(adc_a_ch3),                  /* Data of channel-V3, 16 bit */
        .usr_channel4(adc_a_ch4),                  /* Data of channel-V4, 16 bit */
        .usr_channel5(adc_a_ch5),                  /* Data of channel-V5, 16 bit */
        .usr_channel6(adc_a_ch6),                  /* Data of channel-V6, 16 bit */
        .usr_channel7(adc_a_ch7),                  /* Data of channel-V7, 16 bit */
        .usr_channel8(adc_a_ch8),                  /* Data of channel-V8, 16 bit */

        .usr_error(adc_a_err),                     /* Error flags */

        .usr_sampling(adc_a_sampling),                  /* sampling,      1 = in sampling (do not trigger); 0 = is idle */
        .usr_ready(adc_a_ready),                     /* Reset Down,    1 = complete to create a HIGH pulse for hardware RESET pin */

        /* ------------------------------------------ Hardware interface ---------------------------------------- */

        .hw_busy(adc_a_hw_busy),                       /* BUSY pin of the AD7606 chip */
        .hw_first_data(adc_a_hw_first_data),                 /* FIRSTDATA pin of the AD7606 chip  */
        .hw_data(adc_a_hw_data),                       /* D0 - D15 Pins of the AD7606 chip */

        .hw_convst(adc_a_hw_convst),                     /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
        .hw_rd(adc_a_hw_rd),                         /* RD# pin of the AD7606 chip */
        .hw_cs(adc_a_hw_cs),                         /* CS# pin of the AD7606 chip */
        .hw_range(adc_a_hw_range),                      /* RANGE pin of the AD7606 chip */
        .hw_os(adc_a_hw_os),                         /* OS0 - OS2 pins of the AD7606 chip (Not used) */
        .hw_mode_select(adc_a_hw_mode_select),                /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
        .hw_reset(adc_a_hw_reset),                      /* RESET pin of the AD7606 chip */
        .hw_stby_n(adc_a_hw_stby_n)                      /* STBY# pin of the AD7606 */

     );

	 ad7606 #(

        .USR_CLK_CYCLE_NS(USR_CLK_CYCLE_NS),                      /* unit: ns, clock cycle of [usr_clk] (e.g. 20 ns for 50 MHz) */
        .T_CYCLE_NS(T_CYCLE_NS),                    /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
        .T_RESET_NS(T_RESET_NS),                      /* unit: ns, t_reset of AD7606 (refer to data sheet) */
        .T_CONV_MIN_NS(T_CONV_MIN_NS),                    /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
        .T_CONV_MAX_NS(T_CONV_MAX_NS),                    /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
        .T1_NS(T1_NS),                      /* unit: ns, t1 of AD7606 (refer to data sheet) */
        .T2_NS(T2_NS),                      /* unit: ns, t2 of AD7606 (refer to data sheet) */
        .T10_NS(T10_NS),                      /* unit: ns, t10 of AD7606 (refer to data sheet) */
        .T11_NS(T11_NS),                      /* unit: ns, t11 of AD7606 (refer to data sheet) */
        .T14_NS(T14_NS),                      /* unit: ns, t14 of AD7606 (refer to data sheet) */
        .T15_NS(T15_NS),                       /* unit: ns, t15 of AD7606 (refer to data sheet) */
        .T26_NS(T26_NS)                       /* unit: ns, t15 of AD7606 (refer to data sheet) */

    )
    vuprs_adc_b(

        /* -------------------------------------------- User interface ------------------------------------------ */

        .usr_trigger(sampling_clk),                   /* Sample Enable, rising edge trigger, must be smaller than 100 kHz */
        .usr_clk(adc_clk),                       /* System Clock, corresponding to USR_CLK_CYCLE_NS  */
        .usr_rst(adc_rst_n),                       /* Reset this module, falling edge trigger */

        .usr_channel1(adc_b_ch1),                  /* Data of channel-V1, 16 bit */
        .usr_channel2(adc_b_ch2),                  /* Data of channel-V2, 16 bit */
        .usr_channel3(adc_b_ch3),                  /* Data of channel-V3, 16 bit */
        .usr_channel4(adc_b_ch4),                  /* Data of channel-V4, 16 bit */
        .usr_channel5(adc_b_ch5),                  /* Data of channel-V5, 16 bit */
        .usr_channel6(adc_b_ch6),                  /* Data of channel-V6, 16 bit */
        .usr_channel7(adc_b_ch7),                  /* Data of channel-V7, 16 bit */
        .usr_channel8(adc_b_ch8),                  /* Data of channel-V8, 16 bit */

        .usr_error(adc_b_err),                     /* Error flags */

        .usr_sampling(adc_b_sampling),                  /* sampling,      1 = in sampling (do not trigger); 0 = is idle */
        .usr_ready(adc_b_ready),                     /* Reset Down,    1 = complete to create a HIGH pulse for hardware RESET pin */

        /* ------------------------------------------ Hardware interface ---------------------------------------- */

        .hw_busy(adc_b_hw_busy),                       /* BUSY pin of the AD7606 chip */
        .hw_first_data(adc_b_hw_first_data),                 /* FIRSTDATA pin of the AD7606 chip  */
        .hw_data(adc_b_hw_data),                       /* D0 - D15 Pins of the AD7606 chip */

        .hw_convst(adc_b_hw_convst),                     /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
        .hw_rd(adc_b_hw_rd),                         /* RD# pin of the AD7606 chip */
        .hw_cs(adc_b_hw_cs),                         /* CS# pin of the AD7606 chip */
        .hw_range(adc_b_hw_range),                      /* RANGE pin of the AD7606 chip */
        .hw_os(adc_b_hw_os),                         /* OS0 - OS2 pins of the AD7606 chip (Not used) */
        .hw_mode_select(adc_b_hw_mode_select),                /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
        .hw_reset(adc_b_hw_reset),                      /* RESET pin of the AD7606 chip */
        .hw_stby_n(adc_b_hw_stby_n)                      /* STBY# pin of the AD7606 */

     );

	// User logic ends

	endmodule
