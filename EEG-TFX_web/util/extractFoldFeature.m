function [featureFoldData, featureFoldLabel] = extractFoldFeature(foldData, foldLabel,opts)
opt.nChannel =opts.nChannel;

FreqRngMat= opts.FreqRngMat;
ParallelSwitch=opts.ParallelSwitch;
%% Set filter parameter
opt.filterBankPara = getFilterBankPara(FreqRngMat,opts);
opt.FreqRngMat = opts.FreqRngMat;

%% Set time segment parameter
opt.TimeRngMat = opts.TimeRngMat;

%% Set channel group parameter
opt.SelChCell = getChCell_ChannelSelection(opt);

opt.Windowfunction = opts.Windowfunction;

%% Get CFTS information
[CFTSInfoCell, ~, ~, ~] = getCFTSInfo(opt);
CFTSInfo_VecCell = CFTSInfoCell(:);

parfor_opts = struct();
parfor_opts.FeatureExtractMethod = opts.FeatureExtractMethod;
parfor_opts.type = opts.type;

if (ParallelSwitch==1)
for iFold = 1:numel(foldData)
    curFoldData = foldData{iFold};
    parfor iSample = 1:size(curFoldData,1)
        curSample = squeeze(curFoldData(iSample,:,:));
        curFeatureFoldData(iSample,:) = EEGFeatureExtractor(curSample, CFTSInfo_VecCell, parfor_opts); 
    end
   % disp(['Preprocessing: ' num2str(toc) 's']);
    featureFoldData{iFold} = curFeatureFoldData;
    featureFoldLabel{iFold} = categorical(foldLabel{iFold});
end
else
         for iFold = 1:numel(foldData)
            curFoldData = foldData{iFold};
            for iSample = 1:size(curFoldData,1)
                         curSample = squeeze(curFoldData(iSample,:,:));
            % DE
            curFeatureFoldData(iSample,:) = EEGFeatureExtractor(curSample, CFTSInfo_VecCell, opts); 

            totalSamples=size(curFoldData,1);
            totalFolds=numel(foldData);
            currentSampleProgress = (iSample / totalSamples) * (1 / totalFolds) + ((iFold - 1) / totalFolds);
            progressMessage = sprintf('Extracting features from fold %d/%d, sample %d/%d', iFold, totalFolds, iSample, totalSamples);
            if ~isempty(opts.progressCallback)
                opts.progressCallback(currentSampleProgress, progressMessage);
            end
            end
%     disp(['Preprocessing: ' num2str(toc) 's']);
    featureFoldData{iFold} = curFeatureFoldData;
    featureFoldLabel{iFold} = categorical(foldLabel{iFold});
         end
end
