#/bin/bash

C_PREPRO=cpp
C_PREPRO_OPTS=-P

ARGS=1
E_BADARGS=65

UNCONFIGURED_EXT="vhd.unconfig"
CONFIGURED_EXT="vhd"

# FILES="1st_order_iir_filter 2nd_order_iir_filter cordic_atan fa freq2phase integrator kcm_integrator p2_phase_loop p2_3p_phase_loop park_transform phase_loop"
FILES=$(ls *.vhd.unconfig)

echo "Preprocessing sources:"
for file in $FILES; do
    # dest_file=$file."$CONFIGURED_EXT"
    dest_file=${file/".$UNCONFIGURED_EXT"/".$CONFIGURED_EXT"}
    echo "  Preprocessing $dest_file";
    if [[ -e $dest_file ]]
    then
	echo "    destination file exists, making backup"
	cp "$dest_file" "$dest_file".backup
    fi
    $C_PREPRO $C_PREPRO_OPTS "$file" > $dest_file
done