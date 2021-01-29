`timescale 1ns / 1ps

module vga(
    input   clk25MHZ,               //25MHZ时钟
    input   rst,                    //复位

    input               bk_g,       //背景图信号
    input      [434:0]  col1,       //第一列滑块位置
    input      [434:0]  col2,       //第一列滑块位置
    input      [434:0]  col3,       //第一列滑块位置
    input      [434:0]  col4,       //第一列滑块位置
    input      [3:0]    hits,       //按钮敲击信号
    input      [2:0]    msg,        //显示信息

    output reg [3:0]    color_r,    //红色分量
    output reg [3:0]    color_g,    //绿色分量
    output reg [3:0]    color_b,    //蓝色分量
    output              hs,         //行同步
    output              vs          //场同步
    );

    parameter   HS_SYNC     = 96,   //同步
                HS_BACK     = 48,   //后沿
                HS_ACTIVE   = 640,  //显示区
                HS_FRONT    = 16;   //前沿

    parameter   VS_SYNC     = 2,    //同步
                VS_BACK     = 33,   //后沿
                VS_ACTIVE   = 480,  //显示区
                VS_FRONT    = 10;   //前沿

    parameter COL = 800;
    parameter ROW = 525;

    reg [11:0]  h_cnt = 12'd0;      //列计数
    reg [11:0]  v_cnt = 12'd0;      //行计数
    wire        active;             //有效标志

    reg  [16:0]  addra   = 0;       //ROM地址
    wire [11:0]  douta;             //数据输出

    wire [48:0]  msg_arr[6:0];      //字模

    //控制显示
    always @(posedge clk25MHZ) begin
        if(active) begin
            if(v_cnt > VS_SYNC + VS_BACK + 12'd410 && v_cnt <= VS_SYNC + VS_BACK + 12'd434)    //下方横线
                {color_r, color_g, color_b} <=  (bk_g)? 12'h49f:
                                                (h_cnt >= HS_SYNC + HS_BACK + 12'd100 && h_cnt <= HS_SYNC + HS_BACK + 12'd130)? (hits[0]? 12'hff0:12'h808):
                                                (h_cnt >= HS_SYNC + HS_BACK + 12'd230 && h_cnt <= HS_SYNC + HS_BACK + 12'd260)? (hits[1]? 12'hff0:12'h808):
                                                (h_cnt >= HS_SYNC + HS_BACK + 12'd360 && h_cnt <= HS_SYNC + HS_BACK + 12'd390)? (hits[2]? 12'hff0:12'h808):
                                                (h_cnt >= HS_SYNC + HS_BACK + 12'd490 && h_cnt <= HS_SYNC + HS_BACK + 12'd520)? (hits[3]? 12'hff0:12'h808): 12'haaa;
            else if(bk_g && v_cnt > VS_SYNC + VS_BACK + 12'd100 && v_cnt <= VS_SYNC + VS_BACK + 12'd340 && h_cnt > HS_SYNC + HS_BACK + 12'd150 && h_cnt <= HS_SYNC + HS_BACK + 12'd470) begin
                //背景图片
                {color_r, color_g, color_b} <= douta;
                addra <= (v_cnt - (VS_SYNC + VS_BACK) - 12'd101)*12'd320 + (h_cnt - (HS_SYNC + HS_BACK) - 12'd150);
            end
            else begin
                //背景色与下落音符
                {color_r, color_g, color_b} <=  (col1[v_cnt - (VS_SYNC + VS_BACK)] && h_cnt >= HS_SYNC + HS_BACK + 12'd100 && h_cnt <= HS_SYNC + HS_BACK + 12'd130)? (12'hf00):
                                                (col2[v_cnt - (VS_SYNC + VS_BACK)] && h_cnt >= HS_SYNC + HS_BACK + 12'd230 && h_cnt <= HS_SYNC + HS_BACK + 12'd260)? (12'hf00):
                                                (col3[v_cnt - (VS_SYNC + VS_BACK)] && h_cnt >= HS_SYNC + HS_BACK + 12'd360 && h_cnt <= HS_SYNC + HS_BACK + 12'd390)? (12'hf00):
                                                (col4[v_cnt - (VS_SYNC + VS_BACK)] && h_cnt >= HS_SYNC + HS_BACK + 12'd490 && h_cnt <= HS_SYNC + HS_BACK + 12'd520)? (12'hf00): 
                                                (h_cnt >= HS_SYNC + HS_BACK + 12'd530 && h_cnt < HS_SYNC + HS_BACK + 12'd579 && v_cnt >= VS_SYNC + VS_BACK + 12'd50 && v_cnt < VS_SYNC + VS_BACK + 12'd57 && msg_arr[v_cnt - (VS_SYNC + VS_BACK) - 12'd50][h_cnt - (HS_SYNC + HS_BACK) - 12'd530])? 12'h000:12'h49f;
            end
        end
        else begin
            {color_r, color_g, color_b} <= 12'h000;
        end
    end

    //行时序
    always @(posedge clk25MHZ or negedge rst) begin
        if(!rst)
            h_cnt <= 12'd0;
        else if(h_cnt == COL)
            h_cnt <= 12'd0;
        else
            h_cnt <= h_cnt + 1'b1;
    end

    //场时序
    always @(posedge clk25MHZ or negedge rst) begin
        if(!rst)
            v_cnt <= 12'd0;
        else if(v_cnt == ROW)
            v_cnt <= 12'd0;
        else if(h_cnt == COL)
            v_cnt <= v_cnt + 1'b1;
        else
            v_cnt <= v_cnt;
    end

    assign hs = (h_cnt < HS_SYNC)? 1'b0 : 1'b1;
    assign vs = (v_cnt < VS_SYNC)? 1'b0 : 1'b1;
    assign active =  (h_cnt >= (HS_SYNC + HS_BACK))  &&                 
                    (h_cnt <= (HS_SYNC + HS_BACK + HS_ACTIVE))  && 
                    (v_cnt >= (VS_SYNC + VS_BACK))  &&
                    (v_cnt <= (VS_SYNC + VS_BACK + VS_ACTIVE))  ;

    char_set char(
        .rst(rst),
        .msg(msg),

        .row1(msg_arr[0]),
        .row2(msg_arr[1]),
        .row3(msg_arr[2]),
        .row4(msg_arr[3]),
        .row5(msg_arr[4]),
        .row6(msg_arr[5]),
        .row7(msg_arr[6])
    );
    blk_mem_gen_2 bkg (
        .clka(clk25MHZ),    // 时钟
        .addra(addra),      // 地址
        .douta(douta)       // 输出数据
    );
endmodule
