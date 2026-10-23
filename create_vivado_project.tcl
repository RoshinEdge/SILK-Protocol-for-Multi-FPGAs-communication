# Создание проекта Vivado 2020.2 для SILK и GTXE2_CHANNEL семейства Kintex-7.
# Выполните команду в Tcl Console среды Vivado:
#   source C:/путь/к/SILK_GTX_Vivado_Project/create_vivado_project.tcl
set script_dir [file dirname [file normalize [info script]]]
set project_dir [file join $script_dir vivado_project]

create_project silk_gtx $project_dir -part xc7k325tffg900-2L -force
set_property simulator_language Verilog [current_project]

add_files -norecurse [glob [file join $script_dir src *.v]]
add_files -fileset sim_1 -norecurse [file join $script_dir sim tb_silk_gtx.v]
set_property top silk_gtx_hw_top [get_filesets sources_1]
set_property top tb_silk_gtx [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Проект SILK для GTX создан в: $project_dir"
puts "Откройте поведенческую симуляцию и выполните: source [file join $script_dir sim add_article_waves.tcl]"
puts "Синтезируемый верхний модуль silk_gtx_hw_top использует GTXE2_CHANNEL. Добавьте XDC с выводами канала трансивера конкретной платы."
