%% Code to display 2D projections of densitites of each functional cluster

% 1) define image directory
tDir = strrep(which('display_cluster_densitites'), ...
    'display_cluster_densitites.m', '');
imdir = [tDir, 'densitites', filesep];

% 2) name conventions
im_string = {'cnt', 'exp1', 'exp2'};
exp_string = {'cnt', 'pC1split', 'pC1alpha'};
cluster_string = {'clus-1 (ON-1)', 'clus-2 (ON-2)', 'clus-3(ON persist)', 'clus-4(ramp)'};
n_totalperexp = [11 7 10];

% 3) load all images
target_dir = [imdir, filesep, 'density_per_cluster_IBNWB'];
im2plot = [];
exptype = {'roidensity_all_07_new_cnt_clus_', ...
    'roidensity_all_07_new_exp1_clus_', ...
    'roidensity_all_07_new_exp2_clus_'};
for exp_i= 1:numel(exptype)
    for clus_i = 1:4
        f2load = [target_dir, filesep, exptype{exp_i}, num2str(clus_i), '.nrrd'];
        im2plot{exp_i, clus_i} = nrrdread(f2load);
    end
end

% 4) plot results from activating pC1-alpha (pC1ed)

figure('Position', [1 1 1800 300])
n_bis = 8;
cmap_ = colorGradient([1 1 1], [1 0 1], ceil(n_bis/2));
colormap2use = colorGradient([1 0 1], [0 1 1], ceil(n_bis/2));
colormap2use = [cmap_(1:end-1, :); colormap2use];
clear cmap_
colormap(colormap2use)
exp_i = 3;
max_per_exp = n_totalperexp(exp_i);
for clus_i = 1:4
    axH(clus_i) = subplot(1, 4, clus_i);
    tempim = double(im2plot{exp_i, clus_i});
    tempim = (tempim/max_per_exp)*100;
    imagesc(max(flip(tempim, 2), [], 3), 'Parent', axH(clus_i))
    caxis(axH(clus_i), [30 100])
    axH(clus_i).Title.String = cluster_string{clus_i};
    colorbar
end
