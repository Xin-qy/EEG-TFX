% function [ranked,weight] = RelieffV(X,Y)
% K=10;
% [ranked,weight] = Relieff(X,Y,K,varargin);

% end
function [ranked, weight] = Relieff(X, Y, varargin)
% RelieffV: Wrapper function for Relieff with default K=10
% [ranked, weight] = RelieffV(X, Y, varargin)
% This function calls the Relieff function with a default K=10.
% Additional optional parameters can be passed via varargin.

    % Set default value for K
    K = 10;

    % Call the original Relieff function with the specified K and additional arguments
    [ranked, weight] = relieff(X, Y, K, varargin{:});
end

% ------------------------------------------------------------------------- 
% Subfunction: Relieff
function [ranked, weight] = relieff(X, Y, K, varargin)
% RELIEFF Importance of attributes (predictors) using ReliefF algorithm.
%   [IDX, WEIGHT] = RELIEFF(X, Y, K) computes ranks and weights of attributes
%   (predictors) for input data matrix X and response vector Y using
%   ReliefF algorithm for classification or RReliefF for regression with K
%   nearest neighbors. For classification, RELIEFF uses K nearest neighbors
%   per class. IDX are indices of columns in X ordered by attribute
%   importance, meaning IDX(1) is the index of the most important
%   predictor. WEIGHT are attribute weights ranging from -1 to 1 with large
%   positive weights assigned to important attributes.

    % Check number of required arguments
    if nargin > 1
        Y = convertStringsToChars(Y);
    end

    if nargin > 3
        [varargin{:}] = convertStringsToChars(varargin{:});
    end

    if nargin < 3
        error(message('stats:relieff:TooFewInputs'));
    end

    % Check if the predictors in X are of the right type
    if ~isnumeric(X)
        error(message('stats:relieff:BadX'));
    end

    % Parse input arguments
    validArgs = {'method' 'prior' 'updates' 'categoricalx' 'sigma'};
    defaults = {      ''      []     'all'            'off'      []};

    % Get optional args
    [method, prior, numUpdates, categoricalX, sigma] = ...
        internal.stats.parseArgs(validArgs, defaults, varargin{:});

    % Classification or regression?
    isRegression = [];
    if ~isempty(method)
        method = internal.stats.getParamVal(method, {'regression', 'classification'}, '''Method''');
        isRegression = strcmp(method, 'regression');
    end

    % Check the type of Y
    if isnumeric(Y)
        if isempty(isRegression)
            isRegression = true;
        end
    elseif iscellstr(Y) || ischar(Y) || isa(Y, 'categorical') || islogical(Y)
        if isempty(isRegression)
            isRegression = false;
        elseif isRegression
            error(message('stats:relieff:BadYTypeForClass'));
        end
    else
        error(message('stats:relieff:BadYType'));
    end

    % Reject prior for regression
    if isRegression && ~isempty(prior)
        error(message('stats:relieff:NoPriorForRegression'));
    end

    % Check if the input sizes are consistent
    if (~ischar(Y) && length(Y) ~= size(X, 1)) || (ischar(Y) && size(Y, 1) ~= size(X, 1))
        error(message('stats:relieff:XYSizeMismatch'));
    end

    % Prepare data for classification or regression
    if isRegression
        [X, Y] = removeNaNs(X, Y);
    else % Group Y for classification. Get class counts and probabilities.
        % Get groups and matrix of class counts
        if isa(Y, 'categorical')
            Y = removecats(Y);
        end
        [Y, grp] = grp2idx(Y);
        [X, Y] = removeNaNs(X, Y);
        Ngrp = numel(grp);
        N = size(X, 1);
        C = false(N, Ngrp);
        C(sub2ind([N Ngrp], (1:N)', Y)) = true;

        % Get class probs
        if isempty(prior) || strcmpi(prior, 'empirical')
            classProb = sum(C, 1);
        elseif strcmpi(prior, 'uniform')
            classProb = ones(1, Ngrp);
        elseif isstruct(prior)
            if ~isfield(prior, 'group') || ~isfield(prior, 'prob')
                error(message('stats:relieff:PriorWithMissingField'));
            end
            if iscell(prior.group)
                usrgrp = prior.group;
            else
                usrgrp = cellstr(prior.group);
            end
            [tf, pos] = ismember(grp, usrgrp);
            if any(~tf)
                error(message('stats:relieff:PriorWithClassNotFound', grp{find(~tf, 1)}));
            end
            classProb = prior.prob(pos);
        elseif isnumeric(prior)
            if ~isfloat(prior) || length(prior) ~= Ngrp || any(prior < 0) || all(prior == 0)
                error(message('stats:relieff:BadNumericPrior', Ngrp));
            end
            classProb = prior;
        else
            error(message('stats:relieff:BadPrior'));
        end

        % Normalize class probs
        classProb = classProb / sum(classProb);

        % If there are classes with zero probs, remove them
        zeroprob = classProb == 0;
        if any(zeroprob)
            t = zeroprob(Y);
            if sum(t) == length(Y)
                error(message('stats:relieff:ZeroWeightPrior'));
            end
            Y(t) = [];
            X(t, :) = [];
            C(t, :) = [];
            C(:, zeroprob) = [];
            classProb(zeroprob) = [];
        end
    end

    % Do we have enough observations?
    if length(Y) < 2
        error(message('stats:relieff:NotEnoughObs'));
    end

    % Check the number of nearest neighbors
    if ~isnumeric(K) || ~isscalar(K) || K <= 0
        error(message('stats:relieff:BadK'));
    end
    K = ceil(K);

    % Check number of updates
    if (~ischar(numUpdates) || ~strcmpi(numUpdates, 'all')) && ...
            (~isnumeric(numUpdates) || ~isscalar(numUpdates) || numUpdates <= 0)
        error(message('stats:relieff:BadNumUpdates'));
    end
    if ischar(numUpdates)
        numUpdates = size(X, 1);
    else
        numUpdates = ceil(numUpdates);
    end

    % Check the type of X
    if ~ischar(categoricalX) || ...
            (~strcmpi(categoricalX, 'on') && ~strcmpi(categoricalX, 'off'))
        error(message('stats:relieff:BadCategoricalX'));
    end
    categoricalX = strcmpi(categoricalX, 'on');

    % Check sigma
    if ~isempty(sigma) && ...
            (~isnumeric(sigma) || ~isscalar(sigma) || sigma <= 0)
        error(message('stats:relieff:BadSigma'));
    end
    if isempty(sigma)
        if isRegression
            sigma = 50;
        else
            sigma = Inf;
        end
    end

    % The # updates cannot be more than the # observations
    numUpdates = min(numUpdates, size(X, 1));

    % Choose the distance function depending upon the categoricalX
    if ~categoricalX
        distFcn = 'cityblock';
    else
        distFcn = 'hamming';
    end

    % Find max and min for every predictor
    p = size(X, 2);
    Xmax = max(X);
    Xmin = min(X);
    Xdiff = Xmax - Xmin;

    % Exclude single-valued attributes
    isOneValue = Xdiff < eps(Xmax);
    if all(isOneValue)
        ranked = 1:p;
        weight = NaN(1, p);
        return;
    end
    X(:, isOneValue) = [];
    Xdiff(isOneValue) = [];
    rejected = find(isOneValue);
    accepted = find(~isOneValue);

    % Scale and center the attributes
    if ~categoricalX
        X = bsxfun(@rdivide, bsxfun(@minus, X, mean(X)), Xdiff);
    end

    % Get appropriate distance function in one dimension.
    % thisx must be a row-vector for one observation.
    % x can have more than one row.
    if ~categoricalX
        dist1D = @(thisx, x) cityblock(thisx, x);
    else
        dist1D = @(thisx, x) hamming(thisx, x);
    end

    % Call ReliefF. By default all weights are set to NaN.
    weight = NaN(1, p);
    if ~isRegression
        weight(accepted) = RelieffClass(X, C, classProb, numUpdates, K, distFcn, dist1D, sigma);
    else
        weight(accepted) = RelieffReg(X, Y, numUpdates, K, distFcn, dist1D, sigma);
    end

    % Assign ranks to attributes
    [~, sorted] = sort(weight(accepted), 'descend');
    ranked = accepted(sorted);
    ranked(end + 1:p) = rejected;
end

% ------------------------------------------------------------------------- 
function attrWeights = RelieffClass(scaledX, C, classProb, numUpdates, K, ...
    distFcn, dist1D, sigma)
% ReliefF for classification

    [numObs, numAttr] = size(scaledX);
    attrWeights = zeros(1, numAttr);
    Nlev = size(C, 2);

    % Choose the random instances
    rndIdx = randsample(numObs, numUpdates);
    idxVec = (1:numObs)';

    % Make searcher objects, one object per class. 
    searchers = cell(Nlev, 1);
    for c = 1:Nlev
        searchers{c} = createns(scaledX(C(:, c), :), 'Distance', distFcn);
    end

    % Outer loop, for updating attribute weights iteratively
    for i = 1:numUpdates
        thisObs = rndIdx(i);

        % Choose the correct random observation
        selectedX = scaledX(thisObs, :);

        % Find the class for this observation
        thisC = C(thisObs, :);

        % Find the k-nearest hits 
        sameClassIdx = idxVec(C(:, thisC));

        % we may not always find numNeighbor Hits
        lenHits = min(length(sameClassIdx) - 1, K);

        % find nearest hits
        % It is not guaranteed that the first hit is the same as thisObs. Since
        % they have the same class, it does not matter. If we add observation
        % weights in the future, we will need here something similar to what we
        % do in ReliefReg.
        Hits = [];
        if lenHits > 0
            idxH = knnsearch(searchers{thisC}, selectedX, 'K', lenHits + 1);
            idxH(1) = [];
            Hits = sameClassIdx(idxH);
        end

        % Process misses
        missClass = find(~thisC);
        Misses = [];

        if ~isempty(missClass) % Make sure there are misses!
            % Find the k-nearest misses Misses(C,:) for each class C ~= class(selectedX)
            % Misses will be of size (no. of classes -1)x(K)
            Misses = zeros(Nlev - 1, min(numObs, K + 1)); % last column has class index

            for mi = 1:length(missClass)

                % find all observations of this miss class
                missClassIdx = idxVec(C(:, missClass(mi)));

                % we may not always find K misses
                lenMiss = min(length(missClassIdx), K);

                % find nearest misses
                idxM = knnsearch(searchers{missClass(mi)}, selectedX, 'K', lenMiss);
                Misses(mi, 1:lenMiss) = missClassIdx(idxM);

            end

            % Misses contains obs indices for miss classes, sorted by dist.
            Misses(:, end) = missClass;
        end

        %***************** ATTRIBUTE UPDATE *****************************
        % Inner loop to update weights for each attribute:

        for j = 1:numAttr
            dH = diffH(j, scaledX, thisObs, Hits, dist1D, sigma) / numUpdates;
            dM = diffM(j, scaledX, thisObs, Misses, dist1D, sigma, classProb) / numUpdates;
            attrWeights(j) = attrWeights(j) - dH + dM;
        end
        %****************************************************************
    end
end

% ------------------------------------------------------------------------- 
function attrWeights = RelieffReg(scaledX, Y, numUpdates, K, distFcn, dist1D, sigma)
% ReliefF for regression

    % Initialize the variables used to calculate the probabilities
    % NdC : corresponds to the probability two nearest instances
    % have different predictions.
    % NdA(i) : corresponds to the probability that two nearest instances
    % have different values for the attribute 'i'
    % NdAdC(i) : corresponds to the probability that two nearest
    % instances have different predictions, and different values for 'i'

    [numObs, numAttr] = size(scaledX);
    NdC = 0;
    NdA = zeros(1, numAttr);
    NdAdC = zeros(1, numAttr);

    % Select 'numUpdates' random instances
    rndIdx = randsample(numObs, numUpdates);

    % Scale and center the response
    % We need to do this for regression. 'y'-distance between instances
    % is used to evaluate the attribute weights.
    Ymax = max(Y);
    Ymin = min(Y);
    Y = bsxfun(@rdivide, bsxfun(@minus, Y, mean(Y)), Ymax - Ymin);

    % How many neighbors can we find?
    lenNei = min(numObs - 1, K);

    % The influences of neighbors decreases with their distance from
    % the random instance. Calculate the weights that describe this
    % decreasing influence. 
    distWts = exp(-((1:lenNei) / sigma).^2)';
    distWts = distWts / sum(distWts);

    % Create NN searcher
    searcher = createns(scaledX, 'Distance', distFcn);

    % Outer loop that iterates over the randomly chosen attributes
    for i = 1:numUpdates
        thisObs = rndIdx(i);

        % Choose the correct random observation
        selectedX = scaledX(thisObs, :);

        % Find the k-nearest instances to the random instance
        idxNearest = knnsearch(searcher, selectedX, 'K', lenNei + 1);

        % Exclude this observation from the list of nearest neighbors if it is
        % there. If not, exclude the last one.
        tf = idxNearest == thisObs;
        if any(tf)
            idxNearest(tf) = [];
        else
            idxNearest(end) = [];
        end

        % Update NdC
        NdC = NdC + sum(abs(Y(thisObs) - Y(idxNearest)) .* distWts);

        % Update NdA and NdAdC for each attribute
        for a = 1:numAttr
            vdiff = dist1D(scaledX(thisObs, a), scaledX(idxNearest, a));
            NdA(a) = NdA(a) + sum(vdiff .* distWts);
            NdAdC(a) = NdAdC(a) + ...
                sum(vdiff .* abs(Y(thisObs) - Y(idxNearest)) .* distWts);
        end
    end

    attrWeights = NdAdC / NdC - (NdA - NdAdC) / (numUpdates - NdC);
end

% ------------------------------------------------------------------------- 
% Helper functions for RelieffReg and RelieffClass

%-------------------------------------------------------------------------- 
% DIFFH (for RelieffClass): Function to calculate difference measure
% for an attribute between the selected instance and its hits

function distMeas = diffH(a, X, thisObs, Hits, dist1D, sigma)

    % If no hits, return zero by default
    if isempty(Hits)
        distMeas = 0;
        return;
    end

    % Get distance weights
    distWts = exp(-((1:length(Hits)) / sigma).^2)';
    distWts = distWts / sum(distWts);

    % Calculate weighted sum of distances
    distMeas = sum(dist1D(X(thisObs, a), X(Hits, a)) .* distWts);
end

%-------------------------------------------------------------------------- 
% DIFFM (for RelieffClass) : Function to calculate difference measure
% for an attribute between the selected instance and its misses
function distMeas = diffM(a, X, thisObs, Misses, dist1D, sigma, classProb)

    distMeas = 0;

    % If no misses, return zero
    if isempty(Misses)
        return;
    end

    % Loop over misses
    for mi = 1:size(Misses, 1)

        ismiss = Misses(mi, 1:end - 1) ~= 0;

        if any(ismiss)
            cls = Misses(mi, end);
            nmiss = sum(ismiss);

            distWts = exp(-((1:nmiss) / sigma).^2)';
            distWts = distWts / sum(distWts);

            distMeas = distMeas + ...
                sum(dist1D(X(thisObs, a), X(Misses(mi, ismiss), a)) .* distWts(1:nmiss)) ...
                * classProb(cls);
        end
    end

    % Normalize class probabilities.
    % This is equivalent to P(C)/(1-P(class(R))) in ReliefF paper.
    totProb = sum(classProb(Misses(:, end)));
    distMeas = distMeas / totProb;
end

% ------------------------------------------------------------------------- 
function [X, Y] = removeNaNs(X, Y)
    % Remove observations with missing data
    NaNidx = bsxfun(@or, isnan(Y), any(isnan(X), 2));
    X(NaNidx, :) = [];
    Y(NaNidx, :) = [];
end

% ------------------------------------------------------------------------- 
function d = cityblock(thisX, X)
    d = abs(thisX - X);
end

% ------------------------------------------------------------------------- 
function d = hamming(thisX, X)
    d = thisX ~= X;
end