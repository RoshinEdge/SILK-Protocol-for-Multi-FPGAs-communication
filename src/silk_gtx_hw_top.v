`timescale 1ns / 1ps
// Верхний модуль аппаратной реализации для GTXE2_CHANNEL в Kintex-7.
// Сигналы src_vector/src_valid должны быть синхронны tx_usrclk. Если логика-источник
// работает от другого тактового сигнала, перед SILK следует добавить асинхронный FIFO/узел пересечения тактовых доменов.
module silk_gtx_hw_top (
    input  wire        sys_clk_p,
    input  wire        sys_clk_n,
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
    output wire        tx_usrclk,
    output wire        rx_usrclk
);
    wire sys_clk;
    wire unused_header_error_debug;
    wire unused_tx_word_valid;
    wire [31:0] unused_tx_word_data;
    wire [3:0] unused_tx_word_charisk;
    wire unused_rx_word_valid;
    wire [31:0] unused_rx_word_data;
    wire [3:0] unused_rx_word_charisk;

    IBUFDS u_sys_clk_buf (
        .I(sys_clk_p),
        .IB(sys_clk_n),
        .O(sys_clk)
    );

    silk_top #(
        .USE_GTX_PRIMITIVE(1),
        .MAP_ID(8'h42)
    ) u_silk (
        .sys_clk              (sys_clk),
        .rst_n                (rst_n),
        .gt_refclk_p          (gt_refclk_p),
        .gt_refclk_n          (gt_refclk_n),
        .rxp                  (rxp),
        .rxn                  (rxn),
        .txp                  (txp),
        .txn                  (txn),
        .src_vector           (src_vector),
        .src_valid            (src_valid),
        .src_ready            (src_ready),
        .rx_vector            (rx_vector),
        .frame_commit         (frame_commit),
        .frame_valid          (frame_valid),
        .crc_error_pulse      (crc_error_pulse),
        .header_error_pulse   (unused_header_error_debug),
        .sequence_error_pulse (sequence_error_pulse),
        .link_up              (link_up),
        .tx_word_valid        (unused_tx_word_valid),
        .tx_word_data         (unused_tx_word_data),
        .tx_word_charisk      (unused_tx_word_charisk),
        .rx_word_valid        (unused_rx_word_valid),
        .rx_word_data         (unused_rx_word_data),
        .rx_word_charisk      (unused_rx_word_charisk),
        .tx_usrclk            (tx_usrclk),
        .rx_usrclk            (rx_usrclk),
        .sim_corrupt_next     (1'b0)
    );
endmodule
