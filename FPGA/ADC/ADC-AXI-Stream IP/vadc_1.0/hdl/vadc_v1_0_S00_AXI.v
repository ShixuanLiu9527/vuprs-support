
`timescale 1 ns / 1 ps

	module vadc_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 5,

		parameter integer USR_CLK_CYCLE_NS      = 20
	)
	(
		// Users to add ports here

		input wire adc_module_ready,              /* sampling ready */
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] adc_module_error_flag,  /* error flag */
		input wire adc_card_present_detect,
		
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] sampling_clk_increment,  /* sampling clock increment */
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] sampling_points,  /* sampling points */

		output wire one_frame_sampling_trigger,                 /* sampling trigger */
		output wire last_frame,                                 /* indicate this is the last frame */
		output wire software_rst,
		output wire continuous_sampling,                        /* indicate this is the interminable sampling */

		output wire fpga_sampling_led,
		output wire fpga_adc_card_present_led,
		
		/* DEBUG */

		output wire [2:0] DEBUG_frame_state,

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	localparam TRUE                               = 1'b1,
			   FALSE                              = 1'b0;

	localparam HIGH                               = 1'b1,
			   LOW                                = 1'b0;

	localparam FRAME_STATE__IDLE                  = 3'd0,
			   FRAME_STATE__MAKE_TRIGGER          = 3'd1,
			   FRAME_STATE__WAIT_FRAME_START      = 3'd2,
			   FRAME_STATE__WAIT_FRAME_END        = 3'd3;

	localparam MINIUM_SAMPLING_CLK_INCREMENT      = (1000_000_000 / 150_000) / USR_CLK_CYCLE_NS + 1;  // 150 kHz max

	localparam DEFAULT_SAMPLING_FRAMES            = 32'd2048,
			   DEFAULT_SAMPLING_POINTS            = 32'd2048,
			   DEFAULT_SAMPLING_CLK_INCREMENT     = MINIUM_SAMPLING_CLK_INCREMENT + 10000;

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 2;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 8
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;   // Sampling Clock Increment   (W/R)
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;   // Sampling Points            (W/R)
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;   // Sampling Frames            (W/R)
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;   // Ready & sampling trigger   (R)
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;   // Number of Generated Frames (R)
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;   // ADC Error Flag             (R)
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;   // Software reset             (R/W)
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;   // Continuous Sampling        (R/W)
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	/* ------------------------------------------------------------------ */

	reg [C_S_AXI_DATA_WIDTH-1 : 0] sampling_clk_increment_reg = DEFAULT_SAMPLING_CLK_INCREMENT;  /* sampling clock increment */
    reg [C_S_AXI_DATA_WIDTH-1 : 0] sampling_points_reg = DEFAULT_SAMPLING_POINTS;         /* sampling points */
	reg [C_S_AXI_DATA_WIDTH-1 : 0] sampling_frames_reg = DEFAULT_SAMPLING_FRAMES;  /* sampling frames */

	reg continuous_sampling_reg = FALSE;

	reg start_generate_frames = FALSE;
	reg start_generate_frames_sync = FALSE;

	reg software_rst_reg = FALSE;
	reg software_rst_reg_sync = FALSE;

	reg sampling_trigger_control = LOW;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] generated_frames_count = 0;

	reg [2: 0] frame_state = FRAME_STATE__IDLE;

	reg last_frame_reg = FALSE;
	
	/* output signal */

	assign one_frame_sampling_trigger = sampling_trigger_control;
	assign sampling_clk_increment = sampling_clk_increment_reg;
	assign sampling_points = sampling_points_reg;
	assign last_frame = last_frame_reg;
	assign continuous_sampling = continuous_sampling_reg;

	assign software_rst = software_rst_reg;
	
	assign DEBUG_frame_state = frame_state;

	/* led */

	assign fpga_adc_card_present_led = ~adc_card_present_detect;
	assign fpga_sampling_led = (frame_state != FRAME_STATE__IDLE);
	
	/* ------------------------------------------------------------------ */

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= DEFAULT_SAMPLING_CLK_INCREMENT;
	      slv_reg1 <= DEFAULT_SAMPLING_POINTS;
	      slv_reg2 <= DEFAULT_SAMPLING_FRAMES;
	    //   slv_reg3 <= 0;
	    //   slv_reg4 <= 0;
	    //   slv_reg5 <= 0;
	    //   slv_reg6 <= 0;
	      slv_reg7 <= FALSE;
		  start_generate_frames <= FALSE;
		  software_rst_reg <= FALSE;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          3'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h3: begin

				start_generate_frames <= TRUE;  // write slv_reg3 will start sampling
				
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 3
	            //     slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
			  end
	          3'h4:;
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 4
	            //     slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
	          3'h5:;
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 5
	            //     slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
	          3'h6:

			  	software_rst_reg <= TRUE;  // software reset
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 6
	            //     slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
	          3'h7:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 7
	                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                    //   slv_reg3 <= slv_reg3;
	                    //   slv_reg4 <= slv_reg4;
	                    //   slv_reg5 <= slv_reg5;
	                    //   slv_reg6 <= slv_reg6;
	                      slv_reg7 <= slv_reg7;
	                    end
	        endcase
		end else begin
			if (software_rst_reg_sync) software_rst_reg <= FALSE;  /* latency = 1 */
			if (start_generate_frames_sync) start_generate_frames <= FALSE;
		end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        3'h0   : reg_data_out <= slv_reg0;
	        3'h1   : reg_data_out <= slv_reg1;
	        3'h2   : reg_data_out <= slv_reg2;
	        3'h3   : reg_data_out <= slv_reg3;
	        3'h4   : reg_data_out <= slv_reg4;
	        3'h5   : reg_data_out <= slv_reg5;
	        3'h6   : reg_data_out <= slv_reg6;
	        3'h7   : reg_data_out <= slv_reg7;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			software_rst_reg_sync <= FALSE;
			start_generate_frames_sync <= FALSE;
		end else begin
			software_rst_reg_sync <= software_rst_reg;
			start_generate_frames_sync <= start_generate_frames;
		end
	end

	/* Sampling parameters sync */

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN || software_rst_reg) begin
			sampling_clk_increment_reg <= DEFAULT_SAMPLING_CLK_INCREMENT;
	      	sampling_points_reg <= DEFAULT_SAMPLING_POINTS;
	      	sampling_frames_reg <= DEFAULT_SAMPLING_FRAMES;
			continuous_sampling_reg <= FALSE;
			slv_reg4 <= 0;
			slv_reg5 <= 0;
		end else begin
			if (frame_state == FRAME_STATE__IDLE) begin
				if (slv_reg0 >= MINIUM_SAMPLING_CLK_INCREMENT) sampling_clk_increment_reg <= slv_reg0;
				if (slv_reg1 > 0) sampling_points_reg <= slv_reg1;
				if (slv_reg2 > 0) sampling_frames_reg <= slv_reg2;

				if (slv_reg7 > 0) continuous_sampling_reg <= TRUE;
				else continuous_sampling_reg <= FALSE;
			end
			slv_reg4 <= generated_frames_count;
			slv_reg5 <= adc_module_error_flag;
		end
	end

	/* Flags */

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN || software_rst_reg) begin
			frame_state <= FRAME_STATE__IDLE;
		end else begin
			case (frame_state)

				FRAME_STATE__IDLE: begin
					if (((sampling_frames_reg > 0 && sampling_points_reg > 0) || continuous_sampling_reg) && 
						sampling_clk_increment_reg >= MINIUM_SAMPLING_CLK_INCREMENT && 
						adc_module_ready) begin

						if (start_generate_frames) begin
							frame_state <= FRAME_STATE__MAKE_TRIGGER;
						end else begin
							frame_state <= FRAME_STATE__IDLE;
						end

					end else begin
						frame_state <= FRAME_STATE__IDLE;
					end
				end

				FRAME_STATE__MAKE_TRIGGER: begin
					if (sampling_trigger_control == LOW && adc_module_ready) frame_state <= FRAME_STATE__WAIT_FRAME_START;
					else frame_state <= FRAME_STATE__MAKE_TRIGGER;
				end

				FRAME_STATE__WAIT_FRAME_START: begin
					if (!adc_module_ready) frame_state <= FRAME_STATE__WAIT_FRAME_END;
					else frame_state <= FRAME_STATE__WAIT_FRAME_START;
				end

				FRAME_STATE__WAIT_FRAME_END: begin
					if (adc_module_ready) begin
						if (generated_frames_count >= sampling_frames_reg - 1) begin
							frame_state <= FRAME_STATE__IDLE;
						end else begin
							frame_state <= FRAME_STATE__MAKE_TRIGGER;
						end
					end else begin
						frame_state <= FRAME_STATE__WAIT_FRAME_END;
					end
				end

				default: frame_state <= FRAME_STATE__IDLE;

			endcase
		end
	end

	/* Registers */

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN || software_rst_reg) begin

			generated_frames_count <= 0;
			sampling_trigger_control <= LOW;
			slv_reg3 <= 0;
			last_frame_reg <= FALSE;

		end else begin

			case (frame_state)

				FRAME_STATE__IDLE: begin
					generated_frames_count <= 0;
					sampling_trigger_control <= LOW;
					last_frame_reg <= FALSE;

					if (((sampling_frames_reg > 0 && sampling_points_reg > 0) || continuous_sampling_reg) && 
						sampling_clk_increment_reg >= MINIUM_SAMPLING_CLK_INCREMENT && 
						adc_module_ready)

						if (start_generate_frames) begin  /* trigger condition */
						  	slv_reg3[0] <= FALSE;
						end else begin
							slv_reg3[0] <= TRUE;
						end

					else slv_reg3[0] <= FALSE;

				end

				FRAME_STATE__MAKE_TRIGGER: begin
					slv_reg3[0] <= FALSE;
					if (adc_module_ready) begin

						if (sampling_trigger_control == LOW) begin  /* LOW */

							sampling_trigger_control <= HIGH;  /* rising edge */
							
							if (continuous_sampling_reg) begin
								last_frame_reg <= FALSE;
							end else begin
								if (generated_frames_count >= sampling_frames_reg - 1) begin
									last_frame_reg <= TRUE;
								end else begin
									last_frame_reg <= FALSE;
								end
							end
							
						end else begin
							sampling_trigger_control <= LOW;
						end
							
					end
				end

				FRAME_STATE__WAIT_FRAME_START: begin
					slv_reg3[0] <= FALSE;
					sampling_trigger_control <= HIGH;
				end

				FRAME_STATE__WAIT_FRAME_END: begin
					sampling_trigger_control <= LOW;  // change to low
					if (adc_module_ready) begin
						generated_frames_count <= generated_frames_count + 1;
						if (generated_frames_count >= sampling_frames_reg - 1) begin
							slv_reg3[0] <= TRUE;
						end else begin
							slv_reg3[0] <= FALSE;
						end
					end else begin
						slv_reg3[0] <= FALSE;
					end
				end

				default: begin
					generated_frames_count <= 0;
					sampling_trigger_control <= LOW;
					slv_reg3[0] <= FALSE;
					last_frame_reg <= FALSE;
				end

			endcase

		end
	end

	// User logic ends

	endmodule
