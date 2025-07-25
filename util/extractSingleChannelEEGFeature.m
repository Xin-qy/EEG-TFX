function fv = extractSingleChannelEEGFeature(banddata, opts)
fv = zeros(1,numel(opts.FeatureExtractMethod));
for iFea = 1:numel(opts.FeatureExtractMethod)
    fv(iFea) = obtainFuncHandle(opts.FeatureExtractMethod{iFea}, banddata,opts);
end

end