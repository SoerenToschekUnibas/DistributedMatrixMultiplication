#!/bin/bash
#SBATCH --job-name=pmt-exp
#SBATCH --nodes=1
#SBATCH --ntasks=8                   # max MPI ranks launched in this job
#SBATCH --cpus-per-task=8            # 8 cores per rank = 64 CPUs total
#SBATCH --mem-per-cpu=2G             # 128 GB total
#SBATCH --partition=l40s            # partition name don't change it (or you can use l40s)
#SBATCH --gres=gpu:8                 # remove if no GPU measurement
#SBATCH --time=00:05:00
#SBATCH --qos=l40s-30min             # adapt according to your partition and decided cos
#SBATCH --exclusive                  # only needed for the CPU measurements
#SBATCH --output=pmt-%j.out

#load your required modules below
#################################
ml purge
ml CMake
ml HDF5/1.14.6-gompi-2025b
ml CUDA/13.1.0
export PATH=/scicore/home/ciorba/simsek0003/lib_installed/pmt/bin:$PATH
export LD_LIBRARY_PATH=/scicore/home/ciorba/simsek0003/lib_installed/pmt/lib:${LD_LIBRARY_PATH}

nvcc -arch=sm_89 dense.cu -o dense.out

srun ./PMT -n nvml dense.out >> nvml_result_file.txt
echo "NVML done"
srun ./PMT -n rapl dense.out >> rapl_result_file.txt
echo "RAPL done"