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

# build surface object similar to IBNWB.surf
# 1. Vertices: clus_mesh3d_FAFB14$vb is 4 x N (homogeneous coords)
verts <- t(clus_mesh3d_FAFB14$vb[1:3, ])  # drop homogeneous row, N x 3

Vertices <- data.frame(
  X = verts[, 1],
  Y = verts[, 2],
  Z = verts[, 3],
  PointNo = seq_len(nrow(verts))
)

verts_sm <- t(clus_mesh3d_FAFB14_sm$vb[1:3, ])  # drop homogeneous row, N x 3

Vertices_sm <- data.frame(
  X = verts_sm[, 1],
  Y = verts_sm[, 2],
  Z = verts_sm[, 3],
  PointNo = seq_len(nrow(verts_sm))
)

# 2. Faces/triangles: mesh$it is 3 x nFaces (indices into vb columns)
tri <- t(clus_mesh3d_FAFB14$it)  # nFaces x 3

Regions_df <- data.frame(
  V1 = tri[, 1],
  V2 = tri[, 2],
  V3 = tri[, 3]
)

tri_sm <- t(clus_mesh3d_FAFB14_sm$it)  # nFaces x 3

Regions_df_sm <- data.frame(
  V1 = tri_sm[, 1],
  V2 = tri_sm[, 2],
  V3 = tri_sm[, 3]
)

# 3. Wrap into hxsurf-like structure
region_name <- "Exterior000001"
clus_mesh3d_FAFB14 <- list(
  Vertices = Vertices,
  Regions = setNames(list(Regions_df), region_name),
  RegionList = region_name,
  RegionColourList = "#FFCC66"  # or any color you like
)
class(clus_mesh3d_FAFB14) <- c("hxsurf", "list")
str(clus_mesh3d_FAFB14, max.level = 1)

region_name <- "Exterior000001"
clus_mesh3d_FAFB14_sm <- list(
  Vertices = Vertices_sm,
  Regions = setNames(list(Regions_df_sm), region_name),
  RegionList = region_name,
  RegionColourList = "#FFCC66"  # or any color you like
)
class(clus_mesh3d_FAFB14_sm) <- c("hxsurf", "list")
str(clus_mesh3d_FAFB14_sm, max.level = 1)

# Visualize both meshes to compare
open3d()
plot3d(FAFB14, color = "blue", alpha = 0.6)
plot3d(clus_mesh3d_FAFB14, color = "red", alpha = 0.6)

# Visualize both meshes to compare
open3d()
plot3d(FAFB14, color = "blue", alpha = 0.6)
plot3d(clus_mesh3d_FAFB14_sm, color = "red", alpha = 0.6)
