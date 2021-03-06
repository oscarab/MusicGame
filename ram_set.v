`timescale 1ns / 1ps

module char_set(
    input                  rst,
    input      [2:0]       msg,

    output reg [48:0]   row1,
    output reg [48:0]   row2,
    output reg [48:0]   row3,
    output reg [48:0]   row4,
    output reg [48:0]   row5,
    output reg [48:0]   row6,
    output reg [48:0]   row7
    );

    always @(*) begin
        if(!rst) begin
            row1 = 49'd0;
            row2 = 49'd0;
            row3 = 49'd0;
            row4 = 49'd0;
            row5 = 49'd0;
            row6 = 49'd0;
            row7 = 49'd0;
        end
        else begin
            case (msg)
                3'd1: 
                begin       //PERFECT
                    row1 = 49'b0111110_0011100_0111110_0111110_0011110_0111110_0011110_;
                    row2 = 49'b0001000_0100010_0000010_0000010_0100010_0000010_0100010_;
                    row3 = 49'b0001000_0000010_0000010_0000010_0100010_0000010_0100010_;
                    row4 = 49'b0001000_0000010_0011110_0011110_0011110_0011110_0011110_;
                    row5 = 49'b0001000_0000010_0000010_0000010_0001010_0000010_0000010_;
                    row6 = 49'b0001000_0100010_0000010_0000010_0010010_0000010_0000010_;
                    row7 = 49'b0001000_0011100_0011110_0000010_0100010_0011110_0000010_;
                end
                3'd2:
                begin       //GOOD
                    row1 = 49'b0000000_0011110_0011100_0011100_0011100_0000000_0000000;
                    row2 = 49'b0000000_0100010_0100010_0100010_0000010_0000000_0000000;
                    row3 = 49'b0000000_0100010_0100010_0100010_0000010_0000000_0000000;
                    row4 = 49'b0000000_0100010_0100010_0100010_0111010_0000000_0000000;
                    row5 = 49'b0000000_0100010_0100010_0100010_0100010_0000000_0000000;
                    row6 = 49'b0000000_0100010_0100010_0100010_0100010_0000000_0000000;
                    row7 = 49'b0000000_0011110_0011100_0011100_0011100_0000000_0000000;
                end
                3'd3:
                begin       //OK
                    row1 = 49'b0000000_0000000_0100010_0011100_0000000_0000000_0000000;
                    row2 = 49'b0000000_0000000_0010010_0100010_0000000_0000000_0000000;
                    row3 = 49'b0000000_0000000_0001010_0100010_0000000_0000000_0000000;
                    row4 = 49'b0000000_0000000_0000110_0100010_0000000_0000000_0000000;
                    row5 = 49'b0000000_0000000_0001010_0100010_0000000_0000000_0000000;
                    row6 = 49'b0000000_0000000_0010010_0100010_0000000_0000000_0000000;
                    row7 = 49'b0000000_0000000_0100010_0011100_0000000_0000000_0000000;
                end
                default:
                begin
                    row1 = 49'd0;
                    row2 = 49'd0;
                    row3 = 49'd0;
                    row4 = 49'd0;
                    row5 = 49'd0;
                    row6 = 49'd0;
                    row7 = 49'd0;
                end
            endcase
        end
    end
endmodule
