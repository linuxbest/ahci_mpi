####
#
#

xload_xilinx_library libmXMLTclIf

proc update_version_proc {param_handle} {
	set    mhsinst      [xget_hw_parent_handle $param_handle]
	set    ipinsthandle [xget_hw_mpd_handle $mhsinst]
	set    ipdir        [xget_hw_pcore_dir_from_mpd $ipinsthandle]
	set    version      [exec $ipdir/setlocalversion $ipdir]

	return [expr 0x$version];
}

proc generate_corelevel_ucf {mhsinst} {
	############################
	set  filePath [xget_ncf_dir $mhsinst]
	file mkdir    $filePath

	set    instname   [xget_hw_parameter_value $mhsinst "INSTANCE"]
	set    ipname     [xget_hw_option_value    $mhsinst "IPNAME"]
	set    name_lower [string   tolower   $instname]
	set    fileName   $name_lower
	append fileName   "_wrapper.ucf"
	append filePath   $fileName


	# Open a file for writing
	set    outputFile [open $filePath "w"]
	puts   $outputFile "################################################################################ "
	close $outputFile

	# append -reduce_control_sets into *.scr
	set    postFile   "synthesis/post_"
	append postFile   $name_lower
	append postFile   "_wrapper"
	append postFile   ".sh"
	set    outputFile [open $postFile "w"]
	set    command    "MOD="
	append command    $name_lower
	puts   $outputFile $command
	close  $outputFile

	puts [xget_ncf_loc_info $mhsinst]

	# update the ahci rom.
	set    ipinsthandle [xget_hw_mpd_handle $mhsinst]
	set    ipdir        [xget_hw_pcore_dir_from_mpd $ipinsthandle]
#	exec make -C $ipdir/../hdl/vhdl/fw/
}
