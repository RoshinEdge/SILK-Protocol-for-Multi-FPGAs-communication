`timescale 1ns / 1ps
// Физический адаптер Kintex-7 на основе GTXE2_CHANNEL.
// Принятая частота опорного дифференциального сигнала GTREFCLK: 125 МГц.
// Номинальная линейная скорость: 2,5 Гбит/с; включено 8b/10b; данные шириной 32 бита и 4 флага K-символов.
// Параметры тактирования и сброса GT необходимо проверить для конкретной платы
// и настроек Transceiver Wizard в Vivado до использования аппаратной реализации.
module silk_gtx_kintex7 (
    input  wire        sys_clk,
    input  wire        rst_n,
    input  wire        gt_refclk_p,
    input  wire        gt_refclk_n,
    input  wire        rxp,
    input  wire        rxn,
    output wire        txp,
    output wire        txn,

    input  wire        tx_valid,
    input  wire [31:0] tx_data,
    input  wire [3:0]  tx_charisk,
    output wire        tx_ready,

    output wire        tx_usrclk,
    output wire        rx_usrclk,
    output wire        rx_valid,
    output wire [31:0] rx_data,
    output wire [3:0]  rx_charisk,
    output wire        link_up
);
    wire gt_refclk;
    wire gt_refclk_div2;
    wire txoutclk_i;
    wire rxoutclk_i;
    wire cplllock;
    wire txresetdone;
    wire rxresetdone;
    wire rxbyteisaligned;
    wire rxbyterealign;
    wire [31:0] rxdata_i;
    wire [3:0]  rxcharisk_i;

    reg cpllreset;
    reg gttxreset;
    reg gtrxreset;
    reg txuserrdy;
    reg rxuserrdy;
    reg [2:0] reset_state;
    reg [7:0] reset_count;

    localparam [2:0] R_HOLD       = 3'd0;
    localparam [2:0] R_WAIT_LOCK  = 3'd1;
    localparam [2:0] R_WAIT_USER  = 3'd2;
    localparam [2:0] R_RELEASE_GT = 3'd3;
    localparam [2:0] R_WAIT_DONE  = 3'd4;

    IBUFDS_GTE2 u_refclk_buf (
        .I    (gt_refclk_p),
        .IB   (gt_refclk_n),
        .CEB  (1'b0),
        .O    (gt_refclk),
        .ODIV2(gt_refclk_div2)
    );

    // Пользовательские тактовые сигналы GTX подаются через глобальные буферы тактирования.
    BUFG u_txoutclk_buf (
        .I(txoutclk_i),
        .O(tx_usrclk)
    );
    BUFG u_rxoutclk_buf (
        .I(rxoutclk_i),
        .O(rx_usrclk)
    );

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            cpllreset   <= 1'b1;
            gttxreset   <= 1'b1;
            gtrxreset   <= 1'b1;
            txuserrdy   <= 1'b0;
            rxuserrdy   <= 1'b0;
            reset_state <= R_HOLD;
            reset_count <= 8'd0;
        end else begin
            case (reset_state)
                R_HOLD: begin
                    cpllreset <= 1'b1;
                    gttxreset <= 1'b1;
                    gtrxreset <= 1'b1;
                    txuserrdy <= 1'b0;
                    rxuserrdy <= 1'b0;
                    if (reset_count == 8'd31) begin
                        reset_count <= 8'd0;
                        cpllreset   <= 1'b0;
                        reset_state <= R_WAIT_LOCK;
                    end else begin
                        reset_count <= reset_count + 1'b1;
                    end
                end

                R_WAIT_LOCK: begin
                    cpllreset <= 1'b0;
                    if (cplllock) begin
                        reset_count <= 8'd0;
                        reset_state <= R_WAIT_USER;
                    end
                end

                R_WAIT_USER: begin
                    // После захвата ФАПЧ следует удерживать GTX в сбросе, пока сигналы готовности пользовательского интерфейса
                    // не будут активированы и не получат время для распространения.
                    if (reset_count == 8'd63) begin
                        reset_count <= 8'd0;
                        txuserrdy   <= 1'b1;
                        rxuserrdy   <= 1'b1;
                        reset_state <= R_RELEASE_GT;
                    end else begin
                        reset_count <= reset_count + 1'b1;
                    end
                end

                R_RELEASE_GT: begin
                    if (reset_count == 8'd15) begin
                        reset_count <= 8'd0;
                        gttxreset   <= 1'b0;
                        gtrxreset   <= 1'b0;
                        reset_state <= R_WAIT_DONE;
                    end else begin
                        reset_count <= reset_count + 1'b1;
                    end
                end

                R_WAIT_DONE: begin
                    if (!cplllock) begin
                        cpllreset   <= 1'b1;
                        gttxreset   <= 1'b1;
                        gtrxreset   <= 1'b1;
                        txuserrdy   <= 1'b0;
                        rxuserrdy   <= 1'b0;
                        reset_count <= 8'd0;
                        reset_state <= R_HOLD;
                    end
                end

                default: reset_state <= R_HOLD;
            endcase
        end
    end

    assign link_up  = (reset_state == R_WAIT_DONE) && cplllock && txresetdone && rxresetdone;
    // На параллельных выводах GTX нет интерфейса valid/ready. Пользовательская логика продвигается
    // только при готовности канала; управляющие символы-заполнители поддерживают выравнивание по байтам.
    assign tx_ready = link_up;
    assign rx_valid = link_up;
    assign rx_data  = rxdata_i;
    assign rx_charisk = rxcharisk_i;

    GTXE2_CHANNEL #(
        .CPLL_FBDIV          (4),
        .CPLL_FBDIV_45       (5),
        .CPLL_REFCLK_DIV     (1),
        .CPLL_CFG             (24'hBC07DC),
        .CPLL_INIT_CFG        (24'h00001E),
        .CPLL_LOCK_CFG        (16'h01E8),
        .TX_DATA_WIDTH        (40),
        .RX_DATA_WIDTH        (40),
        .TX_INT_DATAWIDTH     (1),
        .RX_INT_DATAWIDTH     (1),
        .TXOUT_DIV            (2),
        .RXOUT_DIV            (2),
        .TXBUF_EN             ("TRUE"),
        .RXBUF_EN             ("TRUE"),
        .TX_XCLK_SEL          ("TXUSR"),
        .RX_XCLK_SEL          ("RXUSR"),
        .ALIGN_COMMA_ENABLE   (10'b0001111111),
        .ALIGN_COMMA_WORD     (2),
        .ALIGN_MCOMMA_DET     ("TRUE"),
        .ALIGN_PCOMMA_DET     ("TRUE"),
        .RXSLIDE_MODE         ("OFF")
    ) u_gtxe2_channel (
        .GTREFCLK0            (gt_refclk),
        .GTREFCLK1            (1'b0),
        .GTNORTHREFCLK0       (1'b0),
        .GTNORTHREFCLK1       (1'b0),
        .GTSOUTHREFCLK0       (1'b0),
        .GTSOUTHREFCLK1       (1'b0),
        .GTGREFCLK            (1'b0),
        .QPLLCLK              (1'b0),
        .QPLLREFCLK           (1'b0),
        .CPLLREFCLKSEL        (3'b001),
        .CPLLLOCKDETCLK       (sys_clk),
        .CPLLLOCKEN           (1'b1),
        .CPLLPD               (1'b0),
        .CPLLRESET            (cpllreset),
        .CPLLLOCK             (cplllock),
        .CPLLREFCLKLOST        (),
        .CPLLFBCLKLOST         (),
        .GTRSVD               (16'b0),
        .PCSRSVDIN            (16'b0),
        .PCSRSVDIN2           (5'b0),
        .PMARSVDIN            (5'b0),
        .PMARSVDIN2           (5'b0),
        .TSTIN                (20'hF_FFFF),

        .GTTXRESET            (gttxreset),
        .GTRXRESET            (gtrxreset),
        .TXUSERRDY            (txuserrdy),
        .RXUSERRDY            (rxuserrdy),
        .TXRESETDONE          (txresetdone),
        .RXRESETDONE          (rxresetdone),
        .GTRESETSEL           (1'b0),
        .RESETOVRD            (1'b0),

        .TXUSRCLK             (tx_usrclk),
        .TXUSRCLK2            (tx_usrclk),
        .RXUSRCLK             (rx_usrclk),
        .RXUSRCLK2            (rx_usrclk),
        .TXOUTCLK             (txoutclk_i),
        .RXOUTCLK             (rxoutclk_i),
        .TXOUTCLKSEL          (3'b010),
        .RXOUTCLKSEL          (3'b010),
        .TXSYSCLKSEL          (2'b00),
        .RXSYSCLKSEL          (2'b00),
        .TXRATE               (3'b000),
        .RXRATE               (3'b000),
        .TXDLYBYPASS          (1'b1),
        .RXDLYBYPASS          (1'b1),

        .TXDATA               (tx_valid ? tx_data : 32'h000000BC),
        .TXCHARISK            (tx_valid ? tx_charisk : 4'b0001),
        .TX8B10BEN            (1'b1),
        .TX8B10BBYPASS        (8'b0000_0000),
        .TXCHARDISPMODE       (4'b0000),
        .TXCHARDISPVAL        (4'b0000),
        .TXPOLARITY           (1'b0),
        .TXINHIBIT            (1'b0),
        .TXELECIDLE           (1'b0),
        .TXDEEMPH             (1'b0),
        .TXMARGIN             (3'b000),
        .TXSWING              (1'b0),
        .TXMAINCURSOR         (7'b0000000),
        .TXCOMINIT            (1'b0),
        .TXCOMWAKE            (1'b0),
        .TXCOMSAS             (1'b0),
        .TXDETECTRX           (1'b0),
        .TXPD                 (2'b00),
        .TXPRBSSEL            (3'b000),
        .TXPRBSFORCEERR       (1'b0),

        .RXDATA               (rxdata_i),
        .RXCHARISK            (rxcharisk_i),
        .RX8B10BEN            (1'b1),
        .RXMCOMMAALIGNEN      (1'b1),
        .RXPCOMMAALIGNEN      (1'b1),
        .RXCOMMADETEN         (1'b1),
        .RXSLIDE              (1'b0),
        .RXPOLARITY           (1'b0),
        .RXBUFRESET           (1'b0),
        .RXCDRRESET           (1'b0),
        .RXCDRFREQRESET       (1'b0),
        .RXCDRHOLD            (1'b0),
        .RXCDROVRDEN          (1'b0),
        .RXCDRRESETRSV        (1'b0),
        .RXPD                 (2'b00),
        .RXPRBSSEL            (3'b000),
        .RXPRBSCNTRESET       (1'b0),
        .RXBYTEISALIGNED      (rxbyteisaligned),
        .RXBYTEREALIGN        (rxbyterealign),

        .TXDIFFCTRL           (4'b1000),
        .TXPRECURSOR          (5'b00000),
        .TXPOSTCURSOR         (5'b00000),
        .TXBUFDIFFCTRL        (3'b100),

        .DRPCLK               (sys_clk),
        .DRPADDR              (9'b0),
        .DRPDI                (16'b0),
        .DRPEN                (1'b0),
        .DRPWE                (1'b0),
        .DRPDO                (),
        .DRPRDY               (),

        .TXP                  (txp),
        .TXN                  (txn),
        .RXP                  (rxp),
        .RXN                  (rxn)
    );

    wire unused_refclk_div2 = gt_refclk_div2;
    wire unused_rx_status = rxbyteisaligned ^ rxbyterealign;
endmodule
