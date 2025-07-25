function feat = obtainFuncHandle(methodName, X,opts)    

    fun = str2func(methodName);
   
    if nargin < 3
        opts = struct();
    end

    feat = fun(X, opts);
end