function [propsTable, XTrain, YTrain, XTest, YTest] = lab7_buildTable(Props)
% Adds dataset folder to path and declare global variables
addpath('Data');

% Removes missing properties (the commented ones)
Props = rmmissing(Props);

% Number of properties
nProps = length(Props);

% Define classes and number of test images per class
classNames = ["Rhombus", "Square", "Triangle"];
imgNames = ["rho", "squ", "tri"];
nClasses = length(classNames);
nImagesperClass = 9;

% Load each image and extract properties
for classNumber = 1:nClasses
    imgName = imgNames(classNumber);
%     class = classNames(classNumber);
    for i = 1:nImagesperClass
        imgIn = imread(sprintf('%s(%d).jpg', imgName, i));
        SE = strel('disk',1);
        img = imerode(imbinarize(imcomplement(imgIn)), SE);
        currentLine = i + ((classNumber - 1)*nImagesperClass);
        propsTable(currentLine, 1:nProps) = regionprops('table', img, Props);
        classVector(1, currentLine)=classNames(classNumber);
    end
end
propsTable.Class = classVector';

% Display table
disp(propsTable)


%% Partition Data
% Convert data to matrix
propsMatrix = table2array(propsTable(:, 1:end-1));

% Partition data
data = cvpartition(classVector, "Holdout", 0.2);

% Indeces for training and testing
trainIndices = training(data);
testIndices = test(data);

% Properties and class for training
XTrain = propsMatrix(trainIndices, :);
YTrain = cellstr(classVector(trainIndices))';


% Properties and class for training
XTest = propsMatrix(testIndices, :);
YTest = cellstr(classVector(testIndices))';

end