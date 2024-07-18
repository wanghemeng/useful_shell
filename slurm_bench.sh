#!/bin/bash

node_list=$(scontrol show node --oneliner | grep "State=IDLE" | awk '{print $1}')
usr_name=$(whoami)

IFS=$'\n' read -d '' -ra lines <<< "$node_list"

for line in "${lines[@]}"; do
    node_name=${line#*=}
    echo "$node_name"

    log_file="./bench_log/${node_name}_bench.log"

    script_content="#!/bin/bash

#SBATCH -N 1
#SBATCH -n 96
#SBATCH -t 00:30:00
#SBATCH -w ${node_name}
#SBATCH -o ${log_file}

source /public1/soft/modules/module.sh

module purge
module load gcc/9.3.0
module load cmake/3.21.2
module load intel/2022.1
module load mpi/intel/2022.1

export PETSC_ARCH=arch-intel-omp
export PETSC_DIR=/public1/home/${usr_name}/iterative/petsc_omp

make streams NPMAX=96 MPI_BINDING=\"--bind-to core --map-by socket\"
"

    script_file="./scripts/${node_name}_bench_temp.sh"
    echo "$script_content" > "$script_file"
    chmod +x "$script_file"

    while true; do
        pd_jobs=$(squeue -u ${usr_name} -h -t PD -o %i | wc -l)
        
        running_jobs=$(squeue -u ${usr_name} -h -t R -o %i | wc -l)

        total_jobs=$((running_jobs + pd_jobs))
        
        if [[ $total_jobs -lt 5 ]]; then
            job_id=$(sbatch "$script_file" | awk '{print $4}')
            # rm "$script_file"
            break
        else
            echo "queue is full, wait 5 mins to re-check..."
            sleep 5m
            err_pd_job_num=$(squeue -u ${usr_name} -h -t PD -o "%i %r" | awk '/ReqNodeNotAvail/{print $1;exit}' | wc -l)
            while [[ $err_pd_job_num -gt 0 ]]; do
                err_pd_job_id=$(squeue -u ${usr_name} -h -t PD -o "%i %r" | awk '/ReqNodeNotAvail/{print $1;exit}')
                echo "cancel $err_pd_job_id"
                scancel $err_pd_job_id
                err_pd_job_num=$(squeue -u ${usr_name} -h -t PD -o "%i %r" | awk '/ReqNodeNotAvail/{print $1;exit}' | wc -l)
            done
        fi
    done

done
