##########################################################################
### Code to generate meshes of activity clusters from binary 3D arrays ###
##########################################################################

library(natverse)
library(Rvcg)
library(rgl)
library(imager)

# Path to your image files of cluster densities
# Note: add the CaIm2EM_mesh_compare repository main directory
repodir <- "add repository directory"
setwd(repodir)

# Use image of persistent cluster when activating pC1alpha (pC1ed)
fdir <- file.path(repodir, "densitites", "density_per_cluster_IBNWB")
fname <- "roidensity_all_07_new_exp2_clus_3.nrrd"

# Load image and binarize
total_n <- 10
im   <- read.im3d(file.path(fdir, fname))
vol  <- im[]
mask <- vol > total_n*.3
mask_med <- medianblur(as.cimg(mask), n = 5)
mask_med <- mask_med[,,,1] > 0

# Generate raw and smoothed mesh
clus_mesh3d_IBNWB <- vcgIsosurface(mask_med, threshold = 0, 
                      origin = c(0, 0, 0), 
                      direction = diag(c(-1, -1, 1)), 
                      spacing = voxdims(im))

# prune small meshes (drop any connected piece with < facenum faces)
clus_mesh3d_IBNWB <- vcgIsolated(
  clus_mesh3d_IBNWB,
  facenum = 9000,
  silent = TRUE
)

# get mesh size
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
#   exclude meshes
#     3 (mesh by the optic lobe what has holes)
#     4 (is the mesh mostly of somas outside neuropil)

meshdir <- file.path(repodir, "meshes")
setwd(meshdir)

idx <- c(1, 2, 5, 6)

for (k in seq_along(idx)) {
  vcgStlWrite(
    mesh     = clus_mesh3d_FAFB14[[ idx[k] ]],
    filename = sprintf("clus_mesh3d_FAFB14_%d", k),
    binary   = TRUE
  )
}
