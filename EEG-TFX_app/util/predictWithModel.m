function [results, votingResults] = predictWithModel(inputData, matFilePath)
    load(matFilePath, 'opts'); 

    trainedClassifiers = opts.trainedClassifiers;
    classifierNames = opts.Classifierchosed;
    numClassifiers = numel(classifierNames);


    numBlocks = size(trainedClassifiers, 1);

    fullFeatureData = extractFeatures(inputData, opts)';

    if isfield(opts, 'selectedOption')
        if strcmp(opts.selectedOption, 'Select Certain Features')
            if ~isfield(opts, 'featureMask') || numel(opts.featureMask) ~= size(fullFeatureData, 2)
                error('Invalid featureMask');
            end
            featureData = fullFeatureData(:, opts.featureMask);
        elseif strcmp(opts.selectedOption, 'Traverse All Feature Ratios')
            if ~isfield(opts, 'featureMask') || ~isfield(opts, 'featureScores')
                error('When the Feature selection mode is Traverse All Feature Ratios, Feature Mask and Feature cores are required');
            end
            featureData = fullFeatureData(:, opts.featureMask);
        else
            featureData = fullFeatureData; 
        end
    else
        featureData = fullFeatureData; 
    end

    results = struct();
    votingResults = struct();

    for typeIdx = 1:numClassifiers
        currentName = classifierNames{typeIdx};
        allPredictions = zeros(size(featureData, 1), numBlocks);

        for blockIdx = 1:numBlocks
            try
                model = trainedClassifiers{blockIdx, typeIdx};

                if strcmp(currentName, 'ANN')
                    [pred, ~] = predictANN(model, featureData);
                elseif strcmp(currentName, 'LSTM')
                    numFeatures = model.Layers(1).InputSize;
                    lstmData = arrayfun(@(i) reshape(featureData(i,:), [numFeatures,1]), ...
                        1:size(featureData,1), 'UniformOutput', false)';
                    pred = predict(model, lstmData);
                    if size(pred,2) > 1
                        [~, pred] = max(pred, [], 2);
                    end
                else
                    pred = predict(model, featureData);
                end
                allPredictions(:, blockIdx) = double(pred(:));
            catch
                allPredictions(:, blockIdx) = NaN;
                warning('第%d块%s分类器预测失败', blockIdx, currentName);
            end
        end

        results.(currentName) = allPredictions;
        votingResults.(currentName) = modeWithNaN(allPredictions);

        fprintf(currentName);
        disp(votingResults.(currentName));
    end

 end

function modeResult = modeWithNaN(data)
    [rows, cols] = size(data);
    modeResult = zeros(rows, 1);
    
    for i = 1:rows
        row = data(i, :);
        validValues = row(~isnan(row));
        
        if isempty(validValues)
            modeResult(i) = NaN;
        else

            freqTable = tabulate(validValues);
            [maxCount, idx] = max(freqTable(:,2));

            if sum(freqTable(:,2) == maxCount) > 1
                modeResult(i) = max(freqTable(freqTable(:,2) == maxCount, 1));
            else
                modeResult(i) = freqTable(idx,1);
            end
        end
    end
end

function printMatrix(mat)
    [rows, cols] = size(mat);
    for r = 1:rows
        fprintf('[');
        for c = 1:cols
            if isnan(mat(r,c))
                fprintf(' NaN');
            else
                fprintf(' %g', mat(r,c));
            end
            if c < cols
                fprintf(',');
            end
        end
        fprintf(' ]\n');
    end
end