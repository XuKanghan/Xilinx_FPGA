`timescale 1ns / 1ps

module uart_tx(
    input clk,
    input rstn,
    input send_en,
    input [2:0] baud_set,
    input [7:0] data_byte,
    output reg uart_tx,
    output reg tx_done,
    output reg uart_state
    );

    /*--------bps generation--------*/
    reg [15:0] bps_DR;
    reg [15:0] div_cnt;
    reg bps_clk;

    //1.1 bps setting
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bps_DR <= 16'd5207;
        end
        else begin
            case (baud_set)
                0:bps_DR <= 16'd5207; //9600
                1:bps_DR <= 16'd2603; //19200
                2:bps_DR <= 16'd1301; //38400
                3:bps_DR <= 16'd867; //57600
                4:bps_DR <= 16'd433;  //115200
                default: bps_DR <= 16'd5207;
            endcase
        end
    end

    //1.2 counter for bps clock
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            div_cnt <= 16'd0;
        end
        else if (uart_state) begin
            if (div_cnt == bps_DR) begin
                div_cnt <= 16'd0;
            end
            else begin
                div_cnt <= div_cnt + 1'b1;
            end
        end
        else
            div_cnt <= 16'd0;
    end
    
    //1.3 bps clock generation (pulse)
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            bps_clk <= 1'b0;
        end
        else if (div_cnt == 16'd1) begin
            bps_clk <= 1'b1;
        end
        else
            bps_clk <= 1'b0;
    end


    /*--------transmit state--------*/
    reg [3:0] bps_cnt;
    reg [7:0] data_byte_reg;

    //2.1 bps conter
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bps_cnt <= 4'd0;
        end
        else if (bps_cnt == 4'd11) begin //11bit
            bps_cnt <= 4'd0;
        end
        else if(bps_clk) begin
            bps_cnt <= bps_cnt +1'b1;
        end
        else
            bps_cnt <= bps_cnt;
    end

    //2.2 tx_done
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tx_done <= 1'b0;
        end
        else if (bps_cnt == 4'd11) begin //11bit
            tx_done <= 1'b1;
        end
        else begin
            tx_done <= 1'b0;
        end
    end

    //2.3 uart_state
    always @(posedge clk or negedge rstn) begin
        if(!rstn)begin
            uart_state <= 1'b0;
        end
        else if (send_en) begin
            uart_state <= 1'b1;
        end
        else if (bps_cnt == 4'd11) begin
            uart_state <= 1'b0;
        end
        else
            uart_state <= uart_state;
    end

    //2.4 transimit buffer
    always @(posedge clk or negedge rstn) begin
        if(!rstn)begin
            data_byte_reg <= 8'b0;
        end
        else if (send_en) begin
            data_byte_reg <= data_byte;
        end
        else
            data_byte_reg <= data_byte_reg;
    end

    /*--------transmition--------*/
    parameter START_BIT = 1'b0;
    parameter STOP_BIT = 1'b1;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            uart_tx <= 1'b1;
        end
        else begin
            case (bps_cnt)
                0:uart_tx <= 1'b1;
                1:uart_tx <= START_BIT;
                2:uart_tx <= data_byte_reg[0];
                3:uart_tx <= data_byte_reg[1];
                4:uart_tx <= data_byte_reg[2];
                5:uart_tx <= data_byte_reg[3];
                6:uart_tx <= data_byte_reg[4];
                7:uart_tx <= data_byte_reg[5];
                8:uart_tx <= data_byte_reg[6];
                9:uart_tx <= data_byte_reg[7];
                10:uart_tx <= STOP_BIT;
                11:uart_tx <= 1'b1;
            endcase
        end
    end

endmodule

