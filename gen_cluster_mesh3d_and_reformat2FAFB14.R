##########################################################################
### Code to generate meshes of activity clusters from binary 3D arrays ###
##########################################################################
#
# Input:  NRRD density image of persistent cluster (exp2, clus_3) in IBNWB space
# Output: 4 STL mesh files in FAFB14 space (meshes/clus_mesh3d_FAFB14_[1-4].stl)

library(natverse)
library(Rvcg)
library(rgl)
library(imager)

# Set repository as the working directory
repodir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(repodir)

# Use image of persistent cluster when activating pC1alpha (pC1ed)
fdir <- file.path(repodir, "densitites", "density_per_cluster_IBNWB")
fname <- "roidensity_all_07_new_exp2_clus_3.nrrd"

# Load image and binarize
# define the total number of animals contributing to this density
total_n <- 10
im   <- read.im3d(file.path(fdir, fname))
vol  <- im[]
# binarize: keep voxels active in >= 30% of animals (same threshold as original paper)
mask <- vol > total_n*.3
# smooth binary mask with median filter to remove isolated noisy voxels
mask_med <- medianblur(as.cimg(mask), n = 5)
mask_med <- mask_med[,,,1] > 0

# Generate raw and smoothed mesh
clus_mesh3d_IBNWB <- vcgIsosurface(mask_med, threshold = 0, 
                      origin = c(0, 0, 0), 
                      direction = diag(c(-1, -1, 1)), # define correct direction to match IBNWB
                      spacing = voxdims(im))

# prune small meshes (drop any connected piece with < facenum faces)
clus_mesh3d_IBNWB <- vcgIsolated(
  clus_mesh3d_IBNWB,
  facenum = 9000, # cutoff defined to just get the largest 6 volumes
  silent = TRUE
)

# split into individual components and inspect sizes
parts <- vcgIsolated(
  clus_mesh3d_IBNWB,
  split = TRUE,
  silent = TRUE
)

mesh_sizes <- data.frame(
  component = seq_along(parts),
  faces     = sapply(parts, function(m) ncol(m$it)),
  vertices  = sapply(parts, function(m) ncol(m$vb)),
  area      = sapply(parts, vcgArea)
)

# clean meshes
clus_mesh3d_IBNWB <- lapply(parts, function(m)
  vcgClean(m, sel = 0:7, iterate = TRUE, silent = TRUE))

# check if mesh is watertight
lapply(clus_mesh3d_IBNWB, function(m) vcgVolume(m))

# plot meshes: test 1
open3d()
shade3d(clus_mesh3d_IBNWB[[6]], color = "red", alpha = 0.6)

# register mesh3d to fafb14
clus_mesh3d_FAFB14 <- lapply(clus_mesh3d_IBNWB, function(m)
  xform_brain(m, "IBNWB", "FAFB14"))

# plot meshes: test 2
open3d()
plot3d(FAFB14, color = "blue", alpha = 0.6)
lapply(clus_mesh3d_FAFB14, function(m)
  shade3d(m, color = "red", alpha = 0.6))

open3d()
plot3d(FAFB14, color = "blue", alpha = 0.6)
shade3d(clus_mesh3d_FAFB14[[3]], color = "red", alpha = 0.6)

# save meshes
# Note: 
#   exclude meshes based on visual inspection
#     3 (mesh by the optic lobe what has holes)
#     4 (is the mesh mostly of somas outside neuropil)

# vcgStlWrite requires setwd to the output directory
meshdir <- file.path(repodir, "meshes")
setwd(meshdir)

# define new mesh index from 1-6 to 1-4
idx <- c(1, 2, 5, 6)

for (k in seq_along(idx)) {
  vcgStlWrite(
    mesh     = clus_mesh3d_FAFB14[[ idx[k] ]],
    filename = sprintf("clus_mesh3d_FAFB14_%d", k),
    binary   = TRUE
  )
}
