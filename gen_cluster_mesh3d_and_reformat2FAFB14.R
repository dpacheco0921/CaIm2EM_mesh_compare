##########################################################################
### Code to generate meshes of activity clusters from binary 3D arrays ###
##########################################################################

library(natverse)
library(Rvcg)
library(rgl)

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

# Generate raw and smoothed mesh
clus_mesh3d_IBNWB <- vcgIsosurface(mask, threshold = 0, 
                      origin = c(0, 0, 0), 
                      direction = diag(c(-1, -1, 1)), 
                      spacing = voxdims(im))
clus_mesh3d_IBNWB_sm <- vcgQEdecim(clus_mesh3d_IBNWB, percent = 0.2)
clus_mesh3d_IBNWB_sm <- vcgSmooth(
  clus_mesh3d_IBNWB_sm,
  type = "laplace",
  iteration = 10,
  lambda = 0.5
)

# register mesh3d to fafb14
clus_mesh3d_FAFB14 <- xform_brain(clus_mesh3d_IBNWB, "IBNWB", "FAFB14")
clus_mesh3d_FAFB14_sm <- xform_brain(clus_mesh3d_IBNWB_sm, "IBNWB", "FAFB14")

# plot meshes
open3d()
plot3d(FAFB14, color = "blue", alpha = 0.6)
shade3d(clus_mesh3d_FAFB14, color = "red", alpha = 0.6)

open3d()
plot3d(FAFB14, color = "blue", alpha = 0.6)
shade3d(clus_mesh3d_FAFB14_sm, color = "red", alpha = 0.6)

# save meshes
meshdir <- file.path(repodir, "meshes")
setwd(meshdir)

vcgStlWrite(
  mesh     = clus_mesh3d_FAFB14,
  filename = "clus_mesh3d_FAFB14",  # .stl will be appended automatically
  binary   = TRUE                   # or FALSE for ASCII
)

vcgStlWrite(
  mesh     = clus_mesh3d_FAFB14_sm,
  filename = "clus_mesh3d_FAFB14_sm",  # .stl will be appended automatically
  binary   = TRUE                   # or FALSE for ASCII
)
