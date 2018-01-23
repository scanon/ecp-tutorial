#!/bin/bash
#SBATCH -N 1 -C haswell -q regular
#SBATCH --reservation=ecp_tut
#SBATCH --image docker:ubuntu

srun -N 1 shifter /app/app.py
