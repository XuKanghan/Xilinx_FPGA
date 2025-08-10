`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/08 20:59:25
// Design Name: 
// Module Name: multi_byte_tx
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


module multi_byte_tx (
    input clk,
    input rstn,
    input multi_byte_send_en,    
    input [2:0] baud_set, 
    input [DATA_WIDTH-1:0] multi_byte_data_in,
    output uart_tx,
    output uart_state,
    output multi_byte_tx_done
    );

    wire tx_done;
    wire send_en;
    wire [7:0] data_byte;

    parameter DATA_WIDTH = 32;
    parameter MSB_1st = 1;

    fsm_tx u1_fsm_tx(
        .clk(clk),
        .rstn(rstn),
        .multi_byte_send_en(multi_byte_send_en),
        .multi_byte_data_in(multi_byte_data_in),
        .tx_done(tx_done),
        .send_en(send_en),
        .data_byte(data_byte),
        .multi_byte_tx_done(multi_byte_tx_done)
    );

    uart_tx u2_uart_tx(
        .clk(clk),
        .rstn(rstn),
        .send_en(send_en),
        .baud_set(baud_set),
        .data_byte(data_byte),
        .uart_tx(uart_tx),
        .tx_done(tx_done),
        .uart_state(uart_state)
    );


endmodule
