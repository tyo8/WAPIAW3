#!/bin/sh

verbose_out=${1:-false}
check_stg1=${2:-true}

basedir="/scratch/tyoeasley/WAPIAW3/brainrep_data/PROFUMO_data/out_PROFUMO"
ica_datadirs=$( ls -d ${basedir}/rmed_*/Results.ppp/Maps )
check_xtr="/scratch/tyoeasley/WAPIAW3/utils/check_generic_extraction.sh"

for datadir in $ica_datadirs
do
	# hacky shortcut
	groupname=$( echo $datadir | cut -d/ -f 8 ) ###  CHANGE THIS LATER
	group_fpath="/scratch/tyoeasley/WAPIAW3/subject_lists/combined_subj_eid/${groupname}.csv" ###  CHANGE THIS LATER

	??????????
	if $check_stg1
	then
		if $verbose_out
		then
			${check_xtr} -i "${datadir}/dr_stage1" -g ${group_fpath} -o "incomplete_groups.txt" -m "completed"  -e "${check_xtr} -i '${datadir}/mask_' -g '${group_fpath}' -o 'unmasked_groups.txt' -m 'masked'"
		else
			${check_xtr} -i "${datadir}/dr_stage1" -g ${group_fpath} -m "completed"  -e "${check_xtr} -i '${datadir}/mask_' -g '${group_fpath}' -m 'masked'"
		fi
	else
		if $verbose_out
		then
			${check_xtr} -i ${datadir}/mask_ -g ${group_fpath} -o 'unmasked_groups.txt' -m 'masked'
		else
			${check_xtr} -i ${datadir}/mask_ -g ${group_fpath} -m 'masked'
		fi
	fi
done
