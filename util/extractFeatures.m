function featureData = extractFeatures(inputData, opts)
    opt = struct();
    opt.nChannel = opts.nChannel;
    opt.FreqRngMat = opts.FreqRngMat;
    opt.Windowfunction = opts.Windowfunction;
    opt.TimeRngMat = opts.TimeRngMat;
    opt.fs = opts.fs;

    opt.filterBankPara = getFilterBankPara(opt.FreqRngMat, opts);

    opt.SelChCell = getChCell_ChannelSelection(opt);

    [CFTSInfoCell, ~, ~, ~] = getCFTSInfo(opt);
    CFTSInfo_VecCell = CFTSInfoCell(:);

    featureData = EEGFeatureExtractor(inputData, CFTSInfo_VecCell, opts);
end