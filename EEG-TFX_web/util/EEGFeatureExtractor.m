function DE = EEGFeatureExtractor(dataeeg, CFTSInfo_VecCell, opts)
% function DE = DEFeatureExtractor(dataeeg, Fs)

%   INPUT:  Fs            1000
%           dataeeg       [62,N]:for each person
%   OUTPUT: DEFeature     fea_num*second

% time_length = size(dataeeg,2)/Fs;
% Fs = opts.fs;
% [nChannel,~] = size(dataeeg);
nFeatureType = numel(opts.FeatureExtractMethod);
nCFTS = numel(CFTSInfo_VecCell);
DE = [];    % zeros(nChannel*nCFTS*nFeatureType,1);
for iCFTS = 1:nCFTS
    curCFTSInfo = CFTSInfo_VecCell{iCFTS};
    CFTSData = getCFTSData(dataeeg, curCFTSInfo);
    [nChannel,~] = size(CFTSData);
    fv = zeros(nChannel,nFeatureType);
    for i = 1:nChannel
        fv(i,:) = extractSingleChannelEEGFeature(CFTSData(i,:), opts); %jfeeg(opts.FeatureExtractMethod, banddata, opts);
    end
    fv = fv(:);
    DE = cat(1,DE,fv);
end
