function [ranked,p] = F_Test(X,Y,varargin)
%FSRFTEST Univariate feature selection for regression using F-test.
%   IDX=FSRFTEST(TBL,Y) ranks predictors for table TBL and response Y.
%   The predictors are ranked using the F-test.
%
%   TBL contains the predictor variables. Y can be any of the following:
%      1. A column vector of floating-point numbers.
%      2. The name of a variable in TBL. This variable is used as the
%         response Y, and the remaining variables in TBL are used as predictors.
%         This variable must be continuous.
%      3. A formula character vector such as 'y ~ x1 + x2 + x3' specifying
%         that the variable y is to be used as the response, and the other
%         variables in the formula are predictors. Any table variables not
%         listed in the formula are not used.
%
%   IDX is a 1-by-P vector for P predictors. IDX are indices of
%   columns in X ordered by importance, meaning IDX(1) is the index of
%   the most important predictor.
%
%   IDX=FSRFTEST(X,Y) is an alternative syntax that accepts X as an
%   N-by-P matrix of predictors with one row per observation and one column
%   per predictor. Y is the response and is an array of size N-by-1. 
%
%   [IDX,SCORES]=FSRFTEST(...) also returns predictor scores SCORES, a
%   1-by-P array for P predictors. SCORES have the same order as predictors
%   in the input data, meaning SCORES(1) is the score for the first
%   predictor. Large score indicates important predictor.
%
%   [...]=FSRFTEST(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%       'CategoricalPredictors' - List of categorical predictors. Pass
%                        'CategoricalPredictors' as one of:
%                          * A numeric vector with indices between 1 and P,
%                            where P is the number of columns of X or
%                            variables in TBL.
%                          * A logical vector of length P, where a true
%                            entry means that the corresponding column of X
%                            or TBL is a categorical variable. 
%                          * 'all', meaning all predictors are categorical.
%                          * A string array or cell array of character
%                            vectors, where each element in the array is
%                            the name of a predictor variable. The names
%                            must match variable names in table TBL.
%                        Default: for a matrix input X, no categorical
%                        predictors; for a table TBL, predictors are
%                        treated as categorical if they are strings, cell
%                        arrays of character vectors, logical, or unordered
%                        of type 'categorical'.
%       'NumBins'      - Number of bins for binning continuous variables, a    
%                        positive integer. Default: 10.
%       'UseMissing'      - Logical value specifying whether missing values 
%                        in the predictors must be used or discarded. When
%                        'UseMissing' is set to true, missing values are binned
%                        into a separate bin. When it is set to false, missing
%                        values from in each feature will be omitted while 
%                        computing the f-statistics for that feature
%                        with the response. Default: false
%       'Weights'      - Vector of observation weights, one weight per
%                        observation. FSRFTEST normalizes the weights to
%                        add up to 1. Default: ones(size(X,1),1).
%                        For an input table TBL, the 'Weights' value can be
%                        the name of a variable in TBL.

%   Copyright 2019 The MathWorks, Inc.

    if nargin > 1
        Y = convertStringsToChars(Y);
    end

    if nargin > 2
        [varargin{:}] = convertStringsToChars(varargin{:});
    end

    args =   {'NumBins' 'UseMissing'};
    defaults = {10 false};
    [nBins,useMissing,~,otherArgs] = internal.stats.parseArgs(args,defaults,varargin{:});
    
    % Error conditions
    if ~isnumeric(nBins) || ~isscalar(nBins) ...
            || ~isreal(nBins) || nBins~=round(nBins) ...
            || nBins<=0 || isnan(nBins) || isinf(nBins)
        error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadNumBins'));
    end
    
    useMissing = internal.stats.parseOnOff(useMissing,'UseMissing');
    
    D = size(X,2);
    if nBins == 1
        ranked = 1:D;
        p = zeros(1,D);
        return
    end
    
    [X,Y,weights,dataSummary] = ...
      classreg.learning.regr.FullRegressionModel.prepareData(...
      X,Y,otherArgs{:},'OrdinalIsCategorical',false);
  
    D = size(X,2);
    
    % Get indices of categorical features
    catpreds = dataSummary.CategoricalPredictors;
    iscat = false(1,D);
    iscat(catpreds) = true;

    % Bin continuous features.
    nbin = nBins*ones(D,1);

    % binPredictors returns -1 for missing values; these get transformed into
    % ones.
    if ~any(iscat)
        Xbinned = 1 + classreg.learning.treeutils.binPredictors(X,nbin);
    else
        Xbinned = zeros(size(X),'int32');
        Xbinned(:,~iscat) = 1 + classreg.learning.treeutils.binPredictors(...
            X(:,~iscat),nbin(~iscat));
        Xbinned(:,iscat) = classreg.learning.fsutils.indexCategoricals(X(:,iscat));
    end
    
    % Compute p-values
    p = classreg.learning.fsutils.ftest(Xbinned,Y,weights,useMissing);
    p = p(:)';
        
    p = -log(p);
    [~,ranked] = sort(p,'descend');
end
