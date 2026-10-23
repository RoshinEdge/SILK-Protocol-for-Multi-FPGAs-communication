`timescale 1ns / 1ps
// Сквозной тестбенч протокола с поведенческой моделью GTX на уровне параллельных слов.
// Физическая оболочка GTXE2_CHANNEL выбирается в синтезируемом верхнем модуле параметром
// USE_GTX_PRIMITIVE=1. Данный тестбенч намеренно использует быструю поведенческую
// модель, чтобы CRC, кадрирование и восстановление можно было наглядно изучать на временных диаграммах Vivado.
module tb_silk_gtx;
    reg clk = 1'b0;
    always #4 clk = ~clk; // 125 MHz test clock

    reg rst_n = 1'b0;
    reg [63:0] src_vector = 64'd0;
    reg src_valid = 1'b0;
    wire src_ready;

    reg sim_corrupt_next = 1'b0;
    reg corrupt_pending = 1'b0;
    reg [31:0] corrupt_data_word = 32'hDEADBEEF;

    wire link_up;
    wire [63:0] rx_vector;
    wire frame_commit;
    wire frame_valid;
    wire crc_error_pulse;
    wire header_error_pulse;
    wire sequence_error_pulse;
    wire tx_word_valid;
    wire [31:0] tx_word_data;
    wire [3:0] tx_word_charisk;
    wire rx_word_valid;
    wire [31:0] rx_word_data;
    wire [3:0] rx_word_charisk;
    wire tx_usrclk;
    wire rx_usrclk;
    wire txp, txn;
    wire rxp = txp;
    wire rxn = txn;
    wire refclk_p = clk;
    wire refclk_n = ~clk;

    integer committed_frames = 0;
    integer crc_errors = 0;
    integer header_errors = 0;
    integer sequence_errors = 0;
    integer timeout_count = 0;
    reg [63:0] last_rx_vector = 64'd0;

    silk_top #(
        .USE_GTX_PRIMITIVE(0),
        .MAP_ID(8'h42)
    ) dut (
        .sys_clk              (clk),
        .rst_n                (rst_n),
        .gt_refclk_p          (refclk_p),
        .gt_refclk_n          (refclk_n),
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
        .header_error_pulse   (header_error_pulse),
        .sequence_error_pulse (sequence_error_pulse),
        .link_up              (link_up),
        .tx_word_valid        (tx_word_valid),
        .tx_word_data         (tx_word_data),
        .tx_word_charisk      (tx_word_charisk),
        .rx_word_valid        (rx_word_valid),
        .rx_word_data         (rx_word_data),
        .rx_word_charisk      (rx_word_charisk),
        .tx_usrclk            (tx_usrclk),
        .rx_usrclk            (rx_usrclk),
        .sim_corrupt_next     (sim_corrupt_next)
    );

    always @(negedge clk) begin
        // Внести однобитовую ошибку при первом появлении выбранного
        // слова полезной нагрузки. Ошибка изменяет только принимаемый поток.
        if (corrupt_pending && tx_word_valid && (tx_word_data == corrupt_data_word))
            sim_corrupt_next = 1'b1;
        else
            sim_corrupt_next = 1'b0;
    end

    always @(posedge clk) begin
        if (frame_commit) begin
            committed_frames = committed_frames + 1;
            last_rx_vector = rx_vector;
            $display("[%0t] Кадр принят #%0d, rx_vector=0x%016h", $time,
                     committed_frames, rx_vector);
        end
        if (crc_error_pulse) begin
            crc_errors = crc_errors + 1;
            $display("[%0t] Обнаружена ошибка CRC", $time);
        end
        if (header_error_pulse) begin
            header_errors = header_errors + 1;
            $display("[%0t] Обнаружена ошибка заголовка", $time);
        end
        if (sequence_error_pulse) begin
            sequence_errors = sequence_errors + 1;
            $display("[%0t] Обнаружен пропуск номера кадра; корректный кадр принят для восстановления", $time);
        end
        if (corrupt_pending && sim_corrupt_next && tx_word_valid) begin
            // Сбросить запрос ошибки по тому же активному фронту, на котором считывается повреждённое слово.
            corrupt_pending = 1'b0;
        end
    end

    task send_vector;
        input [63:0] value;
        begin
            @(negedge clk);
            src_vector = value;
            src_valid  = 1'b1;
            while (!src_ready) @(negedge clk);
            // src_valid/src_vector остаются стабильными до следующего положительного фронта тактового сигнала.
            @(posedge clk);
            @(negedge clk);
            src_valid = 1'b0;
        end
    endtask

    task wait_for_commit_count;
        input integer target_count;
        begin
            timeout_count = 0;
            while ((committed_frames < target_count) && (timeout_count < 300)) begin
                @(posedge clk);
                timeout_count = timeout_count + 1;
            end
            if (committed_frames < target_count) begin
                $display("ОШИБКА ТЕСТА: истекло время ожидания фиксации кадра #%0d", target_count);
                $fatal(1);
            end
            @(negedge clk); // avoid races with the waveform-monitor process
        end
    endtask

    initial begin
        $display("Запуск тестбенча SILK с интерфейсом GTX");
        repeat (10) @(posedge clk);
        rst_n = 1'b1;

        wait (link_up == 1'b1);
        $display("[%0t] Линия готова", $time);

        // Тест 1: обычный кадр должен быть восстановлен без изменения битов.
        send_vector(64'h11223344_AA55C33C);
        wait_for_commit_count(1);
        if (rx_vector !== 64'h11223344_AA55C33C) begin
            $display("ОШИБКА ТЕСТА: кадр 1 не совпал, принято %016h", rx_vector);
            $fatal(1);
        end

        // Тест 2: повредить младшее слово полезной нагрузки; CRC должна привести к отклонению кадра.
        corrupt_data_word = 32'hDEADBEEF;
        corrupt_pending = 1'b1;
        send_vector(64'h55667788_DEADBEEF);
        timeout_count = 0;
        while ((crc_errors < 1) && (timeout_count < 300)) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end
        @(negedge clk);
        if (crc_errors != 1) begin
            $display("ОШИБКА ТЕСТА: ожидалась ровно одна ошибка CRC, количество=%0d", crc_errors);
            $fatal(1);
        end
        if (committed_frames != 1) begin
            $display("ОШИБКА ТЕСТА: повреждённый кадр был ошибочно опубликован");
            $fatal(1);
        end
        if (rx_vector !== 64'h11223344_AA55C33C) begin
            $display("ОШИБКА ТЕСТА: отклонённый кадр изменил ранее опубликованный вектор");
            $fatal(1);
        end

        // Тест 3: следующий кадр с корректной CRC должен быть принят; пропуск номера кадра отмечается.
        send_vector(64'hCAFEBABE_01234567);
        wait_for_commit_count(2);
        if (rx_vector !== 64'hCAFEBABE_01234567) begin
            $display("ОШИБКА ТЕСТА: кадр восстановления не совпал, принято %016h", rx_vector);
            $fatal(1);
        end
        if (sequence_errors < 1) begin
            $display("ОШИБКА ТЕСТА: после отброшенного кадра не отмечен пропуск последовательности");
            $fatal(1);
        end

        if (header_errors != 0) begin
            $display("ОШИБКА ТЕСТА: неожиданные ошибки заголовка=%0d", header_errors);
            $fatal(1);
        end

        $display("------------------------------------------------------------");
        $display("ТЕСТ ПРОЙДЕН: принято кадров=%0d, ошибок CRC=%0d, пропусков последовательности=%0d",
                 committed_frames, crc_errors, sequence_errors);
        $display("------------------------------------------------------------");
        repeat (10) @(posedge clk);
        $finish;
    end

    initial begin
        #100000;
        $display("ОШИБКА ТЕСТА: превышено общее время ожидания");
        $fatal(1);
    end
endmodule
