/**
 *
 * Author:            Shixuan Liu, Tongji University
 * Brief:             Controller for VUPRS-AD7606 Chip
 * Date:              2025-8
 *
 * Note of Usage:     1. Before performing any operation, it must be reset (apply a falling edge 
 *                       pulse to [usr_rst] and maintain a LOW level for 2 clock cycles);
 *                    2. If [usr_ready] is HIGH, it means this module is ready to sampling.
 *                       Therefore, apply a falling edge pulse to [usr_rst] and maintain a LOW 
 *                       level for 2 clock cycle of [usr_clk] to reset this module again;
 *                    3. After resetting, apply a rising edge to [usr_trigger] and maintain a 
 *                       HIGH level for 2 clock cycles of [usr_clk] to start sampling.
 *                       You should wait until [usr_sampling] goes to LOW before the 
 *                       next trigger;
 *                    4. If [usr_error] becomes high, it means some error occurred in 
 *                       sampling process;
 *                    5. Sampling frequency must smaller than 150 kHz (with an approximately 
 *                       540 ns cycle of sampling).
 *                    6. Error flags, [usr_error] = 4'd0: No error;
 *                                                  4'd1: Error - Conversion timeout;
 *                                                  4'd2: Error - FIRST_DATA level error;
 *                                                  4'd3: Error - Internal registers in wrong status;
 *                                                  4'd4: Error - Sampling timeout;
 *                                                  4'd5: Error - Unable to start sampling;
 *                                                  4'd6: Error - Sampling too fast;
 *
 * Conditions of Use: 1. V_DRIVE of AD7606 is 3.3 V;
 *                    2. Pins CONVST_A and CONVST_B of AD7606 are connected together;
 *                    3. Oversampling is not supported (OS[2: 0] is 3'b000);
 *                    4. Maximum sampling frequency: 150 kHz;
 *
 */

module ad7606 
#(

/* --------------------------------------------- Parameters ---------------------------------------------- */

    parameter USR_CLK_CYCLE_NS = 20,                      /* unit: ns, clock cycle of [usr_clk] (e.g. 20 ns for 50 MHz) */
              T_CYCLE_NS       = 5000,                    /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
              T_RESET_NS       = 50,                      /* unit: ns, t_reset of AD7606 (refer to data sheet) */
              T_CONV_MIN_NS    = 3450,                    /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
              T_CONV_MAX_NS    = 4150,                    /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
              T1_NS            = 40,                      /* unit: ns, t1 of AD7606 (refer to data sheet) */
              T2_NS            = 25,                      /* unit: ns, t2 of AD7606 (refer to data sheet) */
              T10_NS           = 25,                      /* unit: ns, t10 of AD7606 (refer to data sheet) */
              T11_NS           = 15,                      /* unit: ns, t11 of AD7606 (refer to data sheet) */
              T14_NS           = 25,                      /* unit: ns, t14 of AD7606 (refer to data sheet) */
              T15_NS           = 6,                       /* unit: ns, t15 of AD7606 (refer to data sheet) */
              T26_NS           = 25                       /* unit: ns, t15 of AD7606 (refer to data sheet) */

)
(

/* -------------------------------------------- User interface ------------------------------------------ */

    input wire         usr_trigger,                   /* Sample Enable, rising edge trigger, must be smaller than 100 kHz */
    input wire         usr_clk,                       /* System Clock, corresponding to USR_CLK_CYCLE_NS  */
    input wire         usr_rst,                       /* Reset this module, falling edge trigger */

    output reg [15: 0] usr_channel1,                  /* Data of channel-V1, 16 bit */
    output reg [15: 0] usr_channel2,                  /* Data of channel-V2, 16 bit */
    output reg [15: 0] usr_channel3,                  /* Data of channel-V3, 16 bit */
    output reg [15: 0] usr_channel4,                  /* Data of channel-V4, 16 bit */
    output reg [15: 0] usr_channel5,                  /* Data of channel-V5, 16 bit */
    output reg [15: 0] usr_channel6,                  /* Data of channel-V6, 16 bit */
    output reg [15: 0] usr_channel7,                  /* Data of channel-V7, 16 bit */
    output reg [15: 0] usr_channel8,                  /* Data of channel-V8, 16 bit */

    output reg [3: 0]  usr_error,                     /* Error flags */

    output reg         usr_sampling,                  /* sampling,      1 = in sampling (do not trigger); 0 = is idle */
    output reg         usr_ready,                     /* Reset Down,    1 = complete to create a HIGH pulse for hardware RESET pin */

/* ------------------------------------------ Hardware interface ---------------------------------------- */

    input wire         hw_busy,                       /* BUSY pin of the AD7606 chip */
    input wire         hw_first_data,                 /* FIRSTDATA pin of the AD7606 chip  */
    input wire [15: 0] hw_data,                       /* D0 - D15 Pins of the AD7606 chip */

    output reg         hw_convst,                     /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    output reg         hw_rd,                         /* RD# pin of the AD7606 chip */
    output reg         hw_cs,                         /* CS# pin of the AD7606 chip */
    output reg         hw_range,                      /* RANGE pin of the AD7606 chip */
    output reg [2: 0]  hw_os,                         /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    output reg         hw_mode_select,                /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    output reg         hw_reset,                      /* RESET pin of the AD7606 chip */
    output reg         hw_stby_n                      /* STBY# pin of the AD7606 */

);

/* --------------------------------------------- Local Parameters ----------------------------------------- */

localparam CONVERT_COMPLETE_MAX_CYCLE                = T_CONV_MAX_NS + 500,
           WAIT_BUSY_TO_HIGH_MAX_CYCLE               = ((T1_NS + 100) > T_CONV_MIN_NS)? (T_CONV_MIN_NS / 2): (T1_NS + 100),
           FIRST_DATA_MAX_CYCLE                      = T26_NS + 100,
           TIMEOUT_CYCLE                             = T_CYCLE_NS + 20000;

localparam PULSE_MIN_REQUIRED                        = (40  + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS;

/* ORIGIN parameters */

/* ORIGIN chip parameters, all refer to data-sheet */

localparam TIMEOUT_CLOCKS_ORIGIN                     = (TIMEOUT_CYCLE  + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS,
           T_RESET_CLOCKS_ORIGIN                     = (T_RESET_NS + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS,
           T1_CLOCKS_ORIGIN                          = (T1_NS  + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS,
           T2_CLOCKS_ORIGIN                          = (T2_NS  + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS,
           T10_CLOCKS_ORIGIN                         = (T10_NS  + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS,
           T11_CLOCKS_ORIGIN                         = (T11_NS + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS,
           T14_CLOCKS_ORIGIN                         = (T14_NS + T15_NS  + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS + 1;  // +1: wait sync

/* ORIGIN timeout parameters */

localparam FIRST_DATA_WAIT_CLOCKS_ORIGIN             = (FIRST_DATA_MAX_CYCLE + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS,
           WAIT_BUSY_TO_HIGH_MAX_CLOCKS_ORIGIN       = (WAIT_BUSY_TO_HIGH_MAX_CYCLE + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS,
           CONVERT_COMPLETE_WAIT_CLOCKS_ORIGIN       = (CONVERT_COMPLETE_MAX_CYCLE + USR_CLK_CYCLE_NS - 1) / USR_CLK_CYCLE_NS;

/* FINAL parameters */

/* FINAL chip parameters, all refer to data-sheet */

localparam TIMEOUT_CLOCKS                            = (TIMEOUT_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: TIMEOUT_CLOCKS_ORIGIN,
           T_RESET_CLOCKS                            = (T_RESET_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: T_RESET_CLOCKS_ORIGIN,
           T1_CLOCKS                                 = (T1_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: T1_CLOCKS_ORIGIN,
           T2_CLOCKS                                 = (T2_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: T2_CLOCKS_ORIGIN,
           T10_CLOCKS                                = (T10_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: T10_CLOCKS_ORIGIN,
           T11_CLOCKS                                = (T11_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: T11_CLOCKS_ORIGIN,
           T14_CLOCKS                                = (T14_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: T14_CLOCKS_ORIGIN;

/* FINAL timeout parameters */

localparam FIRST_DATA_WAIT_CLOCKS                    = (FIRST_DATA_WAIT_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: FIRST_DATA_WAIT_CLOCKS_ORIGIN,
           WAIT_BUSY_TO_HIGH_MAX_CLOCKS              = (WAIT_BUSY_TO_HIGH_MAX_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: WAIT_BUSY_TO_HIGH_MAX_CLOCKS_ORIGIN,
           CONVERT_COMPLETE_WAIT_CLOCKS              = (CONVERT_COMPLETE_WAIT_CLOCKS_ORIGIN < PULSE_MIN_REQUIRED)? PULSE_MIN_REQUIRED: CONVERT_COMPLETE_WAIT_CLOCKS_ORIGIN;

/* Power On Reset Setting */

localparam POWER_ON_RESET_CLOCKS                     = 8'd4;
localparam TIMER_WIDTH                               = $clog2(TIMEOUT_CLOCKS) + 1;

/* ----------------------------------------------- status value ------------------------------------------- */

/* timer reset values */

localparam TIMER_RESET_VALUE                         = 0;
          
/* channels */

localparam CHANNEL_POINTER__CH1                      = 9'b000000001,
           CHANNEL_POINTER__CH2                      = 9'b000000010,
           CHANNEL_POINTER__CH3                      = 9'b000000100,
           CHANNEL_POINTER__CH4                      = 9'b000001000,
           CHANNEL_POINTER__CH5                      = 9'b000010000,
           CHANNEL_POINTER__CH6                      = 9'b000100000,
           CHANNEL_POINTER__CH7                      = 9'b001000000,
           CHANNEL_POINTER__CH8                      = 9'b010000000,
           CHANNEL_POINTER__NONE                     = 9'b100000000;

/* Errors */

localparam ERROR_NONE                                = 4'd0,
           ERROR_CONVERT_TIMEOUT                     = 4'd1, 
           ERROR_FIRST_DATA_WRONG_SIGNAL             = 4'd2, 
           ERROR_INTERNAL_REGISTER_WRONG_CONDITION   = 4'd3, 
           ERROR_SAMPLING_TIMEOUT                    = 4'd4,
           ERROR_UNABLE_TO_START_SAMPLING            = 4'd5,
           ERROR_SAMPLING_TOO_FAST                   = 4'd6;

/* Logic parameters for hardware pins */

localparam HIGH                                      = 1'b1,
           LOW                                       = 1'b0;

/* Logic parameters for signals */

localparam TRUE                                      = 1'b1,
           FALSE                                     = 1'b0;

/* system state choice */

localparam STATE_WAIT_FOR_USR_SAMPLE_TRIGGER         = 6'b000001, 
           STATE_CREATE_CONVST_PULSE                 = 6'b000010,
           STATE_WAIT_BUSY_READY                     = 6'b000100,
           STATE_WAIT_CONVERT_COMPLETE               = 6'b001000,
           STATE_READ_CHANNELS                       = 6'b010000,
           STATE_COMPLETE                            = 6'b100000;

/* system sub state choice */

localparam SUB_STATE_CREATE_RD_HIGH_PULSE            = 4'b0001,
           SUB_STATE_WAIT_DATA_READY                 = 4'b0010,
           SUB_STATE_READ_DATA                       = 4'b0100,
           SUB_STATE_RD_LOW_PULSE_INTERVAL           = 4'b1000;

/* system reset state choice */

localparam RESET_STATE_CREATE_RESET_PULSE            = 3'b001,
           RESET_STATE_WAIT_RESET_HIGH               = 3'b010,
           RESET_STATE_CREATE_COMPLETE               = 3'b100;

/* ----------------------------------------------- registers ---------------------------------------------- */

/* system auto reset */

reg [7: 0] power_on_timer                            = TIMER_RESET_VALUE;
reg system_power_on_reset                            = TRUE;

/* sync registers */

reg [2: 0] usr_trigger_sync_list                     = 3'b0;
reg [1: 0] hw_busy_sync_list                         = 2'b0;
reg [1: 0] hw_first_data_sync_list                   = 2'b0;

reg [15: 0] hw_data_sync1                            = 16'b0;
reg [15: 0] hw_data_sync2                            = 16'b0;

/* state flags */

reg [5: 0] system_state                              = STATE_WAIT_FOR_USR_SAMPLE_TRIGGER;
reg [3: 0] system_sub_state                          = SUB_STATE_CREATE_RD_HIGH_PULSE;
reg [2: 0] reset_state                               = RESET_STATE_CREATE_RESET_PULSE;

/* timer counters */

reg [TIMER_WIDTH - 1: 0] system_state_timer                          = TIMER_RESET_VALUE;
reg [TIMER_WIDTH - 1: 0] system_sub_state_timer                      = TIMER_RESET_VALUE;
reg [7: 0] reset_timer                                               = TIMER_RESET_VALUE;

reg [TIMER_WIDTH - 1: 0] system_state_timer_last_value               = TIMER_RESET_VALUE;
reg [TIMER_WIDTH - 1: 0] system_sub_state_timer_last_value           = TIMER_RESET_VALUE;
reg [TIMER_WIDTH - 1: 0] system_sub_state_timer_last_value_at_rd_low = TIMER_RESET_VALUE;

/* channel reading pointer */

reg [8: 0] current_channel                           = CHANNEL_POINTER__CH1;

/* timer power control flag */

reg system_state_timer_en                            = FALSE;
reg system_sub_state_timer_en                        = FALSE;
reg reset_timer_en                                   = FALSE;

reg entry_sub_state_for_first_time                   = TRUE;

reg error_condition__convert_timeout                 = FALSE, 
    error_condition__first_data_wait_timeout         = FALSE, 
    error_condition__channel_pointer_error           = FALSE, 
    error_condition__first_data_wrong_status         = FALSE, 
    error_condition__timeout                         = FALSE,
    error_condition__unable_to_start_convert         = FALSE,
    error_condition__state_case_error                = FALSE,
    error_condition__sub_state_case_error            = FALSE,
    error_condition__sampling_too_fast               = FALSE;  /* do not need reset */
    
reg one_state_trigger_occur                          = FALSE;
reg one_sub_state_trigger_occur                      = FALSE;
reg one_reset_state_trigger_occur                    = FALSE;

wire posedge_trigger = usr_trigger_sync_list[1] && ~usr_trigger_sync_list[2];

/* ------------------------------------------------ define -------------------------------------------- */

`define SYSTEM_STATE_TIME_INTERVAL (system_state_timer - system_state_timer_last_value)
`define SYSTEM_SUB_STATE_TIME_INTERVAL (system_sub_state_timer - system_sub_state_timer_last_value)
`define RD_LOW_PULSE_TIME_INTERVAL (system_sub_state_timer - system_sub_state_timer_last_value_at_rd_low)

`define STATE_UPDATE_CLOCK system_state_timer_last_value <= system_state_timer;
`define SUB_STATE_UPDATE_CLOCK system_sub_state_timer_last_value <= system_sub_state_timer;
`define RD_LOW_PULSE_START_UPDATE_CLOCK system_sub_state_timer_last_value_at_rd_low <= system_sub_state_timer;

`define HW_BUSY_SYNCED hw_busy_sync_list[1]
`define HW_FIRST_DATA_SYNCED hw_first_data_sync_list[1]
`define HW_PARALLEL_DATA_SYNCED hw_data_sync2

`define SYSTEM_STATE_TIMER_HAVE_RESET     (system_state_timer == TIMER_RESET_VALUE)
`define SYSTEM_SUB_STATE_TIMER_HAVE_RESET (system_sub_state_timer == TIMER_RESET_VALUE)

`define RESET_TIMER_HAVE_RESET            (reset_timer == TIMER_RESET_VALUE)
`define TIMEOUT_TIMER_HAVE_RESET          (timeout_timer == TIMER_RESET_VALUE)

`define INCREASE_CHANNEL \
        case (current_channel) \
            CHANNEL_POINTER__CH1: current_channel <= CHANNEL_POINTER__CH2; \
            CHANNEL_POINTER__CH2: current_channel <= CHANNEL_POINTER__CH3; \
            CHANNEL_POINTER__CH3: current_channel <= CHANNEL_POINTER__CH4; \
            CHANNEL_POINTER__CH4: current_channel <= CHANNEL_POINTER__CH5; \
            CHANNEL_POINTER__CH5: current_channel <= CHANNEL_POINTER__CH6; \
            CHANNEL_POINTER__CH6: current_channel <= CHANNEL_POINTER__CH7; \
            CHANNEL_POINTER__CH7: current_channel <= CHANNEL_POINTER__CH8; \
            CHANNEL_POINTER__CH8: current_channel <= CHANNEL_POINTER__NONE; \
            default: current_channel <= CHANNEL_POINTER__NONE; \
        endcase \

`define ERROR_OCCURRED (error_condition__convert_timeout || \
                        error_condition__first_data_wait_timeout || \
                        error_condition__channel_pointer_error || \
                        error_condition__first_data_wrong_status || \
                        error_condition__timeout || \
                        error_condition__unable_to_start_convert || \
                        error_condition__state_case_error || \
                        error_condition__sub_state_case_error || \
                        error_condition__sampling_too_fast) \

`define CHANNEL_POINTER_VALID (current_channel == CHANNEL_POINTER__CH1 || \
                               current_channel == CHANNEL_POINTER__CH2 || \
                               current_channel == CHANNEL_POINTER__CH3 || \
                               current_channel == CHANNEL_POINTER__CH4 || \
                               current_channel == CHANNEL_POINTER__CH5 || \
                               current_channel == CHANNEL_POINTER__CH6 || \
                               current_channel == CHANNEL_POINTER__CH7 || \
                               current_channel == CHANNEL_POINTER__CH8) \

`define SYSTEM_AUTO_RESET_CONDITION (`ERROR_OCCURRED || system_power_on_reset)

`define SYSTEM_STATE_HARDWARE_RESET \
        /* CONVRST_A and CONVRST_B are connect together on the board */\
        hw_convst <= HIGH; \
        /* CS# pin of the AD7606 chip */\
        hw_cs <= HIGH; \
        /* Range select of the AD7606 chip */\
        hw_range <= HIGH; \
        /* OS0, OS1, OS2 Pins of the AD7606 */\
        hw_os <= {LOW, LOW, LOW}; \
        /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */\
        hw_mode_select <= LOW; \
        /* STBY# pin of AD7606 */\
        hw_stby_n <= HIGH; \

`define SYSTEM_SUB_STATE_HARDWARE_RESET \
        /* CS# pin of the AD7606 chip */\
        hw_rd <= HIGH; \

`define SYSTEM_STATE_FLAGS_RESET \
        system_state <= STATE_WAIT_FOR_USR_SAMPLE_TRIGGER; \
        one_state_trigger_occur <= FALSE; \
        system_state_timer_en <= FALSE; \
        system_state_timer_last_value <= TIMER_RESET_VALUE; \

`define SYSTEM_SUB_STATE_FLAGS_RESET \
        system_sub_state <= SUB_STATE_CREATE_RD_HIGH_PULSE; \
        one_sub_state_trigger_occur <= FALSE; \
        system_sub_state_timer_en <= FALSE; \
        current_channel <= CHANNEL_POINTER__CH1; \
        entry_sub_state_for_first_time <= TRUE; \
        system_sub_state_timer_last_value <= TIMER_RESET_VALUE; \
        system_sub_state_timer_last_value_at_rd_low <= TIMER_RESET_VALUE; \

`define RESET_OUTPUT_CHANNELS \
        usr_channel1 <= 16'b0; \
        usr_channel2 <= 16'b0; \
        usr_channel3 <= 16'b0; \
        usr_channel4 <= 16'b0; \
        usr_channel5 <= 16'b0; \
        usr_channel6 <= 16'b0; \
        usr_channel7 <= 16'b0; \
        usr_channel8 <= 16'b0; \

`define UPDATE_ERROR_FLAG \
        if (error_condition__channel_pointer_error || error_condition__state_case_error || error_condition__sub_state_case_error) usr_error <= ERROR_INTERNAL_REGISTER_WRONG_CONDITION; \
        else if (error_condition__first_data_wait_timeout || error_condition__first_data_wrong_status) usr_error <= ERROR_FIRST_DATA_WRONG_SIGNAL; \
        else if (error_condition__convert_timeout) usr_error <= ERROR_CONVERT_TIMEOUT; \
        else if (error_condition__timeout) usr_error <= ERROR_SAMPLING_TIMEOUT; \
        else if (error_condition__unable_to_start_convert) usr_error <= ERROR_UNABLE_TO_START_SAMPLING; \
        else if (error_condition__sampling_too_fast) usr_error <= ERROR_SAMPLING_TOO_FAST; \
        else usr_error <= ERROR_NONE; \

/* -------------------------------------- Detect usr_trigger (posedge) ----------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) usr_trigger_sync_list <= 3'b0;
    else if (`SYSTEM_AUTO_RESET_CONDITION) usr_trigger_sync_list <= 3'b0;
    else usr_trigger_sync_list <= {usr_trigger_sync_list[1: 0], usr_trigger};

end

/* ------------------------------------------- Detect hw_busy ------------------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) hw_busy_sync_list <= 2'b0;
    else if (`SYSTEM_AUTO_RESET_CONDITION) hw_busy_sync_list <= 2'b0;
    else begin

        hw_busy_sync_list[1] <= hw_busy_sync_list[0];
        hw_busy_sync_list[0] <= hw_busy;

    end

end

/* -------------------------------------- Detect hw_first_data ------------------------------------------ */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) hw_first_data_sync_list <= 2'b0;
    else if (`SYSTEM_AUTO_RESET_CONDITION) hw_first_data_sync_list <= 2'b0;
    else begin

        hw_first_data_sync_list[1] <= hw_first_data_sync_list[0];
        hw_first_data_sync_list[0] <= hw_first_data;

    end

end

/* -------------------------------------- Detect hw_data ------------------------------------------ */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) begin

        hw_data_sync1 <= 16'b0;
        hw_data_sync2 <= 16'b0;
    
    end else if (`SYSTEM_AUTO_RESET_CONDITION) begin

        hw_data_sync1 <= 16'b0;
        hw_data_sync2 <= 16'b0;

    end else begin

        hw_data_sync2 <= hw_data_sync1;
        hw_data_sync1 <= hw_data;

    end

end

/* -------------------------------------------------------------------------------------------------- */
/* ------------------------------------------- System State ----------------------------------------- */
/* -------------------------------------------------------------------------------------------------- */

/* -------------------------------------------- State Flags ----------------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) begin

        `SYSTEM_STATE_FLAGS_RESET
        
    end else if (`SYSTEM_AUTO_RESET_CONDITION) begin 

        `SYSTEM_STATE_FLAGS_RESET

        if (`ERROR_OCCURRED) begin
            
            error_condition__unable_to_start_convert <= FALSE;
            error_condition__convert_timeout <= FALSE;
            error_condition__state_case_error <= FALSE;
            error_condition__sampling_too_fast <= FALSE;

        end

    end else begin

        if (system_state != STATE_WAIT_FOR_USR_SAMPLE_TRIGGER && posedge_trigger) error_condition__sampling_too_fast <= TRUE;
        
        case (system_state)

            STATE_WAIT_FOR_USR_SAMPLE_TRIGGER: begin

                if (posedge_trigger && reset_state == RESET_STATE_CREATE_COMPLETE && !one_state_trigger_occur) begin

                    one_state_trigger_occur = TRUE;

                end else begin

                    `SYSTEM_STATE_FLAGS_RESET

                end
                
                if (one_state_trigger_occur) begin
                    if (!`SYSTEM_STATE_TIMER_HAVE_RESET) begin

                        system_state_timer_en <= FALSE;
                        
                    end else begin

                        system_state_timer_en <= TRUE;
                        one_state_trigger_occur <= FALSE;
                        system_state <= STATE_CREATE_CONVST_PULSE;
                        `STATE_UPDATE_CLOCK

                    end

                end

            end

            STATE_CREATE_CONVST_PULSE: begin

                if (`SYSTEM_STATE_TIME_INTERVAL >= T2_CLOCKS) begin

                    system_state <= STATE_WAIT_BUSY_READY;
                    `STATE_UPDATE_CLOCK

                end
                
            end

            STATE_WAIT_BUSY_READY: begin

                if ((`SYSTEM_STATE_TIME_INTERVAL >= T1_CLOCKS && `HW_BUSY_SYNCED == HIGH)) begin

                    system_state <= STATE_WAIT_CONVERT_COMPLETE;
                    `STATE_UPDATE_CLOCK

                end else if (`SYSTEM_STATE_TIME_INTERVAL >= WAIT_BUSY_TO_HIGH_MAX_CLOCKS && `HW_BUSY_SYNCED == LOW) begin

                    error_condition__unable_to_start_convert <= TRUE;

                end

            end

            STATE_WAIT_CONVERT_COMPLETE: begin

                if (`HW_BUSY_SYNCED == LOW) begin

                    system_state <= STATE_READ_CHANNELS;
                    
                end else if (`SYSTEM_STATE_TIME_INTERVAL >= CONVERT_COMPLETE_WAIT_CLOCKS && `HW_BUSY_SYNCED == HIGH) begin

                    error_condition__convert_timeout <= TRUE;

                end

            end

            STATE_READ_CHANNELS: begin
                
                if (!`CHANNEL_POINTER_VALID) system_state <= STATE_COMPLETE;

            end

            STATE_COMPLETE: begin

                `SYSTEM_STATE_FLAGS_RESET
            
            end

            default: error_condition__state_case_error <= TRUE;

        endcase
    end
end

/* --------------------------------------------- Registers ------------------------------------------ */

always @(posedge usr_clk or negedge usr_rst) begin
    
    if (!usr_rst) begin

        usr_sampling <= FALSE;
        usr_error <= ERROR_NONE;

        `SYSTEM_STATE_HARDWARE_RESET
    
    end else if (`SYSTEM_AUTO_RESET_CONDITION) begin 

        `SYSTEM_STATE_HARDWARE_RESET
        
        usr_sampling <= FALSE;

        `UPDATE_ERROR_FLAG

    end else begin
    
        case (system_state)

            STATE_WAIT_FOR_USR_SAMPLE_TRIGGER: begin

                usr_sampling <= FALSE;
                `SYSTEM_STATE_HARDWARE_RESET
            
            end

            STATE_CREATE_CONVST_PULSE: begin

                /* hardware control */

                hw_cs <= LOW;      // CS# to LOW
                hw_convst <= LOW;  // set CONVST to LOW to make a LOW pulse

                /* user signals control */

                usr_error <= ERROR_NONE;
                usr_sampling <= TRUE;

            end

            STATE_WAIT_BUSY_READY: hw_convst <= HIGH;   // set CONVST to HIGH, complete to create a LOW pulse

            STATE_WAIT_CONVERT_COMPLETE: begin
                /* do nothing */
            end

            STATE_READ_CHANNELS: begin
                /* do nothing */
            end

            STATE_COMPLETE: begin

                usr_sampling <= FALSE;
                usr_error <= ERROR_NONE;
                `SYSTEM_STATE_HARDWARE_RESET
                
            end

        endcase

    end

end

/* -------------------------------------------------------------------------------------------------- */
/* ----------------------------------------- System Sub-State --------------------------------------- */
/* -------------------------------------------------------------------------------------------------- */

/* -------------------------------------------- State Flags ----------------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) begin

        `SYSTEM_SUB_STATE_FLAGS_RESET
    
    end else if (`SYSTEM_AUTO_RESET_CONDITION) begin 

        `SYSTEM_SUB_STATE_FLAGS_RESET

        if (`ERROR_OCCURRED) begin
            
            error_condition__first_data_wait_timeout <= FALSE;
            error_condition__first_data_wrong_status <= FALSE;
            error_condition__sub_state_case_error <= FALSE;

        end

    end else if (system_state == STATE_READ_CHANNELS) begin

        system_sub_state_timer_en <= TRUE;

        if (`CHANNEL_POINTER_VALID) begin
        
            case (system_sub_state)

                SUB_STATE_CREATE_RD_HIGH_PULSE: begin

                    /* maintain a HIGH level for RD# until now, and then make a negative edge for RD# to trigger DATA */

                    if (`SYSTEM_SUB_STATE_TIME_INTERVAL >= T11_CLOCKS || entry_sub_state_for_first_time) begin
                        system_sub_state <= SUB_STATE_WAIT_DATA_READY;
                        entry_sub_state_for_first_time <= FALSE;
                        `SUB_STATE_UPDATE_CLOCK
                        `RD_LOW_PULSE_START_UPDATE_CLOCK
                    end

                end

                SUB_STATE_WAIT_DATA_READY: begin

                    /* maintain a LOW level for RD# until now, and then read the data */

                    if (`SYSTEM_SUB_STATE_TIME_INTERVAL >= T14_CLOCKS) begin
                        system_sub_state <= SUB_STATE_READ_DATA;
                        `SUB_STATE_UPDATE_CLOCK
                    end

                end

                SUB_STATE_READ_DATA: begin

                    /* read the data, and detect FIRST_DATA */

                    if (current_channel == CHANNEL_POINTER__CH1) begin
                        if (`HW_FIRST_DATA_SYNCED == HIGH) system_sub_state <= SUB_STATE_RD_LOW_PULSE_INTERVAL;
                        else if (`SYSTEM_SUB_STATE_TIME_INTERVAL >= FIRST_DATA_WAIT_CLOCKS) error_condition__first_data_wait_timeout <= TRUE;
                    end else begin
                        if (`HW_FIRST_DATA_SYNCED == LOW) system_sub_state <= SUB_STATE_RD_LOW_PULSE_INTERVAL;
                        else if (`SYSTEM_SUB_STATE_TIME_INTERVAL >= FIRST_DATA_WAIT_CLOCKS) error_condition__first_data_wrong_status <= TRUE;
                    end

                end

                SUB_STATE_RD_LOW_PULSE_INTERVAL: begin

                    /* after reading, make a HIGH pulse for RD# and increase the channel pointer */

                    if (`RD_LOW_PULSE_TIME_INTERVAL >= T10_CLOCKS) begin
                        system_sub_state <= SUB_STATE_CREATE_RD_HIGH_PULSE;
                        `SUB_STATE_UPDATE_CLOCK
                        `INCREASE_CHANNEL
                    end

                end

                default: error_condition__sub_state_case_error <= TRUE;

            endcase

        end

    end else begin
    
        `SYSTEM_SUB_STATE_FLAGS_RESET

    end
end

/* --------------------------------------------- Registers ------------------------------------------ */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) begin

        `SYSTEM_SUB_STATE_HARDWARE_RESET
        `RESET_OUTPUT_CHANNELS
    
    end else if (`SYSTEM_AUTO_RESET_CONDITION) begin

        `SYSTEM_SUB_STATE_HARDWARE_RESET
        `RESET_OUTPUT_CHANNELS

        if (`ERROR_OCCURRED) error_condition__channel_pointer_error <= FALSE;

    end else if (system_state == STATE_READ_CHANNELS) begin
    
        case (system_sub_state)

            SUB_STATE_CREATE_RD_HIGH_PULSE: hw_rd <= HIGH;  // RD# to HIGH

            SUB_STATE_WAIT_DATA_READY: hw_rd <= LOW;  // make a falling edge for RD# 

            SUB_STATE_READ_DATA: begin
            
                if (current_channel == CHANNEL_POINTER__CH1) begin
                    usr_channel1 <= `HW_PARALLEL_DATA_SYNCED;
                end else if (current_channel != CHANNEL_POINTER__CH1) begin
                    case (current_channel)
                        CHANNEL_POINTER__CH2: usr_channel2 <= `HW_PARALLEL_DATA_SYNCED;
                        CHANNEL_POINTER__CH3: usr_channel3 <= `HW_PARALLEL_DATA_SYNCED;
                        CHANNEL_POINTER__CH4: usr_channel4 <= `HW_PARALLEL_DATA_SYNCED;
                        CHANNEL_POINTER__CH5: usr_channel5 <= `HW_PARALLEL_DATA_SYNCED;
                        CHANNEL_POINTER__CH6: usr_channel6 <= `HW_PARALLEL_DATA_SYNCED;
                        CHANNEL_POINTER__CH7: usr_channel7 <= `HW_PARALLEL_DATA_SYNCED;
                        CHANNEL_POINTER__CH8: usr_channel8 <= `HW_PARALLEL_DATA_SYNCED;
                        CHANNEL_POINTER__NONE: /* do nothing here */;
                        default: error_condition__channel_pointer_error <= TRUE;
                    endcase
                end else begin
                    error_condition__channel_pointer_error <= TRUE;
                end

            end

            SUB_STATE_RD_LOW_PULSE_INTERVAL: hw_rd <= LOW;  // make a LOW pulse for RD#
            
            default: begin

                `SYSTEM_SUB_STATE_HARDWARE_RESET
            
            end
            
        endcase

    end else begin
        
        `SYSTEM_SUB_STATE_HARDWARE_RESET

    end
    
end

/* ---------------------------------------------- Reset Logic ------------------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) begin

        reset_state <= RESET_STATE_CREATE_RESET_PULSE;
        hw_reset <= LOW;                    /* reset the AD7606 chip */
        usr_ready <= FALSE;
        one_reset_state_trigger_occur <= FALSE;
        
        reset_timer_en <= FALSE;
    
    end else if (`SYSTEM_AUTO_RESET_CONDITION) begin

        reset_state <= RESET_STATE_CREATE_RESET_PULSE;
        hw_reset <= LOW;                    /* reset the AD7606 chip */
        usr_ready <= FALSE;
        one_reset_state_trigger_occur <= FALSE;
        
        reset_timer_en <= FALSE;

    end else begin

        case(reset_state)

            RESET_STATE_CREATE_RESET_PULSE: begin

                if (!`RESET_TIMER_HAVE_RESET) reset_timer_en <= FALSE;
                else begin

                    reset_timer_en <= TRUE;
                    hw_reset <= HIGH;
                    reset_state <= RESET_STATE_WAIT_RESET_HIGH;

                end

            end 

            RESET_STATE_WAIT_RESET_HIGH: begin

                if (reset_timer >= T_RESET_CLOCKS && !one_reset_state_trigger_occur) one_reset_state_trigger_occur <= TRUE;
                if (one_reset_state_trigger_occur) begin

                    if (!`RESET_TIMER_HAVE_RESET) reset_timer_en <= FALSE;
                    else begin

                        reset_timer_en <= FALSE;
                        hw_reset <= LOW;
                        reset_state <= RESET_STATE_CREATE_COMPLETE;

                    end

                end

            end 

            RESET_STATE_CREATE_COMPLETE: begin

                if (!`RESET_TIMER_HAVE_RESET) reset_timer_en <= FALSE;
                else begin

                    reset_timer_en <= FALSE;
                    hw_reset <= LOW;
                    usr_ready <= TRUE;
                    reset_state <= RESET_STATE_CREATE_COMPLETE;

                end
            end

            default: reset_state <= RESET_STATE_CREATE_RESET_PULSE;

        endcase
    end
end

/* --------------------------------------------- System State Timer ------------------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) begin

        system_state_timer <= TIMER_RESET_VALUE;

    end else if (`SYSTEM_AUTO_RESET_CONDITION) begin 

        system_state_timer <= TIMER_RESET_VALUE;
        if (`ERROR_OCCURRED) error_condition__timeout <= FALSE;

    end else begin

        if (!system_state_timer_en) system_state_timer <= TIMER_RESET_VALUE;
        else system_state_timer <= system_state_timer + 1;

        /* detect timeout */

        if (system_state_timer >= TIMEOUT_CLOCKS) error_condition__timeout <= TRUE;

    end

end

/* ------------------------------------------ System Sub State Timer ------------------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) system_sub_state_timer <= TIMER_RESET_VALUE;
    else if (`SYSTEM_AUTO_RESET_CONDITION) system_sub_state_timer <= TIMER_RESET_VALUE;
    else begin

        if (!system_sub_state_timer_en) system_sub_state_timer <= TIMER_RESET_VALUE;
        else system_sub_state_timer <= system_sub_state_timer + 1;

    end

end

/* ------------------------------------------ Reset Timer ----------------------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) reset_timer <= TIMER_RESET_VALUE;
    else if (`SYSTEM_AUTO_RESET_CONDITION) reset_timer <= TIMER_RESET_VALUE;
    else begin

        if (reset_timer_en) reset_timer <= reset_timer + 1;
        else reset_timer <= TIMER_RESET_VALUE;

    end

end

/* ---------------------------------------------- Power On Reset Timer ----------------------------------------------- */

always @(posedge usr_clk or negedge usr_rst) begin

    if (!usr_rst) begin

        power_on_timer <= TIMER_RESET_VALUE;
        system_power_on_reset <= TRUE;

    end else begin

        if (system_power_on_reset) begin

            if (power_on_timer >= POWER_ON_RESET_CLOCKS) system_power_on_reset <= FALSE;
            else power_on_timer <= power_on_timer + 1;

        end

    end

end

endmodule
