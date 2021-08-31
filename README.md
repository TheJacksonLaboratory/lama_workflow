# lama_workflow
Repo with the inner workings for a container-based LAMA workflow.

# Running the LAMA sample workflow on Sumner

Build the container from `LAMA.rec` in whichever way you prefer and place it somewhere Sumner has access to. I'll refer to the built container as `LAMA.sif`.

From now, we are following along the [walkthrough page for LAMA](https://github.com/mpi2/LAMA/wiki/walkthroughs). Grab an interactive session on Sumner and the following:

```
$ module load singularity
$ singularity exec LAMA.sif lama_get_walkthrough_data 
$ cd lama_walkthroughs/
$ chmod u+x *.sh # make excecutable
```

This will download the walkthrough data to the current folder. Enter the `lama_walkthroughs` folder and make the `.sh` scripts executable.

Now I will skip step 1 on the walkthrough ("Make a population average") since it's standalone and similar to step 2 in execution.

For step 2, I am providing the `sbatch` file I've submitted to Sumner as an array job (`sbatch --array=1-8 LAMA.sbatch`, for example). Before submitting it, check the contents of the actual script that is being called (`spatially_normalise_data.sh`) and see which TOML file is being used for config. Edit that config file to match the number of cores your batch job is asking for (16 in this case, though this and the amount of memory are just suggestions). This step in particular benefits a lot from multiple jobs running on the same data since it keeps track of what is being run by individual jobs, so maybe an array with a job per input file is a good idea.

After running this step, you can move to step 3, where you can submit a similar batch job. It does not benefit from multiple jobs AFAIK, so I would remove the references to `$$SLURM_ARRAY_TASK_ID` and just submit as a single job. 

Both steps seemed to use all available memory (so requesting more might be a good idea), but were very inefficient CPU-wise - there might be some optimization to be done there.

# Running an actual workflow on Sumner

I think it is a fairly straightforward thing - we'd need to build the TOML files (that can be strongly inspired by the ones provided by `lama_walkthroughs`) and shell scripts (also inspired by the existing ones) for the particular data to be used, but I think it would be a pretty similar process to this walkthrough process.

# A final note

The LAMA wiki page on [running LAMA](https://github.com/mpi2/LAMA/wiki/running-lama) has a bunch of commands that use the actual python files of the utilities it is running, like for example:
```
$ lama_reg.py -c tests/test_data/population_average_data/registration_config_population_average.yaml
```

In our container, these are in our `$PATH`, so they should be invoked without `.py`:
```
$ lama_reg -c tests/test_data/population_average_data/registration_config_population_average.yaml
```
Other necesasry utilities such as `elastix` and `R` should also be on `$PATH` and available to be called directly.