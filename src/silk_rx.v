`timescale 1ns / 1ps
// Демонстрационный приёмник SILK. Публикует полезную нагрузку атомарно после проверки CRC.
module silk_rx #(
    parameter [7:0] MAP_ID = 8'h42
) (
    input  wire        clk,
    input  wire        rst,

    input  wire        rx_word_valid,
    input  wire [31:0] rx_word_data,
    input  wire [3:0]  rx_word_charisk,

    output reg  [63:0] rx_vector,
    output reg         frame_commit,
    output reg         frame_valid,
    output reg         crc_error_pulse,
    output reg         header_error_pulse,
    output reg         sequence_error_pulse
);
    localparam [31:0] SYNC_WORD = 32'hA55A5ABC;
    localparam [7:0]  FRAME_VERSION = 8'h01;
    localparam [7:0]  PAYLOAD_WORDS = 8'd2;

    localparam [2:0] ST_SEARCH_SYNC = 3'd0;
    localparam [2:0] ST_HEADER      = 3'd1;
    localparam [2:0] ST_PAYLOAD_LO  = 3'd2;
    localparam [2:0] ST_PAYLOAD_HI  = 3'd3;
    localparam [2:0] ST_CRC         = 3'd4;

    reg [2:0]  state;
    reg [31:0] header_reg;
    reg [31:0] payload_lo_reg;
    reg [31:0] payload_hi_reg;
    reg [31:0] crc_state;
    reg [7:0]  rx_sequence;
    reg [7:0]  expected_sequence;

    wire [31:0] crc_next;
    silk_crc32_word u_crc_rx_word (
        .crc_in (crc_state),
        .data_in(rx_word_data),
        .crc_out(crc_next)
    );

    always @(posedge clk) begin
        if (rst) begin
            state                <= ST_SEARCH_SYNC;
            header_reg           <= 32'd0;
            payload_lo_reg       <= 32'd0;
            payload_hi_reg       <= 32'd0;
            crc_state            <= 32'hFFFF_FFFF;
            rx_sequence          <= 8'd0;
            expected_sequence    <= 8'd0;
            rx_vector            <= 64'd0;
            frame_commit         <= 1'b0;
            frame_valid          <= 1'b0;
            crc_error_pulse      <= 1'b0;
            header_error_pulse   <= 1'b0;
            sequence_error_pulse <= 1'b0;
        end else begin
            frame_commit         <= 1'b0;
            crc_error_pulse      <= 1'b0;
            header_error_pulse   <= 1'b0;
            sequence_error_pulse <= 1'b0;

            if (rx_word_valid) begin
                case (state)
                    ST_SEARCH_SYNC: begin
                        if ((rx_word_data == SYNC_WORD) &&
                            (rx_word_charisk == 4'b0001)) begin
                            state     <= ST_HEADER;
                            crc_state <= 32'hFFFF_FFFF;
                        end
                    end

                    ST_HEADER: begin
                        if ((rx_word_charisk != 4'b0000) ||
                            (rx_word_data[31:24] != FRAME_VERSION) ||
                            (rx_word_data[23:16] != MAP_ID) ||
                            (rx_word_data[15:8]  != PAYLOAD_WORDS)) begin
                            header_error_pulse <= 1'b1;
                            state              <= ST_SEARCH_SYNC;
                        end else begin
                            header_reg        <= rx_word_data;
                            rx_sequence       <= rx_word_data[7:0];
                            crc_state         <= crc_next;
                            state             <= ST_PAYLOAD_LO;
                        end
                    end

                    ST_PAYLOAD_LO: begin
                        if (rx_word_charisk != 4'b0000) begin
                            header_error_pulse <= 1'b1;
                            state              <= ST_SEARCH_SYNC;
                        end else begin
                            payload_lo_reg <= rx_word_data;
                            crc_state      <= crc_next;
                            state          <= ST_PAYLOAD_HI;
                        end
                    end

                    ST_PAYLOAD_HI: begin
                        if (rx_word_charisk != 4'b0000) begin
                            header_error_pulse <= 1'b1;
                            state              <= ST_SEARCH_SYNC;
                        end else begin
                            payload_hi_reg <= rx_word_data;
                            crc_state      <= crc_next;
                            state          <= ST_CRC;
                        end
                    end

                    ST_CRC: begin
                        if (rx_word_charisk != 4'b0000) begin
                            header_error_pulse <= 1'b1;
                        end else if (rx_word_data == (crc_state ^ 32'hFFFF_FFFF)) begin
                            // Политика восстановления: принимать данные с корректной CRC и отмечать пропуски номеров кадров,
                            // затем устанавливать ожидаемый номер кадра равным номеру принятого кадра плюс один.
                            if (rx_sequence != expected_sequence)
                                sequence_error_pulse <= 1'b1;
                            rx_vector         <= {payload_hi_reg, payload_lo_reg};
                            frame_commit      <= 1'b1;
                            frame_valid       <= 1'b1;
                            expected_sequence <= rx_sequence + 1'b1;
                        end else begin
                            crc_error_pulse <= 1'b1;
                        end
                        state <= ST_SEARCH_SYNC;
                    end

                    default: state <= ST_SEARCH_SYNC;
                endcase
            end
        end
    end
endmodule
