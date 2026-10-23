`timescale 1ns / 1ps
// Комбинаторное обновление отражённой CRC-32 для одного 32-битного слова.
// Полином: 0xEDB88320; обработка входных битов начинается с младшего.
module silk_crc32_word (
    input  wire [31:0] crc_in,
    input  wire [31:0] data_in,
    output reg  [31:0] crc_out
);
    integer i;
    reg [31:0] c;

    always @* begin
        c = crc_in;
        for (i = 0; i < 32; i = i + 1) begin
            if (c[0] ^ data_in[i])
                c = (c >> 1) ^ 32'hEDB88320;
            else
                c = (c >> 1);
        end
        crc_out = c;
    end
endmodule
