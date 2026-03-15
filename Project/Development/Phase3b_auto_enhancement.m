%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 3b - Automatic Enhancement Selector
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase3.mat');
disp('Workspace from Phase 3 loaded');

%% ----------------------------------------------------------
%  SECTION 1: RUN AUTO-ENHANCER ON ALL 15 IMAGES
% -----------------------------------------------------------

images_enhanced = cell(N, 1);
enhance_log     = cell(N, 1);   % stores which technique was applied

fprintf('\n%s\n', repmat('=', 1, 60));
fprintf('PHASE 3b — AUTOMATIC ENHANCEMENT SELECTOR\n');
fprintf('%s\n', repmat('=', 1, 60));
fprintf('%-22s | %6s | %-28s\n', 'Image', 'Mean', 'Technique applied');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    Ig = images_gray{i};
    [I_enh, technique] = auto_enhance(Ig);
    images_enhanced{i} = I_enh;
    enhance_log{i}     = technique;
    fprintf('%-22s | %6.1f | %s\n', [name ext], mean(double(Ig(:))), technique);
end

fprintf('%s\n', repmat('=', 1, 60));

%% ----------------------------------------------------------
%  SECTION 2: VISUALISE — ORIGINAL vs ENHANCED (all 15)
% -----------------------------------------------------------

figure('Name', 'Figure — Auto Enhancement: Original vs Enhanced', ...
    'NumberTitle', 'off', 'Position', [0 0 1500 900]);

for i = 1:N

    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    % Original
    subplot(3, 5, i);
    imshow(images_enhanced{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], enhance_log{i}), ...
        'FontSize', 6, 'Color', col, 'Interpreter', 'none');

end

sgtitle('Phase 3b — Enhanced images  (green = clear  |  red = obstructed)', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 3: SIDE-BY-SIDE COMPARISON PER TIER
%  Shows original vs enhanced for one image from each tier
% -----------------------------------------------------------

% Find one representative image per tier
tier_examples = struct();
for i = 1:N
    Ig  = images_gray{i};
    mn  = mean(double(Ig(:)));
    log = enhance_log{i};
    if contains(log, 'very dark') && ~isfield(tier_examples, 'very_dark')
        tier_examples.very_dark = i;
    elseif contains(log, 'dark') && ~isfield(tier_examples, 'dark')
        tier_examples.dark = i;
    elseif contains(log, 'normal') && ~isfield(tier_examples, 'normal')
        tier_examples.normal = i;
    end
end

tier_fields  = fieldnames(tier_examples);
tier_labels  = {'Very dark (mean < 50)', 'Dark (mean 50–80)', 'Normal (mean ≥ 80)'};
nTiers       = length(tier_fields);

figure('Name', 'Figure — Tier comparison: Original vs Enhanced', ...
    'NumberTitle', 'off', 'Position', [0 0 900 700]);

for t = 1:nTiers

    if ~isfield(tier_examples, tier_fields{t}); continue; end

    i  = tier_examples.(tier_fields{t});
    Ig = images_gray{i};
    Ie = images_enhanced{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    subplot(nTiers, 2, (t-1)*2 + 1);
    imshow(Ig);
    title(sprintf('%s\nOriginal — Mean: %.0f', [name ext], mean(double(Ig(:)))), ...
        'FontSize', 8, 'Color', col, 'Interpreter', 'none');

    subplot(nTiers, 2, (t-1)*2 + 2);
    imshow(Ie);
    title(sprintf('%s\n%s', tier_labels{t}, enhance_log{i}), ...
        'FontSize', 8, 'Color', col);

end

sgtitle('Figure — Tier-based auto enhancement: original vs enhanced', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 4: QUANTITATIVE COMPARISON — all 15 images
%  Original vs enhanced: mean, std, edge density, SSIM
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 90));
fprintf('PHASE 3b — ORIGINAL vs ENHANCED: all images\n');
fprintf('%s\n', repmat('=', 1, 90));
fprintf('%-22s | %-6s | %6s | %6s | %10s | %6s | %s\n', ...
    'Image', 'Label', 'Mean', 'Std', 'Edge dens.', 'SSIM', 'Technique');
fprintf('%s\n', repmat('-', 1, 90));

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    Ig = images_gray{i};
    Ie = images_enhanced{i};

    if labels(i) == 0; lbl = 'CLEAR'; else; lbl = 'OBSTR'; end

    mn    = mean(double(Ie(:)));
    sd    = std(double(Ie(:)));
    edens = sum(sum(edge(Ie, 'Canny'))) / numel(Ie) * 100;
    sv    = ssim(Ie, Ig);

    fprintf('%-22s | %-6s | %6.1f | %6.1f | %9.2f%% | %6.4f | %s\n', ...
        [name ext], lbl, mn, sd, edens, sv, enhance_log{i});
end

fprintf('%s\n', repmat('=', 1, 90));

%% ----------------------------------------------------------
%  SECTION 5: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase3b.mat', ...
    'images', 'images_gray', 'images_enhanced', ...
    'filenames', 'labels', 'descriptions', ...
    'N', 'enhance_log');

fprintf('\nWorkspace saved to ./Output/workspace_phase3b.mat\n');

%% ----------------------------------------------------------
%  LOCAL FUNCTIONS
% -----------------------------------------------------------

function [I_out, technique] = auto_enhance(Ig)
%AUTO_ENHANCE Automatically selects and applies the best enhancement
%   technique based on the mean intensity of the input grayscale image.
%
%   Inputs:
%     Ig        — grayscale uint8 image
%
%   Outputs:
%     I_out     — enhanced grayscale uint8 image
%     technique — string describing which technique was applied
%
%   Tiers:
%     mean < 50  → very dark  → gamma(0.4) + CLAHE [8x8]
%     mean 50-80 → dark       → gamma(0.6) + CLAHE [8x8] + imsharpen
%     mean >= 80 → normal     → imsharpen + imadjust

    mn = mean(double(Ig(:)));

    if mn < 50
        % Very dark (e.g. deep tunnel) — aggressive brightening first,
        % then CLAHE to recover local contrast
        I_gam  = imadjust(Ig, [], [], 0.4);
        I_out  = adapthisteq(I_gam, 'NumTiles', [8 8], 'ClipLimit', 0.01);
        technique = sprintf('very dark (mean=%.0f): gamma(0.4) + CLAHE [8x8]', mn);

    elseif mn < 80
        % Dark (e.g. tunnel with some light) — moderate brightening,
        % CLAHE for local contrast, sharpen for edges
        I_gam  = imadjust(Ig, [], [], 0.6);
        I_clahe = adapthisteq(I_gam, 'NumTiles', [8 8], 'ClipLimit', 0.01);
        I_out  = imsharpen(I_clahe, 'Amount', 1.0, 'Radius', 1, 'Threshold', 0);
        technique = sprintf('dark (mean=%.0f): gamma(0.6) + CLAHE [8x8] + imsharpen', mn);

    else
        % Normal/bright (outdoor, station, crossing) — sharpen edges
        % and mild contrast stretch
        I_sharp = imsharpen(Ig, 'Amount', 1.0, 'Radius', 1, 'Threshold', 0);
        I_out   = imadjust(I_sharp, [0.20 0.80], []);
        technique = sprintf('normal (mean=%.0f): imsharpen + imadjust [0.20 0.80]', mn);

    end

end