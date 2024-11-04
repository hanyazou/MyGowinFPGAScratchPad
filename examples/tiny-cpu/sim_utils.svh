`ifdef SIMULATION
    `define SIM_DISPLAY(args) $display args
`else
    `define SIM_DISPLAY(args) do begin end while(0)
`endif
