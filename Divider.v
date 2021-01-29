`timescale 1ns / 1ps

module Divider(
    input I_CLK,
    output reg O_CLK1 = 0,
    output reg O_CLK2 = 0
    );
    parameter MOD1 = 32'd6;
    parameter MOD2 = 32'd12288;
    integer cnt1 = 32'd0;
    integer cnt2 = 32'd0;
    always @(posedge I_CLK) begin
        if (cnt1 < MOD1 / 2 - 1)
            cnt1 <= cnt1 + 1'b1;
        else begin
            cnt1 <= 32'd0;
            O_CLK1 <= ~O_CLK1;
        end

        if (cnt2 < MOD2 / 2 - 1)
            cnt2 <= cnt2 + 1'b1;
        else begin
            cnt2 <= 32'd0;
            O_CLK2 <= ~O_CLK2;
        end
    end
endmodule
