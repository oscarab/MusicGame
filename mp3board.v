`timescale 1ns / 1ps

module mp3board(
    input clk,                  //12.288/6MHZ时钟

    input       rst,
    input       play,           //开始播放请求
    output reg  end_sig,        //结束信号 

    input       SO,             //传出
    input       DREQ,           //数据请求，高电平时可传输数据
    output reg  XCS,            //片选SCI 传输读、写指令
    output reg  XDCS,           //片选SDI 传输数据
    output      SCK,            //时钟
    output reg  SI,             //传入mp3
    output reg  XRESET,         //硬件复位，低电平有效

    output reg  debug
    );
    parameter   H_RESET     = 4'd0,         //硬复位
                S_RESET     = 4'd1,         //软复位
                SET_CLOCKF  = 4'd2,         //设置时钟寄存器
                SET_BASS    = 4'd3,         //设置音调寄存器
                SET_VOL     = 4'd4,         //设置音量
                WAITE       = 4'd5,         //等待
                PLAY        = 4'd6;         //播放
    
    parameter   MAX_ADDRA   = 17'd103382,
                MAX_BIT     = 32'd3308256;

    reg [3:0]       state       = WAITE;            //状态
    reg [31:0]      cntdown     = 32'd0;            //延时
    reg [31:0]      sci_w       = 32'd0;            //指令与地址 写
    reg [7:0]       sci_w_cnt   = 8'd32;            //SCI指令地址位数计数

    reg [31:0]      music_d     = 256'd0;           //音乐数据
    reg [31:0]      sdi_cnt     = 32'd32;           //SDI当前4字节已传送BIT数
    reg [31:0]      sended      = 32'd0;            //总传送BIT数o

    reg [16:0]      addra       = 16'd0;            //ROM中的地址
    reg [31:0]      buffer;                         //缓冲区
    reg             b_emp       = 1'b0;             //缓冲区是否已满
    wire [31:0]     douta;                          //ROM传出

    reg             ena         = 0;

    assign SCK = (clk & ena);
    
    always @(negedge clk) begin
        if(!rst) begin
            XDCS <= 1'b1;
            ena <= 0;
            SI <= 1'b0;
            XCS <= 1'b1;
            XRESET <= 1'b1;

            state <= WAITE;
            debug <= 0;

            addra <= 17'd0;
            sdi_cnt <= 32'd32;
            sended <= 32'd0;
            music_d <= 32'd0;
            b_emp <= 0;
        end
        else begin
            case (state)
                /*----------------等待---------------*/
                WAITE:
                if(cntdown > 0)
                    cntdown <= cntdown - 1'b1;
                else if(play) begin         //收到播放信号就转到硬复位
                    cntdown <= 32'd1000;
                    state <= H_RESET;
                    end_sig <= 0;
                    debug <= 0;
                end
                else
                    state <= WAITE;
                /*-----------------硬复位------------------*/
                H_RESET:
                if(cntdown > 0)
                    cntdown <= cntdown - 1'b1;
                else begin
                    XCS <= 1'b1;
                    XRESET <= 1'b0;
                    cntdown <= 32'd16700;               //复位后延时一段时间

                    state <= S_RESET;                   //转移到软复位
                    sci_w <= 32'h02_00_0804;            //软复位指令
                    sci_w_cnt <= 8'd32;                 //指令、地址、数据总长度
                end

                /*------------------软复位-----------------*/
                S_RESET:
                if(cntdown > 0) begin
                    XRESET <= (cntdown < 32'd16650);
                    cntdown <= cntdown - 1'b1;
                end
                else if(sci_w_cnt == 0) begin           //软复位结束
                    cntdown <= 32'd16600;

                    state <= SET_VOL;                   //转移到设置VOL
                    sci_w <= 32'h02_0b_0000;
                    sci_w_cnt <= 8'd32;

                    XCS <= 1'b1;                        //拉高XCS
                    ena <= 1'b0;                        //关闭输入时钟
                    SI <= 1'b0;
                end
                else if(DREQ) begin                     //当DREQ有效时开始软复位
                    XCS <= 1'b0;
                    ena <= 1'b1;
                    SI <= sci_w[sci_w_cnt - 1];
                    sci_w_cnt <= sci_w_cnt - 1'b1;
                end
                else begin
                    XCS <= 1'b1;                        //DREQ无效时继续等待
                    ena <= 1'b0;
                    SI <= 1'b0;
                end             

                /*----------播放音乐----------*/
                PLAY:
                if(cntdown > 0)
                    cntdown <= cntdown - 1'b1;
                else if(sended == MAX_BIT) begin
                    XDCS <= 1'b1;                       //播放结束
                    ena <= 0;
                    SI <= 1'b0;
                    
                    debug <= 1;
                    state <= WAITE;                     //转移到等待状态
                    addra <= 17'd0; 
                    end_sig <= 1;
                    sdi_cnt <= 32'd32;
                    sended <= 32'd0;
                    music_d <= 32'd0;
                    b_emp <= 0;
                end
                else begin
                    XDCS <= 1'b0;
                    ena <= 1'b1;
                    if(sdi_cnt == 0) begin              //传输完4字节
                        XDCS <= 1'b1;                   //拉高XDCS
                        ena <= 1'b0;
                        SI <= 1'b0;
                        sdi_cnt <= 32'd32;
                        music_d <= buffer;              //从缓冲区获取MP3数据
                        b_emp <= 0;
                    end
                    else begin
                        //当DREQ有效 或当前字节尚未发送完毕 则继续传输
                        if(DREQ || (sdi_cnt != 32 && sdi_cnt != 24 && sdi_cnt != 16 && sdi_cnt != 8)) begin
                            SI <= music_d[sdi_cnt - 1];
                            sdi_cnt <= sdi_cnt - 1'b1; 
                            sended <= sended + 1'b1;

                            ena <= 1;
                            XDCS <= 1'b0;
                        end
                        else begin      //DREQ拉低，停止传输
                            ena <= 1'b0;
                            XDCS <= 1'b1;
                            SI <= 1'b0;
                        end
                    end
                end                                           

                /*---------------------寄存器配置------------------*/
                default:
                if(cntdown > 0)
                    cntdown <= cntdown - 1'b1;
                else if(sci_w_cnt == 0) begin           //结束一次SCI写入
                    if(state == SET_CLOCKF) begin
                        cntdown <= 32'd11000;
                        state <= PLAY;
                    end
                    else if(state == SET_BASS) begin
                        cntdown <= 32'd2100;
                        sci_w <= 32'h02_03_7000;
                        state <= SET_CLOCKF;
                    end
                    else begin
                        cntdown <= 32'd2100;
                        sci_w <= 32'h02_02_0000;
                        state <= SET_BASS;
                    end
                    sci_w_cnt <= 8'd32;
                    XCS <= 1'b1;
                    ena <= 1'b0;
                    SI <= 1'b0;
                end
                else if(DREQ) begin                     //写入SCI指令、地址、数据
                    XCS <= 1'b0;
                    ena <= 1'b1;
                    SI <= sci_w[sci_w_cnt - 1];
                    sci_w_cnt <= sci_w_cnt - 1'b1;
                end
                else begin                              //DREQ拉低，等待
                    XCS <= 1'b1;
                    ena <= 1'b0;
                    SI <= 1'b0;
                end
            endcase
        end

        //当缓冲区清空时，从ROM中读取新数据
        if(!b_emp && addra < MAX_ADDRA && state != H_RESET && state != WAITE) begin
            buffer <= douta;
            b_emp <= 1'b1;
            addra <= addra + 1'b1;
        end
        else;
    end

    blk_mem_gen_0 muisic_mem (
    .clka(clk),             // 时钟
    .addra(addra),          // 地址
    .douta(douta)           // 数据输出
    );
endmodule
