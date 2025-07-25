function [DataTrain, DataTrainLabel, DataTest, DataTestLabel] = getAllDataTrain(trainBlockData, trainBlockLabel, testBlockData, testBlockLabel, opts)

    opts.ExecuteMode = 'for';

    % Gather Training Dataset
    DataTrain = [];
    DataTrainLabel = [];
    for i = 1:numel(trainBlockData)
        DataTrain = cat(1, DataTrain, trainBlockData{i});
        DataTrainLabel = cat(1, DataTrainLabel, trainBlockLabel{i});
    end
    DataTrain = DataTrain(:,:);
    

    % Gather Testing Dataset
    DataTest = [];
    DataTestLabel = [];
    for i = 1:numel(testBlockData)
        DataTest = cat(1, DataTest, testBlockData{i});
        DataTestLabel = cat(1, DataTestLabel, testBlockLabel{i});
    end
    DataTest = DataTest(:,:);

end