function DE = DifferentialEntropy(X,~)
    sigma2 = var(X'); %varience, clm prior, return a row.
    DE = (log2(2*pi*exp(1)*sigma2))/2;%DE:a row
    %DE = DE'; %return a clm
end
