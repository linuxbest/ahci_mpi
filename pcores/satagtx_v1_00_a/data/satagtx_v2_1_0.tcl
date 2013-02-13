####
#
#

proc generate_corelevel_ucf {mhsinst} {
	set  filePath [xget_ncf_dir $mhsinst]
	file mkdir    $filePath

	# specify file name
	set    instname   [xget_hw_parameter_value $mhsinst "INSTANCE"]
	set    ipname     [xget_hw_option_value    $mhsinst "IPNAME"]
	set    name_lower [string   tolower   $instname]
	set    fileName   $name_lower
	append fileName   "_wrapper.ucf"
	append filePath   $fileName

	# Open a file for writing
	set    outputFile [open $filePath "w"]
	puts   $outputFile "################################################################################ "

	# 12000 for 150Mhz
	# 6000  for  75Mhz
	puts $outputFile "INST \"${instname}/*gtx_dual_i\"          TNM=\"${instname}_gtx_dual_i\";"
	puts $outputFile "INST \"${instname}/*gtx_oob_*/txdata_o*\"   TNM=FFS \"${instname}_TxMGTData\";"
	puts $outputFile "INST \"${instname}/*gtx_oob_*/txdatak_o*\"  TNM=FFS \"${instname}_TxMGTDataIsK\";"
	puts $outputFile "TIMESPEC \"TS_TXregs1_to_${instname}\" = FROM \"${instname}_TxMGTData\"    TO \"${instname}_gtx_dual_i\" 12000 ps;"
	puts $outputFile "TIMESPEC \"TS_TXregs2_to_${instname}\" = FROM \"${instname}_TxMGTDataIsK\" TO \"${instname}_gtx_dual_i\" 12000 ps;"

	puts $outputFile "#"
	puts $outputFile "INST \"${instname}/*gtx_rxdata0*\"  TNM=FFS \"${instname}_DataOutA0\";"
	puts $outputFile "INST \"${instname}/*gtx_rxdatak0*\" TNM=FFS \"${instname}_KOutA0\";"
	puts $outputFile "INST \"${instname}/*gtx_rxdata1*\"  TNM=FFS \"${instname}_DataOutA1\";"
	puts $outputFile "INST \"${instname}/*gtx_rxdatak1*\" TNM=FFS \"${instname}_KOutA1\";"
	
	puts $outputFile "#"
	puts $outputFile "TIMESPEC  \"TS_GT_to_${instname}_RXregs01\" = FROM \"${instname}_gtx_dual_i\" TO \"${instname}_DataOutA0\"  12000 ps;"
	puts $outputFile "TIMESPEC  \"TS_GT_to_${instname}_RXregs02\" = FROM \"${instname}_gtx_dual_i\" TO \"${instname}_KOutA0\"     12000 ps;"
	puts $outputFile "TIMESPEC  \"TS_GT_to_${instname}_RXregs11\" = FROM \"${instname}_gtx_dual_i\" TO \"${instname}_DataOutA1\"  12000 ps;"
	puts $outputFile "TIMESPEC  \"TS_GT_to_${instname}_RXregs12\" = FROM \"${instname}_gtx_dual_i\" TO \"${instname}_KOutA1\"     12000 ps;"

	puts $outputFile "#"
	puts $outputFile "NET \"${instname}/*sata_gtx_phy/txusrclk0\"  TNM_NET = \"${instname}_TXCLK0\";"
	puts $outputFile "NET \"${instname}/*sata_gtx_phy/txusrclk20\" TNM_NET = \"${instname}_TXCLK1\";"
	
	puts $outputFile "#"
	puts $outputFile "TIMESPEC \"TS_${instname}_TXCLK0\" = PERIOD \"${instname}_TXCLK0\"  6000 ps;"
	puts $outputFile "TIMESPEC \"TS_${instname}_TXCLK1\" = PERIOD \"${instname}_TXCLK1\" 12000 ps;"
	
	puts $outputFile "#"
	# Close the file
	close $outputFile
	puts [xget_ncf_loc_info $mhsinst]
}
