%% Function lab5_buildDescriptors: builds a dataset of descriptors using a feature detection method, given a set of images
%  > Outputs: descrip struct, with fields - 'Number', 'Name', 'Features' and 'Points'
%  > Procedure: 
%     1) given a number of classes (nClasses), loads the sample images belonging to that class.
%     As an example, 3 classes ('Rhombus', 'Square' and 'Triangle') are used, with 4 sample images for each;
%     2) given the input method, detects the features and points for all 4 sample images and adds them to a matrix;
%     2.a) shows the sample images for each class, plotting the interest
%     points for each sample image;
%     3) outputs the 'descrip' struct with the descriptor data
% 
%  > EDIT THE CODE WHEN MARKED FOR THE FEATURE DETECTION AND EXTRACTION (point 2)
[descripRho, descripSqu, descripTri, featuresRho, featuresSqu, featuresTri] = lab5_buildDescrip;

function [descripRho, descripSqu, descripTri, featuresRho, featuresSqu, featuresTri] = lab5_buildDescrip
    %% Select class to extract interest points
    % Additionally, loads a string with class name and name for file
    nClasses = 3;
    
    % Add image folder to current path
    restoredefaultpath
    addpath(cd, './Data/datasetImages');

    for class = 1 : nClasses
        if class == 1
                str = 'Rhombus';
                imgName = 'rho_build';
        elseif class == 2
                str = 'Square';
                imgName = 'squ_build';
        elseif class == 3
                str = 'Triangle';
                imgName = 'tri_build';
        else
            fprintf('\n Error: Please create another class for this class number.\n');
            return
        end
        
        %% Detect and extract interest points and features
        
        feats = [];% featPts = [];
        % Reads 4 images for each class
        for i=1:4
            img=imread(sprintf('%s(%d).jpg',imgName,i));
            
            
            % ---------------- EDIT THE CODE HERE ---------------- %
            
            % Feature detection
            points = detectSURFFeatures(img);
%             points = detectHarrisFeatures(img);
%             points = detectBRISKFeatures(img);
%             points = detectFASTFeatures(img);
%             points = detectORBFeatures(img);
            
            % Extract features and points
            [newFeats, newPts] = extractFeatures(img, points);
            
            % -------------------- STOP HERE! -------------------- %
            
            % Correction because surfpoints has a different field structure
            if isa(points, 'SURFPoints') == 1
                feats = [feats; newFeats];
            else
                feats = [feats; newFeats.Features];
            end
            if ~exist('featPts', 'var')
                featPts = newPts;
            else
                featPts = [featPts; newPts];
            end
            
            % Show images and plot interest points (Optional)
            sgtitle('Detected Features')
            subplot(nClasses, 4, i + 4*(class - 1)), imshow(img), hold on
            plot(newPts.Location(:,1), newPts.Location(:,2), 'r*','MarkerSize',2),
            title(['Class ' num2str(class) ' - ', str])
            hold off
        end
        
        % Save class to struct
        descripFull(class).Number = class;
        descripFull(class).Name = str;
        descripFull(class).Features = feats;
        descripFull(class).Points = featPts;
        clear feats featPts
    end
    descripRho = descripFull(1);
    descripSqu = descripFull(2);
    descripTri = descripFull(3);
    featuresRho = descripRho.Features;
    featuresSqu = descripSqu.Features;
    featuresTri = descripTri.Features;
    save('./Data/output/featuresRho', 'featuresRho')
    save('./Data/output/featuresSqu', 'featuresSqu')
    save('./Data/output/featuresTri', 'featuresTri')
end
