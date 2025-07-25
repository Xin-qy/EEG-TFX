function [DataTrain, DataTrainLabel, DataTest, DataTestLabel] = getTrainTestData(DATA, LABEL, iBlock, opt)

    testBlockFlag = false(1,numel(DATA));
    testBlockFlag(iBlock) = true;
    testBlockData = DATA(testBlockFlag);
    testBlockLabel = LABEL(testBlockFlag);
    trainBlockData = DATA(~testBlockFlag);
    trainBlockLabel = LABEL(~testBlockFlag);

    % Gather Training Dataset
    DataTrain = [];
    DataTrainLabel = [];
    for i = 1:numel(trainBlockData)
        DataTrain = cat(1,DataTrain,trainBlockData{i});
        DataTrainLabel = cat(1,DataTrainLabel,trainBlockLabel{i});
    end


    % Gather Testing Dataset
    DataTest = [];
    DataTestLabel = [];
    for i = 1:numel(testBlockData)
        DataTest = cat(1,DataTest,testBlockData{i});
        DataTestLabel = cat(1,DataTestLabel,testBlockLabel{i});
    end        

    
end

