`timescale 1ns / 1ps

module gamecontrol(
    input                   clk,        //25MHZ
    input                   rst,

    input                   signal,     //开始与结束按钮
    input       [3:0]       hits,       //按钮

    output  reg [434:0]     col1,       //第一列所有滑块位置
    output  reg [434:0]     col2,       //第二列所有滑块位置
    output  reg [434:0]     col3,       //第三列所有滑块位置
    output  reg [434:0]     col4,       //第四列所有滑块位置

    input                   end_sig,    //音乐播放结束信号
    output                  bk_g,       //游戏开始界面信号
    output                  start,      //开始播放音乐信号

    output      [11:0]      score,      //得分
    output      [2:0]       msg         //提示信息
    );

    parameter   READY   = 1,            //游戏准备阶段
                PLAY    = 2,            //游戏进行阶段
                END     = 3;            //游戏结束阶段

    reg  [7:0]  addra   = 0;            //音符储存ROM地址
    wire [3:0]  douta;                  //ROM输出

    reg [3:0]   state   = READY;        //当前状态
    reg [31:0]  cnt1    = 0;            //音符下落速度控制计时
    reg [31:0]  cnt2    = 0;            //音符出现速度控制计时
    reg [9:0]   cnt3    = 0;
    reg         not_f   = 0;            //是否读取新音符

    reg [11:0]  score1  = 0;            //四个按键的分数统计
    reg [11:0]  score2  = 0;
    reg [11:0]  score3  = 0;
    reg [11:0]  score4  = 0;
    reg [2:0]   msgs[3:0];              //每个按键的击中提示信息

    assign score = score1 + score2 + score3 + score4;
    assign msg =    (msgs[0] != 0)? msgs[0]:
                    (msgs[1] != 0)? msgs[1]:
                    (msgs[2] != 0)? msgs[2]:
                    (msgs[3] != 0)? msgs[3]:0;

    //音符获取下落与击中
    always @(posedge clk) begin
        if(cnt1 < 32'd100000) begin
            cnt1 <= cnt1 + 1'b1;

            if(state == PLAY)begin
                //灌入新的音符下落
                if(cnt2 == 0) begin
                    addra <= addra + 1;
                    cnt2 <= 32'd1;
                    not_f <= 1;
                end
                else if(not_f) begin
                    col1[23:0] <= (douta[0])? 24'hffffff : col1[23:0];
                    col2[23:0] <= (douta[1])? 24'hffffff : col2[23:0];
                    col3[23:0] <= (douta[2])? 24'hffffff : col3[23:0];
                    col4[23:0] <= (douta[3])? 24'hffffff : col4[23:0];
                    not_f <= 0;
                    cnt2 <= cnt2 + 1;
                end
                else
                    cnt2 <= (cnt2 < 32'd12500000)? cnt2 + 1 : 0;

                //检测击中
                score1 <= (~hits[0] || col1[434:387] < 48'hffffff)? score1:
                    (col1[434:387] <= 48'h0000ff_ffff00)? score1 + 12'd1:                        //ok
                    (col1[434:387] <= 48'h00ffff_ff0000)? score1 + 12'd5:score1 + 12'd10;         //good perfect
                col1[434:387] <= (~hits[0] || col1[434:387] < 48'hffffff)? col1[434:387]:48'h0;
                msgs[0] <= (~hits[0] || col1[434:387] < 48'hffffff)? msgs[0]:
                    (col1[434:387] <= 48'h0000ff_ffff00)? 3'd3:              //ok
                    (col1[434:387] <= 48'h00ffff_ff0000)? 3'd2:3'd1;         //good perfect

                score2 <= (~hits[1] || col2[434:387] < 48'hffffff)? score2:
                    (col2[434:387] <= 48'h0000ff_ffff00)? score2 + 12'd1:                        //ok
                    (col2[434:387] <= 48'h00ffff_ff0000)? score2 + 12'd5:score2 + 12'd10;         //good perfect
                col2[434:387] <= (~hits[1] || col2[434:387] < 48'hffffff)? col2[434:387]:48'h0;
                msgs[1] <= (~hits[1] || col2[434:387] < 48'hffffff)? msgs[1]:
                    (col2[434:387] <= 48'h0000ff_ffff00)? 3'd3:                 //ok
                    (col2[434:387] <= 48'h00ffff_ff0000)? 3'd2:3'd1;            //good perfect

                score3 <= (~hits[2] || col3[434:387] < 48'hffffff)? score3:
                    (col3[434:387] <= 48'h0000ff_ffff00)? score3 + 12'd1:                        //ok
                    (col3[434:387] <= 48'h00ffff_ff0000)? score3 + 12'd5:score3 + 12'd10;         //good perfect
                col3[434:387] <= (~hits[2] || col3[434:387] < 48'hffffff)? col3[434:387]:48'h0;
                msgs[2] <= (~hits[2] || col3[434:387] < 48'hffffff)? msgs[2]:
                    (col3[434:387] <= 48'h0000ff_ffff00)? 3'd3:                 //ok
                    (col3[434:387] <= 48'h00ffff_ff0000)? 3'd2:3'd1;            //good perfect
                
                score4 <= (~hits[3] || col4[434:387] < 48'hffffff)? score4:
                    (col4[434:387] <= 48'h0000ff_ffff00)? score4 + 12'd1:                        //ok
                    (col4[434:387] <= 48'h00ffff_ff0000)? score4 + 12'd5:score4 + 12'd10;         //good perfect
                col4[434:387] <= (~hits[3] || col4[434:387] < 48'hffffff)? col4[434:387]:48'h0;
                msgs[3] <= (~hits[3] || col4[434:387] < 48'hffffff)? msgs[3]:
                    (col4[434:387] <= 48'h0000ff_ffff00)? 3'd3:                 //ok
                    (col4[434:387] <= 48'h00ffff_ff0000)? 3'd2:3'd1;            //good perfect
            end
            else if(state == READY) begin
                score1 <= 0;
                score2 <= 0;
                score3 <= 0;
                score4 <= 0;
                msgs[0] = 3'd0;
                msgs[1] = 3'd0;
                msgs[2] = 3'd0;
                msgs[3] = 3'd0;
            end
            else begin
                col1 <= 435'd0;
                col2 <= 435'd0;
                col3 <= 435'd0;
                col4 <= 435'd0;
                addra <= 8'd0;
            end
        end
        else begin
            cnt1 <= 32'd0;
            cnt3 <= cnt3 + 1;
            if(cnt3 == 10'd600) begin
                msgs[0] <= 0;
                msgs[1] <= 0;
                msgs[2] <= 0;
                msgs[3] <= 0;
                cnt3 <= 0;
            end
            
            //音符下落移动
            col1 <= col1 << 1;
            col2 <= col2 << 1;
            col3 <= col3 << 1;
            col4 <= col4 << 1;
        end
    end

    //状态转移
    always @(posedge clk) begin
        if(!rst) begin
            state <= READY;
        end
        else begin
            case (state)
                READY:
                    if(signal)
                        state <= PLAY;
                    else
                        state <= state;
                PLAY:
                    if(addra == 8'd176)
                        state <= END;
                    else
                        state <= state;
                default:
                    if(~signal && end_sig)
                        state <= READY;
                    else
                        state <= state;
            endcase
        end
    end
    assign start = (state == PLAY && signal);
    assign bk_g  = (state == READY);

    //储存音符下落顺序ROM
    blk_mem_gen_1 muisic_note (
    .clka(clk),             // 时钟输入
    .addra(addra),          // 地址线
    .douta(douta)           // 输出数据
    );
endmodule
