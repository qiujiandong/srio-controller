set_false_path -from [get_ports sys_nrst]

create_clock -period 8.000 -name srio_ref_clk_clk_p -waveform {0.000 4.000} [get_ports srio_ref_clk_clk_p]