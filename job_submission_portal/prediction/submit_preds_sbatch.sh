#!/bin/bash

set -o nounset

# constants
base_dir="/scratch/tyoeasley/WAPIAW3"
pred_dir="${base_dir}/job_submission_portal/prediction"
out_dir="${base_dir}/prediction_outputs"
build_path_src="${base_dir}/utils/build_fpath_from_specs.sh"

# data parameters
subj_group_flist="${base_dir}/subject_lists/lists_of_groups/dummy_groups.txt"
spec_list_fpath="${pred_dir}/spec_list_test.txt"

# submission parameters
n_jobs=12
mem_gb=$(( 100/${n_jobs} ))
maxtime_str="23:55:00"

while getopts ":i:o:b:p:s:n:t:m:" opt; do
  case $opt in
    i) spec_list_fpath=${OPTARG}
    ;;
    o) out_dir=${OPTARG}
    ;;
    b) base_dir=${OPTARG}
    ;;
    p) pred_dir=${OPTARG}
    ;;
    s) subj_group_flist=${OPTARG}
    ;;
    n) n_jobs=${OPTARG}
    ;;
    t) maxtime_str=${OPTARG}
    ;;
    m) mem_gb=${OPTARG}
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done

subj_group_list=$( cat ${subj_group_flist} )
spec_list=$( cat ${spec_list_fpath} )

########################## Write the input and the script #########################

echo "Running predictions for the following parameters:"
echo "subject groups in list: ${subj_group_flist}"
echo "brainrep and feature parameters specified in: ${spec_list_fpath}"

for spec_line in spec_list
do
	brainrep=$( echo $spec_line | cut -d_ -f 1 )
	feature=$( echo $spec_line | cut -d_ -f 2 )
	for subj_group in ${subj_group_list}
	do
		groupname=$( basename ${subj_group} | cut -d. -f 1 )
		
		datapath_type=$( ${build_path_src} ${brainrep} ${groupname} ${feature} )

		sbatch_fpath="${pred_dir}/sbatch_scripts/do_cl_${groupname}_${brainrep}_${feature}"

		echo "Predicting diagnosis from ${brainrep} ${feature} in subject group: ${groupname}"	
		echo "\
\
#!/bin/sh
#SBATCH --job-name=cl_${groupname}_${brainrep}_${feature}
#SBATCH --output=/scratch/tyoeasley/WAPIAW3/job_submission_portal/prediction/logs/cl_${groupname}_${brainrep}_${feature}.out
#SBATCH --error=/scratch/tyoeasley/WAPIAW3/job_submission_portal/prediction/logs/cl_${groupname}_${brainrep}_${feature}.err
#SBATCH --time=${maxtime_str}
#SBATCH --partition=small
#SBATCH --nodes=${n_jobs}
#SBATCH --mem=${mem_gb}gb

# constants
classifier=\"${base_dir}/classification_model/classify_patients.py\"
patient_eid_dir=\"${base_dir}/subject_lists/patient_eid\"

# input parameters
subj_list=\"${subj_group}\"
datapath_type=\"${datapath_type}\"
outpath=\"${out_dir}/metrics_${groupname}_${brainrep}_${feature}.csv\"

# resource & computation parameters
n_jobs=${n_jobs}                # number of cores requested by process
rng_seed=0              # random seed state integer

# (bagged) classifier parameters
folds=5                 # number of folds during gridsearch hyperparameter validation
n_splits=${n_splits}            # number of random train/validation splits within training data=number of models learned
n_estimators=250        # number of trees in random forest
loss_criterion=\'gini\'   # minimized objective function

python \${classifier} -l \${subj_list} -f \${datapath_type} -o \${outpath} -p \${patient_eid_dir} \
        -n \${n_jobs} -R \${rng_seed} \
        -k \${folds} -s \${n_splits} -e \${n_estimators} -L \${loss_criterion} -v
\
" > "${sbatch_fpath}"  

		# Overwrite submission script# Make script executable
		chmod +x "${sbatch_fpath}" || { echo "Error changing the script permission!"; exit 1; }

    		# Submit script
    		sbatch "${sbatch_fpath}" || { echo "Error submitting jobs!"; exit 1; }
	done
done
