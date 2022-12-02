function classificationTest(MEX_PATH)
clear;
% if nargin < 1
%     MEX_PATH = '../build';
% end
% 
% addpath(MEX_PATH);
load("C:\Users\md_ra\Box Sync\PhD\Stair case detection\Code\Matlab\Finals\createDataset\Mean\15\individual\train_12.mat");
load("C:\Users\md_ra\Box Sync\PhD\Stair case detection\Code\Matlab\Finals\createDataset\Mean\15\individual\test_12.mat");
file_data = trainMatrix;
Data = file_data(:,1:2)';
Labels = file_data(:, end)';
Labels = Labels*2 - 1;

X = Data';
Y = Labels';

X_test = (testMatrix(:,1:2));
Y_test = (testMatrix(:,end));
Y_test = Y_test*2 - 1;
% numTrain = round(length(Y)/2);

train.X = X;
train.Y = Y;

test.X = X_test;
test.Y = Y_test;

opts = [];
opts.loss = 'exploss'; % can be logloss or exploss

% gradient boost options
opts.shrinkageFactor = 0.1;
opts.subsamplingFactor = 0.5;
opts.maxTreeDepth = uint32(2);  % this was the default before customization
opts.randSeed = uint32(rand()*1000);

numIters = 200;
tic;
model = SQBMatrixTrain(single(train.X), train.Y, uint32(numIters), opts);
toc

pred = SQBMatrixPredict( model, single(test.X) );

err = sum( (pred > 0) ~= (test.Y > 0))/length(pred);
fprintf('Prediction error: %f\n', err);