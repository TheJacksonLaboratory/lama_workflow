# lama_workflow
Repo with the inner workings for a container-based LAMA workflow.

# Building the LAMA container on Sumner2

> [!TIP]
> At JAX, the easiest way to build containers from the definitions in this repository is to use the `build` partition on Sumner2.
> For more details regarding accessing and using this JAX-specific resource, please see [the instructions in SharePoint](https://jacksonlaboratory.sharepoint.com/sites/ResearchIT/SitePages/JAX-HPC-Pro-Tip.aspx).

You can access it from a login node by using:  
```bash
sinteractive -p build -q build
```
Load the needed sigularity/apptainer module (note that `singularity` can be used interchangeably with the new name `apptainer`):
```
module load singularity
```

To build the container either clone the repository:
```
git clone https://github.com/TheJacksonLaboratory/lama_workflow.git
```
or download the container definition and the Python requirements.txt (lock)file:
```
wget https://github.com/TheJacksonLaboratory/lama_workflow/raw/refs/heads/main/LAMA.def
wget https://github.com/TheJacksonLaboratory/lama_workflow/raw/refs/heads/main/requirements.txt
```

> [!IMPORTANT]
> The `LAMA.def` file and the `requirements.txt` must be placed in the same directory!

Eitherway, using the build partition, ensure you are in the directory with the definition and requirements.txt file and then you can build the container using [`singularity build`](https://apptainer.org/docs/user/1.1/build_a_container.html) :

```
singularity build LAMA.sif LAMA.def
```
> [!NOTE]
> This will take a few minutes! It will download an image, install pacakges, build the python environment, and then write the resultant .sif file.

Once you see `INFO:    Build complete: LAMA.sif` you can end the session using `exit`.

You can now add this to your `PATH` variable to ensure you can run LAMA entry points from other directories, such as the LAMA repository if you've cloned that. Ensure you are in the same directory as the `LAMA.sif` file and run:
```
export PATH=$PATH:$(pwd)
```

> [!NOTE]
> For more information about the container, please see [the technical notes](#the-container-definition).


# Using the `LAMA.sif` container on Sumner2

For using the container, you need to use an interactive session.
> [!TIP]
> At JAX, the easiest way to get an interactive session on Sumner2 from a login node is to use the `sinteractive` command.
> For more details about this JAX-specific feature, see [the instructions in SharePoint](https://jacksonlaboratory.sharepoint.com/sites/ResearchIT/SitePages/HPC-Pro-T.aspx).
  
On Sumner2 from a login node, you can use the following to request 4 cores and 32 Gb of RAM:
```
sinteractive -c 4 -m 32G
```
> [!IMPORTANT]
> The Sumner2 scheduler is merciless; if your job exceeds the requested memory it will be killed.

Once in the interactive session, make sure to load the singularity/apptainer module:
```
module load singularity
```

Assuming you modified the PATH variable after building the container, you can now use it by prefixing commands with `LAMA.sif`.
For example, you can access the Python entry points of LAMA listed here:
https://github.com/mpi2/LAMA/blob/8ca9e4ef59c67c26f9778d951f05e792536404e3/setup.py#L56-L68
using:
```
LAMA.sif <entry point>
```
You can also shell into the container:
```
LAMA.sif bash
```
or run a python script using:
```
LAMA.sif python my_script.py
```

# Running the LAMA walkthrough on Sumner2

> [!IMPORTANT]
> This section is geared for running on the JAX HPC cluster Sumner2. The scripts, when submitted to the cluster using `sbatch`, have been tested and will run for the case of the [LAMA walkthrough](https://github.com/mpi2/LAMA/wiki/walkthroughs). For your own data, remember that the Sumner2 scheduler is merciless, so if your job is killed, you may need to increase the requested memory in the header of the script (`--mem=`).

From now, we are following along the [walkthrough page for LAMA](https://github.com/mpi2/LAMA/wiki/walkthroughs). Grab an interactive session on Sumner2 (with, for example, `sinteractive` as above) and do the following:

```bash
module load singularity
singularity exec LAMA.sif lama_get_walkthrough_data 
```

This will download the walkthrough data to the current folder.

> [!IMPORTANT]
> The walkthrough sample data was not publically available as of 2024/12/20 and may need to be downloaded from the IMPC Cloud. In this case, you can use `wget` to download the `.zip` or use `scp` to copy it from your local machine to Sumner2.

Next, we need to ensure the scripts are executable:
```bash
cd lama_walkthroughs/
chmod u+x *.sh 
```

In this repo, we've provided `sbatch` scripts to run each of the parts of the walkthrough on Sumner2 as `sbatch` jobs. These are just regular `bash` scripts with `sbatch` headers defining SLURM job parameters, such as memory usage. You can run them as normal `bash` scripts, but you will need to ensure your interactive session has enough resources, especially memory. Otherwise, it's best to run them using the `sbatch` command, which will use the job parameters from the header.  

For step 1 on the walkthrough ("Make a population average"), we can use `lama_popavg.sbatch` as provided in this repository. To submit a job using this `sbatch` file, use:

```bash
sbatch lama_popavg.sbatch
```

Sumner2 will queue up your job and then run it using the parameters from the header. Output files will be stored inside `lama_walkthroughs` and named according to what was specified in the `sbatch` file (by default, `lama_popavg.out` and `lama_popavg.err`).

> [!NOTE]
> By default, all of the `sbatch` scripts point to the `lama_walkthroughs` directory. To run them on your own data, you can put the data in the template folder in this repository, `lama_workspace`, and then edit the `sbatch` scripts to comment out the line pointing to `lama_walkthroughs` and un-comment the line pointing to `lama_workspace`.

For step 2, use `lama_spatial.sbatch` - it is similar to the previous step, but for parallelization and performance it should be submitted to Sumner2 as an array job using: 

```bash
sbatch --array=1-8 lama_spatial.sbatch
``` 

> [!NOTE]
> Again, when running on your own data, you can use the `lama_workspace` template folder. Before submitting it, check the contents of the actual script that is being called (`spatially_normalise_data.sh`) and see which TOML file is being used for config (it should be in `lama_workspace/data/wild_type_and_mutant_data/generate_data.toml`). Edit that config file to match the number of cores your batch job is asking for (16 in this case, though this and the amount of memory are just suggestions). This step in particular benefits a lot from multiple jobs running on the same data since it keeps track of what is being run by individual jobs, so maybe an array with a job per input file is a good idea, instead of always using an array of 8 jobs.


After running this step, you can move to step 3, where you can submit a similar batch job using:

```bash
sbatch lama_stats.sbatch
```

> [!NOTE]
> All 3 sections are rather CPU inefficient, spending most of their time using just a single core. Memory usage was variable, tending to increase as the scripts ran on, so for your own data you may need to increase the requested memory, as noted previously.

# Running an actual workflow on Sumner

In this repo, the relevant TOML files and .sh scripts are provided in `lama_workspace`, but they need to be modified to point towards the particular data to be used. Other than that, there is almost no change necessary.

> [!IMPORTANT]
> Ensure that you edit the `sbatch` scripts to use the proper directory `lama_workspace`!

## Population average:
- Replicate folder structure shown on this repo (easily done by just cloning it)
- Put your data inside `lama_workspace/data/population_average/inputs`
- Take whatever file you want to use as a "fixed volume" and put it inside `lama_workspace/data/target`as well
- Edit `pop_avg.toml` inside `lama_workspace/data/population_average` accordingly, so that it points to the correct fixed volume file. 
- It's good practice to make sure the thread number you specify in `pop_avg.toml` matches the number of threads you are asking for in `lama_popavg.sbatch`!
- All this done, you can submit `lama_popavg.sbatch` and that should work. Output files will be stored inside `lama_workspace` and named according to what was specified in the `sbatch` file (by default, I have `lama_popavg.out` and `lama_popavg.err`).

## Spatial normalization:
- Replicate folder structure shown on this repo (easily done by just cloning it)
- Put your baseline and mutant data inside `lama_workspace/data/wild_type_and_mutant_data/baseline/inputs/baseline` and `lama_workspace/data/wild_type_and_mutant_data/mutant/inputs/YOUR_MUTATION_NAME`, respectively.
- Put your atlas data inside `lama_workspace/data/target`. 
- Edit `generate_data.toml` inside `lama_workspace/data/wild_type_and_mutant_data` accordingly. You will need to point to a fixed volume, a fixed mask, a stats mask, a label map and a label info CSV file, so your atlas should have all that info! 
- It's good practice to make sure the thread number you specify in `generate_data.toml` matches the number of threads you are asking for in `lama_spatial.sbatch`!
- All this done, you can submit `lama_spatial.sbatch` and that should work. Remember to submit it as an array job for faster processing (`sbatch --array=1-8 lama_spatial.sbatch`)! 
- Output files will be stored inside `lama_workspace` and named according to what was specified in the `sbatch` file (by default, I have `lama_spatial_N.out` and `lama_spatial_N.err`, where `N` is the number of the job in the array).

## Stats
- Replicate folder structure shown on this repo (easily done by just cloning it)
- You need to run spatial normalization before this step. No extra input data is needed.
- Edit `stats.toml` inside `lama_workspace/data/stats_with_BH_correction` accordingly. You will need to point to a stats mask, a label map and a label info CSV file. You need these for the spatial normalization anyway, so they should already be in the right place - just make sure the file names in `stats.toml` correspond to the correct files!
- All this done, you can submit `lama_stats.sbatch` and that should work. Output files will be stored inside `lama_workspace` and named according to what was specified in the `sbatch` file (by default, I have `lama_stats.out` and `lama_stats.err`).


# Potential pitfalls
- The biggest issue was finding an atlas with all the data LAMA needs. The provided walkthrough supplies all the relevant for E14.5, but trying to run spatial normalization and stats over E15.5 proved impossible - likely due to failure to find where the corresponding atlas files were available. Make sure you have target data that is enough for LAMA!
- As noted previosuly, the Sumner2 scheduler is merciless! While the provided `sbatch` scripts request enough resources to run through the walkthrough, the memory amount may not be sufficient for your data. If your job is killed with an "Out of Memory" error and email notification, you will need to edit the `sbatch` script to increase the requested amount of memory.


# A final note

(This information is only relevant in case you decide to explore more of what LAMA can do outside of the tasks for which we are providing scripts and batch files.)

The LAMA wiki page on [running LAMA](https://github.com/mpi2/LAMA/wiki/running-lama) has a bunch of commands that use the actual python files of the utilities it is running, like for example:
```
$ lama_reg.py -c tests/test_data/population_average_data/registration_config_population_average.yaml
```

In our container, these are in our `$PATH`, so they should be invoked without `.py`:
```
$ lama_reg -c tests/test_data/population_average_data/registration_config_population_average.yaml
```
Other necesasry utilities such as `elastix` and `R` should also be on `$PATH` and available to be called directly.

# Technical notes

## The container definition

- The apptainer/singularity container is build using Ubuntu Bionic (18.04) base docker image.
- Python (3.6.9) and R (3.4.4) are installed from the official distribution using `apt`.
- The [the LAMA GitHub repo](https://github.com/mpi2/LAMA) is cloned inside the container and can be accesssed at `/LAMA/`. Then, the latest commit as of 2024/12/20 is checked out ([8ca9e4ef59c67c26f9778d951f05e792536404e3](https://github.com/mpi2/LAMA/commit/8ca9e4ef59c67c26f9778d951f05e792536404e3)).
- To resolve and create the Python environment, local testing was done with `lama_phenotype_detection == 0.9.9.100` (the latest version as of 2024/12/20) and Python 3.6.9. 
- For reproducibility, `pip-tools` was used to generate a `requirements.txt` that acts as a lockfile with all dependencies and their hashes. This file is then used for the installation in the container. Note: it will be copied into the container so it needs to be in the same directory as the definition .def file.
- `elastix` release 4.9.0 is installed from [the elastix GitHub repo](https://github.com/SuperElastix/elastix) and is available on the PATH inside the container.
