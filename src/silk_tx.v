`timescale 1ns / 1ps
// Демонстрационный передатчик SILK.
// Формат кадра: SYNC, заголовок, PAYLOAD[31:0], PAYLOAD[63:32], CRC32.
module silk_tx #(
    parameter [7:0] MAP_ID = 8'h42
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        link_up,

    input  wire [63:0] src_vector,
    input  wire        src_valid,
    output wire        src_ready,

    output reg         tx_word_valid,
    output reg  [31:0] tx_word_data,
    output reg  [3:0]  tx_word_charisk,
    input  wire        tx_word_ready
);
    localparam [31:0] SYNC_WORD = 32'hA55A5ABC;
    localparam [7:0]  FRAME_VERSION = 8'h01;
    localparam [7:0]  PAYLOAD_WORDS = 8'd2;

    localparam [2:0] ST_IDLE = 3'd0;
    localparam [2:0] ST_SYNC = 3'd1;
    localparam [2:0] ST_HEADER = 3'd2;
    localparam [2:0] ST_PAYLOAD_LO = 3'd3;
    localparam [2:0] ST_PAYLOAD_HI = 3'd4;
    localparam [2:0] ST_CRC = 3'd5;

    reg [2:0]  state;
    reg [63:0] payload_reg;
    reg [31:0] header_reg;
    reg [31:0] crc_reg;
    reg [7:0]  sequence_reg;

    wire [31:0] header_next = {FRAME_VERSION, MAP_ID, PAYLOAD_WORDS, sequence_reg};
    wire [31:0] crc_after_header;
    wire [31:0] crc_after_payload_lo;
    wire [31:0] crc_after_payload_hi;

    silk_crc32_word u_crc_header (
        .crc_in (32'hFFFF_FFFF),
        .data_in(header_next),
        .crc_out(crc_after_header)
    );
    silk_crc32_word u_crc_payload_lo (
        .crc_in (crc_after_header),
        .data_in(src_vector[31:0]),
        .crc_out(crc_after_payload_lo)
    );
    silk_crc32_word u_crc_payload_hi (
        .crc_in (crc_after_payload_lo),
        .data_in(src_vector[63:32]),
        .crc_out(crc_after_payload_hi)
    );

    assign src_ready = link_up && (state == ST_IDLE);

    always @* begin
        tx_word_valid  = 1'b0;
        tx_word_data   = 32'h0000_0000;
        tx_word_charisk = 4'b0000;

        if (link_up) begin
            case (state)
                ST_SYNC: begin
                    tx_word_valid   = 1'b1;
                    tx_word_data    = SYNC_WORD;
                    // В младшем байте первого слова передаётся K28.5 (0xBC) для выравнивания потока GTX по байтам.
                    tx_word_charisk = 4'b0001;
                end
                ST_HEADER: begin
                    tx_word_valid = 1'b1;
                    tx_word_data  = header_reg;
                end
                ST_PAYLOAD_LO: begin
                    tx_word_valid = 1'b1;
                    tx_word_data  = payload_reg[31:0];
                end
                ST_PAYLOAD_HI: begin
                    tx_word_valid = 1'b1;
                    tx_word_data  = payload_reg[63:32];
                end
                ST_CRC: begin
                    tx_word_valid = 1'b1;
                    tx_word_data  = crc_reg;
                end
                default: begin
                    tx_word_valid = 1'b0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state        <= ST_IDLE;
            payload_reg  <= 64'd0;
            header_reg   <= 32'd0;
            crc_reg      <= 32'd0;
            sequence_reg <= 8'd0;
        end else if (!link_up) begin
            state <= ST_IDLE;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (src_valid && src_ready) begin
                        payload_reg  <= src_vector;
                        header_reg   <= header_next;
                        crc_reg      <= crc_after_payload_hi ^ 32'hFFFF_FFFF;
                        state        <= ST_SYNC;
                    end
                end
                ST_SYNC: begin
                    if (tx_word_valid && tx_word_ready)
                        state <= ST_HEADER;
                end
                ST_HEADER: begin
                    if (tx_word_valid && tx_word_ready)
                        state <= ST_PAYLOAD_LO;
                end
                ST_PAYLOAD_LO: begin
                    if (tx_word_valid && tx_word_ready)
                        state <= ST_PAYLOAD_HI;
                end
                ST_PAYLOAD_HI: begin
                    if (tx_word_valid && tx_word_ready)
                        state <= ST_CRC;
                end
                ST_CRC: begin
                    if (tx_word_valid && tx_word_ready) begin
                        state        <= ST_IDLE;
                        sequence_reg <= sequence_reg + 1'b1;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
