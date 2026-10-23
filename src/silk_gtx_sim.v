`timescale 1ns / 1ps
// Поведенческая модель пользовательского интерфейса, используемая в tb_silk_gtx.
// Модель имитирует готовый канал GTX с задержкой в одно пользовательское слово; она НЕ моделирует
// аналоговый последовательный тракт, CPLL/CDR, кодирование 8b/10b или ошибки передачи битов.
module silk_gtx_sim (
    input  wire        sys_clk,
    input  wire        rst_n,
    input  wire        sim_corrupt_next,

    input  wire        tx_valid,
    input  wire [31:0] tx_data,
    input  wire [3:0]  tx_charisk,
    output wire        tx_ready,

    output wire        tx_usrclk,
    output wire        rx_usrclk,
    output reg         rx_valid,
    output reg  [31:0] rx_data,
    output reg  [3:0]  rx_charisk,
    output reg         link_up,

    output wire        txp,
    output wire        txn,
    input  wire        rxp,
    input  wire        rxn
);
    reg [4:0] startup_count;

    assign tx_usrclk = sys_clk;
    assign rx_usrclk = sys_clk;
    assign tx_ready  = link_up;

    // Выводы rxp/rxn в поведенческой модели являются заглушками; параллельный поток слов
    // замыкается непосредственно. В аппаратном режиме используются последовательные выводы GTX.
    assign txp = 1'b0;
    assign txn = 1'b1;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            startup_count <= 5'd0;
            link_up       <= 1'b0;
            rx_valid      <= 1'b0;
            rx_data       <= 32'd0;
            rx_charisk    <= 4'd0;
        end else begin
            if (!link_up) begin
                if (startup_count == 5'd15)
                    link_up <= 1'b1;
                else
                    startup_count <= startup_count + 1'b1;
            end

            rx_valid <= 1'b0;
            if (link_up && tx_valid) begin
                rx_valid   <= 1'b1;
                rx_data    <= tx_data ^ (sim_corrupt_next ? 32'h0000_0001 : 32'h0000_0000);
                rx_charisk <= tx_charisk;
            end
        end
    end

    // В данной тестовой модели на уровне слов выводы rxp/rxn намеренно не используются.
    wire unused_rx_pins = rxp ^ rxn;
endmodule
