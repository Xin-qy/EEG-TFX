function selChCell = getChCell_ChannelSelection(opt)
    opt.maxSamplePoint = max(opt.TimeRngMat, [], 'all');   
    nchannel =opt.nChannel;
    selChCell{1} = [1: nchannel];
end

%% Support Functioins
function selNsCh = getChSelIdx(allChannelData, Ns, opt)
maxSamplePoint = opt.maxSamplePoint;
% allChannelData = cell2mat(allChannelData);
allChannelData = allChannelData(:,:,1:maxSamplePoint);
nTrial = size(allChannelData, 1);
selChMat = zeros(Ns, nTrial);
parfor iTrial = 1:nTrial
    curTrial = squeeze(allChannelData(iTrial,:,:));
    curTrial_norm = zscore(curTrial')';
%     curTrial_norm = curTrial;
    curTrial_R = corrcoef(curTrial_norm');
    curTrial_meanRow = mean(curTrial_R, 2);
    [~, curTrial_sortIdx] = sort(curTrial_meanRow, 'descend');
    curTrial_selCh = curTrial_sortIdx(1:Ns);
    selChMat(:, iTrial) = curTrial_selCh;
    
end

selChTbl = tabulate(selChMat(:));
selChTbl_chIdx = selChTbl(:,1);
selChTbl_count = selChTbl(:,2);
[~, selChTbl_sortIdx] = sort(selChTbl_count, 'descend');
selNsCh = selChTbl_chIdx(selChTbl_sortIdx(1:Ns))';

end

