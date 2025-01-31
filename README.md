# DS-101-Final

The final project in DS course

### Setting up an Environment and Git for Clean Notebooks

Steps to create a conda environment for project and configure Git to automatically clean Jupyter Notebooks (`.ipynb`) before committing.

#### 1. Create and Activate Conda Environment

###### 1.1 Option 1 using conda

```bash
conda create -f env.yml -n DS-101-Final -y
conda activate DS-101-Final
```

_Note:_ PowerShell might encounter issues with conda activation. Using `cmd.exe` is often more reliable.

###### 1.2 Option 2 using mamba

conda create -n DS-101-Final python=3.12.8 -y
conda install -c conda-forge mamba -y
mamba install -f requirements.txt -y

#### 2. Configure Git for Notebook Cleaning

Automatically clean Jupyter Notebooks (remove outputs and metadata) before committing, you need to configure Git attributes and the `nb-clean` filter.

**2.1 Find your Conda Installation Path:**

```
where conda # Windows
which conda # macOS/Linux
```

**2.2 Add the DS-101-Final Scripts Path to Environment Variables:**

Add the path to the `nb-clean` executable (located within your `DS-101-Final` environment's `Scripts` or `bin` directory) to your system's PATH environment variable. The typical path is:

- **Windows:** `conda_path\envs\DS-101-Final\Scripts` (e.g., `C:\Users\YourUser\anaconda3\envs\DS-101-Final\Scripts`)
- **macOS/Linux:** `conda_path/envs/DS-101-Final/bin` (e.g., `/Users/youruser/anaconda3/envs/DS-101-Final/bin`)

**2.3 Restart your computer:**

For the PATH changes to take effect, you _must_ restart your terminal or IDE.

**2.4 Configure the Git Filter:**

```
git config --global filter.nb-clean.clean "nb-clean clean"
git config --global filter.nb-clean.smudge "cat"
```

This ensures that notebooks are automatically cleaned (outputs and metadata removed) when using `git add`.
