function CFTSInfo_VecCell = getCFTCell(opts)
    %% Set filter parameter
    FreqRngMat= opts.FreqRngMat;
    opt.filterBankPara = getFilterBankPara(FreqRngMat,opts);
    opt.FreqRngMat = opts.FreqRngMat;

    %% Set time segment parameter
    opt.TimeRngMat = opts.TimeRngMat;

    %% Set channel group parameter
    opt.nChannel =opts.nChannel;
    opt.SelChCell = getChCell_ChannelSelection(opt);

    opt.Windowfunction = opts.Windowfunction;
    %% Get CFTS information
    [CFTSInfoCell, ~, ~, ~] = getCFTSInfo(opt);
    CFTSInfo_VecCell = CFTSInfoCell(:);
end
