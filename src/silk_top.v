`timescale 1ns / 1ps
// Общий верхний модуль протокола SILK.
// USE_GTX_PRIMITIVE=0 выбирает поведенческую модель канала для быстрого запуска тестбенча.
// USE_GTX_PRIMITIVE=1 выбирает адаптер Kintex-7 на основе GTXE2_CHANNEL.
module silk_top #(
    parameter integer USE_GTX_PRIMITIVE = 1,
    parameter [7:0] MAP_ID = 8'h42
) (
    input  wire        sys_clk,
    input  wire        rst_n,
    input  wire        gt_refclk_p,
    input  wire        gt_refclk_n,
    input  wire        rxp,
    input  wire        rxn,
    output wire        txp,
    output wire        txn,

    input  wire [63:0] src_vector,
    input  wire        src_valid,
    output wire        src_ready,

    output wire [63:0] rx_vector,
    output wire        frame_commit,
    output wire        frame_valid,
    output wire        crc_error_pulse,
    output wire        header_error_pulse,
    output wire        sequence_error_pulse,
    output wire        link_up,

    // Сигналы для наглядной временной диаграммы статьи: только параллельные словные интерфейсы.
    output wire        tx_word_valid,
    output wire [31:0] tx_word_data,
    output wire [3:0]  tx_word_charisk,
    output wire        rx_word_valid,
    output wire [31:0] rx_word_data,
    output wire [3:0]  rx_word_charisk,
    output wire        tx_usrclk,
    output wire        rx_usrclk,

    // Внесение ошибки используется только в тестбенче. Игнорируется при USE_GTX_PRIMITIVE=1.
    input  wire        sim_corrupt_next
);
    wire tx_word_ready;
    wire [31:0] phy_rx_data;
    wire [3:0] phy_rx_charisk;
    wire phy_rx_valid;
    wire core_rst_tx = (~rst_n) | (~link_up);
    wire core_rst_rx = (~rst_n) | (~link_up);

    assign rx_word_valid  = phy_rx_valid;
    assign rx_word_data   = phy_rx_data;
    assign rx_word_charisk = phy_rx_charisk;

    silk_tx #(.MAP_ID(MAP_ID)) u_tx (
        .clk             (tx_usrclk),
        .rst             (core_rst_tx),
        .link_up         (link_up),
        .src_vector      (src_vector),
        .src_valid       (src_valid),
        .src_ready       (src_ready),
        .tx_word_valid   (tx_word_valid),
        .tx_word_data    (tx_word_data),
        .tx_word_charisk (tx_word_charisk),
        .tx_word_ready   (tx_word_ready)
    );

    silk_rx #(.MAP_ID(MAP_ID)) u_rx (
        .clk                  (rx_usrclk),
        .rst                  (core_rst_rx),
        .rx_word_valid        (phy_rx_valid),
        .rx_word_data         (phy_rx_data),
        .rx_word_charisk      (phy_rx_charisk),
        .rx_vector            (rx_vector),
        .frame_commit         (frame_commit),
        .frame_valid          (frame_valid),
        .crc_error_pulse      (crc_error_pulse),
        .header_error_pulse   (header_error_pulse),
        .sequence_error_pulse (sequence_error_pulse)
    );

    generate
        if (USE_GTX_PRIMITIVE == 0) begin : g_behavioral_phy
            silk_gtx_sim u_phy (
                .sys_clk          (sys_clk),
                .rst_n            (rst_n),
                .sim_corrupt_next (sim_corrupt_next),
                .tx_valid         (tx_word_valid),
                .tx_data          (tx_word_data),
                .tx_charisk       (tx_word_charisk),
                .tx_ready         (tx_word_ready),
                .tx_usrclk        (tx_usrclk),
                .rx_usrclk        (rx_usrclk),
                .rx_valid         (phy_rx_valid),
                .rx_data          (phy_rx_data),
                .rx_charisk       (phy_rx_charisk),
                .link_up          (link_up),
                .txp              (txp),
                .txn              (txn),
                .rxp              (rxp),
                .rxn              (rxn)
            );
        end else begin : g_gtx_primitive
            silk_gtx_kintex7 u_phy (
                .sys_clk     (sys_clk),
                .rst_n       (rst_n),
                .gt_refclk_p (gt_refclk_p),
                .gt_refclk_n (gt_refclk_n),
                .rxp         (rxp),
                .rxn         (rxn),
                .txp         (txp),
                .txn         (txn),
                .tx_valid    (tx_word_valid),
                .tx_data     (tx_word_data),
                .tx_charisk  (tx_word_charisk),
                .tx_ready    (tx_word_ready),
                .tx_usrclk   (tx_usrclk),
                .rx_usrclk   (rx_usrclk),
                .rx_valid    (phy_rx_valid),
                .rx_data     (phy_rx_data),
                .rx_charisk  (phy_rx_charisk),
                .link_up     (link_up)
            );
        end
    endgenerate
endmodule
