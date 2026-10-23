# Наглядная временная диаграмма для статьи: только сигналы, необходимые для объяснения интерфейса.
# Выполните этот скрипт после открытия поведенческой симуляции в Vivado.
add_wave -group {Управление} /tb_silk_gtx/clk
add_wave -group {Управление} /tb_silk_gtx/rst_n
add_wave -group {Управление} /tb_silk_gtx/link_up

add_wave -group {Интерфейс источника} /tb_silk_gtx/src_valid
add_wave -group {Интерфейс источника} /tb_silk_gtx/src_ready
add_wave -radix hex -group {Интерфейс источника} /tb_silk_gtx/src_vector

add_wave -group {Поток слов TX} /tb_silk_gtx/tx_word_valid
add_wave -radix hex -group {Поток слов TX} /tb_silk_gtx/tx_word_data
add_wave -radix hex -group {Поток слов TX} /tb_silk_gtx/tx_word_charisk

add_wave -group {Поток слов RX} /tb_silk_gtx/rx_word_valid
add_wave -radix hex -group {Поток слов RX} /tb_silk_gtx/rx_word_data
add_wave -radix hex -group {Поток слов RX} /tb_silk_gtx/rx_word_charisk

add_wave -group {Результат приёма} /tb_silk_gtx/frame_commit
add_wave -group {Результат приёма} /tb_silk_gtx/frame_valid
add_wave -radix hex -group {Результат приёма} /tb_silk_gtx/rx_vector
add_wave -group {Результат приёма} /tb_silk_gtx/crc_error_pulse
add_wave -group {Результат приёма} /tb_silk_gtx/sequence_error_pulse
