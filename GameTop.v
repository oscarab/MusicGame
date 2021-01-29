`timescale 1ns / 1ps

module GameTop(
    input           clk100M,        //主时钟 100MHZ
    input           rst,            //复位

    /*七段数码管*/
    output  [7:0]   num,            //片选信号
    output  [6:0]   oData,          //位选信号

    /*VGA模块*/
    output  [3:0]   color_r,        //R
    output  [3:0]   color_g,        //G
    output  [3:0]   color_b,        //B
    output          hs,             //列信号
    output          vs,             //行信号

    /*mp3模块*/
    input           SO,             //传出
    input           DREQ,           //数据请求，高电平时可传输数据
    output          XCS,            //片选SCI 传输读、写指令
    output          XDCS,           //片选SDI 传输数据
    output          SCK,            //时钟
    output          SI,             //传入mp3
    output          XRESET,         //硬件复位，低电平有效

    /*按钮*/
    input           signal,         //开始与结束游戏开关
    input [3:0]     hits,           //四个敲击按钮

    output  led      
    );
    wire clk25MHZ;
    wire clk12MHZ;
    wire clk2MHZ;
    wire clk1000HZ;

    wire [434:0]    col1;
    wire [434:0]    col2;
    wire [434:0]    col3;
    wire [434:0]    col4;
    wire            end_sig;
    wire            start;
    wire            bk_g;
    wire [11:0]     score;
    wire [2:0]      msg;

    /*游戏逻辑控制器*/
    gamecontrol game(
        .clk(clk25MHZ),
        .rst(rst),

        .signal(signal),
        .hits(hits),

        .col1(col1),
        .col2(col2),
        .col3(col3),
        .col4(col4),
        .end_sig(end_sig),
        .bk_g(bk_g),
        .start(start),

        .score(score),
        .msg(msg)
    );

    /*VGA显示*/
    vga vga_inst(
        .clk25MHZ(clk25MHZ), 
        .rst(rst), 

        .bk_g(bk_g),
        .col1(col1),
        .col2(col2),
        .col3(col3),
        .col4(col4),
        .hits(hits),
        .msg(msg),

        .color_r(color_r), 
        .color_g(color_g), 
        .color_b(color_b), 
        .hs(hs), 
        .vs(vs));

    /*mp3播放模块*/
    mp3board mp3(
        .clk(clk2MHZ),
        .rst(rst),
        .play(start),
        .end_sig(end_sig),

        .SO(SO),
        .DREQ(DREQ),
        .XCS(XCS),
        .XDCS(XDCS),
        .SCK(SCK),
        .SI(SI),
        .XRESET(XRESET),
        .debug(led)
    );

    /*七段数码管模块*/
    numberdisplay display(
        .clk(clk1000HZ),
        .number(score),

        .num(num),
        .oData(oData)
    );

    /*分频器*/
    Divider div(
        .I_CLK(clk12MHZ),
        .O_CLK1(clk2MHZ),
        .O_CLK2(clk1000HZ)
    );

    /*分频器IP核*/
    wire locked;
    clk_wiz_0 instance_name
    (
        .clk_in1(clk100M),      // 输入时钟100MHZ
        .clk_out1(clk25MHZ),    // 输出25MHZ
        .clk_out2(clk12MHZ),    // 输出12.288MHZ
        .reset(1'b0),           // 保持不复位
        .locked(locked));       // 稳定信号

endmodule