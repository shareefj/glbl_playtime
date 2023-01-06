module clk_gate (
    input wire clk,
    input wire clk_en,
    output wire clk_g
);

    BUFGCE u_buf (
        .O  (clk_g),
        .CE (clk_en),
        .I  (clk)
    );

endmodule
