function [DataTrain, DataTrainLabel, DataTest, DataTestLabel, OutputData] = getFeatureSelectedData(trainBlockData, trainBlockLabel, testBlockData, testBlockLabel, opts)

    FeatureSelectionName = opts.FeatureSelectionName;
    featureSelectionFunction = str2func(FeatureSelectionName);

    OutputData = struct();

    nBlock = numel(trainBlockData);
    FeaSelSortMat = zeros(nBlock, size(trainBlockData{1}, 2)); 

    for iBlock = 1:nBlock
        %*** DataSelTrain/DataSelTest: sample*featureLength ***
        [DataSelTrain, DataSelTrainLabel] = getTrainTestData(trainBlockData, trainBlockLabel, iBlock, opts);

        FeaSelScore = featureSelectionFunction(DataSelTrain, double(DataSelTrainLabel));

        FeaSelSortMat(iBlock, :) = FeaSelScore;
    end

    meanFeaSelScore = mean(FeaSelSortMat, 1);
    [SortedScore, SortedScoreIdx] = sort(meanFeaSelScore, 'descend');

    nSelFeature = round(opts.selFeatureNumPercent * numel(meanFeaSelScore));
    selFeatureIdxVector = SortedScoreIdx(1:nSelFeature);

    % Gather Training Dataset
    DataTrain = [];
    DataTrainLabel = [];
    for i = 1:numel(trainBlockData)
        DataTrain = cat(1, DataTrain, trainBlockData{i});
        DataTrainLabel = cat(1, DataTrainLabel, trainBlockLabel{i});
    end
    DataTrain = DataTrain(:, selFeatureIdxVector);

    % Gather Testing Dataset
    DataTest = [];
    DataTestLabel = [];
    for i = 1:numel(testBlockData)
        DataTest = cat(1, DataTest, testBlockData{i});
        DataTestLabel = cat(1, DataTestLabel, testBlockLabel{i});
    end
    DataTest = DataTest(:, selFeatureIdxVector);

     OutputData.FeaSelSortMat = FeaSelSortMat;
     OutputData.meanFeaSelScore = meanFeaSelScore;
     OutputData.SortedScore = SortedScore;
     OutputData.SortedScoreIdx = SortedScoreIdx;
     OutputData.selFeatureIdxVector = selFeatureIdxVector;
end
