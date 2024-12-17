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
or download the container definition:
```
wget https://github.com/TheJacksonLaboratory/lama_workflow/raw/refs/heads/main/LAMA.def
```

Eitherway, once you have the .def file in your Sumner2 user-space or projects folder and you're using the build partition, you can build it using [`singularity build`](https://apptainer.org/docs/user/1.1/build_a_container.html) :

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

# Running the LAMA sample workflow on Sumner

> [!WARNING]
> This section likely needs to be updated for Sumner2. The scripts are likely to work from an interactive session using `bash <script>` but not when submitted to the cluster using `sbatch`.
> 


From now, we are following along the [walkthrough page for LAMA](https://github.com/mpi2/LAMA/wiki/walkthroughs). Grab an interactive session on Sumner (with, for example, `srun -q batch -N 1 -n 16 --mem 20G -t 01:00:00 bash`) and do the following:

```
$ module load singularity
$ singularity exec LAMA.sif lama_get_walkthrough_data 
$ cd lama_walkthroughs/
$ chmod u+x *.sh 
```

This will download the walkthrough data to the current folder, then enter the `lama_walkthroughs` folder and make the `.sh` scripts executable.

For step 1 on the walkthrough ("Make a population average"), we can use something similar to `lama_popavg.sbatch` as provided in this repository. Make sure to change references to `lama_workspace` to `lama_walkthroughs` so that it points to the right folder. To submit a job using this `sbatch` file, use something like `sbatch lama_popavg.sbatch`. Sumner will queue up your job and then run it. Output files will be stored inside `lama_walkthroughs` and named according to what was specified in the `sbatch` file (by default, I have `lama_popavg.out` and `lama_popavg.err`).

For step 2, I am providing `lama_spatial.sbatch` - it is similar to the previous step, but for parallelization and performance it should be submitted to Sumner as an array job (`sbatch --array=1-8 lama_spatial.sbatch`, for example). Make sure to change references to `lama_workspace` to `lama_walkthroughs` so that it points to the right folder. Before submitting it, check the contents of the actual script that is being called (`spatially_normalise_data.sh`) and see which TOML file is being used for config (it should be in `lama_workspace/data/wild_type_and_mutant_data/generate_data.toml`). Edit that config file to match the number of cores your batch job is asking for (16 in this case, though this and the amount of memory are just suggestions). This step in particular benefits a lot from multiple jobs running on the same data since it keeps track of what is being run by individual jobs, so maybe an array with a job per input file is a good idea, instead of always using an array of 8 jobs.

After running this step, you can move to step 3, where you can submit a similar batch job. I have provided `lama_stats.sbatch`, and that should be submitted similarly to step 1. Make sure to change references to `lama_workspace` to `lama_walkthroughs` so that it points to the right folder. It does not benefit from multiple jobs AFAIK, so I would just submit as a single job. 

All steps seemed to use all available memory (so requesting more might be a good idea), but were very inefficient CPU-wise - there might be some optimization to be done there.


# Running an actual workflow on Sumner

It is a fairly straightforward thing - I have provided the relevant TOML files and .sh scripts in this repo, but they need to be modified to point towards the particular data to be used. Other than that, there is almost no change necessary.

## Population average:
- Replicate folder structure shown on this repo (easily done by just cloning it)
- Put your data inside `lama_workspace/data/population_average/inputs`
- Take whatever file you want to use as a "fixed volume" and put it inside `lama_workspace/data/target`as well
- Edit `pop_avg.toml` inside `lama_workspace/data/population_average` accordingly, so that it points to the correct fixed volume file. 
- It's good practice to make sure the thread number you specify in `pop_avg.toml` matches the number of threads you are asking for in `lama_popavg.sbatch`!
- All this done, you can submit `lama_popavg.sbatch` and that should work. Output files will be stored inside `lama_walkthroughs` and named according to what was specified in the `sbatch` file (by default, I have `lama_popavg.out` and `lama_popavg.err`).

## Spatial normalization:
- Replicate folder structure shown on this repo (easily done by just cloning it)
- Put your baseline and mutant data inside `lama_workspace/data/wild_type_and_mutant_data/baseline/inputs/baseline` and `lama_workspace/data/wild_type_and_mutant_data/mutant/inputs/YOUR_MUTATION_NAME`, respectively.
- Put your atlas data inside `lama_workspace/data/target`. 
- Edit `generate_data.toml` inside `lama_workspace/data/wild_type_and_mutant_data` accordingly. You will need to point to a fixed volume, a fixed mask, a stats mask, a label map and a label info CSV file, so your atlas should have all that info! 
- It's good practice to make sure the thread number you specify in `generate_data.toml` matches the number of threads you are asking for in `lama_spatial.sbatch`!
- All this done, you can submit `lama_spatial.sbatch` and that should work. Remember to submit it as an array job for faster processing (`sbatch --array=1-8 lama_spatial.sbatch`)! 
- Output files will be stored inside `lama_walkthroughs` and named according to what was specified in the `sbatch` file (by default, I have `lama_spatial_N.out` and `lama_spatial_N.err`, where `N` is the number of the job in the array).

## Stats
- Replicate folder structure shown on this repo (easily done by just cloning it)
- You need to run spatial normalization before this step. No extra input data is needed.
- Edit `stats.toml` inside `lama_workspace/data/stats_with_BH_correction` accordingly. You will need to point to a stats mask, a label map and a label info CSV file. You need these for the spatial normalization anyway, so they should already be in the right place - just make sure the file names in `stats.toml` correspond to the correct files!
- All this done, you can submit `lama_stats.sbatch` and that should work. Output files will be stored inside `lama_walkthroughs` and named according to what was specified in the `sbatch` file (by default, I have `lama_stats.out` and `lama_stats.err`).


# Potential pitfalls
- The biggest issue I ran into was finding an atlas with all the data LAMA needs. The provided walkthrough supplies all the relevant for E14.5, but trying to run spatial normalization and stats over E15.5 proved impossible - I assume due to my own failure to find where the corresponding atlas files were available. I have only found a population average and a label map for it and my attempts to manually reconstruct the rest of the necessary data for spatial normalization did not work. So, heads up, make sure you have target data that is enough for LAMA!


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
- The [the LAMA GitHub repo](https://github.com/mpi2/LAMA) is cloned inside the container and can be accesssed at `/LAMA/`.
- To resolve and create the Python environment, the `pipenv` lockfile is used from [the LAMA GitHub repo](https://github.com/mpi2/LAMA), specifically from [this commit](https://github.com/mpi2/LAMA/commit/8ca9e4ef59c67c26f9778d951f05e792536404e3). To ensure compatibility, the `pipenv` release available at the commit date of the repository was used (`pipenv==2018.11.26`). The virtual environment (venv) created by `pipenv` is activated automatically at container runtime.
- `elastix` release 4.9.0 is installed from [the elastix GitHub repo](https://github.com/SuperElastix/elastix) and is available on the PATH inside the container.
