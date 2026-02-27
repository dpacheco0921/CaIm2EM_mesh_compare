###############################################################
### Code to load activity cluster and check synapse overlap ###
###############################################################

library(natverse)
library(fafbseg)
library(rgl)
library(Rvcg)

# Path to your image files of cluster densities
# Note: add the CaIm2EM_mesh_compare repository main directory
repodir <- "add repository directory"
setwd(repodir)

###############################################################
### load cluster meshes
###############################################################

clus_mesh3d_FAFB14_each <- lapply(1:4, function(i) {
  vcgImport(
    file.path(repodir, "meshes",
              sprintf("clus_mesh3d_FAFB14_%d.stl", i))
  )
})

clus_mesh3d_FAFB14_each <- lapply(clus_mesh3d_FAFB14_each, function(m)
  vcgClean(m, sel = 0:7, iterate = TRUE, silent = TRUE))

# check if mesh is watertight
lapply(clus_mesh3d_FAFB14_each, function(m) vcgVolume(m))

open3d()
plot3d(FAFB14, color = "blue", alpha = 0.6)
lapply(clus_mesh3d_FAFB14_each, function(m)
  shade3d(m, color = "red", alpha = 0.6))

###############################################################
### load synapses
###############################################################

# download synapse coordinates csv file from:
#   https://codex.flywire.ai/api/download?dataset=fafb
#   move to "synapses" folder in repository, and rename it to 
#   "synapse_coordinates.csv"

# load csv file with all synapses (Buhman synapses)
csvdir <- file.path(repodir, "synapses", "synapse_coordinates.csv")
synapses_xyz <- read.csv(csvdir)

# get xyz, and transform
syn_xyz <- synapses_xyz[, c("x","y","z")]
syn_xyz <- transform(syn_xyz,
                     x = as.numeric(x),
                     y = as.numeric(y),
                     z = as.numeric(z))
syn_xyz <- syn_xyz[complete.cases(syn_xyz), ]

# find synapses inside cluster meshes (run for each mesh separately and then get the union)
#   it uses nat::pointsinside which assumes meshes must be watertight.
inside_list <- lapply(1:4, function(i) nat::pointsinside(syn_xyz, clus_mesh3d_FAFB14_each[[i]]))
inside <- Reduce(`|`, inside_list)

# save logical vector "inside"
csvoutdir <- file.path(repodir, "synapses", "points_inside_persistent_cluster_buhman.csv")
write.csv(data.frame(inside = inside), csvoutdir, row.names = FALSE)

# load logical vector "inside" to confirm size and reability
# inside <- read.csv(csvoutdir)

# load csv file with all synapses (Princeton synapses)
csvdir <- file.path(repodir, "synapses", "fafb_v783_princeton_synapse_table.csv")
synapses_xyz <- read.csv(csvdir)

# get xyz, and transform
syn_xyz <- synapses_xyz[, c("post_x","post_y","post_z")]
colnames(syn_xyz) <- c("x", "y", "z")
syn_xyz <- transform(syn_xyz,
                     x = as.numeric(x),
                     y = as.numeric(y),
                     z = as.numeric(z))
syn_xyz <- syn_xyz[complete.cases(syn_xyz), ]

# find synapses inside cluster meshes (run for each mesh separately and then get the union)
#   it uses nat::pointsinside which assumes meshes must be watertight.
inside_list <- lapply(1:4, function(i) nat::pointsinside(syn_xyz, clus_mesh3d_FAFB14_each[[i]]))
inside <- Reduce(`|`, inside_list)

# save logical vector "inside"
csvoutdir <- file.path(repodir, "synapses", "points_inside_persistent_cluster_princeton.csv")
write.csv(data.frame(inside = inside), csvoutdir, row.names = FALSE)

# load logical vector "inside" to confirm size and reability
# inside <- read.csv(csvoutdir)

###############################################################
# debugging: plot and overlay with brain surface
###############################################################

# 1) plot mesh and FAFB14 surface
open3d()
plot3d(FAFB14, color = "grey", alpha = 0.3)
lapply(clus_mesh3d_FAFB14_each, function(m)
  shade3d(m, color = "red", alpha = 0.6))

# 2) plot synapses and mesh surface
open3d()
plot3d(FAFB14, color = "grey", alpha = 0.3)
lapply(clus_mesh3d_FAFB14_each, function(m)
  shade3d(m, color = "blue", alpha = 0.3))
points3d(syn_xyz[inside,1], syn_xyz[inside,2], syn_xyz[inside,3], size = 3, color = "red")
