function [ranked,p] = Chi_SquareTest(X,Y,varargin)
%FSCCHI2 Univariate feature selection for classification using Chi-2 test.
%   IDX=FSCCHI2(TBL,Y) ranks predictors for table TBL and class label Y.
%   The predictors are ranked using the Chi-2 test.
%
%   TBL contains the predictor variables. Y can be any of the following:
%      1. An array of class labels. Y can be a categorical array, logical
%         vector, numeric vector, string array or cell array of character 
%         vectors.
%      2. The name of a variable in TBL. This variable is used as the
%         response Y, and the remaining variables in TBL are used as
%         predictors.
%      3. A formula character vector such as 'y ~ x1 + x2 + x3' specifying
%         that the variable y is to be used as the response, and the other
%         variables in the formula are predictors. Any table variables not
%         listed in the formula are not used.
%
%   IDX is a 1-by-P vector for P predictors. IDX are indices of
%   columns in X ordered by importance, meaning IDX(1) is the index of
%   the most important predictor.
%
%   IDX=FSCCHI2(X,Y) is an alternative syntax that accepts X as an
%   N-by-P matrix of predictors with one row per observation and one column
%   per predictor. Y is the response and is an array of N class labels. 
%
%   [IDX,SCORES]=FSCCHI2(...) also returns predictor scores SCORES, a
%   1-by-P array for P predictors. SCORES have the same order as predictors
%   in the input data, meaning SCORES(1) is the score for the first
%   predictor. Large score indicates important predictor.
%
%   [...]=FSCCHI2(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
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
%       'ClassNames'   - Array of class names. Use the data type that
%                        exists in Y. You can use this argument to select a
%                        subset of classes out of all classes in Y.
%                        Default: All class names in Y.
%       'NumBins'      - Number of bins for binning continuous variables, a
%                        positive integer. Default: 10.
%       'Prior'        - Prior probabilities for each class. Specify as one of:
%                         * A character vector:
%                           - 'empirical' determines class probabilities
%                             from class frequencies in Y
%                           - 'uniform' sets all class probabilities equal
%                         * A vector (one scalar value for each class)
%                         * A structure S with two fields: S.ClassProbs
%                           containing a vector of class probabilities, and
%                           S.ClassNames classes containing the class names
%                           and defining the ordering of classes used for
%                           the elements of this vector.
%                        If you pass numeric values, FSCCHI2 normalizes
%                        them to add up to one. Default: 'empirical'
%       'UseMissing'      - Logical value specifying whether missing values 
%                        in the predictors must be used or discarded. When
%                        'UseMissing' is set to true, missing values are binned
%                        into a separate bin. When it is set to false,
%                        missing values from in each feature will be omitted 
%                        while computing the chi-2 statistics for that feature
%                        with the response. Default: false
%       'Weights'      - Vector of observation weights, one weight per
%                        observation. FSCCHI2 normalizes the weights to
%                        add up to the value of the prior probability in
%                        the respective class. Default: ones(size(X,1),1).
%                        For an input table TBL, the 'Weights' value can be
%                        the name of a variable in TBL.

%   Copyright 2019 The MathWorks, Inc.

    if nargin > 1
        Y = convertStringsToChars(Y);
    end

    if nargin > 2
        [varargin{:}] = convertStringsToChars(varargin{:});
    end

    args =   {'NumBins','UseMissing'};
    defaults = {10,false};
    [nBins,useMissing,~,otherArgs] = internal.stats.parseArgs(args,defaults,varargin{:});
    
    % Error conditions
    if ~isnumeric(nBins) || ~isscalar(nBins) ...
            || ~isreal(nBins) || nBins~=round(nBins) ...
            || nBins<=0 || isnan(nBins) || isinf(nBins)
        error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadNumBins'));
    end

    useMissing = internal.stats.parseOnOff(useMissing,'UseMissing');
    
    [X,Y,weights,dataSummary] = ...
      classreg.learning.classif.FullClassificationModel.prepareData(...
      X,Y,otherArgs{:},'OrdinalIsCategorical',false);
  
    Y = int32(grp2idx(Y));
    D = size(X,2);
    
    % Edge case: one class only or only one bin
    if max(Y)==1 || nBins == 1
        ranked = 1:D;
        p = zeros(1,D);
        return
    end

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
    p = classreg.learning.fsutils.chi2test(Xbinned,Y,weights,useMissing);
    p = p(:)';
        
    p = -log(p);
    [~,ranked] = sort(p,'descend'); 
end
