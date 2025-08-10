`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/08 20:57:09
// Design Name: 
// Module Name: fsm_tx
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


module fsm_tx(
    input clk,
    input rstn,
    input multi_byte_send_en,
    input [DATA_WIDTH-1:0] multi_byte_data_in,
    input tx_done,
    output reg send_en,
    output reg[7:0] data_byte,
    output reg multi_byte_tx_done
    );

    /*--------状态字设置-------*/
    localparam S0 = 0; //等待发送
    localparam S1 = 1; //发起单字节数据发送
    localparam S2 = 2; //等待单字节数据发送完成
    localparam S3 = 3; //检查所有数据是否发送完成

    reg [1:0] fsm_state;
    parameter DATA_WIDTH = 32;
    parameter MSB_1st = 1;

    /*--------状态转移--------*/
    reg [DATA_WIDTH-1:0] data_reg;
    reg [7:0] bit_cnt;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            fsm_state <= S0;
            data_byte <= 0;
        end
        else begin
            case (fsm_state)
                S0:begin
                    bit_cnt <= 0;
                    multi_byte_tx_done <= 0;
                    if(multi_byte_send_en) begin
                        fsm_state <= S1;
                        data_reg <= multi_byte_data_in;
                    end
                    else begin
                        fsm_state <= S0;
                        data_reg <= data_reg;
                    end
                end
                S1:begin
                    send_en <= 1;
                    if(MSB_1st == 1) begin
                        data_byte <= data_reg[DATA_WIDTH-1:DATA_WIDTH-8];
                        data_reg <= data_reg << 8;
                    end
                    else begin
                        data_byte <= data_reg[7:0];
                        data_reg <= data_reg >> 8;
                    end
                    fsm_state <= S2;
                end
                S2:begin
                    send_en <= 0;
                    if(tx_done)begin
                        fsm_state <= S3;
                        bit_cnt <= bit_cnt + 8'd8;
                    end
                    else
                        fsm_state <= S2;
                end
                S3:begin
                    if(bit_cnt == DATA_WIDTH)begin
                        fsm_state <= S0;
                        bit_cnt <= 0;
                        multi_byte_tx_done <= 1;
                    end
                    else begin
                        fsm_state <= S1;
                        multi_byte_tx_done <= 0;
                    end  
                end
            endcase
        end
    end
endmodule
