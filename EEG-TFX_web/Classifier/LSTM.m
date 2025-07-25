function Mdl = LSTM(DATA, LABEL)

    numFeatures = size(DATA, 2); 
    numObservations = size(DATA, 1); 
    
    % cell array
    DATA_cell = cell(numObservations, 1);
    for i = 1:numObservations        
        DATA_cell{i} = DATA(i,:)';
    end

    inputSize = numFeatures;
    
    numHiddenUnits = 256;
    numClasses = 2;

    layers = [ ...
        sequenceInputLayer(inputSize)
        bilstmLayer(numHiddenUnits, 'OutputMode', 'last')
        fullyConnectedLayer(numClasses)
        softmaxLayer
        classificationLayer];

    options = trainingOptions('adam', ...
        'L2Regularization', 5e-4, ...
        'InitialLearnRate', 2e-4, ...
        'MaxEpochs', 1, ...
        'MiniBatchSize', 256, ...
        'Shuffle', 'every-epoch', ...
        'Verbose', true, ...
        'ExecutionEnvironment', 'cpu');

    Mdl = trainNetwork(DATA_cell, LABEL, layers, options);
end
