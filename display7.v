`timescale 1ns / 1ps

module display7(
    input       clk,        //时钟信号
    input [3:0] n1,         //输入数字
    input [3:0] n2,         //输入数字
    input [3:0] n3,         //输入数字
    input [3:0] n4,         //输入数字
    input [3:0] n5,         //输入数字
    input [3:0] n6,         //输入数字
    input [3:0] n7,         //输入数字
    input [3:0] n8,         //输入数字

    output reg  [7:0]   num,    //片选信号
    output reg  [6:0]   oData   //输出
    );
    reg [3:0]   cnt     = 0;
    wire [3:0]  nums[7:0];

    assign nums[0] = n1;
    assign nums[1] = n2;
    assign nums[2] = n3;
    assign nums[3] = n4;
    assign nums[4] = n5;
    assign nums[5] = n6;
    assign nums[6] = n7;
    assign nums[7] = n8;

    always @(posedge clk) begin
        if(cnt == 4'd8)
            cnt = 0;
        else
            cnt = cnt + 1;
        
        num = 8'b11111111;
        num[cnt] = 1'b0;    //片选一个数字
        case (nums[cnt])
            4'b0000: oData = 7'b1000000;
            4'b0001: oData = 7'b1111001;
            4'b0010: oData = 7'b0100100;
            4'b0011: oData = 7'b0110000;
            4'b0100: oData = 7'b0011001;
            4'b0101: oData = 7'b0010010;
            4'b0110: oData = 7'b0000010;
            4'b0111: oData = 7'b1111000;
            4'b1000: oData = 7'b0000000;
            4'b1001: oData = 7'b0010000;
            default: oData = 7'b1111111;
        endcase
    end
endmodule

module numberdisplay(
    input               clk,        //时钟
    input   [11:0]      number,     //数字

    output  [7:0]       num,        //片选信号
    output  [6:0]       oData       //位选信号
    );

    reg [11:0]  bin;
    reg [15:0]  result;
    reg [15:0]  bcd;
    always @(number) begin
        bin = number;
        result = 16'd0;
        repeat (11)             //将二进制数转为BCD码
        begin
            result[0] = bin[11];
            if (result[3:0] > 4)
                result[3:0] = result[3:0] + 4'd3;
            else
                result[3:0] = result[3:0];
            if (result[7:4] > 4)
                result[7:4] = result[7:4] + 4'd3;
            else
                result[7:4] = result[7:4];
            if (result[11:8] > 4)
                result[11:8] = result[11:8] + 4'd3;
            else
                result[11:8] = result[11:8];
            if (result[15:12] > 4)
                result[15:12] = result[15:12] + 4'd3;
            else
                result[15:12] = result[15:12];
            result = result << 1;
            bin = bin << 1;
        end
        result[0] = bin[11];
        bcd = result;
    end

    display7 display(
        .clk(clk), 
        .n1(bcd[3:0]), 
        .n2(bcd[7:4]), 
        .n3(bcd[11:8]), 
        .n4(bcd[15:12]), 
        .n5(4'd10), 
        .n6(4'd10), 
        .n7(4'd10), 
        .n8(4'd10),
        .num(num),
        .oData(oData));
endmodule
