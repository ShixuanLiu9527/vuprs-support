create_clock -period 10.000 -name pcie_ref_clk -waveform {0.000 5.000} [get_ports {pcie_ref_clk_p[0]}]
create_clock -period 20.000 -name adc_clk_50m -waveform {0.000 10.000} [get_ports adc_clk_in]

set_clock_groups -name main_clk_group -asynchronous -group [get_clocks -include_generated_clocks [get_clocks pcie_ref_clk]] -group [get_clocks -include_generated_clocks [get_clocks adc_clk_50m]]

set_clock_groups -name adc_axi_clk_group -asynchronous \
-group [get_clocks -of_objects [get_pins vuprs_block_design_i/clk_wiz/inst/plle2_adv_inst/CLKOUT1]] \
-group [get_clocks *userclk*]
