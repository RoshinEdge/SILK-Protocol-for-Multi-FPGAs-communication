# Шаблон ограничений для ПЛИС Kintex-7 xc7k325tffg900, используемой в данном примере.
# Перед реализацией сверьте каждое назначение с принципиальной схемой конкретной платы.

# Дифференциальный системный тактовый сигнал логики (номинально 200 МГц).
# Эти выводы использовались в предыдущем варианте проекта; оставляйте их только
# если используется та же печатная плата и та же ревизия.
set_property PACKAGE_PIN AG10 [get_ports sys_clk_p]
set_property PACKAGE_PIN AH10 [get_ports sys_clk_n]
set_property IOSTANDARD LVDS [get_ports {sys_clk_p sys_clk_n}]
create_clock -name sys_clk -period 5.000 [get_ports sys_clk_p]

# Пара опорного тактового сигнала GTX (номинально 125 МГц). Это выделенный опорный сигнал MGT;
# не назначайте ему стандарт IOSTANDARD для обычных выводов логики.
set_property PACKAGE_PIN N8 [get_ports gt_refclk_p]
set_property PACKAGE_PIN N7 [get_ports gt_refclk_n]
create_clock -name gt_refclk -period 8.000 [get_ports gt_refclk_p]

# ВАЖНО: укажите корректные выводы выбранного канала GTX для rxp/rxn
# и txp/txn по схеме платы и распиновке корпуса в Vivado. Не подбирайте их наугад:
# пары должны относиться к поддерживаемому каналу/линии GTX.
