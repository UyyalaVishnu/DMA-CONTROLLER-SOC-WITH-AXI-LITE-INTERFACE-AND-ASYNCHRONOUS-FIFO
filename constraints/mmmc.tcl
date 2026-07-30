# Version:1.0 MMMC View Definition File
# Do Not Remove Above Line
create_library_set -name libs_slow -timing {/home/install/FOUNDRY/digital/45nm/LIBS/lib/max/slow.lib}
create_constraint_mode -name func -sdc_files {/home/vlsi/vvr/project/dma.sdc}
create_delay_corner -name slow -library_set {libs_slow}
create_analysis_view -name view_slow -constraint_mode {func} -delay_corner {slow}
set_analysis_view -setup {view_slow} -hold {view_slow}
