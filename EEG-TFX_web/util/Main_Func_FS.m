function [ResData,ResultsData] = Main_Func_FS(opts)

    ResultsData = struct();
    ResultsData.opts = opts;

    numBlocks = numel(opts.featureFoldData);
    numClassifiers = numel(opts.Classifierchosed);
    disp(opts.Classifierchosed);
    Acc = zeros(numBlocks, numClassifiers);

    trainedClassifiers = cell(numBlocks, numClassifiers); 

    for iBlock = 1:numBlocks
        %*** Get Train Test set ***%
        testBlockFlag = false(1, numBlocks);
        testBlockFlag(iBlock) = true;
        testBlockData = opts.featureFoldData(testBlockFlag);
        testBlockLabel = opts.featureFoldLabel(testBlockFlag);
        trainBlockData = opts.featureFoldData(~testBlockFlag);
        trainBlockLabel = opts.featureFoldLabel(~testBlockFlag);

        %*** Formate Data ***%
        [DataTrain, DataTrainLabel, DataTest, DataTestLabel, OutputData] = getFeatureSelectedData(trainBlockData, trainBlockLabel,...
                                                                                          testBlockData, testBlockLabel, opts);

        %*** Formate Data ***%
        DataTrainLabel = categorical(DataTrainLabel);
        DataTestLabel = categorical(DataTestLabel);

        ResData{iBlock}.DataTestLabel = DataTestLabel;
        ResData{iBlock}.OutputData.meanFeaSelScore = OutputData.meanFeaSelScore;

        % 遍历所有选择的分类器
        for iClassifier = 1:numClassifiers
            
            classifierFunction = str2func(opts.Classifierchosed{iClassifier});

            trainedClassifier = classifierFunction(DataTrain, DataTrainLabel);

            trainedClassifiers{iBlock, iClassifier} = trainedClassifier;

            if strcmp(opts.Classifierchosed{iClassifier}, 'ANN')
                [result, ~] = predictANN(trainedClassifier, DataTest);
                result = double(result); 
            elseif strcmp(opts.Classifierchosed{iClassifier}, 'LSTM')
                numFeatures = trainedClassifier.Layers(1).InputSize;
                lstmTestData = cell(size(DataTest,1), 1);
                for i = 1:size(DataTest,1)
                    lstmTestData{i} = reshape(DataTest(i,:), [numFeatures, 1]);
                end
                
                pred = predict(trainedClassifier, lstmTestData);
                
                if size(pred, 2) > 1 
                    [~, result] = max(pred, [], 2); 
                end
                result = double(result(:)); 
            else 
                result = double(predict(trainedClassifier, DataTest));
            end

            if size(DataTestLabel, 1) == 1
                DataTestLabel = DataTestLabel';
            end

            Acc(iBlock, iClassifier) = sum(double(result) == double(DataTestLabel)) / numel(result);
        end
    end

    Acc_Mean = mean(Acc, 1);

    ResultsData.meanBlockclassifier = Acc_Mean;
    ResultsData.blockclassifier = Acc;
    ResultsData.OutputData = OutputData;

    ResultsData.trainedClassifiers = trainedClassifiers; 
end

