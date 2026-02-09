# CaIm2EM Mesh Compare

Pipeline for identifying electron microscopy (EM) synapses that overlap with 3D meshes of functional activity clusters derived from calcium imaging in *Drosophila*.

## Overview

This repository bridges calcium imaging (functional activity) with connectomics (structural connectivity) by:

1. Converting voxel density maps of neural activity clusters into 3D meshes
2. Transforming those meshes into the FAFB14 EM coordinate space
3. Testing which FlyWire synapses fall inside the activity cluster meshes

## Pipeline

```
NRRD density images (IBNWB space)
        |
        v
  gen_cluster_mesh3d_and_reformat2FAFB14.R
  (binarize -> isosurface -> filter -> transform to FAFB14)
        |
        v
  STL mesh files (FAFB14 space)
        |
        v
  cluster2syn_overlap.R
  (load meshes + FlyWire synapses -> point-in-mesh test)
        |
        v
  points_inside_persistent_cluster.csv
```

## Scripts

| Script | Description |
|--------|-------------|
| `gen_cluster_mesh3d_and_reformat2FAFB14.R` | Generates 3D meshes from density images: applies median filtering, binarizes at 30% threshold, creates isosurfaces, removes small components, and transforms from IBNWB to FAFB14 space. Exports 4 STL files. |
| `gen_cluster_hxsurf_and_reformat2FAFB14.R` | Alternative mesh generation producing HXSurf-format surfaces (compatible with Amira/Avizo), with decimation and Laplacian smoothing. |
| `cluster2syn_overlap.R` | Main analysis script. Loads cluster meshes and synapse coordinates, uses `nat::pointsinside()` for point-in-polyhedron testing, and outputs a logical vector indicating which synapses are inside the persistent cluster. |
| `display_cluster_densitites.m` | MATLAB script for 2D maximum intensity projections of cluster density images across experimental conditions. |

## Data organization

```
densitites/
  density_per_cluster_IBNWB/   # Density images in IBNWB brain space
  density_per_cluster_IVIA/    # Density images in IVIA brain space
meshes/
  clus_mesh3d_FAFB14_[1-4].stl # Activity cluster meshes in FAFB14 space
synapses/
  points_inside_persistent_cluster.zip  # Output: synapse overlap results
```

### Density images

NRRD files named `roidensity_all_07_new_{condition}_clus_{cluster}.nrrd`, where:
- **Conditions**: `cnt` (control), `exp1` (pC1split), `exp2` (pC1alpha activation)
- **Clusters**: 1 (ON-1), 2 (ON-2), 3 (ON persistent), 4 (Ramp)

### Synapse data

Synapse coordinates are downloaded from [FlyWire Codex](https://codex.flywire.ai/api/download?dataset=fafb) in FAFB14 space.

## Dependencies

### R packages
- [natverse](https://natverse.org/) -- neuroanatomy toolbox (`pointsinside()`, `xform_brain()`, `read.im3d()`)
- [Rvcg](https://cran.r-project.org/package=Rvcg) -- 3D mesh processing (`vcgIsosurface()`, `vcgClean()`, `vcgImport()`, etc.)
- [rgl](https://cran.r-project.org/package=rgl) -- 3D visualization
- [fafbseg](https://natverse.org/fafbseg/) -- FAFB brain surface and segmentation tools
- [imager](https://cran.r-project.org/package=imager) -- image filtering

### MATLAB (optional, for visualization only)
- `nrrdread()`, `colorGradient()` (custom functions)

## References

Deutsch D, Pacheco DA, Encarnacion-Rivera L, Pereira T, Fathy R, Calhoun A, Ireland E, Burke A, Dorkenwald S, McKellar C, Macrina T, Lu R, Lee K, Kemnitz N, Ih D, Castro M, Halageri A, Jordan C, Silversmith W, Wu J, Seung S, and Murthy M. 2020. "The Neural Basis for a Persistent Internal State in Drosophila Females", [https://doi.org/10.7554/eLife.59502](https://doi.org/10.7554/eLife.59502).
