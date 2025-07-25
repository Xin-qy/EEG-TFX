function filterBankPara = getFilterBankPara(FreqRngMat,opts)
%N = 4;
N = opts.Filterorder;
SAMP = 250;
%SAMP = opts.nFrequency;
% [RngMat, nBand] = GetFreqBands;
RngMat = FreqRngMat;
nBand = size(RngMat,1);
for iBand = 1:nBand
    FreqRng = RngMat(iBand, :);
    W1=[2*FreqRng(1)/SAMP 2*FreqRng(2)/SAMP];
    [filterBankPara(iBand).b,filterBankPara(iBand).a]=butter(N,W1);   
%     [DataTrainCell{iBand}, DataTestCell{iBand}] = FilterBankProc(DataTrain, DataTest, RngMat(iBand, :), N, reSAMP);
end



