`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/09 22:34:16
// Design Name: 
// Module Name: key_filter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module key_filter(
    input clk, //50MHz时钟
    input rstn, //低电平复位
    input key_in, //原始信号
    output reg key_flag, //边沿检测标志位
    output reg key_state //按键真实状态
    );

    /*--------时序同步--------*/
    reg [1:0] key_in_sync;
    reg [1:0] key_in_reg;
    wire key_in_posedge;
    wire key_in_negedge;

    //1.1 将输入的按键信号与时序同步
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            key_in_sync <= 2'b0;
        else begin
            key_in_sync[0] <= key_in;
            key_in_sync[1] <= key_in_sync[0];
        end
    end

    //1.2 将同步后的按键时序电平保存到触发器
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            key_in_reg <= 2'b0;
        else begin
            key_in_reg[0] <= key_in_sync[1];
            key_in_reg[1] <= key_in_reg[0];
        end
    end

    //1.3 边沿判断逻辑
    assign key_in_negedge = key_in_reg[1] & !key_in_reg[0];
    assign key_in_posedge = !key_in_reg[1] & key_in_reg[0];

    /*--------20ms溢出计数器--------*/
    reg [19:0] cnt; 
    reg overflow_flag; //溢出标志位
    reg cnt_en;

    //2.1 自增计数器(20ms溢出一次)
    always @(posedge clk or negedge rstn) begin
        if(!rstn) 
            cnt <= 20'd0;
        else if(cnt_en)
            cnt <= cnt + 1;
        else
            cnt <= 20'd0;
    end

    //2.2 溢出脉冲产生
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            overflow_flag <= 1'b0;
        else if(cnt == 20'd999_999)
            overflow_flag <= 1'b1;
        else
            overflow_flag <= 1'b0;
    end

    /*--------状态机--------*/
    localparam IDLE = 4'b0001;
    localparam FILTER0 = 4'b0010;
    localparam DOWN = 4'b0100;
    localparam FILTER1 = 4'b1000;
    reg [3:0] STATE;

    //3.1 状态转移逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt_en <= 1'b0;
            key_flag <= 1'b0;
            key_state <= 1'b1;
            STATE <= IDLE;
        end
        else begin
            case (STATE)
                //S0 初状态
                IDLE:begin
                    key_flag <= 1'b0;
                    //若检测到低电平，进入按键按下消抖
                    if (key_in_negedge) begin
                        STATE <= FILTER0;
                        cnt_en <= 1'b1;
                    end
                    else
                        STATE <= IDLE;
                end
                //S1 确定下降沿的20ms内有无上升沿
                FILTER0:begin
                    //若无，则说明已稳定到低电平
                    if (overflow_flag) begin
                        key_flag <= 1'b1; //检测到边沿
                        key_state <= 1'b0; //低电平
                        cnt_en <= 1'b0; //停止20ms计数使能
                        STATE <= DOWN;
                    end
                    //若有，重新回到初始状态
                    else if (key_in_posedge) begin
                        STATE <= IDLE;
                        cnt_en <= 1'b0;
                    end
                    else
                        STATE <= FILTER0;
                end
                //S2 确定低电平
                DOWN: begin
                    key_flag <= 1'b0;
                    //若检测到上升沿，进入按键释放消抖
                    if (key_in_posedge) begin
                        STATE <= FILTER1;
                        cnt_en <= 1'b1;
                    end
                    else 
                        STATE <= DOWN;
                end
                //S3 确定20ms内有无下降沿
                FILTER1:begin
                    //若无，则完成释放，状态机回复初状态
                    if (overflow_flag) begin
                        key_flag <= 1'b1;
                        key_state <= 1'b1;
                        cnt_en <= 1'b0;
                        STATE <= IDLE;
                    end
                    //若有，则返回DOWN
                    else if (key_in_negedge) begin
                        STATE <= DOWN;
                        cnt_en <= 1'b0;
                    end
                    else
                        STATE <= FILTER1;
                end

                default: begin
                    cnt_en <= 1'b0;
                    key_flag <= 1'b0;
                    key_state <= 1'b1;
                    STATE <= IDLE;
                end
            endcase
        end
    end

endmodule
