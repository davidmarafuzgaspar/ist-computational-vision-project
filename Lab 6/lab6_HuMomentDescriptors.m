%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script is a model for the following operations:
% 1) Find the descriptors of a set of images
% 2) Perform PCA analysis
% It performs the clustering of the data given a number of classes. This
% clustering has as objective to find the center of mass of each class.
%
% developed by Prof. Rogério Caldas Pinto @ IST
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lab6_HuMomentDescriptors(printFigures)

%% Initializations:
Number_of_descriptors = 7;  % Hu moments
NC = 3; % number of classes    (Change if different)
% existing classes:  (note these names are the names given to the images
c1 = 'rho_build';
c2 = 'squ_build';
c3 = 'tri_build';

%% step 2: evaluation of the descriptors
% Read images from a directory
d = dir(['datasetImages\*.' 'jpg']);

% Inicialize the descriptor matrix:
dm = zeros(size(d,1),Number_of_descriptors);
% preallocate cell array
e = cell(size(d));
e{size(d,1),1} = [];
% Read the name of the images:
for k = 1:size(d)
    e{k,:} = d(k).name;
end

% To count the number of objects (images) from each class
nelem1 = 0;
nelem2 = 0;
nelem3 = 0;

% Read and evaluate the descriptors
idx = zeros(size(d));
for k = 1:length(e) % for all images
    % the elements of the vector idx correspond to the groundtrue (defined
    % by the filename)
    cc = e{k};
    kk = strfind(cc,'('); % identifies the position of '(' in the filename
    switch cc(1:kk-1) % compares the filename with the defined classes
        case c1 % quad
            idx(k) = 1;
            nelem1 = nelem1 + 1; 
        case c2 % triang
            idx(k) = 2;
            nelem2 = nelem2 + 1;
        case c3 % los
            idx(k) = 3;
            nelem3 = nelem3 + 1;
        %case c4
            % ..........
    end
    
    % evaluation of the descriptors
    imagename = ['datasetImages\' e{k}];
    % at least for these descriptors
    A = imbinarize(imread(imagename)); % binarizes image - may not be necessary  
    A = imcomplement(A); % complement of the image (object is white)
    
    % Hu Invariant Moments(A)
    dm(k,1:Number_of_descriptors) = HuInvariantMoments(A);
end

%%  step 3: PCA analysis
[coeff,score,latent,~] = pca(dm(:,1:Number_of_descriptors),'Centered',false);

%%%%%%%%%%%%%%%%%%%%%%%%%
cd = 2;  % cd: chosen dimension that depends on the problem and data
%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% step 4: find the center of mass of each distribution
jj1 = 1;
jj2 = 1;
jj3 = 1;

sc1 = zeros(nelem1,cd);
sc2 = zeros(nelem2,cd);
sc3 = zeros(nelem3,cd);
for kk = 1:length(idx)
    switch idx(kk)
        case 1
            sc1(jj1,:) = score(kk,1:cd);
            jj1 = jj1 + 1;
        case 2
            sc2(jj2,:) = score(kk,1:cd);
            jj2 = jj2 + 1;
        case 3
            sc3(jj3,:) = score(kk,1:cd);
            jj3 = jj3 + 1;
    end
end
cc = zeros(NC,cd);
cc(1,:) = mean(sc1);
cc(2,:) = mean(sc2);
cc(3,:) = mean(sc3);

% Comment to speed up the process
if printFigures==1
    biplot(coeff(:,1:2),'scores',score(:,1:cd));

    % Represent graphically the data to verify that it is indeed well separated
    figure;
    X = score(:,1:2);
    plot(X(idx==1,1),X(idx==1,2),'r.','MarkerSize',12)
    hold on
    plot(X(idx==2,1),X(idx==2,2),'b.','MarkerSize',12)
    hold on
    plot(X(idx==3,1),X(idx==3,2),'c.','MarkerSize',12)
    plot(cc(:,1),cc(:,2),'kx',...
        'MarkerSize',15,'LineWidth',3)
    legend('Cluster 1','Cluster 2','Cluster 3','Centroids',...
        'Location','NW')
    title 'Cluster Assignments and Centroids'
    hold off

end

% save data to be used with the real time classifier
save('HuMoments','coeff','cc')
end